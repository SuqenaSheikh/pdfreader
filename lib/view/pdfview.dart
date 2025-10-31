import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import '../contents/assets/assets.dart';
import '../contents/services/recent_pdf_storage.dart';

// ---------------- main screen ----------------
class PDFViewerScreen extends StatefulWidget {
  final String path;
  final String name;

  const PDFViewerScreen({super.key, required this.path, required this.name});

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  final PdfViewerController _controller = PdfViewerController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _viewerKey = GlobalKey();
  final ImagePicker _imagePicker = ImagePicker();
  final GlobalKey _pdfViewerInternalKey = GlobalKey();

  // UI state
  bool _showSearchBar = false;
  String _selectedTool =
      ''; // '', 'text', 'signature'  (highlight left to selection menu)
  Color _selectedColor = Colors.black;
  Color _selectedBgColor = Colors.transparent;
  double _opacity = 0.5;

  // selection storage (unchanged)
  Rect? _lastSelectionGlobalRect;
  String? _lastSelectedText;
  int? _lastSelectedPageNumber;

  // overlays (kept as you had them)
  final List<_HighlightOverlay> _highlights = [];
  final List<_TextOverlay> _texts = [];
  final List<_ImageOverlay> _images = [];

  // page metrics
  final List<Size> _pageSizes = [];
  final double _pageSpacing = 8.0; // keep in sync with SfPdfViewer.pageSpacing
  bool _pagesReady = false;

  // temporary mode flag: after closing sheet for text, we enable placement until the user adds a text overlay
  bool _awaitingTextPlacement = false;

  @override
  void initState() {
    super.initState();
    RecentPDFStorage.addPDF(widget.path, widget.name);
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    _loadPageSizes();
  }

  Future<void> _loadPageSizes() async {
    try {
      final bytes = await File(widget.path).readAsBytes();
      final doc = PdfDocument(inputBytes: bytes);
      _pageSizes.clear();
      for (int i = 0; i < doc.pages.count; i++) {
        final page = doc.pages[i];
        final s = page.getClientSize();
        _pageSizes.add(Size(s.width, s.height));
      }
      doc.dispose();
      setState(() {
        _pagesReady = true;
      });
    } catch (_) {
      setState(() {
        _pagesReady = false;
      });
    }
  }

  double _effectiveScaleForPage(int pageNumber) {
    if (_pageSizes.isEmpty) return 1.0;
    final box = _viewerKey.currentContext?.findRenderObject() as RenderBox?;
    final viewerWidth = box?.size.width ?? 300.0;
    final pageSize =
        _pageSizes[(pageNumber - 1).clamp(0, _pageSizes.length - 1)];
    final base = viewerWidth / pageSize.width;
    return base * _controller.zoomLevel;
  }

  double _pageTopInScroll(int pageNumber) {
    if (_pageSizes.isEmpty) return 0.0;
    double y = 0.0;
    for (int p = 1; p < pageNumber; p++) {
      final size = _pageSizes[p - 1];
      final scale = _effectiveScaleForPage(p);
      y += size.height * scale + _pageSpacing;
    }
    return y;
  }

  int _pageForContentY(double contentY) {
    if (_pageSizes.isEmpty) return 1;
    double acc = 0.0;
    for (int i = 0; i < _pageSizes.length; i++) {
      final scale = _effectiveScaleForPage(i + 1);
      final h = _pageSizes[i].height * scale;
      final next = acc + h;
      if (contentY < next) return i + 1;
      acc = next + _pageSpacing;
    }
    return _pageSizes.length;
  }

  Offset _pageToLocal(int pageNumber, Offset pagePoint) {
    final scale = _effectiveScaleForPage(pageNumber);
    final top = _pageTopInScroll(pageNumber);
    final localX = pagePoint.dx * scale;
    final localY = pagePoint.dy * scale - _controller.scrollOffset.dy + top;
    return Offset(localX, localY);
  }

