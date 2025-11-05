import 'dart:convert';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/pdf_models.dart';

class CommentStorage {
  static const _keyPrefix = 'pdf_comments_';

  // Generate a storage key from PDF path (using hash to avoid issues with special chars)
  static String _getKey(String pdfPath) {
    // Use a simple hash of the path to create a unique key
    final hash = pdfPath.hashCode.toString();
    return '$_keyPrefix$hash';
  }

  // Save comments for a PDF
  static Future<void> saveComments(
    String pdfPath,
    List<CommentOverlay> comments,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKey(pdfPath);

      // Convert comments to JSON
      final jsonList = comments
          .map(
            (comment) => {
              'pageNumber': comment.pageNumber,
              'pageOffset': {
                'dx': comment.pageOffset.dx,
                'dy': comment.pageOffset.dy,
              },
              'comment': comment.comment,
            },
          )
          .toList();

      await prefs.setString(key, jsonEncode(jsonList));
    } catch (e) {
      // Handle error silently
      print('Error saving comments: $e');
    }
  }

  // Load comments for a PDF
  static Future<List<CommentOverlay>> loadComments(String pdfPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKey(pdfPath);
      final jsonString = prefs.getString(key);

      if (jsonString == null) return [];

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((item) {
        final offsetData = item['pageOffset'] as Map<String, dynamic>;
        return CommentOverlay(
          pageNumber: item['pageNumber'] as int,
          pageOffset: ui.Offset(
            (offsetData['dx'] as num).toDouble(),
            (offsetData['dy'] as num).toDouble(),
          ),
          comment: item['comment'] as String,
        );
      }).toList();
    } catch (e) {
      // Handle error silently
      print('Error loading comments: $e');
      return [];
    }
  }

  // Update comment path mapping (when PDF is saved with a new path)
  static Future<void> updateCommentsPath(String oldPath, String newPath) async {
    try {
      final oldComments = await loadComments(oldPath);
      if (oldComments.isNotEmpty) {
        // Save comments to new path
        await saveComments(newPath, oldComments);
        // Optionally delete old comments (or keep both for safety)
        // await deleteComments(oldPath);
      }
    } catch (e) {
      print('Error updating comment path: $e');
    }
  }

  // Delete comments for a PDF (optional cleanup)
  static Future<void> deleteComments(String pdfPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKey(pdfPath);
      await prefs.remove(key);
    } catch (e) {
      print('Error deleting comments: $e');
    }
  }
}
