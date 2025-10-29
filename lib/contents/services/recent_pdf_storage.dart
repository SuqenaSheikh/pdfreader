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
}
