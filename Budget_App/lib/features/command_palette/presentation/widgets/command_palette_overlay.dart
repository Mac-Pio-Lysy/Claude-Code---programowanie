import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_math.dart';
import '../../../budget_sheet/domain/models/expense_category_type.dart';
import '../../../budget_sheet/domain/models/expense_entry.dart';
import '../../../budget_sheet/domain/models/income_entry.dart';
import '../../../budget_sheet/domain/models/income_type.dart';
import '../../../budget_sheet/presentation/bloc/budget_sheet_bloc.dart';
import '../../../budget_sheet/presentation/bloc/budget_sheet_event.dart';
import '../../../budget_sheet/presentation/widgets/expense_category_label.dart';
import '../../../currency/domain/repositories/exchange_rate_repository.dart';
import '../../../settings/presentation/widgets/fair_share_split_dialog.dart';
import '../../../workspace/presentation/cubit/active_workspace_cubit.dart';
import '../../domain/models/parsed_command.dart';
import '../../domain/services/command_parser.dart';

const _uuid = Uuid();

/// Cmd/Ctrl+K, or the search icon in the workspace top bar: a single text
/// field that either quick-adds an income/expense ("kino 45 zachcianki",
/// "paliwo 250 eur", "premia 1500 wplyw") or jumps straight to a section
/// ("arkusz", "oszczednosci", "skaner", "import", "podzial").
///
/// [context] (the caller's, not the dialog's own) is threaded through for
/// any follow-up navigation/dialog after this one closes — its own
/// BuildContext is gone the instant `Navigator.pop()` removes it.
Future<void> showCommandPaletteOverlay(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (_) => _CommandPaletteDialog(hostContext: context),
  );
}

class _CommandPaletteDialog extends StatefulWidget {
  const _CommandPaletteDialog({required this.hostContext});

  final BuildContext hostContext;

  @override
  State<_CommandPaletteDialog> createState() => _CommandPaletteDialogState();
}

