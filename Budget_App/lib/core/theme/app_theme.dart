import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Single Light Theme for the app: minimalist cards, soft elevation, and
/// consistently rounded corners (12px) across inputs, buttons and cards.
abstract final class AppTheme {
  static const double cornerRadius = 12;

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.accentBlue,
      brightness: Brightness.light,
      primary: AppColors.accentBlue,
      surface: AppColors.pureWhite,
    );

    final textTheme = GoogleFonts.interTextTheme().apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 6,
        shadowColor: AppColors.navy.withValues(alpha: 0.08),
        color: AppColors.pureWhite.withValues(alpha: 0.72),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.pureWhite.withValues(alpha: 0.85),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cornerRadius),
          borderSide: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentBlue,
          foregroundColor: AppColors.pureWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cornerRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.pureWhite.withValues(alpha: 0.92),
        indicatorColor: AppColors.accentBlue.withValues(alpha: 0.15),
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.navy.withValues(alpha: 0.08),
      ),
    );
  }
}
