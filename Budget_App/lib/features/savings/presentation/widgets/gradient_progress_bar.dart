import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A `LinearProgressIndicator`-alike with a green gradient fill (plain
/// `LinearProgressIndicator` only supports a solid `color`), used for a
/// savings goal's progress toward its target.
class GradientProgressBar extends StatelessWidget {
  const GradientProgressBar({super.key, required this.progress, this.height = 10});

  /// 0.0 to 1.0.
  final double progress;
  final double height;

  static const _gradient = LinearGradient(
    colors: [Color(0xFF66BB6A), AppColors.positive],
  );

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Container(
                height: height,
                width: double.infinity,
                color: AppColors.indigoSlate.withValues(alpha: 0.08),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                height: height,
                width: constraints.maxWidth * clamped,
                decoration: const BoxDecoration(gradient: _gradient),
              ),
            ],
          );
        },
      ),
    );
  }
}
