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

  static const Color pureWhite = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  static const Color positive = Color(0xFF1B9C63);
  static const Color negative = Color(0xFFD64545);

  /// Amber — the middle tier of the emergency-runway traffic light
  /// (3-6 months of fixed costs covered).
  static const Color caution = Color(0xFFF59E0B);

  /// Orange — the emergency-runway traffic light's low tier (under 3
  /// months covered). Deliberately distinct from [negative] (red), which
  /// is reserved for outright negative amounts/errors.
  static const Color critical = Color(0xFFF97316);

  /// Background gradient: pastel indigo on the left fading into a snow
  /// white workspace on the right.
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [indigoMistLight, indigoMist, pureWhite],
    stops: [0.0, 0.35, 1.0],
  );
}
