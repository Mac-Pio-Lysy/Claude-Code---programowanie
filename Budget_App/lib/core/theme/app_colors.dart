import 'package:flutter/material.dart';

/// Brand color tokens. The app leans on a navy-to-white gradient with a
/// single accent blue, per the product's visual identity.
abstract final class AppColors {
  static const Color navy = Color(0xFF0A2540);
  static const Color accentBlue = Color(0xFF1E88E5);
  static const Color mistWhite = Color(0xFFF4F8FA);
  static const Color pureWhite = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF0A2540);
  static const Color textSecondary = Color(0xFF5C7080);

  static const Color positive = Color(0xFF1B9C63);
  static const Color negative = Color(0xFFD64545);

  /// Background gradient: elegant navy blending into a snow-white surface.
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, accentBlue, mistWhite, pureWhite],
    stops: [0.0, 0.28, 0.7, 1.0],
  );
}
