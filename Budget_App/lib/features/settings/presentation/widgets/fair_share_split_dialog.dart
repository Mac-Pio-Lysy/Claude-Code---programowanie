import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../budget_sheet/domain/services/cost_split_calculator.dart';

const _calculator = CostSplitCalculator();

double? _parseAmount(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

/// AB-7: for a shared budget (`BudgetWorkspace.isShared`), splits the
/// household's shared expenses proportionally to each partner's income
/// instead of a plain 50/50 — reached from the workspace top bar's "Podział
/// kosztów" icon and from BudgetSettingsDialog.
Future<void> showFairShareSplitDialog(
  BuildContext context, {
  double initialSharedExpensesTotal = 0,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: _FairShareSplitForm(initialSharedExpensesTotal: initialSharedExpensesTotal),
          ),
        ),
      ),
    ),
  );
}

class _FairShareSplitForm extends StatefulWidget {
  const _FairShareSplitForm({required this.initialSharedExpensesTotal});

  final double initialSharedExpensesTotal;

  @override
  State<_FairShareSplitForm> createState() => _FairShareSplitFormState();
}

class _FairShareSplitFormState extends State<_FairShareSplitForm> {
  late final _partnerAController = TextEditingController();
  late final _partnerBController = TextEditingController();
  late final _sharedExpensesController = TextEditingController(
    text: widget.initialSharedExpensesTotal > 0
        ? widget.initialSharedExpensesTotal.toStringAsFixed(2)
        : '',
  );

  @override
  void dispose() {
    _partnerAController.dispose();
    _partnerBController.dispose();
    _sharedExpensesController.dispose();
    super.dispose();
  }

  CostSplitResult get _result => _calculator.calculate(
        partnerAIncome: _parseAmount(_partnerAController.text) ?? 0,
        partnerBIncome: _parseAmount(_partnerBController.text) ?? 0,
        sharedExpensesTotal: _parseAmount(_sharedExpensesController.text) ?? 0,
      );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sprawiedliwy podział kosztów', style: textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Wspólne wydatki rozłożone proporcjonalnie do dochodów, zamiast po połowie.',
          style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _partnerAController,
                decoration: const InputDecoration(labelText: 'Dochód Partnera A'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _partnerBController,
                decoration: const InputDecoration(labelText: 'Dochód Partnera B'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _sharedExpensesController,
          decoration: const InputDecoration(labelText: 'Wspólne wydatki (zrzutka na konto domowe)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        _IncomeShareBar(result: _result),
        const SizedBox(height: 16),
        _SplitComparisonTable(result: _result),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Zamknij'),
          ),
        ),
      ],
    );
  }
}

/// Two-color bar sized by each partner's share of total income.
class _IncomeShareBar extends StatelessWidget {
  const _IncomeShareBar({required this.result});

  final CostSplitResult result;

  static const _partnerAColor = AppColors.primaryIndigo;
  static const _partnerBColor = Colors.orange;

  int _flex(double percent) => percent.round().clamp(1, 1000);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Udział w dochodzie gospodarstwa', style: textTheme.labelMedium),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 14,
            child: Row(
              children: [
                Expanded(
                  flex: _flex(result.partnerASharePercent),
                  child: Container(color: _partnerAColor),
                ),
                Expanded(
                  flex: _flex(result.partnerBSharePercent),
                  child: Container(color: _partnerBColor),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _LegendDot(color: _partnerAColor, label: 'Partner A ${result.partnerASharePercent}%'),
            _LegendDot(color: _partnerBColor, label: 'Partner B ${result.partnerBSharePercent}%'),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _SplitComparisonTable extends StatelessWidget {
  const _SplitComparisonTable({required this.result});

  final CostSplitResult result;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Table(
      columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1.5), 2: FlexColumnWidth(1.5)},
      children: [
        TableRow(
          children: [
            const SizedBox.shrink(),
            Text('Proporcjonalnie', style: textTheme.labelSmall, textAlign: TextAlign.end),
            Text('Po połowie', style: textTheme.labelSmall, textAlign: TextAlign.end),
          ],
        ),
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Partner A', style: textTheme.bodyMedium),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                CurrencyFormatter.format(result.partnerAContribution),
                textAlign: TextAlign.end,
                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                CurrencyFormatter.format(result.equalSplitAmount),
                textAlign: TextAlign.end,
                style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Partner B', style: textTheme.bodyMedium),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                CurrencyFormatter.format(result.partnerBContribution),
                textAlign: TextAlign.end,
                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                CurrencyFormatter.format(result.equalSplitAmount),
                textAlign: TextAlign.end,
                style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
