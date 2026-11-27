import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The language the user picked: 'system', 'en', 'fr' or 'ar'.
abstract final class LocaleController {
  static const _key = 'app_language';
  static final ValueNotifier<String> choice = ValueNotifier('system');

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      choice.value = prefs.getString(_key) ?? 'system';
    } catch (_) {
      choice.value = 'system';
    }
  }

  static Future<void> set(String value) async {
    choice.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, value);
    } catch (_) {}
  }
}
