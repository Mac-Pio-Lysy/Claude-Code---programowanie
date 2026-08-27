import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/budget_category.dart';
import '../../domain/entities/chart_mode.dart';
import '../cubit/chart_mode_cubit.dart';

/// Category breakdown (pie) with a one-tap switch to the spending trend
/// (line), via [ChartModeCubit].
class BudgetChartCard extends StatelessWidget {
  const BudgetChartCard({
    super.key,
    required this.categories,
    required this.spendingTrend,
  });

  final List<BudgetCategory> categories;
  final List<double> spendingTrend;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final mode = context.watch<ChartModeCubit>().state;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  mode == ChartMode.pie ? 'Wydatki wg kategorii' : 'Trend wydatków',
                  style: textTheme.labelLarge,
                ),
              ),
              IconButton(
                tooltip: mode == ChartMode.pie
                    ? 'Pokaż wykres liniowy'
                    : 'Pokaż wykres kołowy',
                onPressed: () => context.read<ChartModeCubit>().toggle(),
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              ),
            ],
          ),
          SizedBox(
            height: 180,
            child: mode == ChartMode.pie ? _buildPie() : _buildLine(),
          ),
        ],
      ),
    );
  }

  Widget _buildPie() {
    final total = categories.fold<double>(0, (sum, c) => sum + c.spent);
    if (total == 0) return const SizedBox.shrink();

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 36,
        sections: [
          for (final category in categories)
            PieChartSectionData(
              value: category.spent,
              color: category.chartColor,
              title: '${(category.spent / total * 100).round()}%',
              radius: 48,
              titleStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.pureWhite,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLine() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: AppColors.accentBlue,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            spots: [
              for (var i = 0; i < spendingTrend.length; i++)
                FlSpot(i.toDouble(), spendingTrend[i]),
            ],
          ),
        ],
      ),
    );
  }
}
