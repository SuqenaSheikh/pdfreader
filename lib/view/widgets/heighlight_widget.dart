import 'package:flutter/material.dart';

import '../../contents/model/pdf_models.dart';

class HighlightWidget extends StatelessWidget {
  final HighlightOverlay overlay;
  final Offset Function(int, Offset) pageToLocal;
  final double Function(int) effectiveScaleForPage;
  final VoidCallback onDelete;

  HighlightWidget({
    required this.overlay,
    required this.pageToLocal,
    required this.effectiveScaleForPage,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scale = effectiveScaleForPage(overlay.pageNumber);
    final topLeft = pageToLocal(
      overlay.pageNumber,
      Offset(overlay.rect.left, overlay.rect.top),
    );
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