  Offset _localToPagePoint(int pageNumber, Offset localPoint) {
    final scale = _effectiveScaleForPage(pageNumber);
    final top = _pageTopInScroll(pageNumber);
    final pageX = localPoint.dx / scale;
    final pageY = (localPoint.dy + _controller.scrollOffset.dy - top) / scale;
    return Offset(pageX, pageY);
  }

  ({int page, Offset pagePoint}) _localToPage(Offset localPoint) {
    final contentY = localPoint.dy + _controller.scrollOffset.dy;
    final page = _pageForContentY(contentY);
    final pt = _localToPagePoint(page, localPoint);
    return (page: page, pagePoint: pt);
  }

  // ---------------- search ----------------
  void _toggleSearchBar() {
    setState(() => _showSearchBar = !_showSearchBar);
    if (!_showSearchBar) {
      _controller.searchText('');
      _searchController.clear();
    }
  }

  void _performSearch(String query) {
    if (query.trim().isNotEmpty) {
      _controller.searchText(query);
    } else {
      _controller.searchText('');
    }
  }

  // ---------------- edit sheet ----------------
  Future<void> _openEditSheet() async {
    // show sheet and wait for result. The sheet returns a Map with chosen config or null on cancel.
    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.55,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: PdfEditSheet(
              // initial values passed for convenience
              initialColor: _selectedColor,
              initialBg: _selectedBgColor,
              initialFontSize: 18,
            ),
          ),
        );
      },
    );

    if (result == null) {
      // user cancelled sheet
      setState(() {
        _selectedTool = '';
        _awaitingTextPlacement = false;
      });
      return;
    }

    final action = result['action'] as String?;
    if (action == 'text') {
      // store selected config and enable placement mode
      setState(() {
        _selectedTool = 'text';
        _selectedColor = result['color'] as Color? ?? Colors.black;
        _selectedBgColor = result['bg'] as Color? ?? Colors.transparent;
        _awaitingTextPlacement = true;
      });
      // instruct user (optional): user will tap PDF to add text
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tap on PDF to add text (then drag to position). Save to embed.',
          ),
        ),
      );
    } else if (action == 'signature') {
      // immediately open image picker (sheet asked to upload signature)
      setState(() {
        _selectedTool = 'signature';
      });
      await _pickSignatureImage(); // adds image overlay to list
      // keep signature mode active (so user can drag); they'll press Save when ready to embed
    } else {
      // unknown or cancel
      setState(() {
        _selectedTool = '';
        _awaitingTextPlacement = false;
      });
    }
  }

  // ---------------- signature pick ----------------
  Future<Uint8List?> _removeWhiteBackground(
    Uint8List inputBytes, {
    int threshold = 245,
  }) async {
    try {
      final ui.Codec codec = await ui.instantiateImageCodec(inputBytes);
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ui.Image img = fi.image;
      final ByteData? bd = await img.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (bd == null) return inputBytes;
      final Uint8List pixels = bd.buffer.asUint8List();
      for (int i = 0; i < pixels.length; i += 4) {
        final r = pixels[i];
        final g = pixels[i + 1];
        final b = pixels[i + 2];
        if (r >= threshold && g >= threshold && b >= threshold) {
          pixels[i + 3] = 0;
        }
      }
      final ui.Image outImage = await _imageFromPixels(
        pixels,
        img.width,
        img.height,
      );
      final ByteData? png = await outImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return png?.buffer.asUint8List();
    } catch (_) {
      return inputBytes;
    }
  }

  Future<ui.Image> _imageFromPixels(
    Uint8List rgbaPixels,
    int width,
    int height,
  ) async {
    final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(
      rgbaPixels,
    );
    final ui.ImageDescriptor descriptor = ui.ImageDescriptor.raw(
      buffer,
      height: height,
      width: width,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final ui.Codec codec = await descriptor.instantiateCodec();
    final ui.FrameInfo fi = await codec.getNextFrame();
    return fi.image;
  }

  Future<void> _pickSignatureImage() async {
    // allow both gallery and camera selection (simple approach - open gallery by default)
    final XFile? xfile = await _imagePicker.pickImage(
      source: ImageSource.camera,
    );
    if (xfile == null) return;
    final raw = await File(xfile.path).readAsBytes();
    final cleaned = await _removeWhiteBackground(raw) ?? raw;
    final center = await _viewerCenterOffset();
    if (_pageSizes.isEmpty) await _loadPageSizes();
    final hit = _localToPage(center);
    // default width: 40% of page width, keep aspect ratio
    final ui.Codec codec = await ui.instantiateImageCodec(cleaned);
    final ui.FrameInfo fi = await codec.getNextFrame();
    final imgW = fi.image.width.toDouble();
    final imgH = fi.image.height.toDouble();
    final pageW =
        _pageSizes[(hit.page - 1).clamp(0, _pageSizes.length - 1)].width;
    final targetW = pageW * 0.4;
    final targetH = targetW * (imgH / imgW);
    final overlay = _ImageOverlay(
      bytes: cleaned,
      pageNumber: hit.page,
      pageOffset: Offset(
        (hit.pagePoint.dx - targetW / 2).clamp(0, pageW - targetW),
        (hit.pagePoint.dy - targetH / 2).clamp(0, double.infinity),
      ),
      pageWidth: targetW,
      pageHeight: targetH,
    );
    setState(() => _images.add(overlay));
  }

  Future<Offset> _viewerCenterOffset() async {
    await Future.delayed(Duration.zero);
    final box = _viewerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return const Offset(100, 100);
    final size = box.size;
    return Offset(size.width / 2, size.height / 2);
  }

  // ---------------- text selection (highlight via selection menu kept) ----------------
  void _onTextSelectionChanged(PdfTextSelectionChangedDetails details) {
    if (details.selectedText == null || details.selectedText!.trim().isEmpty) {
      _lastSelectedText = null;
      _lastSelectionGlobalRect = null;
      _lastSelectedPageNumber = null;
      return;
    }
    _lastSelectedText = details.selectedText;
    _lastSelectionGlobalRect = details.globalSelectedRegion;
    _lastSelectedPageNumber ??= 1;
    // NOTE: we intentionally do NOT auto-apply highlight here — keep selection menu behavior.
  }

  Future<void> _applyHighlightFromSelection() async {
    if (_lastSelectionGlobalRect == null || _lastSelectedPageNumber == null) return;

    final localRect = await _globalRectToLocal(_lastSelectionGlobalRect!);
    if (localRect == null) return;

    final hit = _localToPage(localRect.center);
    final pageSize = _pageSizes[hit.page - 1];
    final scale = _effectiveScaleForPage(hit.page);

    final pdfRect = Rect.fromLTWH(
      localRect.left / scale,
      localRect.top / scale,
      localRect.width / scale,
      localRect.height / scale,
    );

    final overlay = _HighlightOverlay(
      pageNumber: hit.page,
      rect: pdfRect,
      color: _selectedColor.withOpacity(_opacity),
    );

    setState(() {
      _highlights.add(overlay);
      _controller.clearSelection();
      _lastSelectedText = null;
      _lastSelectionGlobalRect = null;
      _lastSelectedPageNumber = null;
    });
  }

  // ---------------- convert global rect to viewer local ----------------
  Future<Rect?> _globalRectToLocal(Rect globalRect) async {
    final box = _viewerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final topLeftLocal = box.globalToLocal(globalRect.topLeft);
    final bottomRightLocal = box.globalToLocal(globalRect.bottomRight);
    return Rect.fromPoints(topLeftLocal, bottomRightLocal);
  }

  // ---------------- place text on tap ----------------
  void _onViewerTap(TapUpDetails details) {
    final localPos = _getLocalPosition(details.globalPosition);
    if (localPos == null) return;

    if (_selectedTool == 'text' && _awaitingTextPlacement) {
      _showAddTextDialog(localPos);
      // after adding one text overlay, keep placement off so user can choose again via bottom sheet
      setState(() {
        _awaitingTextPlacement = false;
        // keep _selectedTool == 'text' so draggable UI remains active; user must press Save to flatten
      });
    }
  }

  Offset? _getLocalPosition(Offset global) {
    final box = _viewerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return box.globalToLocal(global);
  }

  Future<void> _showAddTextDialog(Offset pos) async {
    final TextEditingController tc = TextEditingController();
    String fontSize = '18';
    bool bold = false;
    bool italic = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add text'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tc,
                decoration: const InputDecoration(hintText: 'Type text'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Size:'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: (v) => fontSize = v,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'e.g. 18'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: bold,
                    onChanged: (v) {
                      bold = v ?? false;
                    },
                  ),
                  const Text('B'),
                  const SizedBox(width: 12),
                  Checkbox(
                    value: italic,
                    onChanged: (v) {
                      italic = v ?? false;
                    },
                  ),
                  const Text('I'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final text = tc.text.trim();
                if (text.isEmpty) return;
                final size = double.tryParse(fontSize) ?? 18.0;
                if (_pageSizes.isEmpty) {
                  await _loadPageSizes();
                }
                final hit = _localToPage(pos);
                final overlay = _TextOverlay(
                  pageNumber: hit.page,
                  text: text,
                  color: _selectedColor,
                  fontSize: size,
                  pageOffset: hit.pagePoint,
                );
                setState(() => _texts.add(overlay));
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // ---------------- drag & edit overlays ----------------
  void _updateTextPosition(int index, Offset newPageOffset) {
    setState(() {
      _texts[index] = _texts[index].copyWith(pageOffset: newPageOffset);
    });
  }

  void _removeText(int index) {
    setState(() => _texts.removeAt(index));
  }
  void _updateImagePosition(int index, Offset newPageOffset) {
    setState(() => _images[index] = _images[index].copyWith(pageOffset: newPageOffset));
  }

  void _updateImageSize(int index, double w, double h) {
    setState(() => _images[index] = _images[index].copyWith(pageWidth: w, pageHeight: h));
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  void _removeHighlight(int index) {
    setState(() => _highlights.removeAt(index));
  }

  // ---------------- Save to PDF (unchanged) ----------------
  Future<void> _savePdfWithChanges() async {
    try {
      final bytes = await File(widget.path).readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      final box = _viewerKey.currentContext?.findRenderObject() as RenderBox?;
      final viewerSize = box?.size ?? const Size(300, 400);

      for (final h in _highlights) {
        final pageIndex = (h.pageNumber - 1).clamp(0, document.pages.count - 1);
        final page = document.pages[pageIndex];
        final pdfPageSize = page.getClientSize();
        final scaleX = pdfPageSize.width / viewerSize.width;
        final scaleY = pdfPageSize.height / viewerSize.height;
        final r = h.rect;
        final pdfRect = Rect.fromLTWH(
          r.left * scaleX,
          r.top * scaleY,
          r.width * scaleX,
          r.height * scaleY,
        );
        final brush = PdfSolidBrush(
          PdfColor(h.color.red, h.color.green, h.color.blue),
        );
        page.graphics.drawRectangle(
          bounds: Rect.fromLTWH(
            pdfRect.left,
            pdfRect.top,
            pdfRect.width,
            pdfRect.height,
          ),
          pen: PdfPen(PdfColor(0, 0, 0, 0)),
          brush: brush,
        );
      }

      for (final t in _texts) {
        final pageIndex = (t.pageNumber - 1).clamp(0, document.pages.count - 1);
        final page = document.pages[pageIndex];
        final pdfX = t.pageOffset.dx;
        final pdfY = t.pageOffset.dy;
        final font = PdfStandardFont(PdfFontFamily.helvetica, t.fontSize);
        final brush = PdfSolidBrush(
          PdfColor(t.color.red, t.color.green, t.color.blue),
        );
        page.graphics.drawString(
          t.text,
          font,
          brush: brush,
          bounds: Rect.fromLTWH(pdfX, pdfY, 500, 200),
        );
      }

      for (final im in _images) {
        final pageIndex = (im.pageNumber - 1).clamp(
          0,
          document.pages.count - 1,
        );
        final page = document.pages[pageIndex];
        final pdfX = im.pageOffset.dx;
        final pdfY = im.pageOffset.dy;
        final pdfW = im.pageWidth;
        final pdfH = im.pageHeight;
        final PdfBitmap bitmap = PdfBitmap(im.bytes);
        page.graphics.drawImage(bitmap, Rect.fromLTWH(pdfX, pdfY, pdfW, pdfH));
      }

      final newBytes = document.save();
      document.dispose();

      final appDoc = await getApplicationDocumentsDirectory();
      final outFile = File(
        '${appDoc.path}/${DateTime.now().millisecondsSinceEpoch}_${widget.name}',
      );
      await outFile.writeAsBytes(await newBytes);

      // Optionally: replace current viewer with saved file so overlays are flattened and won't move.
      setState(() {
        // clear in-memory overlays because we've flattened them
        _highlights.clear();
        _texts.clear();
        _images.clear();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved to ${outFile.path}')));
    } catch (e, st) {
      debugPrint('Save error: $e\n$st');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save PDF')));
    }
  }

  // ---------------- pick PDF replacement ----------------
  Future<void> _pickAndOpenPdfFromHome() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final name = result.files.single.name;
      RecentPDFStorage.addPDF(path, name);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PDFViewerScreen(path: path, name: name),
        ),
      );
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Text(
                        widget.name.length > 12
                            ? '${widget.name.substring(0, 14)}...'
                            : widget.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _toggleSearchBar,
                        child: SvgPicture.asset(Assets.search),
                      ),
                      const SizedBox(width: 12),
                      // open the edit sheet
                      GestureDetector(
                        onTap: _openEditSheet,
                        child: SvgPicture.asset(Assets.fileEdit),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: _savePdfWithChanges,
                        icon: const Icon(Icons.save),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_showSearchBar)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search in document...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                          ),
                          onSubmitted: _performSearch,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _toggleSearchBar,
                      ),
                    ],
                  ),
                ),
              ),

            // viewer + overlays
            // Expanded(
            //   child: Padding(
            //     padding: const EdgeInsets.only(top: 8, left: 7, right: 7),
            //     child: GestureDetector(
            //       onTapUp: _onViewerTap,
            //       child: Stack(
            //         children: [
            //           Positioned.fill(
            //             child: Container(
            //               key: _viewerKey,
            //               color: Colors.white,
            //               child: SfPdfViewer.file(
            //                 File(widget.path),
            //                 controller: _controller,
            //                 onTextSelectionChanged: _onTextSelectionChanged,
            //                 enableTextSelection: true,
            //                 canShowTextSelectionMenu: true,
            //                 pageSpacing: _pageSpacing,
            //                 onDocumentLoaded: (_) => _loadPageSizes(),
            //               ),
            //             ),
            //           ),
            //
            //           // highlights (visual-only until saved)
            //           for (int i = 0; i < _highlights.length; i++)
            //             Positioned(
            //               left: _highlights[i].rect.left,
            //               top: _highlights[i].rect.top,
            //               width: _highlights[i].rect.width,
            //               height: _highlights[i].rect.height,
            //               child: GestureDetector(
            //                 onLongPress: () => _removeHighlight(i),
            //                 child: Container(color: _highlights[i].color),
            //               ),
            //             ),
            //
            //           // text overlays (draggable)
            //           for (int i = 0; i < _texts.length; i++)
            //             _DraggableText(
            //               overlay: _texts[i],
            //               pageToLocal: (page, pt) => _pageToLocal(page, pt),
            //               effectiveScaleForPage: (page) =>
            //                   _effectiveScaleForPage(page),
            //               onUpdatePageOffset: (newPageOffset) =>
            //                   _updateTextPosition(i, newPageOffset),
            //               onDelete: () => _removeText(i),
            //             ),
            //
            //           // image overlays (signatures)
            //           for (int i = 0; i < _images.length; i++)
            //             _DraggableImage(
            //               overlay: _images[i],
            //               pageToLocal: (page, pt) => _pageToLocal(page, pt),
            //               effectiveScaleForPage: (page) =>
            //                   _effectiveScaleForPage(page),
            //               onUpdatePageOffset: (newPageOffset) =>
            //                   _updateImagePosition(i, newPageOffset),
            //               onDelete: () => _removeImage(i),
            //             ),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),
            // ----- replace the whole “viewer + overlays” block -----
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, left: 7, right: 7),
                child: Stack(
                  children: [
                    // ----- PDF viewer -----
                    Positioned.fill(
                      child: Container(
                        key: _viewerKey,
                        color: Colors.white,
                        child: SfPdfViewer.file(
                          File(widget.path),
                          controller: _controller,
                          onTextSelectionChanged: _onTextSelectionChanged,
                          enableTextSelection: true,
                          canShowTextSelectionMenu: true,
                          pageSpacing: _pageSpacing,
                          onDocumentLoaded: (_) => _loadPageSizes(),
                        ),
                      ),
                    ),

                    // ----- tap detector (covers the whole viewer) -----
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTapUp: _onViewerTap,
                      ),
                    ),

                    // ----- highlights (now in PDF points) -----
                    for (int i = 0; i < _highlights.length; i++)
                      _HighlightWidget(
                        overlay: _highlights[i],
                        pageToLocal: _pageToLocal,
                        effectiveScaleForPage: _effectiveScaleForPage,
                        onDelete: () => _removeHighlight(i),
                      ),

                    // ----- text overlays -----
                    for (int i = 0; i < _texts.length; i++)
                      _DraggableText(
                        overlay: _texts[i],
                        pageToLocal: _pageToLocal,
                        effectiveScaleForPage: _effectiveScaleForPage,
                        onUpdatePageOffset: (o) => _updateTextPosition(i, o),
                        onDelete: () => _removeText(i),
                      ),

                    // ----- signature overlays (now resizable) -----
                    for (int i = 0; i < _images.length; i++)
                      _DraggableResizableImage(
                        overlay: _images[i],
                        pageToLocal: _pageToLocal,
                        effectiveScaleForPage: _effectiveScaleForPage,
                        onUpdatePageOffset: (o) => _updateImagePosition(i, o),
                        onUpdateSize: (w, h) => _updateImageSize(i, w, h),
                        onDelete: () => _removeImage(i),
                      ),
                  ],
                ),
              ),
            ),

            // Note: bottom sheet shown by edit icon. we don't show a persistent bottom bar here.
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  // (keep your other helper widgets & classes below unchanged)
}

