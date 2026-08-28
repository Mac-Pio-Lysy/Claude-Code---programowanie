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

    final textTheme = _buildTextTheme(ThemeData.light().textTheme);

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
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: AppColors.primaryIndigo.withValues(alpha: 0.15),
        selectedIconTheme: const IconThemeData(color: AppColors.primaryIndigo),
        unselectedIconTheme: IconThemeData(color: AppColors.textSecondary),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(color: AppColors.primaryIndigo),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.indigoMist,
      ),
    );
  }

  /// Custom type scale layered on Flutter's system font: a clear size
  /// hierarchy, tighter letter-spacing on the large display/headline
  /// styles used for headline numbers (e.g. the dashboard balance), and a
  /// heavier weight on headings/figures than on running text.
  static TextTheme _buildTextTheme(TextTheme base) {
    const primary = AppColors.textPrimary;

    return base.copyWith(
      displayLarge: base.displayLarge
          ?.copyWith(color: primary, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.1),
      displayMedium: base.displayMedium
          ?.copyWith(color: primary, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.15),
      displaySmall: base.displaySmall
          ?.copyWith(color: primary, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.15),
      headlineLarge: base.headlineLarge
          ?.copyWith(color: primary, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.15),
      headlineMedium: base.headlineMedium
          ?.copyWith(color: primary, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.15),
      headlineSmall: base.headlineSmall
          ?.copyWith(color: primary, fontWeight: FontWeight.w600, letterSpacing: -0.3, height: 1.2),
      titleLarge:
          base.titleLarge?.copyWith(color: primary, fontWeight: FontWeight.w600, height: 1.25),
      titleMedium:
          base.titleMedium?.copyWith(color: primary, fontWeight: FontWeight.w600, height: 1.3),
      titleSmall:
          base.titleSmall?.copyWith(color: primary, fontWeight: FontWeight.w600, height: 1.3),
      bodyLarge: base.bodyLarge?.copyWith(color: primary, fontWeight: FontWeight.w500, height: 1.5),
      bodyMedium:
          base.bodyMedium?.copyWith(color: primary, fontWeight: FontWeight.w500, height: 1.45),
      bodySmall:
          base.bodySmall?.copyWith(color: primary, fontWeight: FontWeight.w500, height: 1.4),
      labelLarge:
          base.labelLarge?.copyWith(color: primary, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      labelMedium: base.labelMedium
          ?.copyWith(color: primary, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      labelSmall: base.labelSmall
          ?.copyWith(color: primary, fontWeight: FontWeight.w500, letterSpacing: 0.2),
    );
  }
}
