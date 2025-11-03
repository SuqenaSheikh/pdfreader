import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdfread/view/pdfview.dart';
import '../contents/assets/assets.dart';
import '../contents/services/recent_pdf_storage.dart';
import '../contents/themes/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, String>> _recentPDFs = [];

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

      await RecentPDFStorage.addPDF(path, name);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PDFViewerScreen(path: path, name: name),
          ),
        ).then((_) => _loadRecent());
      }
    }
  }

  void _showUploadSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.45,
       decoration: BoxDecoration(
         color: Theme.of(context).colorScheme.onSecondary,
         borderRadius: const BorderRadius.vertical(top: Radius.circular(10), ),
       ),
       // padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          //mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                    onPressed: () {
                      Get.back();
                    },
                    icon: const Icon(Icons.clear)
                )
              ]
            ),
            Image.asset(Assets.papers),
             Text(
              "Upload Your PDF Document",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _pickAndOpenPDF();
              },
              icon: const Icon(Icons.file_upload),
              label: const Text("Upload Pdf"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String iso) {
    final dt = DateTime.parse(iso);
    return DateFormat('dd/MM/yyyy  hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
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
            const SizedBox(height: 16),

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
                  SvgPicture.asset(
                    Assets.search,
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),

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
                child: _recentPDFs.isEmpty
                    ? Center(
                        child: Text(
                          "No recent files yet.",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textColor),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _recentPDFs.length,
                        itemBuilder: (context, index) {
                          final pdf = _recentPDFs[index];
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
                              trailing: Icon(Icons.more_vert),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PDFViewerScreen(
                                      path: pdf['path']!,
                                      name: pdf['name']!,
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
