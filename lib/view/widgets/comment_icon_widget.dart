import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../contents/model/pdf_models.dart';
import '../../controller/local_controller.dart';

class CommentIconWidget extends StatelessWidget {
  final CommentOverlay overlay;
  final Offset Function(int page, Offset pagePoint) pageToLocal;
  final double Function(int page) effectiveScaleForPage;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;
  final void Function(Offset newPageOffset)? onUpdatePageOffset;
  final VoidCallback? onDragEnd;

  const CommentIconWidget({
    required this.overlay,
    required this.pageToLocal,
    required this.effectiveScaleForPage,
    required this.onTap,
    required this.onDelete,
    this.onUpdatePageOffset,
    this.onDragEnd,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localOffset = pageToLocal(overlay.pageNumber, overlay.pageOffset);
    final scale = effectiveScaleForPage(overlay.pageNumber);
    final lc = Get.find<LocaleController>();

    return Positioned(
      left: localOffset.dx,
      top: localOffset.dy,
      child: GestureDetector(
        onTap: onTap,
        onPanUpdate: (details) {
          if (onUpdatePageOffset == null) return;
          final dxPage = details.delta.dx / scale;
          final dyPage = details.delta.dy / scale;
          final newOffset = Offset(
            overlay.pageOffset.dx + dxPage,
            overlay.pageOffset.dy + dyPage,
          );
          onUpdatePageOffset!(newOffset);
        },
        onPanEnd: (_) {
          if (onDragEnd != null) onDragEnd!();
        },
        onLongPress: () {
          // Delete confirmation
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(lc.t('deleteComment')),
              content: Text(lc.t('deleteQuestion')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(lc.t('cancel')),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await onDelete();
                  },
                  child: Text(lc.t('delete')),
                ),
              ],
            ),
          );
        },
        child: Container(
          width: 36 * scale,
          height: 36 * scale,
          decoration: BoxDecoration(
            color: Colors.amber.shade700,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(Icons.comment, size: 20 * scale, color: Colors.white),
        ),
      ),
    );
  }
}
