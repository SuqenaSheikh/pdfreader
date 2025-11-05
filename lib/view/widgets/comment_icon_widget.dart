import 'package:flutter/material.dart';
import '../../contents/model/pdf_models.dart';

class CommentIconWidget extends StatelessWidget {
  final CommentOverlay overlay;
  final Offset Function(int page, Offset pagePoint) pageToLocal;
  final double Function(int page) effectiveScaleForPage;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;

  const CommentIconWidget({
    required this.overlay,
    required this.pageToLocal,
    required this.effectiveScaleForPage,
    required this.onTap,
    required this.onDelete,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localOffset = pageToLocal(overlay.pageNumber, overlay.pageOffset);
    final scale = effectiveScaleForPage(overlay.pageNumber);

    return Positioned(
      left: localOffset.dx,
      top: localOffset.dy,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: () {
          // Delete confirmation
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Delete Comment?'),
              content: const Text('Do you want to remove this comment?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await onDelete();
                  },
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        },
        child: Container(
          width: 28 * scale,
          height: 28 * scale,
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
          child: Icon(Icons.comment, size: 16 * scale, color: Colors.white),
        ),
      ),
    );
  }
}
