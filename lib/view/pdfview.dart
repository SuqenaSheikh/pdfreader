import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
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
      appBar: AppBar(
        title: Text(widget.name),
        backgroundColor: Colors.redAccent,
      ),
      body: SfPdfViewer.file(File(widget.path), controller: _controller),
    );
  }
}
