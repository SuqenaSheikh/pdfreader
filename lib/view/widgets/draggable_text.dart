import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../contents/model/pdf_models.dart';
import '../../controller/local_controller.dart';

class DraggableText extends StatefulWidget {
  final TextOverlay overlay;
  final Offset Function(int page, Offset pagePoint) pageToLocal;
  final double Function(int page) effectiveScaleForPage;
  final ValueChanged<Offset> onUpdatePageOffset;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const DraggableText({
    required this.overlay,
    required this.pageToLocal,
    required this.effectiveScaleForPage,
    required this.onUpdatePageOffset,
    required this.onDelete,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  State<DraggableText> createState() => DraggableTextState();
}

class DraggableTextState extends State<DraggableText> {
  Offset _dragStartOffset = Offset.zero;
  Offset _initialPageOffset = Offset.zero;
  final lc = Get.find<LocaleController>();


  @override
  Widget build(BuildContext context) {
    final localOffset = widget.pageToLocal(
      widget.overlay.pageNumber,
      widget.overlay.pageOffset,
    );
    final scale = widget.effectiveScaleForPage(widget.overlay.pageNumber);

    return Positioned(
      left: localOffset.dx,
      top: localOffset.dy,
      child: GestureDetector(
        onTap: widget.onTap,
        onPanStart: (details) {
          _dragStartOffset = details.localPosition;
          _initialPageOffset = widget.overlay.pageOffset;
        },
        onPanUpdate: (details) {
          // calculate movement delta
          final delta = details.localPosition - _dragStartOffset;
          // convert movement to PDF page coordinates
          final newPageOffset =
              _initialPageOffset + Offset(delta.dx / scale, delta.dy / scale);
          widget.onUpdatePageOffset(newPageOffset);
        },
        onLongPress: () {
          // optional delete confirmation
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(lc.t('deleteText')),
              content:  Text(lc.t('deleteQuestion')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child:  Text(lc.t('cancel')),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onDelete();
                  },
                  child: Text(lc.t('delete')),
                ),
              ],
            ),
          );
        },
        child: Opacity(
          opacity: widget.overlay.opacity,
          child: Container(
            padding: const EdgeInsets.all(2),
            color: widget.overlay.backgroundColor,
            child: Text(
              widget.overlay.text,
              style: TextStyle(
                color: widget.overlay.color,
                fontSize: widget.overlay.fontSize * scale,
                fontWeight: widget.overlay.bold
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontStyle: widget.overlay.italic
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}