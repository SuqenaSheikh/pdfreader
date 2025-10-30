import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../contents/assets/assets.dart';
import '../contents/services/recent_pdf_storage.dart';

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
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    RecentPDFStorage.addPDF(widget.path, widget.name);
  }
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
  void _showEditToolbar() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _editOption("Highlight", true),
                  _editOption("Text", false),
                  _editOption("Signature", false),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _editOption(String label, bool active) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: active
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        if (active)
          Container(
            margin: const EdgeInsets.only(top: 4),
            height: 3,
            width: 20,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(widget.name),
      //   backgroundColor: Colors.redAccent,
      // ),
      body: SafeArea(
        child: Column(
          children: [
            ///Appbar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () {
                          Get.back();
                        },
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Text(
                        widget.name.length > 14
                            ? '${widget.name.substring(0, 14)}...'
                            : widget.name,
                        style: Theme.of(context).textTheme.titleLarge,
                        // overflow: TextOverflow.ellipsis,
                        // maxLines: 1,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      GestureDetector(
                          onTap: _toggleSearchBar,
                          child: SvgPicture.asset(Assets.search)),
                      SizedBox(width: 12,),
                      GestureDetector(
                          onTap: () {
                            _showEditToolbar();
                          },
                          child: SvgPicture.asset(Assets.fileEdit)),
                      SizedBox(width: 6,),
                      Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onPrimary,),
                    ],
                  ),
                ],
              ),
            ),
            /// Search bar (conditionally visible)
            if (_showSearchBar)
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                          decoration: const InputDecoration(
                            hintText: "Search in document...",
                            border: InputBorder.none,
                            contentPadding:
                            EdgeInsets.symmetric(horizontal: 12),
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
                padding: const EdgeInsets.only(
                  top: 16,
                  left: 7,
                  right: 7
                ),
                child: SfPdfViewer.file(
                  File(widget.path),
                  controller: _controller,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
