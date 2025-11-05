import 'package:flutter/material.dart';

import '../../contents/model/pdf_models.dart';

class DraggableResizableImage extends StatefulWidget {
  final ImageOverlay overlay;
  final Offset Function(int, Offset) pageToLocal;
  final double Function(int) effectiveScaleForPage;
  final void Function(Offset) onUpdatePageOffset;
  final void Function(double w, double h) onUpdateSize;
  final VoidCallback onDelete;

  const DraggableResizableImage({
    required this.overlay,
    required this.pageToLocal,
    required this.effectiveScaleForPage,
    required this.onUpdatePageOffset,
    required this.onUpdateSize,
    required this.onDelete,
    Key? key,
  }) : super(key: key);

  @override
  State<DraggableResizableImage> createState() =>
      DraggableResizableImageState();
}

class DraggableResizableImageState extends State<DraggableResizableImage> {
  late double _initialPageWidth;
  late double _initialPageHeight;

  @override
  Widget build(BuildContext context) {
    final scale = widget.effectiveScaleForPage(widget.overlay.pageNumber);
    final topLeft = widget.pageToLocal(
      widget.overlay.pageNumber,
      widget.overlay.pageOffset,
    );
    final w = widget.overlay.pageWidth * scale;
    final h = widget.overlay.pageHeight * scale;

    return Positioned(
      left: topLeft.dx,
      top: topLeft.dy,
      width: w,
      height: h,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: widget.onDelete,
        onScaleStart: (details) {
          // capture base sizes before pinch
          _initialPageWidth = widget.overlay.pageWidth;
          _initialPageHeight = widget.overlay.pageHeight;
        },
        onScaleUpdate: (details) {
          final pointerCount = details.pointerCount;
          final currentScale = widget.effectiveScaleForPage(
            widget.overlay.pageNumber,
          );

          if (pointerCount == 1) {
            // dragging (single finger) — translate focalPointDelta into page delta
            final deltaLocal = details.focalPointDelta;
            final deltaPage = Offset(
              deltaLocal.dx / currentScale,
              deltaLocal.dy / currentScale,
            );
            widget.onUpdatePageOffset(widget.overlay.pageOffset + deltaPage);
          } else if (pointerCount >= 2) {
            // resizing (pinch) — compute from initial sizes (no compounding)
            final newW = (_initialPageWidth * details.scale).clamp(
              8.0,
              10000.0,
            );
            // preserve aspect ratio:
            final aspect = _initialPageHeight / _initialPageWidth;
            final newH = newW * aspect;
            widget.onUpdateSize(newW, newH);
          }
        },
        onScaleEnd: (_) {},
        child: Image.memory(widget.overlay.bytes, fit: BoxFit.fill),
      ),
    );
  }
}