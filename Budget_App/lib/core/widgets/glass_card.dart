import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A minimalist card with a subtle shadow and a light glass (frosted) look,
/// used throughout the dashboard on top of the indigo-to-white background
/// gradient.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.pureWhite.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
            border: Border.all(color: AppColors.indigoMist),
            boxShadow: [
              BoxShadow(
                color: AppColors.indigoSlate.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
