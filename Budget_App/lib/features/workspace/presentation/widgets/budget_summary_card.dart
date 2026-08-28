import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../budget_sheet/domain/models/budget_summary.dart';

/// Headline card: Wpływy - Wydatki = Pozostało, plus what's earmarked for
/// savings vs. truly free. Sourced live from `BudgetSheetBloc`, so it
/// updates the instant an entry is added, edited or removed.
///
/// Collapsible via the eye icon — for a quick, privacy-friendly glance
/// (e.g. screen-sharing) it can shrink to a single line showing only the
/// remaining balance.
class BudgetSummaryCard extends StatefulWidget {
  const BudgetSummaryCard({super.key, required this.summary});

  final BudgetSummary summary;

  @override
  State<BudgetSummaryCard> createState() => _BudgetSummaryCardState();
}

class _BudgetSummaryCardState extends State<BudgetSummaryCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final textTheme = Theme.of(context).textTheme;
    final balanceColor =
        summary.remainingBalance >= 0 ? AppColors.positive : AppColors.negative;

    if (!_isExpanded) {
      return GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: textTheme.titleMedium,
                  children: [
                    const TextSpan(text: 'Pozostało: '),
                    TextSpan(
                      text: CurrencyFormatter.format(summary.remainingBalance),
                      style: TextStyle(color: balanceColor, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: 'Pokaż pełne podsumowanie',
              onPressed: () => setState(() => _isExpanded = true),
              icon: const Icon(Icons.visibility_outlined),
            ),
          ],
        ),
      );
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Bilans netto', style: textTheme.labelLarge)),
              IconButton(
                tooltip: 'Zwiń do bilansu',
                onPressed: () => setState(() => _isExpanded = false),
                icon: const Icon(Icons.visibility_off_outlined),
              ),
            ],
          ),
          Text(
            CurrencyFormatter.format(summary.remainingBalance),
            style: textTheme.headlineMedium?.copyWith(color: balanceColor),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Figure(
                  label: 'Wpływy',
                  value: summary.totalIncomeNet,
                  color: AppColors.positive,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Figure(
                  label: 'Wydatki',
                  value: summary.totalExpenses,
                  color: AppColors.negative,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
            ],
          ),
          if (summary.allocatedToSavings > 0) ...[
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _Figure(
                    label: 'Oszczędności',
                    value: summary.allocatedToSavings,
                    color: AppColors.primaryIndigo,
                    icon: Icons.savings_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Figure(
                    label: 'Wolne środki',
                    value: summary.freeCash,
                    color: AppColors.indigoSlate,
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ),
              ],
            ),
          ],
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
