import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Single Light Theme for the app: minimalist cards, soft elevation, and
/// consistently rounded corners (12px) across inputs, buttons and cards.
///
/// Uses Flutter's bundled system typography rather than `google_fonts`:
/// this is an offline-first app, and google_fonts throws (rather than
/// falling back) when a font isn't already cached/bundled and runtime
/// fetching is disabled — not an acceptable failure mode for app startup.
abstract final class AppTheme {
  static const double cornerRadius = 12;

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryIndigo,
      brightness: Brightness.light,
      primary: AppColors.primaryIndigo,
      surface: AppColors.pureWhite,
    );

    final textTheme = ThemeData.light()
        .textTheme
        .apply(bodyColor: AppColors.textPrimary, displayColor: AppColors.textPrimary);

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
        shadowColor: AppColors.indigoSlate.withValues(alpha: 0.08),
        color: AppColors.pureWhite.withValues(alpha: 0.72),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadius),
          side: BorderSide(color: AppColors.indigoMist, width: 1),
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
          backgroundColor: AppColors.primaryIndigo,
          foregroundColor: AppColors.pureWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cornerRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.pureWhite.withValues(alpha: 0.92),
        indicatorColor: AppColors.primaryIndigo.withValues(alpha: 0.15),
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.indigoMist,
      ),
    );
  }
}
