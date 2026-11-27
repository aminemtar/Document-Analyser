import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/l10n.dart';

/// Whether the dark palette is active.
///
/// The colors below read this every time they are used, so they are getters
/// and cannot appear in `const` expressions. `DocuMindApp` flips it and
/// rebuilds the whole tree when the theme changes.
abstract final class AppPalette {
  static bool dark = false;
}

Color _pick(Color light, Color dark) => AppPalette.dark ? dark : light;

// Brand colors. Screens use these directly; new code should prefer the
// semantic tokens in [AppColors] below.
Color get navy => _pick(const Color(0xFF101B3D), const Color(0xFFE8EDFA));
Color get blue => _pick(const Color(0xFF3568F5), const Color(0xFF4F7DFF));
Color get pale => _pick(const Color(0xFFF3F6FC), const Color(0xFF0C1220));
Color get muted => _pick(const Color(0xFF8792A8), const Color(0xFF8F9AB5));

/// Semantic color tokens, so a screen says what a color is for, not its hex.
abstract final class AppColors {
  /// Cards, sheets, the navigation bar and input bars.
  static Color get surface => _pick(Colors.white, const Color(0xFF172036));
  static Color get surfaceTint =>
      _pick(const Color(0xFFE9EFFF), const Color(0xFF1F2C4F));
  static Color get accentSoft =>
      _pick(const Color(0xFFE4EBFF), const Color(0xFF22305A));
  static Color get bodyText =>
      _pick(const Color(0xFF58647A), const Color(0xFFA9B4CC));
  static Color get border =>
      _pick(const Color(0xFFDDE3F0), const Color(0xFF2A3554));

  static Color get success =>
      _pick(const Color(0xFF15966D), const Color(0xFF35C494));
  static Color get successSoft =>
      _pick(const Color(0xFFEAF7F2), const Color(0xFF12302A));
  static Color get warning =>
      _pick(const Color(0xFFBD8126), const Color(0xFFE0A24A));
  static Color get warningSoft =>
      _pick(const Color(0xFFFFF4E5), const Color(0xFF3A2D14));
  static Color get danger =>
      _pick(const Color(0xFFD94F5C), const Color(0xFFFF7A87));
  static Color get dangerSoft =>
      _pick(const Color(0xFFFFF0F0), const Color(0xFF3A1E26));
  static Color get dangerText =>
      _pick(const Color(0xFF9C3540), const Color(0xFFFF9AA5));

  /// Same in both themes: white text sits on it.
  static const heroGradient = [
    Color(0xFF172B65),
    Color(0xFF315FE5),
    Color(0xFF5485FF),
  ];
}

/// Spacing and radius scale.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
}

abstract final class AppRadius {
  static const sm = 12.0;
  static const md = 18.0;
  static const lg = 22.0;
}

abstract final class AppTheme {
  /// The theme for the current [AppPalette.dark] value.
  static ThemeData build() {
    final brightness = AppPalette.dark ? Brightness.dark : Brightness.light;
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
            seedColor: const Color(0xFF3568F5), brightness: brightness)
        .copyWith(
            primary: blue,
            onPrimary: Colors.white,
            surface: AppColors.surface,
            onSurface: navy);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: pale,
      // Cairo draws Arabic well; Inter is used for English and French.
      textTheme: (L10n.language.value == 'ar'
              ? GoogleFonts.cairoTextTheme(base.textTheme)
              : GoogleFonts.interTextTheme(base.textTheme))
          .apply(bodyColor: navy, displayColor: navy),
      appBarTheme: AppBarTheme(
        backgroundColor: pale,
        foregroundColor: navy,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      dialogTheme: DialogThemeData(backgroundColor: AppColors.surface),
    );
  }
}
