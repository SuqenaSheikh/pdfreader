import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pdfread/view/pdfview.dart';
import 'package:pdfread/view/widgets/upload_sheet.dart';
import 'package:intl/intl.dart';
import '../contents/assets/assets.dart';
import '../contents/services/recent_pdf_storage.dart';
import '../contents/themes/app_colors.dart';

class Editor extends StatefulWidget {
  const Editor({super.key});

  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
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
              PDFViewerScreen(path: path, name: name, isedit: true),
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
                    "Edit Pdf",
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
            SizedBox(height: size.height * 0.02),

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
            SizedBox(height: size.height * 0.02),


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

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PDFViewerScreen(
                                path: pdf['path']!,
                                name: pdf['name']!,
                                isedit: true,
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
}
