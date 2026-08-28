import 'package:flutter/material.dart';

/// Brand color tokens. The app leans on a light indigo-to-snow-white
/// gradient with a single vivid indigo accent, per the product's visual
/// identity.
abstract final class AppColors {
  /// Deep indigo-slate — primary text and anything needing strong contrast
  /// (shadows, high-emphasis icons) against the light background.
  static const Color indigoSlate = Color(0xFF1E1B4B);

  /// Vivid, elegant indigo — the app's primary brand/accent color: buttons,
  /// active states, links.
  static const Color primaryIndigo = Color(0xFF4F46E5);

  /// A touch deeper, for pressed/emphasis states of [primaryIndigo].
  static const Color primaryIndigoDark = Color(0xFF4338CA);

  /// Background-gradient stops, palest to most saturated.
  static const Color indigoMistLight = Color(0xFFEEF2FF);
  static const Color indigoMist = Color(0xFFE0E7FF);
  static const Color indigoMistDeep = Color(0xFFC7D2FE);

  static const Color snowWhite = Color(0xFFF8FAFC);
  static const Color pureWhite = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  static const Color positive = Color(0xFF1B9C63);
  static const Color negative = Color(0xFFD64545);

  /// Background gradient: pastel indigo at the top fading down into a snow
  /// white workspace area.
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [indigoMistLight, indigoMist, indigoMistDeep, snowWhite, pureWhite],
    stops: [0.0, 0.18, 0.38, 0.75, 1.0],
  );
}
