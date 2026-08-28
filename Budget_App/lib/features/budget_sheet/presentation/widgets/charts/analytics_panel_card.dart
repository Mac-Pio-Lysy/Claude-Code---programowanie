import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../domain/models/budget_summary.dart';
import 'analytics_view_cubit.dart';
import 'budget_comparison_bar_chart.dart';
import 'budget_health_indicators.dart';
import 'budget_pie_chart.dart';

/// Left-column dashboard card: "Podsumowanie Budżetu" with an arrow switch
/// (AB-5) between BudgetPieChart and BudgetComparisonBarChart, followed by
/// a compact row of budget metadata tiles.
class AnalyticsPanelCard extends StatelessWidget {
  const AnalyticsPanelCard({super.key, required this.summary});

  final BudgetSummary summary;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AnalyticsViewCubit(),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(),
            const SizedBox(height: 12),
            BlocBuilder<AnalyticsViewCubit, AnalyticsView>(
              builder: (context, view) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: KeyedSubtree(
                    key: ValueKey(view),
                    child: view == AnalyticsView.pie
                        ? BudgetPieChart(summary: summary)
                        : BudgetComparisonBarChart(summary: summary),
                  ),
                );
              },
            ),
            const Divider(height: 32),
            BudgetHealthIndicators(summary: summary),
            const SizedBox(height: 16),
            _MetadataTiles(summary: summary),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final view = context.watch<AnalyticsViewCubit>().state;

    return Row(
      children: [
        Expanded(
          child: Text('Podsumowanie Budżetu', style: Theme.of(context).textTheme.titleSmall),
        ),
        IconButton(
          tooltip: view == AnalyticsView.pie
              ? 'Pokaż wykres porównawczy'
              : 'Pokaż wykres podziału',
          onPressed: () => context.read<AnalyticsViewCubit>().toggle(),
          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        ),
      ],
    );
  }
}

class _MetadataTiles extends StatelessWidget {
  const _MetadataTiles({required this.summary});

  final BudgetSummary summary;

  @override
  Widget build(BuildContext context) {
    final savingsRate =
        summary.totalIncomeNet > 0 ? summary.allocatedToSavings / summary.totalIncomeNet * 100 : 0;

    return Row(
      children: [
        Expanded(
          child: _Tile(
            icon: Icons.percent_rounded,
            label: 'Wskaźnik oszczędności',
            value: '${savingsRate.round()}%',
            color: AppColors.positive,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Tile(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Wolne środki',
            value: CurrencyFormatter.format(summary.freeCash),
            color: summary.freeCash >= 0 ? AppColors.primaryIndigo : AppColors.negative,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: _Tile(
            icon: Icons.cloud_done_outlined,
            label: 'Status',
            value: 'Online',
            color: AppColors.positive,
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.pureWhite.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
