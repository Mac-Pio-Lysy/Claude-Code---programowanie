import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../domain/models/budget_summary.dart';

class _Slice {
  const _Slice(this.label, this.value, this.color);

  final String label;
  final double value;
  final Color color;
}

/// Donut chart of where every złoty of net income went this period:
/// Wydatki Wymagane, Użytkowe, Zachcianki, Raty/Zobowiązania, Zaalokowane
/// Oszczędności and Pozostałe wolne środki. Shows total expenses in the
/// center, a legend below, and a touch/hover readout with the exact PLN
/// amount and percentage for the selected slice.
class BudgetPieChart extends StatefulWidget {
  const BudgetPieChart({super.key, required this.summary, this.compact = false});

  final BudgetSummary summary;

  /// Smaller radius, no legend — for the mobile tile-list header.
  final bool compact;

  @override
  State<BudgetPieChart> createState() => _BudgetPieChartState();
}

class _BudgetPieChartState extends State<BudgetPieChart> {
  int? _touchedIndex;

  List<_Slice> _slices() {
    final s = widget.summary;
    return [
      _Slice('Wydatki Wymagane', s.totalMandatoryExpenses, const Color(0xFFE57373)),
      _Slice('Wydatki Użytkowe', s.totalUtilityExpenses, const Color(0xFFFFB74D)),
      _Slice('Zachcianki', s.totalWantsExpenses, const Color(0xFF9575CD)),
      _Slice('Raty i Zobowiązania', s.totalLiabilityPayments, AppColors.indigoSlate),
      _Slice('Zaalokowane Oszczędności', s.allocatedToSavings, const Color(0xFF1B9C63)),
      _Slice('Wolne środki', s.freeCash < 0 ? 0 : s.freeCash, const Color(0xFFB0BEC5)),
    ].where((slice) => slice.value > 0).toList();
  }

  @override
  Widget build(BuildContext context) {
    final slices = _slices();
    final total = slices.fold<double>(0, (sum, s) => sum + s.value);
    final radius = widget.compact ? 22.0 : 48.0;
    final centerSpace = widget.compact ? 26.0 : 40.0;

    if (total <= 0) {
      return SizedBox(
        height: widget.compact ? 100 : 220,
        child: Center(
          child: Text(
            'Brak danych do wyświetlenia',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final touched = _touchedIndex != null && _touchedIndex! < slices.length
        ? slices[_touchedIndex!]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: widget.compact ? 110 : 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: centerSpace,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      final index = response?.touchedSection?.touchedSectionIndex;
                      if (!event.isInterestedForInteractions || index == null || index < 0) {
                        setState(() => _touchedIndex = null);
                      } else {
                        setState(() => _touchedIndex = index);
                      }
                    },
                  ),
                  sections: [
                    for (var i = 0; i < slices.length; i++)
                      PieChartSectionData(
                        value: slices[i].value,
                        color: slices[i].color,
                        radius: i == _touchedIndex ? radius + 6 : radius,
                        showTitle: false,
                      ),
                  ],
                ),
              ),
              if (!widget.compact)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      CurrencyFormatter.format(widget.summary.totalExpenses),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Wydatki',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (touched != null) ...[
          const SizedBox(height: 8),
          Text(
            '${touched.label}: ${CurrencyFormatter.format(touched.value)} '
            '(${(touched.value / total * 100).round()}%)',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w600, color: touched.color),
          ),
        ],
        if (!widget.compact) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              for (final slice in slices)
                _LegendEntry(color: slice.color, label: slice.label),
            ],
          ),
        ],
      ],
    );
  }
}

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
