import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Brand colors. Screens still reference these four directly; new code should
// prefer the semantic tokens in [AppColors] below.
const navy = Color(0xFF101B3D);
const blue = Color(0xFF3568F5);
const pale = Color(0xFFF3F6FC);
const muted = Color(0xFF8792A8);

/// Semantic color tokens, so a screen says what a color is for, not its hex.
abstract final class AppColors {
  static const surface = Colors.white;
  static const surfaceTint = Color(0xFFE9EFFF);
  static const accentSoft = Color(0xFFE4EBFF);
  static const bodyText = Color(0xFF58647A);

  static const success = Color(0xFF15966D);
  static const successSoft = Color(0xFFEAF7F2);
  static const warning = Color(0xFFBD8126);
  static const warningSoft = Color(0xFFFFF4E5);
  static const danger = Color(0xFFD94F5C);
  static const dangerSoft = Color(0xFFFFF0F0);
  static const dangerText = Color(0xFF9C3540);

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
  static ThemeData light() => ThemeData(
        useMaterial3: true,
        colorScheme:
            ColorScheme.fromSeed(seedColor: blue, brightness: Brightness.light),
        scaffoldBackgroundColor: pale,
        textTheme: GoogleFonts.interTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: pale,
          foregroundColor: navy,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      );
}
