import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdfread/view/widgets/draggable_image.dart';
import 'package:pdfread/view/widgets/draggable_text.dart';
import 'package:pdfread/view/widgets/heighlight_widget.dart';
import 'package:pdfread/view/widgets/comment_icon_widget.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import '../contents/model/pdf_models.dart';
import '../controller/local_controller.dart';
import 'widgets/pdf_edit_sheet.dart';
import '../contents/assets/assets.dart';
import '../contents/services/recent_pdf_storage.dart';
import '../contents/services/comment_storage.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class PDFViewerScreen extends StatefulWidget {
  final String path;
  final String name;
  final bool isedit;

  const PDFViewerScreen({
    super.key,
    required this.path,
    required this.name,
    required this.isedit,
  });

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  final PdfViewerController _controller = PdfViewerController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _viewerKey = GlobalKey();
  final ImagePicker _imagePicker = ImagePicker();
  final List<CommentOverlay> _comments = [];

  // UI stat
  bool _showSearchBar = false;
  String _selectedTool =
      ''; // '', 'text', 'signature', 'comment'  (highlight left to selection menu)
  Color _selectedColor = Colors.black;
  Color _selectedBgColor = Colors.transparent;
  // removed unused _opacity field

  // selection storage (unchanged)
  // removed unused selection cache
  int? _lastSelectedPageNumber;

  // overlays (kept as you had them)
  final List<HighlightOverlay> _highlights = [];
  final List<TextOverlay> _texts = [];
  final List<ImageOverlay> _images = [];

  // page metrics
  final List<Size> _pageSizes = [];
  final double _pageSpacing = 8.0;

  bool _awaitingTextPlacement = false;
  bool _awaitingCommentPlacement = false;

  // busy overlay
  bool _isUploading = false;
  String? _busyMessage;

  // selected text config from bottom sheet
  double _selectedFontSize = 18;
  bool _selectedBold = false;
  bool _selectedItalic = false;
  double _selectedOpacity = 1.0;
  final lc = Get.find<LocaleController>();

  // track which text overlay is being edited (null = new text)
  @override
  void initState() {
    super.initState();
    RecentPDFStorage.addPDF(widget.path, widget.name);
    // Listen to zoom and scroll changes to update overlay positions
    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _loadPageSizes();
    _loadComments();
  }

  // Load comments from storage
  Future<void> _loadComments() async {
    final comments = await CommentStorage.loadComments(widget.path);
    if (mounted) {
      setState(() {
        _comments.clear();
        _comments.addAll(comments);
      });
    }
  }

  // Save comments to storage
  Future<void> _saveComments() async {
    await CommentStorage.saveComments(widget.path, _comments);
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
    } catch (_) {}
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
      barrierColor: Colors.transparent,
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.55,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: PdfEditSheet(
              // initial values passed for convenience
              initialColor: _selectedColor,
              initialBg: _selectedBgColor,
              initialFontSize: _selectedFontSize,
              initialBold: _selectedBold,
              initialItalic: _selectedItalic,
              initialOpacity: _selectedOpacity,
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
        _awaitingCommentPlacement = false;
      });
      return;
    }

    final action = result['action'] as String?;
    if (action == lc.t('text')) {
      // NEW WORKFLOW: Just enable text placement, user adds text first
      setState(() {
        _selectedTool = lc.t('text');
        _awaitingTextPlacement = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lc.t('tapText'),
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white),
          ),
        ),
      );
    } else if (action == 'comment') {
      // Enable comment placement mode
      setState(() {
        _selectedTool = 'comment';
        _awaitingCommentPlacement = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lc.t('tapComment'),
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white),
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
        _awaitingCommentPlacement = false;
      });
    }
  }

  // Open edit sheet for existing text overlay
  Future<void> _openEditSheetForText(int index) async {
    final overlay = _texts[index];
    // Make sure the text is visible above the bottom sheet
    _ensureOverlayVisible(overlay.pageNumber, overlay.pageOffset);
    setState(() {
      _selectedColor = overlay.color;
      _selectedBgColor = overlay.backgroundColor;
      _selectedFontSize = overlay.fontSize;
      _selectedBold = overlay.bold;
      _selectedItalic = overlay.italic;
      _selectedOpacity = overlay.opacity;
    });

    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.55,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: PdfEditSheet(
              initialColor: overlay.color,
              initialBg: overlay.backgroundColor,
              initialFontSize: overlay.fontSize,
              initialBold: overlay.bold,
              initialItalic: overlay.italic,
              initialOpacity: overlay.opacity,
              onLiveChange: (cfg) {
                setState(() {
                  _texts[index] = _texts[index].copyWith(
                    color: (cfg['color'] as Color?) ?? _texts[index].color,
                    backgroundColor:
                        (cfg['bg'] as Color?) ?? _texts[index].backgroundColor,
                    fontSize:
                        (cfg['fontSize'] as double?) ?? _texts[index].fontSize,
                    bold: (cfg['bold'] as bool?) ?? _texts[index].bold,
                    italic: (cfg['italic'] as bool?) ?? _texts[index].italic,
                    opacity:
                        (cfg['opacity'] as double?) ?? _texts[index].opacity,
                  );
                });
              },
            ),
          ),
        );
      },
    );

    if (result != null) {
      // Update existing text overlay
      setState(() {
        _texts[index] = _texts[index].copyWith(
          color: result['color'] as Color? ?? overlay.color,
          backgroundColor: result['bg'] as Color? ?? overlay.backgroundColor,
          fontSize: (result['fontSize'] as double?) ?? overlay.fontSize,
          bold: (result['bold'] as bool?) ?? overlay.bold,
          italic: (result['italic'] as bool?) ?? overlay.italic,
          opacity: (result['opacity'] as double?) ?? overlay.opacity,
        );
      });
    }

    setState(() {});
  }

  void _ensureOverlayVisible(int page, Offset pagePoint) {
    try {
      final scale = _effectiveScaleForPage(page);
      final top = _pageTopInScroll(page);
      const desiredLocalY =
          200.0; // keep near top, above the future bottom sheet
      final targetScrollY = pagePoint.dy * scale + top - desiredLocalY;
      final y = targetScrollY < 0 ? 0.0 : targetScrollY;
      _controller.jumpTo(yOffset: y);
    } catch (_) {}
  }

  // ---------------- signature pick ----------------
  // Tries local pixel-threshold first (fast, no network).
  /// If it fails (less than 5% of pixels made transparent), falls back to remove.bg API.
  Future<Uint8List?> _removeSignatureBackground(Uint8List rawBytes) async {
    // 1. Try cheap local method
    final local = await _removeWhiteBackgroundLocal(rawBytes);
    if (local != null) return local;

    // 2. Fallback: remove.bg (you need a free API key from https://remove.bg)
    const apiKey = 'mgk2f3PTHLCg8SrArLNxm6sL';

    // Try up to 2 attempts with longer timeout
    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('https://api.remove.bg/v1.0/removebg'),
        );
        request.headers['X-Api-Key'] = apiKey;
        request.files.add(
          http.MultipartFile.fromBytes(
            'image_file',
            rawBytes,
            filename: 'signature.jpg',
          ),
        );

        final response = await request.send().timeout(
          const Duration(seconds: 30),
        );
        if (response.statusCode == 200) {
          final bytes = await response.stream.toBytes();
          return bytes;
        } else {
          debugPrint('remove.bg error ${response.statusCode}');
          if (attempt == 2) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Background removal failed (${response.statusCode}). Using original image.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                  ),
                ),
              );
            }
          }
        }
      } catch (e) {
        debugPrint('remove.bg exception: $e');
        if (attempt == 2) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Background removal timed out. Using original image.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                ),
              ),
            );
          }
        } else {
          // small delay before retry
          await Future.delayed(const Duration(milliseconds: 600));
        }
      }
    }

    return rawBytes;
  }

  Future<Uint8List?> _removeWhiteBackgroundLocal(Uint8List inputBytes) async {
    try {
      final codec = await ui.instantiateImageCodec(inputBytes);
      final frame = await codec.getNextFrame();
      final img = frame.image;

      final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (bd == null) return null;

      final pixels = bd.buffer.asUint8List();
      int transparentCount = 0;
      const threshold = 220;
      const tolerance = 40;

      for (int i = 0; i < pixels.length; i += 4) {
        final r = pixels[i], g = pixels[i + 1], b = pixels[i + 2];
        if (r >= threshold &&
            g >= threshold &&
            b >= threshold &&
            (r - threshold).abs() <= tolerance &&
            (g - threshold).abs() <= tolerance &&
            (b - threshold).abs() <= tolerance) {
          pixels[i + 3] = 0;
          transparentCount++;
        }
      }

      // Heuristic: if <5% became transparent → probably failed
      if (transparentCount < (pixels.length ~/ 4) * 0.05) {
        return null; // signal fallback
      }

      final outImg = await _imageFromPixels(pixels, img.width, img.height);
      final png = await outImg.toByteData(format: ui.ImageByteFormat.png);
      return png?.buffer.asUint8List();
    } catch (_) {
      return null;
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
    final XFile? xfile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      // optional: force JPEG to reduce size
      imageQuality: 85,
    );
    if (xfile == null) return;

    final raw = await File(xfile.path).readAsBytes();

    setState(() {
      _isUploading = true;
      _busyMessage = lc.t('processingSignature');
    });
    Uint8List cleaned;
    try {
      // This now uses local → remove.bg fallback
      final out = await _removeSignatureBackground(raw);
      cleaned = out ?? raw;
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _busyMessage = null;
        });
      }
    }

    // … rest of your code unchanged …
    final center = await _viewerCenterOffset();
    if (_pageSizes.isEmpty) await _loadPageSizes();
    final hit = _localToPage(center);

    final codec = await ui.instantiateImageCodec(cleaned);
    final fi = await codec.getNextFrame();
    final imgW = fi.image.width.toDouble();
    final imgH = fi.image.height.toDouble();

    final pageW =
        _pageSizes[(hit.page - 1).clamp(0, _pageSizes.length - 1)].width;
    final targetW = pageW * 0.4;
    final targetH = targetW * (imgH / imgW);

    final overlay = ImageOverlay(
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
    // Keep selection menu behavior; no-op here
    if (details.selectedText == null || details.selectedText!.trim().isEmpty) {
      _lastSelectedPageNumber = null;
      return;
    }
    _lastSelectedPageNumber ??= 1;
  }

  // ---------------- convert global rect to viewer local ----------------
  // removed unused _globalRectToLocal

  // ---------------- place text on tap ----------------
  void _onViewerTap(TapUpDetails details) {
    final localPos = _getLocalPosition(details.globalPosition);
    if (localPos == null) return;

    if (_selectedTool == lc.t('text') && _awaitingTextPlacement) {
      _showAddTextDialog(localPos);
      // after adding one text overlay, keep placement off so user can choose again via bottom sheet
      setState(() {
        _awaitingTextPlacement = false;
        // keep _selectedTool == 'text' so draggable UI remains active; user must press Save to flatten
      });
    } else if (_selectedTool == 'comment' && _awaitingCommentPlacement) {
      _showAddCommentDialog(localPos);
      // after adding one comment, keep placement off so user can choose again via bottom sheet
      setState(() {
        _awaitingCommentPlacement = false;
        _selectedTool = '';
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

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(lc.t('addText')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tc,
                style: Theme.of(context).textTheme.titleSmall,
                decoration: InputDecoration(
                  hintText: lc.t('typeText'),
                  hintStyle: Theme.of(context).textTheme.titleSmall,
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _awaitingTextPlacement = false;
                  _selectedTool = '';
                });
              },
              child: Text(lc.t('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final text = tc.text.trim();
                if (text.isEmpty) return;
                Navigator.pop(ctx);

                if (_pageSizes.isEmpty) {
                  await _loadPageSizes();
                }
                final hit = _localToPage(pos);

                // Add text with default styling, then open edit sheet
                final newIndex = _texts.length;
                final overlay = TextOverlay(
                  pageNumber: hit.page,
                  text: text,
                  color: Colors.black,
                  fontSize: 18,
                  backgroundColor: Colors.transparent,
                  bold: false,
                  italic: false,
                  opacity: 1.0,
                  pageOffset: hit.pagePoint,
                );
                setState(() {
                  _texts.add(overlay);
                  _awaitingTextPlacement = false;
                });

                // Now open edit sheet to configure styling
                await _openEditSheetForText(newIndex);
              },
              child: Text(lc.t('add')),
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
    setState(
      () => _images[index] = _images[index].copyWith(pageOffset: newPageOffset),
    );
  }

  void _updateImageSize(int index, double w, double h) {
    setState(
      () =>
          _images[index] = _images[index].copyWith(pageWidth: w, pageHeight: h),
    );
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  void _removeHighlight(int index) {
    setState(() => _highlights.removeAt(index));
  }

  Future<void> _removeComment(int index) async {
    setState(() => _comments.removeAt(index));
    // Save comments after removing
    await _saveComments();
  }

  Future<void> _updateComment(int index, String newComment) async {
    setState(() {
      _comments[index] = _comments[index].copyWith(comment: newComment);
    });
    // Save comments after updating
    await _saveComments();
  }

  // Show dialog to add a new comment
  Future<void> _showAddCommentDialog(Offset pos) async {
    final TextEditingController tc = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(lc.t('addComment')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tc,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: lc.t('enterComment'),
                  hintStyle: Theme.of(context).textTheme.bodyMedium,
                ),
                autofocus: true,
                maxLines: 4,
                minLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _awaitingCommentPlacement = false;
                  _selectedTool = '';
                });
              },
              child: Text(lc.t('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final comment = tc.text.trim();
                if (comment.isEmpty) return;
                Navigator.pop(ctx);

                if (_pageSizes.isEmpty) {
                  await _loadPageSizes();
                }
                final hit = _localToPage(pos);

                // Add comment overlay
                final overlay = CommentOverlay(
                  pageNumber: hit.page,
                  pageOffset: hit.pagePoint,
                  comment: comment,
                );
                setState(() {
                  _comments.add(overlay);
                  _awaitingCommentPlacement = false;
                  _selectedTool = '';
                });
                // Save comments after adding
                await _saveComments();
              },
              child: Text(lc.t('add')),
            ),
          ],
        );
      },
    );
  }

  // Show bottom sheet to view/edit comment
  Future<void> _showCommentSheet(int index) async {
    final overlay = _comments[index];
    // Make sure the comment is visible above the bottom sheet
    _ensureOverlayVisible(overlay.pageNumber, overlay.pageOffset);

    final TextEditingController tc = TextEditingController(
      text: overlay.comment,
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final keyboardHeight = MediaQuery.of(ctx).viewInsets.bottom;
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: EdgeInsets.only(bottom: keyboardHeight),
            child: FractionallySizedBox(
              heightFactor: keyboardHeight > 0 ? 0.7 : 0.4,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                          ),
                          const Spacer(),
                          Text(
                            lc.t('comment'),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () async {
                              final newComment = tc.text.trim();
                              if (newComment.isEmpty) {
                                // Delete comment if empty
                                Navigator.pop(ctx);
                                await _removeComment(index);
                              } else {
                                // Update comment
                                Navigator.pop(ctx);
                                await _updateComment(index, newComment);
                              }
                            },
                            icon: const Icon(Icons.check),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    // Comment text field
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: tc,
                          style: Theme.of(context).textTheme.bodyLarge,
                          decoration: InputDecoration(
                            hintText: lc.t('enterComment'),
                            hintStyle: Theme.of(context).textTheme.bodyMedium,
                            border: InputBorder.none,
                          ),
                          autofocus: true,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                        ),
                      ),
                    ),
                    // Delete button
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _removeComment(index);
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: Text(
                          lc.t('deleteComment'),
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------- Save to PDF (unchanged) ----------------
  Future<void> _savePdfWithChanges() async {
    try {
      final bytes = await File(widget.path).readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      final box = _viewerKey.currentContext?.findRenderObject() as RenderBox?;
      final viewerSize = box?.size ?? const Size(300, 400);

      // Apply highlights
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

      // Apply text overlays
      for (final t in _texts) {
        final pageIndex = (t.pageNumber - 1).clamp(0, document.pages.count - 1);
        final page = document.pages[pageIndex];
        final pdfX = t.pageOffset.dx;
        final pdfY = t.pageOffset.dy;
        final PdfFontStyle style = t.bold
            ? PdfFontStyle.bold
            : (t.italic ? PdfFontStyle.italic : PdfFontStyle.regular);
        final font = PdfStandardFont(
          PdfFontFamily.helvetica,
          t.fontSize,
          style: style,
        );
        // draw background if needed
        if (t.backgroundColor.opacity > 0) {
          final size = font.measureString(t.text);
          page.graphics.drawRectangle(
            bounds: Rect.fromLTWH(pdfX, pdfY, size.width, size.height),
            pen: PdfPen(PdfColor(0, 0, 0, 0)),
            brush: PdfSolidBrush(
              PdfColor(
                t.backgroundColor.red,
                t.backgroundColor.green,
                t.backgroundColor.blue,
              ),
            ),
          );
        }
        final brush = PdfSolidBrush(
          PdfColor(
            t.color.red,
            t.color.green,
            t.color.blue,
            (255 * t.opacity).round(),
          ),
        );
        page.graphics.drawString(
          t.text,
          font,
          brush: brush,
          bounds: Rect.fromLTWH(pdfX, pdfY, 500, 200),
        );
      }

      // Apply images (signatures)
      for (final im in _images) {
        final pageIndex = (im.pageNumber - 1).clamp(
          0,
          document.pages.count - 1,
        );
        final page = document.pages[pageIndex];
        final PdfBitmap bitmap = PdfBitmap(im.bytes);
        page.graphics.drawImage(
          bitmap,
          Rect.fromLTWH(
            im.pageOffset.dx,
            im.pageOffset.dy,
            im.pageWidth,
            im.pageHeight,
          ),
        );
      }

      // Save the modified document
      final newBytes = await document.save();
      document.dispose();

      // Build output name: originalName (by pdf read).pdf
      final original = widget.name;
      final dot = original.lastIndexOf('.');
      final base = dot > 0 ? original.substring(0, dot) : original;
      final ext = dot > 0 ? original.substring(dot) : '.pdf';
      final outName = '$base (by pdf read)$ext';

      // Try to save into public Downloads if available (Android), otherwise app docs
      String? downloadsPath;
      try {
        if (Platform.isAndroid) {
          final candidate = Directory('/storage/emulated/0/Download');
          if (await candidate.exists()) downloadsPath = candidate.path;
        }
      } catch (_) {}

      Directory targetDir;
      if (downloadsPath != null) {
        var granted = true;
        try {
          if (Platform.isAndroid) {
            var status = await Permission.storage.request();
            if (!status.isGranted) {
              // Try special access for Android 11+
              status = await Permission.manageExternalStorage.request();
            }
            granted = status.isGranted;
            if (!granted && status.isPermanentlyDenied) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      lc.t('askPermissions'),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                    ),
                  ),
                );
              }
              await openAppSettings();
            }
          }
        } catch (_) {}
        if (granted) {
          targetDir = Directory(downloadsPath);
        } else {
          targetDir = await getApplicationDocumentsDirectory();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  lc.t('permissionFallback'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                ),
              ),
            );
          }
        }
      } else {
        targetDir = await getApplicationDocumentsDirectory();
      }
      final outFile = File('${targetDir.path}/$outName');
      await outFile.writeAsBytes(newBytes);

      // Clear overlays (flattened now) - but keep comments
      setState(() {
        _highlights.clear();
        _texts.clear();
        _images.clear();
      });

      // Update comments path mapping to new saved file
      await CommentStorage.updateCommentsPath(widget.path, outFile.path);

      // Notify and reload viewer
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${lc.t('savedTo')} ${outFile.path}',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white),
          ),
        ),
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PDFViewerScreen(
              path: outFile.path,
              name: widget.name,
              isedit: true,
            ),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('Save error: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save PDF',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white),
          ),
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
            // AppBar
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
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(fontSize: 16),
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
                      widget.isedit
                          ? GestureDetector(
                              onTap: _openEditSheet,
                              child: SvgPicture.asset(Assets.fileEdit),
                            )
                          : SizedBox(width: 0),
                      const SizedBox(width: 6),
                      widget.isedit
                          ? IconButton(
                              onPressed: _savePdfWithChanges,
                              icon: const Icon(Icons.save),
                            )
                          : SizedBox(width: 0),
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
                          style: Theme.of(context).textTheme.titleSmall,
                          decoration: InputDecoration(
                            hintText: lc.t('searchDocument'),
                            hintStyle: Theme.of(context).textTheme.titleSmall,
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, left: 7, right: 7),
                child: Stack(
                  children: [
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
                      HighlightWidget(
                        overlay: _highlights[i],
                        pageToLocal: _pageToLocal,
                        effectiveScaleForPage: _effectiveScaleForPage,
                        onDelete: () => _removeHighlight(i),
                      ),

                    // ----- text overlays -----
                    for (int i = 0; i < _texts.length; i++)
                      DraggableText(
                        overlay: _texts[i],
                        pageToLocal: _pageToLocal,
                        effectiveScaleForPage: _effectiveScaleForPage,
                        onUpdatePageOffset: (o) => _updateTextPosition(i, o),
                        onDelete: () => _removeText(i),
                        onTap: () => _openEditSheetForText(i),
                      ),

                    // ----- signature overlays (now resizable) -----
                    for (int i = 0; i < _images.length; i++)
                      DraggableResizableImage(
                        overlay: _images[i],
                        pageToLocal: _pageToLocal,
                        effectiveScaleForPage: _effectiveScaleForPage,
                        onUpdatePageOffset: (o) => _updateImagePosition(i, o),
                        onUpdateSize: (w, h) => _updateImageSize(i, w, h),
                        onDelete: () => _removeImage(i),
                      ),

                    // ----- comment icon overlays -----
                    for (int i = 0; i < _comments.length; i++)
                      CommentIconWidget(
                        overlay: _comments[i],
                        pageToLocal: _pageToLocal,
                        effectiveScaleForPage: _effectiveScaleForPage,
                        onTap: () => _showCommentSheet(i),
                        onDelete: () async => await _removeComment(i),
                      ),

                    // ----- loading overlay -----
                    if (_isUploading)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.35),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 12),
                                if (_busyMessage != null)
                                  Text(
                                    _busyMessage!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(color: Colors.white),
                                  ),
                              ],
                            ),
                          ),
                        ),
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
}
