import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Paints the app's signature navy-to-white gradient behind [child].
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: child,
    );
  }
}