class _CommandPaletteDialogState extends State<_CommandPaletteDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  ParsedCommand _command = const UnknownCommand('');
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {
      _command = parseCommand(value);
      _errorMessage = null;
    });
  }

  void _execute() {
    if (_isProcessing) return;

    switch (_command) {
      case NavigateCommand(:final destination):
        final activeId = destination == PaletteDestination.budgetSheet
            ? context.read<ActiveWorkspaceCubit>().state
            : null;
        Navigator.of(context).pop();
        _afterClose(() => _navigate(destination, activeId));
      case OpenFairShareDialogCommand():
        final total = context.read<BudgetSheetBloc>().state.summary.totalExpenses;
        Navigator.of(context).pop();
        _afterClose(
          () => showFairShareSplitDialog(widget.hostContext, initialSharedExpensesTotal: total),
        );
      case AddExpenseParsedCommand(
          :final name,
          :final amount,
          :final currency,
          :final categoryType,
          :final subCategory,
        ):
        unawaited(
          _addExpense(
            name: name,
            amount: amount,
            currency: currency,
            categoryType: categoryType,
            subCategory: subCategory,
          ),
        );
      case AddIncomeParsedCommand(:final title, :final amount, :final currency):
        unawaited(_addIncome(title: title, amount: amount, currency: currency));
      case UnknownCommand():
        if (_controller.text.trim().isNotEmpty) {
          setState(() => _errorMessage = 'Nie rozpoznano polecenia.');
        }
    }
  }

  /// Runs [action] once this dialog's own pop has actually gone through —
  /// [widget.hostContext] is a stable ancestor, so it's still valid, but
  /// scheduling for the next frame avoids racing the pop's route removal.
  void _afterClose(void Function() action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.hostContext.mounted) action();
    });
  }

  void _navigate(PaletteDestination destination, String? activeBudgetId) {
    final router = GoRouter.of(widget.hostContext);
    switch (destination) {
      case PaletteDestination.budgetSheet:
        router.push(activeBudgetId == null ? '/workspace' : '/budget/$activeBudgetId');
      case PaletteDestination.savings:
        router.push('/savings');
      case PaletteDestination.ocrScanner:
        router.push('/ocr');
      case PaletteDestination.bankImport:
        router.push('/bank-import');
    }
  }

  /// [amount] is in [currency]; converts to PLN via NBP when it isn't
  /// already, recording the original amount/rate on the entry for
  /// reference.
  Future<(double amountInPln, double? originalAmount, double? exchangeRate)> _convertToPln(
    double amount,
    String currency,
  ) async {
    if (currency == 'PLN') return (amount, null, null);

    setState(() => _isProcessing = true);
    final rate = await context.read<ExchangeRateRepository>().getExchangeRate(currency);
    return (roundCurrency(amount * rate), amount, rate);
  }

  Future<void> _addExpense({
    required String name,
    required double amount,
    required String currency,
    required ExpenseCategoryType categoryType,
    required String subCategory,
  }) async {
    final budgetSheetBloc = context.read<BudgetSheetBloc>();
    final (amountInPln, originalAmount, exchangeRate) = await _convertToPln(amount, currency);
    if (!mounted) return;

    budgetSheetBloc.add(
      AddExpenseEntry(
        ExpenseEntry(
          id: _uuid.v4(),
          name: name,
          amount: amountInPln,
          categoryType: categoryType,
          subCategory: subCategory,
          date: DateTime.now(),
          comment: 'Dodano przez Command Palette',
          currency: currency,
          originalAmount: originalAmount,
          exchangeRate: exchangeRate,
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  Future<void> _addIncome({
    required String title,
    required double amount,
    required String currency,
  }) async {
    final budgetSheetBloc = context.read<BudgetSheetBloc>();
    final (amountInPln, originalAmount, exchangeRate) = await _convertToPln(amount, currency);
    if (!mounted) return;

    budgetSheetBloc.add(
      AddIncomeEntry(
        IncomeEntry(
          id: _uuid.v4(),
          title: title,
          type: IncomeType.other,
          grossAmount: amountInPln,
          netAmount: amountInPln,
          comment: 'Dodano przez Command Palette',
          currency: currency,
          originalAmount: originalAmount,
          exchangeRate: exchangeRate,
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 96, left: 24, right: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'np. kino 45 zachcianki, paliwo 250 eur, arkusz…',
                  border: InputBorder.none,
                ),
                style: Theme.of(context).textTheme.titleMedium,
                onChanged: _onChanged,
                onSubmitted: (_) => _execute(),
              ),
              const Divider(height: 24),
              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                )
              else
                _CommandPreview(command: _command, errorMessage: _errorMessage),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _isProcessing ? null : _execute,
                  icon: const Icon(Icons.keyboard_return, size: 18),
                  label: const Text('Wykonaj'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommandPreview extends StatelessWidget {
  const _CommandPreview({required this.command, required this.errorMessage});

  final ParsedCommand command;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (errorMessage != null) {
      return Text(errorMessage!, style: textTheme.bodyMedium?.copyWith(color: AppColors.negative));
    }

    return switch (command) {
      AddExpenseParsedCommand(
        :final name,
        :final amount,
        :final currency,
        :final categoryType,
        :final subCategory,
      ) =>
        _PreviewLine(
          icon: Icons.remove_circle_outline,
          color: AppColors.negative,
          text: 'Wydatek: $name, ${amount.toStringAsFixed(2)} $currency '
              '(${expenseCategoryTypeLabel(categoryType)} • $subCategory)',
        ),
      AddIncomeParsedCommand(:final title, :final amount, :final currency) => _PreviewLine(
          icon: Icons.add_circle_outline,
          color: AppColors.positive,
          text: 'Wpływ: $title, ${amount.toStringAsFixed(2)} $currency',
        ),
      NavigateCommand(:final destination) => _PreviewLine(
          icon: Icons.arrow_forward_rounded,
          color: AppColors.primaryIndigo,
          text: 'Przejdź do: ${_destinationLabel(destination)}',
        ),
      OpenFairShareDialogCommand() => const _PreviewLine(
          icon: Icons.balance_outlined,
          color: AppColors.primaryIndigo,
          text: 'Otwórz: Sprawiedliwy podział kosztów',
        ),
      UnknownCommand(:final rawInput) => rawInput.trim().isEmpty
          ? const _CommandPaletteHelp()
          : Text(
              'Nie rozpoznano polecenia.',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
    };
  }

  String _destinationLabel(PaletteDestination destination) => switch (destination) {
        PaletteDestination.budgetSheet => 'Arkusz',
        PaletteDestination.savings => 'Oszczędności',
        PaletteDestination.ocrScanner => 'Skaner OCR',
        PaletteDestination.bankImport => 'Import CSV',
      };
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _CommandPaletteHelp extends StatelessWidget {
  const _CommandPaletteHelp();

  static const _examples = [
    'kino 45 zachcianki — dodaje wydatek',
    'paliwo 250 eur — przelicza po kursie NBP',
    'premia 1500 wplyw — dodaje wpływ',
    'arkusz / oszczednosci / skaner / import / podzial — nawigacja',
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final example in _examples)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              example,
              style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }
}
