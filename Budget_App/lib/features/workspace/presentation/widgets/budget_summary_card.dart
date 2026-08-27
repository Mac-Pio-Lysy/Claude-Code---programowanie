import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/budget_summary.dart';

/// Headline card: Wpływy - Wydatki = Pozostało.
class BudgetSummaryCard extends StatelessWidget {
  const BudgetSummaryCard({super.key, required this.summary});

  final BudgetSummary summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bilans netto', style: textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(summary.remaining),
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: summary.remaining >= 0
                  ? AppColors.positive
                  : AppColors.negative,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Figure(
                  label: 'Wpływy',
                  value: summary.income,
                  color: AppColors.positive,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Figure(
                  label: 'Wydatki',
                  value: summary.expenses,
                  color: AppColors.negative,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final double value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: textTheme.bodySmall),
              Text(
                CurrencyFormatter.format(value),
                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
