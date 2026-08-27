import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Reserved slot for a Google AdMob banner on the free tier. Renders a
/// neutral placeholder until the ads SDK is wired in.
class AdBannerPlaceholder extends StatelessWidget {
  const AdBannerPlaceholder({super.key, this.height = 50});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      alignment: Alignment.center,
      color: AppColors.navy.withValues(alpha: 0.05),
      child: Text(
        'Reklama',
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
