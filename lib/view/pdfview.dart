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

  @override
  void initState() {
    super.initState();
    RecentPDFStorage.addPDF(widget.path, widget.name);
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
                      SvgPicture.asset(Assets.search),
                      SizedBox(width: 12,),
                      SvgPicture.asset(Assets.fileEdit),
                      SizedBox(width: 6,),
                      Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onPrimary,),
                    ],
                  ),
                ],
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