// ---------------- Edit bottom sheet widget ----------------
class PdfEditSheet extends StatefulWidget {
  final Color initialColor;
  final Color initialBg;
  final double initialFontSize;

  const PdfEditSheet({
    super.key,
    required this.initialColor,
    required this.initialBg,
    required this.initialFontSize,
  });

  @override
  State<PdfEditSheet> createState() => _PdfEditSheetState();
}

class _PdfEditSheetState extends State<PdfEditSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Color _color = Colors.black;
  Color _bg = Colors.transparent;
  double _fontSize = 18;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _color = widget.initialColor;
    _bg = widget.initialBg;
    _fontSize = widget.initialFontSize;
  }

  void _doneAsText() {
    Navigator.of(context).pop({
      'action': 'text',
      'color': _color,
      'bg': _bg,
      'fontSize': _fontSize,
    });
  }

  void _doneAsSignature() {
    Navigator.of(context).pop({'action': 'signature'});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // header with close/check
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  // confirm based on active tab
                  if (_tabController.index == 0)
                    _doneAsText();
                  else
                    _doneAsSignature();
                },
                icon: const Icon(Icons.check),
              ),
            ],
          ),
        ),

        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Text'),
            Tab(text: 'Signature'),
          ],
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Text options (colors, bg, font size)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Color'),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _tinyDot(Colors.black),
                        _tinyDot(Colors.red),
                        _tinyDot(Colors.blue),
                        _tinyDot(Colors.green),
                        _tinyDot(Colors.orange),
                        _tinyDot(Colors.purple),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Background'),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _tinyBg(Colors.transparent),
                        _tinyBg(Colors.yellow),
                        _tinyBg(Colors.orange),
                        _tinyBg(Colors.pink),
                        _tinyBg(Colors.lightGreen),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Size:'),
                        Expanded(
                          child: Slider(
                            min: 8,
                            max: 48,
                            value: _fontSize,
                            onChanged: (v) => setState(() => _fontSize = v),
                          ),
                        ),
                        Text('${_fontSize.toInt()}pt'),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _doneAsText,
                      child: const Text('Done'),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // Signature tab: only upload button (sheet will return 'signature' on Done)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _doneAsSignature,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Upload Signature'),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'After uploading you can drag signature on the PDF and Save.',
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tinyDot(Color c) => GestureDetector(
    onTap: () => setState(() => _color = c),
    child: CircleAvatar(
      backgroundColor: c,
      radius: 16,
      child: _color == c
          ? const Icon(Icons.check, color: Colors.white, size: 16)
          : null,
    ),
  );

  Widget _tinyBg(Color c) => GestureDetector(
    onTap: () => setState(() => _bg = c),
    child: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: _bg == c ? const Icon(Icons.check, size: 16) : null,
    ),
  );
}

