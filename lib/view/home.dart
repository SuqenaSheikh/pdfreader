import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:share_handler/share_handler.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_core/theme.dart';

class PDFReaderHome extends StatefulWidget {
  const PDFReaderHome({super.key});

  @override
  State<PDFReaderHome> createState() => _PDFReaderHomeState();
}

class _PDFReaderHomeState extends State<PDFReaderHome> {
  String? _pdfPath;
  String? _fileName;
  final PdfViewerController _pdfViewerController = PdfViewerController();
  int _currentPage = 1;
  int _totalPages = 0;
  double _zoomLevel = 1.0;
  bool _showControls = true;
  StreamSubscription<SharedMedia?>? _shareSubscription;
  final TextEditingController _searchController = TextEditingController();
  final List<FileSystemEntity> _foundPdfs = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _initShareHandling();
   // _requestPermissionsAndScan();
  }

  void _initShareHandling() async {
    final handler = ShareHandler.instance;
    // Initial share/open-with intent
    final initial = await handler.getInitialSharedMedia();
    _consumeShared(initial);
    // Stream for shares while app is running
    _shareSubscription = handler.sharedMediaStream.listen(_consumeShared);
  }

  void _consumeShared(SharedMedia? media) {
    if (media == null) return;
    final List<SharedAttachment> attachments = (media.attachments ?? [])
        .whereType<SharedAttachment>()
        .toList();
    if (attachments.isEmpty) return;
    // Pick first PDF attachment
    final SharedAttachment pdf = attachments.firstWhere(
          (a) => a.path.toLowerCase().endsWith('.pdf'),
      orElse: () => attachments.first,
    );
    final path = pdf.path;
    setState(() {
      _pdfPath = path;
      _fileName = p.basename(path);
    });
  }

  Future<void> _pickPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _pdfPath = result.files.single.path;
        _fileName = result.files.single.name;
      });
    }
  }

  // Future<void> _requestPermissionsAndScan() async {
  //   // Request storage where applicable. On Android 13+, general file access is limited,
  //   // but common public dirs may still be readable depending on OEM.
  //   if (Platform.isAndroid) {
  //     await Permission.storage.request();
  //   }
  //   _scanForPdfs();
  // }

  // Future<void> _scanForPdfs() async {
  //   if (_isScanning) return;
  //   setState(() {
  //     _isScanning = true;
  //     _foundPdfs.clear();
  //   });
  //
  //   final List<Directory> candidates = [];
  //   try {
  //     // Common public directories
  //     final downloads = await getDownloadsDirectory();
  //     if (downloads != null) candidates.add(downloads);
  //   } catch (_) {}
  //   try {
  //     final extDirs = await getExternalStorageDirectories();
  //     if (extDirs != null) candidates.addAll(extDirs);
  //   } catch (_) {}
  //   // Heuristic common locations on Android
  //   if (Platform.isAndroid) {
  //     const possible = [
  //       '/storage/emulated/0/Download',
  //       '/storage/emulated/0/Documents',
  //       '/sdcard/Download',
  //       '/sdcard/Documents',
  //     ];
  //     for (final path in possible) {
  //       final dir = Directory(path);
  //       if (await dir.exists()) candidates.add(dir);
  //     }
  //   }
  //
  //   final seenPaths = <String>{};
  //   for (final dir in candidates) {
  //     try {
  //       await for (final entity in dir.list(
  //         recursive: true,
  //         followLinks: false,
  //       )) {
  //         if (entity is File) {
  //           final lower = entity.path.toLowerCase();
  //           if (lower.endsWith('.pdf')) {
  //             if (seenPaths.add(entity.path)) {
  //               _foundPdfs.add(entity);
  //             }
  //           }
  //         }
  //       }
  //     } catch (_) {
  //       // Ignore directories we cannot access
  //     }
  //   }
  //
  //   setState(() {
  //     _isScanning = false;
  //   });
  // }

  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    setState(() {
      _totalPages = details.document.pages.count;
    });
  }

  void _onPageChanged(PdfPageChangedDetails details) {
    setState(() {
      _currentPage = details.newPageNumber;
    });
  }

  void _zoomIn() {
    setState(() {
      _zoomLevel = (_zoomLevel + 0.25).clamp(0.5, 3.0);
      _pdfViewerController.zoomLevel = _zoomLevel;
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomLevel = (_zoomLevel - 0.25).clamp(0.5, 3.0);
      _pdfViewerController.zoomLevel = _zoomLevel;
    });
  }

  void _previousPage() {
    if (_currentPage > 1) {
      _pdfViewerController.previousPage();
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      _pdfViewerController.nextPage();
    }
  }

  void _searchText() {
    _pdfViewerController.searchText(_searchController.text);
  }

  @override
  void dispose() {
    _shareSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F), Color(0xFFFFA500)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: _pdfPath == null
                    ? _buildUploadScreen()
                    : _buildPDFViewer(),
              ),
              if (_pdfPath != null && _showControls) _buildBottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.shade700,
            Colors.red.shade600,
            Colors.orange.shade600,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'PDF Reader',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_fileName != null)
                  Text(
                    _fileName!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (_pdfPath != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() {
                  _pdfPath = null;
                  _fileName = null;
                  _currentPage = 1;
                  _totalPages = 0;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildUploadScreen() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.shade600,
              Colors.red.shade700,
              Colors.orange.shade600,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.upload_file,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Open PDF Document',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap below to browse files or open PDFs from any app',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _pickPDF,
              icon: const Icon(Icons.folder_open, size: 24),
              label: const Text(
                'Browse Files',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
              ),
            ),
            const SizedBox(height: 16),
            // ElevatedButton.icon(
            //   onPressed: _isScanning ? null : _scanForPdfs,
            //   icon: const Icon(Icons.refresh, size: 22),
            //   label: Text(
            //     _isScanning ? 'Scanning...' : 'Scan Device PDFs',
            //     style: const TextStyle(
            //       fontSize: 16,
            //       fontWeight: FontWeight.w600,
            //     ),
            //   ),
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: Colors.white,
            //     foregroundColor: Colors.red.shade700,
            //     padding: const EdgeInsets.symmetric(
            //       horizontal: 24,
            //       vertical: 14,
            //     ),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(12),
            //     ),
            //     elevation: 6,
            //   ),
            // ),
            const SizedBox(height: 16),
            if (_foundPdfs.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 260),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _foundPdfs.length,
                  separatorBuilder: (_, __) =>
                      Divider(color: Colors.white.withOpacity(0.15), height: 1),
                  itemBuilder: (context, index) {
                    final file = _foundPdfs[index] as File;
                    final name = p.basename(file.path);
                    return ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.white,
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        file.path,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        setState(() {
                          _pdfPath = file.path;
                          _fileName = name;
                        });
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPDFViewer() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          // This will be recognized after you add the import
          child: SfPdfViewerTheme(
            data: SfPdfViewerThemeData(
              progressBarColor: Colors.red.shade700, // Matching your app's theme
            ),
            child: SfPdfViewer.file(
              File(_pdfPath!),
              controller: _pdfViewerController,
              onDocumentLoaded: _onDocumentLoaded,
              onPageChanged: _onPageChanged,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade600, Colors.orange.shade600],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Container(
          //   margin: const EdgeInsets.only(bottom: 12),
          //   padding: const EdgeInsets.symmetric(horizontal: 12),
          //   decoration: BoxDecoration(
          //     color: Colors.white.withOpacity(0.2),
          //     borderRadius: BorderRadius.circular(12),
          //   ),
          //   child: Row(
          //     children: [
          //       const Icon(Icons.search, color: Colors.white),
          //       const SizedBox(width: 8),
          //       Expanded(
          //         child: TextField(
          //           controller: _searchController,
          //           style: const TextStyle(color: Colors.white),
          //           decoration: InputDecoration(
          //             hintText: 'Search in document...',
          //             hintStyle: TextStyle(
          //               color: Colors.white.withOpacity(0.7),
          //             ),
          //             border: InputBorder.none,
          //           ),
          //           onSubmitted: (_) => _searchText(),
          //         ),
          //       ),
          //       IconButton(
          //         icon: const Icon(Icons.search, color: Colors.white),
          //         onPressed: _searchText,
          //       ),
          //     ],
          //   ),
          // ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(Icons.remove, _zoomOut),
              _buildControlButton(Icons.chevron_left, _previousPage),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_currentPage / $_totalPages',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              _buildControlButton(Icons.chevron_right, _nextPage),
              _buildControlButton(Icons.add, _zoomIn),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
        iconSize: 28,
      ),
    );
  }
}