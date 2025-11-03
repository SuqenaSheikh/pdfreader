import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RecentPDFStorage {
  static const _key = 'recent_pdfs';

  static Future<void> addPDF(String path, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toIso8601String();
    final newEntry = {'path': path, 'name': name, 'time': now};

    final existing = prefs.getStringList(_key) ?? [];
    existing.removeWhere((e) => jsonDecode(e)['path'] == path);
    existing.insert(0, jsonEncode(newEntry));

    // keep only last 10
    if (existing.length > 10) existing.removeRange(10, existing.length);

    await prefs.setStringList(_key, existing);
  }

  static Future<List<Map<String, String>>> loadPDFs() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.map((e) => Map<String, String>.from(jsonDecode(e))).toList();
  }

  static Future<void> removeByPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key) ?? [];
    existing.removeWhere(
      (e) => Map<String, dynamic>.from(jsonDecode(e))['path'] == path,
    );
    await prefs.setStringList(_key, existing);
  }

  static Future<void> updateEntry({
    required String oldPath,
    String? newPath,
    String? newName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    for (int i = 0; i < list.length; i++) {
      final m = Map<String, dynamic>.from(jsonDecode(list[i]));
      if (m['path'] == oldPath) {
        if (newPath != null) m['path'] = newPath;
        if (newName != null) m['name'] = newName;
        list[i] = jsonEncode(m);
        break;
      }
    }
    await prefs.setStringList(_key, list);
  }
}
