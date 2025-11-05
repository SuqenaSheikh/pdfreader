import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdfread/view/pdfview.dart';
import 'package:pdfread/view/widgets/upload_sheet.dart';
import '../contents/assets/assets.dart';
import '../contents/services/recent_pdf_storage.dart';
import '../contents/themes/app_colors.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:path/path.dart' as p;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, String>> _recentPDFs = [];
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final list = await RecentPDFStorage.loadPDFs();
    setState(() => _recentPDFs = list);
  }

  // Future<void> _pickAndOpenPDF() async {
  //   final result = await FilePicker.platform.pickFiles(
  //     type: FileType.custom,
  //     allowedExtensions: ['pdf'],
  //   );
  //   if (result != null && result.files.single.path != null) {
  //     final path = result.files.single.path!;
  //     final name = result.files.single.name;
  //
  //     await RecentPDFStorage.addPDF(path, name);
  //     if (mounted) {
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder: (_) => PDFViewerScreen(path: path, name: name, isedit: false),
  //         ),
  //       ).then((_) => _loadRecent());
  //     }
  //   }
  // }
  Future<void> _pickAndOpenPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final name = result.files.single.name;

      // 1️⃣ Save to SharedPreferences (Recent list)
      await RecentPDFStorage.addPDF(path, name);

      // 2️⃣ Reload list so user sees it appear instantly
      await _loadRecent();

      // 3️⃣ Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          backgroundColor: Theme.of(context).colorScheme.primary,
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                'PDF added to Home',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      // 4️⃣ Wait a bit before opening viewer
      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PDFViewerScreen(path: path, name: name, isedit: false),
        ),
      ).then((_) => _loadRecent());
    }
  }


  void _showUploadSheet() {
    UploadPdfSheet.show(
      context: context,
      onUploadPressed: _pickAndOpenPDF, // existing method
    );
  }


  String _formatTime(String iso) {
    final dt = DateTime.parse(iso);
    return DateFormat('dd/MM/yyyy  hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final List<Map<String, String>> filtered = _searchQuery.trim().isEmpty
        ? _recentPDFs
        : _recentPDFs
              .where(
                (e) => (e['name'] ?? '').toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showUploadSheet,

        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: const CircleBorder(),
        child: Icon(
          Icons.add,
          size: 32,
          color: Theme.of(context).colorScheme.onSecondary,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: size.height * 0.05),

            ///Appbar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "PDF Reader",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showSearch = !_showSearch;
                        if (!_showSearch) {
                          _searchController.clear();
                          _searchQuery = '';
                        }
                      });
                    },
                    child: SvgPicture.asset(Assets.search),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),

            if (_showSearch)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
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
                            hintText: 'Search recent files...',
                            hintStyle: Theme.of(context).textTheme.titleSmall,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                          ),
                          onChanged: (v) => setState(() => _searchQuery = v),
                          onSubmitted: (v) => setState(() => _searchQuery = v),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _showSearch = false;
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

            ///Container with image and text
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).colorScheme.primary,
                ),
                height: size.height * 0.18,
                width: size.width,
                child: Stack(
                  children: [
                    Positioned(top: 0, right: 0, child: Image.asset(Assets.bg)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'All in One\nPDF Reader',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'The easiest way \nto read and edit PDFs.',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Image.asset(Assets.papers),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            ///List of recent files
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  "Recent Files",
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontSize: 16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          "No recent files yet.",
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppColors.textColor),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final pdf = filtered[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                            child: ListTile(
                              leading: Image.asset(Assets.pdf, height: 40),
                              title: Text(
                                pdf['name'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              subtitle: Text(
                                _formatTime(pdf['time']!),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.more_vert),
                                onPressed: () => _showFileOptions(pdf),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PDFViewerScreen(
                                      path: pdf['path']!,
                                      name: pdf['name']!,
                                      isedit: false,
                                    ),
                                  ),
                                ).then((_) => _loadRecent());
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFileOptions(Map<String, String> pdf) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            ListTile(
              leading: Image.asset(Assets.pdf, height: 40),
              title: Text(
                pdf['name'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              subtitle: Text(
                _formatTime(pdf['time']!),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(
                Icons.print,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Print',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              onTap: () async {
                Navigator.pop(context);
                await _printPdf(pdf['path']!);
              },
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: Color(0xffBDBDBD)),
            ),

            ListTile(
              leading: Icon(
                Icons.drive_file_rename_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Rename',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              onTap: () async {
                Navigator.pop(context);
                await _renamePdf(pdf);
              },
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: Color(0xffBDBDBD)),
            ),
            ListTile(
              leading: Icon(
                Icons.share,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Share',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              onTap: () async {
                Navigator.pop(context);
                await _sharePdf(pdf['path']!, pdf['name']!);
              },
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: Color(0xffBDBDBD)),
            ),
            ListTile(
              leading: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Delete',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              onTap: () async {
                Navigator.pop(context);
                await RecentPDFStorage.removeByPath(pdf['path']!);
                await _loadRecent();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Removed',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printPdf(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) throw Exception('File not found');
      await Printing.layoutPdf(onLayout: (_) async => await file.readAsBytes());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Print failed: $e')));
    }
  }

  Future<void> _sharePdf(String path, String name) async {
    try {
      final file = XFile(path, name: name, mimeType: 'application/pdf');
      await Share.shareXFiles([file], text: name);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Share failed: $e')));
    }
  }

  Future<void> _renamePdf(Map<String, String> pdf) async {
    final oldPath = pdf['path']!;
    final oldName = pdf['name']!;
    final controller = TextEditingController(text: _stripExtension(oldName));

    final newBase = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Rename PDF', style: Theme.of(context).textTheme.bodyLarge),
        content: TextField(
          controller: controller,
          style: Theme.of(context).textTheme.titleSmall,
          decoration: InputDecoration(
            hintText: 'New name (without .pdf)',
            hintStyle: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newBase == null || newBase.isEmpty) return;
    try {
      final file = File(oldPath);
      if (!await file.exists()) throw Exception('File not found');
      final dir = file.parent.path;
      final newPath = p.join(dir, '$newBase.pdf');
      final renamed = await file.rename(newPath);
      await RecentPDFStorage.updateEntry(
        oldPath: oldPath,
        newPath: renamed.path,
        newName: '$newBase.pdf',
      );
      await _loadRecent();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Renamed',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Rename failed: $e')));
    }
  }

  String _stripExtension(String name) {
    final i = name.lastIndexOf('.');
    return i > 0 ? name.substring(0, i) : name;
  }
}