// ---------------- overlay data types & draggable widgets (kept) ----------------
class _HighlightOverlay {
  final int pageNumber;
  final Rect rect;
  final Color color;
  _HighlightOverlay({
    required this.pageNumber,
    required this.rect,
    required this.color,
  });
}

class _TextOverlay {
  final int pageNumber;
  final String text;
  final Color color;
  final double fontSize;
  final Offset pageOffset; // in PDF page points
  _TextOverlay({
    required this.pageNumber,
    required this.text,
    required this.color,
    required this.fontSize,
    required this.pageOffset,
  });
  _TextOverlay copyWith({Offset? pageOffset}) => _TextOverlay(
    pageNumber: pageNumber,
    text: text,
    color: color,
    fontSize: fontSize,
    pageOffset: pageOffset ?? this.pageOffset,
  );
}

class _ImageOverlay {
  final Uint8List bytes;
  final int pageNumber;
  final Offset pageOffset;      // top‑left in PDF points
  double pageWidth;            // mutable
  double pageHeight;           // mutable

  _ImageOverlay({
    required this.bytes,
    required this.pageNumber,
    required this.pageOffset,
    required this.pageWidth,
    required this.pageHeight,
  });

  _ImageOverlay copyWith({
    Offset? pageOffset,
    double? pageWidth,
    double? pageHeight,
  }) => _ImageOverlay(
    bytes: bytes,
    pageNumber: pageNumber,
    pageOffset: pageOffset ?? this.pageOffset,
    pageWidth: pageWidth ?? this.pageWidth,
    pageHeight: pageHeight ?? this.pageHeight,
  );
}
class _DraggableText extends StatelessWidget {
  final _TextOverlay overlay;
  final Offset Function(int page, Offset pagePoint) pageToLocal;
  final double Function(int page) effectiveScaleForPage;
  final void Function(Offset newPageOffset) onUpdatePageOffset;
  final VoidCallback onDelete;
  const _DraggableText({
    required this.overlay,
    required this.pageToLocal,
    required this.effectiveScaleForPage,
    required this.onUpdatePageOffset,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final local = pageToLocal(overlay.pageNumber, overlay.pageOffset);
    final scale = effectiveScaleForPage(overlay.pageNumber);
    return Positioned(
      left: local.dx,
      top: local.dy,
      child: GestureDetector(
        onPanUpdate: (d) {
          final deltaPage = Offset(d.delta.dx / scale, d.delta.dy / scale);
          onUpdatePageOffset(overlay.pageOffset + deltaPage);
        },
        onLongPress: onDelete,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Text(
            overlay.text,
            style: TextStyle(
              color: overlay.color,
              fontSize: overlay.fontSize * scale,
            ),
          ),
        ),
      ),
    );
  }
}

