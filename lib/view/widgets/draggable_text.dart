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
  final VoidCallback onStartEditing;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onEditingComplete;
  final bool isEditing;

  const DraggableText({
    required this.overlay,
    required this.pageToLocal,
    required this.effectiveScaleForPage,
    required this.onUpdatePageOffset,
    required this.onDelete,
    required this.onTap,
    required this.onStartEditing,
    required this.onTextChanged,
    required this.onEditingComplete,
    required this.isEditing,
    Key? key,
  }) : super(key: key);

  @override
  State<DraggableText> createState() => DraggableTextState();
}

class DraggableTextState extends State<DraggableText> {
  Offset _dragStartOffset = Offset.zero;
  Offset _initialPageOffset = Offset.zero;
  final lc = Get.find<LocaleController>();
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _sentComplete = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.overlay.text);
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.isEditing) {
        _focusNode.requestFocus();
        _controller.selection = TextSelection.collapsed(
          offset: _controller.text.length,
        );
      }
    });
  }

  @override
  void didUpdateWidget(covariant DraggableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.overlay.text != widget.overlay.text &&
        _controller.text != widget.overlay.text) {
      _controller.text = widget.overlay.text;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }

    if (!oldWidget.isEditing && widget.isEditing) {
      _sentComplete = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
          _controller.selection = TextSelection.collapsed(
            offset: _controller.text.length,
          );
        }
      });
    }

    if (oldWidget.isEditing && !widget.isEditing) {
      _sentComplete = false;
      if (_focusNode.hasFocus) {
        _focusNode.unfocus();
      }
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localOffset = widget.pageToLocal(
      widget.overlay.pageNumber,
      widget.overlay.pageOffset,
    );
    final scale = widget.effectiveScaleForPage(widget.overlay.pageNumber);
    final textStyle = TextStyle(
      color: widget.overlay.color,
      fontSize: widget.overlay.fontSize * scale,
      fontWeight: widget.overlay.bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: widget.overlay.italic ? FontStyle.italic : FontStyle.normal,
    );

    return Positioned(
      left: localOffset.dx,
      top: localOffset.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onTap,
        onDoubleTap: widget.onStartEditing,
        onPanStart: widget.isEditing
            ? null
            : (details) {
                _dragStartOffset = details.localPosition;
                _initialPageOffset = widget.overlay.pageOffset;
              },
        onPanUpdate: widget.isEditing
            ? null
            : (details) {
                // calculate movement delta
                final delta = details.localPosition - _dragStartOffset;
                // convert movement to PDF page coordinates
                final newPageOffset =
                    _initialPageOffset +
                    Offset(delta.dx / scale, delta.dy / scale);
                widget.onUpdatePageOffset(newPageOffset);
              },
        onLongPress: () {
          // optional delete confirmation
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(lc.t('deleteText')),
              content: Text(lc.t('deleteQuestion')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(lc.t('cancel')),
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
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                widget.isEditing
                    ? ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          maxWidth: 400,
                        ),
                        child: IntrinsicWidth(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            autofocus: false,
                            maxLines: null,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: textStyle,
                            cursorColor: widget.overlay.color,
                            onChanged: widget.onTextChanged,
                            onEditingComplete: () {
                              if (!_sentComplete) {
                                _sentComplete = true;
                                widget.onEditingComplete();
                              }
                            },
                          ),
                        ),
                      )
                    : Text(widget.overlay.text, style: textStyle),
                if (widget.isEditing)
                  Positioned(
                    top: -28,
                    right: -12,
                    child: Material(
                      color: Colors.transparent,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        icon: Icon(
                          Icons.color_lens,
                          size: 20,
                          color: widget.overlay.color,
                        ),
                        onPressed: widget.onTap,
                        tooltip: lc.t('color'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
