import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

/// Logo, active budget name, a view switcher and the profile/settings
/// entry point.
class WorkspaceTopBar extends StatelessWidget {
  const WorkspaceTopBar({
    super.key,
    required this.budgetName,
    this.onViewSwitch,
    this.onProfileTap,
  });

  final String budgetName;
  final VoidCallback? onViewSwitch;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_rounded, color: AppColors.accentBlue),
          const SizedBox(width: 8),
          Text(AppConstants.appName, style: textTheme.titleMedium),
          const SizedBox(width: 16),
          const _Divider(),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              budgetName,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: 'Przełącz widok',
            onPressed: onViewSwitch,
            icon: const Icon(Icons.swap_horiz_rounded),
          ),
          IconButton(
            tooltip: 'Profil i ustawienia',
            onPressed: onProfileTap,
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      color: AppColors.navy.withValues(alpha: 0.12),
    );
  }
}
