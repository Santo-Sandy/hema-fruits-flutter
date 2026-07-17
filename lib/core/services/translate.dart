import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Translate {
  static Map<String, String> _data = {};
  static String _currentLang = "english";

  static Future<void> load(String langCode) async {
    _currentLang = langCode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', langCode);

    final String jsonString = await rootBundle.loadString(
      'assets/language/$langCode.json',
    );
    final Map<String, dynamic> jsonMap = json.decode(jsonString);

    _data = {};
    _flatten(jsonMap, '', _data); // ← recursive flatten
  }

  /// Recursively converts {"homeScreen": {"new": "New"}}
  /// into {"homeScreen.new": "New"}
  static void _flatten(
    Map<String, dynamic> map,
    String prefix,
    Map<String, String> result,
  ) {
    map.forEach((key, value) {
      final fullKey = prefix.isEmpty ? key : '$prefix.$key';
      if (value is Map<String, dynamic>) {
        _flatten(value, fullKey, result);
      } else {
        result[fullKey] = value.toString();
      }
    });
  }

  /// Restores the saved language on app start
  static Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('app_language') ?? 'english';
    await load(saved);
  }

  static String t(String key, [Map<String, String>? params]) {
    String value = _data[key] ?? key;

    if (params != null) {
      params.forEach((k, v) {
        value = value.replaceAll('{{$k}}', v);
      });
    }

    return value;
  }

  static String get currentLang => _currentLang;
}
