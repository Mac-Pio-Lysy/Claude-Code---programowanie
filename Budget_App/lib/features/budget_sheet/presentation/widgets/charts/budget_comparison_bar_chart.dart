import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../domain/models/budget_summary.dart';

/// Compares Wpływy Netto vs Suma Wydatków vs Oszczędności as bars, plus a
/// budget-utilization indicator that turns into a warning once expenses
/// exceed 100% of net income.
class BudgetComparisonBarChart extends StatelessWidget {
  const BudgetComparisonBarChart({super.key, required this.summary});

  final BudgetSummary summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final income = summary.totalIncomeNet;
    final expenses = summary.totalExpenses;
    final savings = summary.allocatedToSavings;
    final maxY = [income, expenses, savings].reduce((a, b) => a > b ? a : b) * 1.2;
    final overBudget = income > 0 && expenses > income;
    final utilization = income > 0 ? (expenses / income).clamp(0.0, 999.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 180,
          child: maxY <= 0
              ? Center(
                  child: Text(
                    'Brak danych do wyświetlenia',
                    style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                )
              : BarChart(
                  BarChartData(
                    maxY: maxY,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const labels = ['Wpływy', 'Wydatki', 'Oszczędności'];
                            final index = value.toInt();
                            if (index < 0 || index >= labels.length) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(labels[index], style: textTheme.labelSmall),
                            );
                          },
                        ),
                      ),
                    ),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                          CurrencyFormatter.format(rod.toY),
                          const TextStyle(color: AppColors.pureWhite, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    barGroups: [
                      _group(0, income, AppColors.positive),
                      _group(1, expenses, overBudget ? AppColors.negative : AppColors.accentBlue),
                      _group(2, savings, const Color(0xFF1B9C63)),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 12),
        _UtilizationIndicator(utilization: utilization, overBudget: overBudget),
        if (overBudget) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.negative),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Przekroczono budżet o ${CurrencyFormatter.format(expenses - income)}!',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.negative,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  BarChartGroupData _group(int x, double value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value < 0 ? 0 : value,
          color: color,
          width: 28,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }
}

class _UtilizationIndicator extends StatelessWidget {
  const _UtilizationIndicator({required this.utilization, required this.overBudget});

  final double utilization;
  final bool overBudget;

  @override
  Widget build(BuildContext context) {
    final color = overBudget ? AppColors.negative : AppColors.accentBlue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wykorzystanie budżetu: ${(utilization * 100).round()}%',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: utilization.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.navy.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
