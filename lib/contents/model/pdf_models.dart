import 'dart:typed_data';
import 'dart:ui';

class HighlightOverlay {
  final int pageNumber;
  final Rect rect;
  final Color color;

  HighlightOverlay({
    required this.pageNumber,
    required this.rect,
    required this.color,
  });
}

class TextOverlay {
  final int pageNumber;
  final String text;
  final Color color;
  final double fontSize;
  final Color backgroundColor;
  final bool bold;
  final bool italic;
  final double opacity;
  final Offset pageOffset;
  TextOverlay({
    required this.pageNumber,
    required this.text,
    required this.color,
    required this.fontSize,
    required this.backgroundColor,
    required this.bold,
    required this.italic,
    required this.opacity,
    required this.pageOffset,
  });

  TextOverlay copyWith({
    Offset? pageOffset,
    double? fontSize,
    Color? color,
    Color? backgroundColor,
    bool? bold,
    bool? italic,
    double? opacity,
  }) => TextOverlay(
    pageNumber: pageNumber,
    text: text,
    color: color ?? this.color,
    fontSize: fontSize ?? this.fontSize,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    bold: bold ?? this.bold,
    italic: italic ?? this.italic,
    opacity: opacity ?? this.opacity,
    pageOffset: pageOffset ?? this.pageOffset,
  );
}

class ImageOverlay {
  final Uint8List bytes;
  final int pageNumber;
  final Offset pageOffset;
  double pageWidth;
  double pageHeight;

  ImageOverlay({
    required this.bytes,
    required this.pageNumber,
    required this.pageOffset,
    required this.pageWidth,
    required this.pageHeight,
  });

  ImageOverlay copyWith({
    Offset? pageOffset,
    double? pageWidth,
    double? pageHeight,
  }) => ImageOverlay(
    bytes: bytes,
    pageNumber: pageNumber,
    pageOffset: pageOffset ?? this.pageOffset,
    pageWidth: pageWidth ?? this.pageWidth,
    pageHeight: pageHeight ?? this.pageHeight,
  );
}
class CommentOverlay {
  final int pageNumber;
  final Offset pageOffset;
  final String comment;

  CommentOverlay({
    required this.pageNumber,
    required this.pageOffset,
    required this.comment,
  });

  CommentOverlay copyWith({
    int? pageNumber,
    Offset? pageOffset,
    String? comment,
  }) {
    return CommentOverlay(
      pageNumber: pageNumber ?? this.pageNumber,
      pageOffset: pageOffset ?? this.pageOffset,
      comment: comment ?? this.comment,
    );
  }
}
