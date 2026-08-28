import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/models/budget_summary.dart';

/// Compact "financial health" panel: the emergency-fund runway badge plus
/// the 50/30/20 rule's actual-vs-target split, shared by the desktop
/// [AnalyticsPanelCard] and the mobile budget list header.
class BudgetHealthIndicators extends StatelessWidget {
  const BudgetHealthIndicators({super.key, required this.summary});

  final BudgetSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EmergencyRunwayBadge(summary: summary),
        const SizedBox(height: 12),
        Rule502030Bar(summary: summary),
      ],
    );
  }
}

/// "🛡️ Poduszka: 4.5 mies." — colored green/amber/orange by
/// [BudgetSummary.emergencyRunwayStatus].
class EmergencyRunwayBadge extends StatelessWidget {
  const EmergencyRunwayBadge({super.key, required this.summary});

  final BudgetSummary summary;

  @override
  Widget build(BuildContext context) {
    final months = summary.emergencyRunwayMonths;
    final color = switch (summary.emergencyRunwayStatus) {
      EmergencyRunwayStatus.healthy => AppColors.positive,
      EmergencyRunwayStatus.caution => AppColors.caution,
      EmergencyRunwayStatus.critical => AppColors.critical,
    };
    final label = months.isInfinite ? '∞ mies.' : '${months.toStringAsFixed(1)} mies.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🛡️', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            'Poduszka: $label',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Tri-color bar showing the current month's actual Potrzeby/Zachcianki/
/// Oszczędności split, each labeled against its 50/30/20 target.
class Rule502030Bar extends StatelessWidget {
  const Rule502030Bar({super.key, required this.summary});

  final BudgetSummary summary;

  static const _mandatoryColor = AppColors.primaryIndigo;
  static const _wantsColor = Colors.orange;
  static const _savingsColor = AppColors.positive;

  @override
  Widget build(BuildContext context) {
    final mandatory = summary.mandatoryPercentage.clamp(0.0, 100.0);
    final wants = summary.wantsPercentage.clamp(0.0, 100.0);
    final savings = summary.savingsPercentage.clamp(0.0, 100.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                Expanded(flex: _flex(mandatory), child: Container(color: _mandatoryColor)),
                Expanded(flex: _flex(wants), child: Container(color: _wantsColor)),
                Expanded(flex: _flex(savings), child: Container(color: _savingsColor)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _LegendItem(color: _mandatoryColor, label: 'Potrzeby', actual: mandatory, target: 50),
            _LegendItem(color: _wantsColor, label: 'Zachcianki', actual: wants, target: 30),
            _LegendItem(color: _savingsColor, label: 'Oszczędności', actual: savings, target: 20),
          ],
        ),
      ],
    );
  }

  /// At least 1 so a 0% bucket still renders a sliver rather than
  /// disappearing entirely from the bar.
  int _flex(double percentage) => percentage.round().clamp(1, 1000);
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.actual,
    required this.target,
  });

  final Color color;
  final String label;
  final double actual;
  final double target;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        // Flexible (rather than a bare Text) so this still respects the
        // Wrap's incoming width constraint instead of overflowing by a
        // hairline fraction of a pixel at common column widths.
        Flexible(
          child: Text(
            '$label ${actual.round()}% (cel ${target.round()}%)',
            style: Theme.of(context).textTheme.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
