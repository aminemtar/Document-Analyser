import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The user's appearance choice: follow the system, or force light or dark.
/// Kept on the device.
abstract final class ThemeController {
  /// Centre of the app bar's sun/moon button on screen, kept up to date by the
  /// button itself. Every theme change, whether it comes from that button,
  /// from Profile or from the phone, spreads from (or shrinks back into) this
  /// point, so it always looks like the icon is what changed the theme.
  static Offset? toggleCenter;

  static const _key = 'theme_mode';

  static final ValueNotifier<ThemeMode> mode =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  /// Reads the saved choice into [mode]. Call before `runApp` so the first
  /// frame already uses the right theme.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      mode.value =
          ThemeMode.values.asNameMap()[prefs.getString(_key)] ?? ThemeMode.system;
    } catch (_) {
      mode.value = ThemeMode.system;
    }
  }

  static Future<void> set(ThemeMode value) async {
    mode.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, value.name);
    } catch (_) {
      // The choice still applies for this session.
    }
  }
}