class _DraggableImage extends StatelessWidget {
  final _ImageOverlay overlay;
  final Offset Function(int page, Offset pagePoint) pageToLocal;
  final double Function(int page) effectiveScaleForPage;
  final void Function(Offset newPageOffset) onUpdatePageOffset;
  final VoidCallback onDelete;
  const _DraggableImage({
    required this.overlay,
    required this.pageToLocal,
    required this.effectiveScaleForPage,
    required this.onUpdatePageOffset,
    required this.onDelete,
  });
  @override
  Widget build(BuildContext context) {
    final scale = effectiveScaleForPage(overlay.pageNumber);
    final localTopLeft = pageToLocal(overlay.pageNumber, overlay.pageOffset);
    final w = overlay.pageWidth * scale;
    final h = overlay.pageHeight * scale;
    return Positioned(
      left: localTopLeft.dx,
      top: localTopLeft.dy,
      width: w,
      height: h,
      child: GestureDetector(
        onPanUpdate: (d) {
          final deltaPage = Offset(d.delta.dx / scale, d.delta.dy / scale);
          onUpdatePageOffset(overlay.pageOffset + deltaPage);
        },
        onLongPress: onDelete,
        child: Image.memory(overlay.bytes, width: w, height: h),
      ),
    );
  }
}
class _HighlightWidget extends StatelessWidget {
  final _HighlightOverlay overlay;
  final Offset Function(int, Offset) pageToLocal;
  final double Function(int) effectiveScaleForPage;
  final VoidCallback onDelete;

