import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/models/expense_category_type.dart';
import '../../domain/models/expense_entry.dart';
import '../../domain/models/income_entry.dart';
import '../../domain/models/installment_liability.dart';
import '../bloc/budget_sheet_bloc.dart';
import '../bloc/budget_sheet_event.dart';
import '../bloc/budget_sheet_state.dart';
import 'charts/budget_pie_chart.dart';
import 'entry_forms.dart';
import 'expense_category_label.dart';
import 'mobile_row_actions_sheet.dart';

/// Touch-optimized budget list for mobile: colored transaction tiles
/// (green = wpływy, red/orange = wydatki with a category badge, blue =
/// raty), long-press for quick actions.
class MobileBudgetList extends StatelessWidget {
  const MobileBudgetList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetSheetBloc, BudgetSheetState>(
      builder: (context, state) {
        if (state.status == BudgetSheetStatus.loading ||
            state.status == BudgetSheetStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == BudgetSheetStatus.error) {
          return Center(child: Text(state.errorMessage ?? 'Błąd wczytywania.'));
        }

        final tiles = <Widget>[
          for (final income in state.incomes) _IncomeTile(income: income),
          for (final expense in state.visibleExpenses) _ExpenseTile(expense: expense),
          for (final liability in state.liabilities) _LiabilityTile(liability: liability),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassCard(child: BudgetPieChart(summary: state.summary, compact: true)),
            const SizedBox(height: 16),
            if (tiles.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Brak pozycji w tej kategorii',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              for (final tile in tiles) Padding(padding: const EdgeInsets.only(bottom: 10), child: tile),
          ],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.accentColor,
    required this.title,
    required this.trailing,
    this.subtitle,
    this.onLongPress,
  });

  final Color accentColor;
  final String title;
  final Widget trailing;
  final Widget? subtitle;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppColors.pureWhite.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: accentColor, width: 4)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    ?subtitle,
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _IncomeTile extends StatelessWidget {
  const _IncomeTile({required this.income});

  final IncomeEntry income;

  Future<void> _handleLongPress(BuildContext context) async {
    final action = await showMobileRowActions(context);
    if (!context.mounted) return;
    final bloc = context.read<BudgetSheetBloc>();

    switch (action) {
      case MobileRowAction.edit:
        showIncomeForm(context, existing: income);
      case MobileRowAction.comment:
        showCommentEditor(
          context,
          initialComment: income.comment,
          onSave: (c) => bloc.add(UpdateIncomeEntry(income.copyWith(comment: c))),
        );
      case MobileRowAction.delete:
        confirmDelete(
          context,
          title: income.title,
          onConfirmed: () => bloc.add(DeleteIncomeEntry(income.id)),
        );
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Tile(
      accentColor: AppColors.positive,
      title: income.title,
      onLongPress: () => _handleLongPress(context),
      trailing: Text(
        '+${CurrencyFormatter.format(income.netAmount)}',
        style: const TextStyle(color: AppColors.positive, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense});

  final ExpenseEntry expense;

  Future<void> _handleLongPress(BuildContext context) async {
    final action = await showMobileRowActions(context);
    if (!context.mounted) return;
    final bloc = context.read<BudgetSheetBloc>();

    switch (action) {
      case MobileRowAction.edit:
        showExpenseForm(context, existing: expense);
      case MobileRowAction.comment:
        showCommentEditor(
          context,
          initialComment: expense.comment,
          onSave: (c) => bloc.add(UpdateExpenseEntry(expense.copyWith(comment: c))),
        );
      case MobileRowAction.delete:
        confirmDelete(
          context,
          title: expense.name,
          onConfirmed: () => bloc.add(DeleteExpenseEntry(expense.id)),
        );
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent =
        expense.categoryType == ExpenseCategoryType.wants ? Colors.orange : AppColors.negative;

    return _Tile(
      accentColor: accent,
      title: expense.name,
      onLongPress: () => _handleLongPress(context),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            expenseCategoryTypeLabel(expense.categoryType),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: accent),
          ),
        ),
      ),
      trailing: Text(
        '-${CurrencyFormatter.format(expense.amount)}',
        style: TextStyle(color: accent, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _LiabilityTile extends StatelessWidget {
  const _LiabilityTile({required this.liability});

  final InstallmentLiability liability;

  Future<void> _handleLongPress(BuildContext context) async {
    final action = await showMobileRowActions(context, includeComment: false);
    if (!context.mounted) return;
    final bloc = context.read<BudgetSheetBloc>();

    switch (action) {
      case MobileRowAction.edit:
        showLiabilityForm(context, existing: liability);
      case MobileRowAction.delete:
        confirmDelete(
          context,
          title: liability.title,
          onConfirmed: () => bloc.add(DeleteInstallmentLiability(liability.id)),
        );
      case MobileRowAction.comment:
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Tile(
      accentColor: AppColors.primaryIndigo,
      title: liability.title,
      onLongPress: () => _handleLongPress(context),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          'Pozostało ${liability.remainingMonths} z ${liability.totalMonths} rat',
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
      ),
      trailing: Text(
        '-${CurrencyFormatter.format(liability.monthlyAmount)}',
        style: const TextStyle(color: AppColors.primaryIndigo, fontWeight: FontWeight.w700),
      ),
    );
  }
}
