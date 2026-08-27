import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';

/// Small at-a-glance tiles: tags, sync status, budget type.
class BudgetMetadataTiles extends StatelessWidget {
  const BudgetMetadataTiles({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _MetaTile(
            icon: Icons.cloud_done_outlined,
            label: 'Online',
            color: AppColors.positive,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _MetaTile(
            icon: Icons.groups_outlined,
            label: 'Wspólny',
            color: AppColors.accentBlue,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _MetaTile(
            icon: Icons.sell_outlined,
            label: 'Miesięczny',
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