  const _HighlightWidget({
    required this.overlay,
    required this.pageToLocal,
    required this.effectiveScaleForPage,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scale = effectiveScaleForPage(overlay.pageNumber);
    final topLeft = pageToLocal(overlay.pageNumber,
        Offset(overlay.rect.left, overlay.rect.top));
    final w = overlay.rect.width * scale;
    final h = overlay.rect.height * scale;

    return Positioned(
      left: topLeft.dx,
      top: topLeft.dy,
      width: w,
      height: h,
      child: GestureDetector(
        onLongPress: onDelete,
        child: Container(color: overlay.color),
      ),
    );
  }
}
class _DraggableResizableImage extends StatefulWidget {
  final _ImageOverlay overlay;
  final Offset Function(int, Offset) pageToLocal;
  final double Function(int) effectiveScaleForPage;
  final void Function(Offset) onUpdatePageOffset;
  final void Function(double w, double h) onUpdateSize;
  final VoidCallback onDelete;

  const _DraggableResizableImage({
    required this.overlay,
    required this.pageToLocal,
    required this.effectiveScaleForPage,
    required this.onUpdatePageOffset,
    required this.onUpdateSize,
    required this.onDelete,
  });

  @override
  State<_DraggableResizableImage> createState() => _DraggableResizableImageState();
}

class _DraggableResizableImageState extends State<_DraggableResizableImage> {
  late double _currentScale;

  @override
  void initState() {
    super.initState();
    _currentScale = widget.effectiveScaleForPage(widget.overlay.pageNumber);
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.effectiveScaleForPage(widget.overlay.pageNumber);
    final topLeft = widget.pageToLocal(widget.overlay.pageNumber, widget.overlay.pageOffset);
    final w = widget.overlay.pageWidth * scale;
    final h = widget.overlay.pageHeight * scale;

    return Positioned(
      left: topLeft.dx,
      top: topLeft.dy,
      width: w,
      height: h,
      child: GestureDetector(
        onLongPress: widget.onDelete,
        onScaleUpdate: (details) {
          // ----- drag -----
          if (details.pointerCount == 1) {
            final delta = Offset(details.focalPointDelta.dx / scale,
                details.focalPointDelta.dy / scale);
            widget.onUpdatePageOffset(widget.overlay.pageOffset + delta);
          }
          // ----- pinch to resize -----
          else if (details.pointerCount == 2) {
            final newW = widget.overlay.pageWidth * details.scale;
            final newH = widget.overlay.pageHeight * (newW / widget.overlay.pageWidth);
            widget.onUpdateSize(newW, newH);
          }
        },
        child: Image.memory(widget.overlay.bytes, fit: BoxFit.fill),
      ),
    );
  }
}