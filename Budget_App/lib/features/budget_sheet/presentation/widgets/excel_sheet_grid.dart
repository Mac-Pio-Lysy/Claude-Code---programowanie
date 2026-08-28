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
import 'comment_indicator.dart';
import 'editable_cell.dart';
import 'entry_forms.dart';
import 'row_context_menu.dart';

/// Excel-like editable budget sheet for desktop/web/tablet: sectioned rows
/// (Wpływy, Wydatki Wymagane, Wydatki Użytkowe, Zachcianki, Zobowiązania/
/// Raty) with inline cell editing, a comment indicator per row, a
/// right-click context menu, and a subtotal footer per section.
class ExcelSheetGrid extends StatelessWidget {
  const ExcelSheetGrid({super.key});

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

        final visibleExpenses = state.visibleExpenses;
        final mandatory = visibleExpenses
            .where((e) => e.categoryType == ExpenseCategoryType.mandatory)
            .toList();
        final utility = visibleExpenses
            .where((e) => e.categoryType == ExpenseCategoryType.utility)
            .toList();
        final wants = visibleExpenses
            .where((e) => e.categoryType == ExpenseCategoryType.wants)
            .toList();

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionCard(
                title: 'Wpływy',
                total: state.incomes.fold(0, (sum, i) => sum + i.netAmount),
                onAdd: () => showIncomeForm(context),
                rows: [for (final income in state.incomes) _IncomeRow(income: income)],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Wydatki Wymagane',
                total: mandatory.fold(0, (sum, e) => sum + e.amount),
                onAdd: () => showExpenseForm(
                  context,
                  initialCategoryType: ExpenseCategoryType.mandatory,
                ),
                rows: [for (final expense in mandatory) _ExpenseRow(expense: expense)],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Wydatki Użytkowe',
                total: utility.fold(0, (sum, e) => sum + e.amount),
                onAdd: () => showExpenseForm(
                  context,
                  initialCategoryType: ExpenseCategoryType.utility,
                ),
                rows: [for (final expense in utility) _ExpenseRow(expense: expense)],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Zachcianki',
                total: wants.fold(0, (sum, e) => sum + e.amount),
                onAdd: () =>
                    showExpenseForm(context, initialCategoryType: ExpenseCategoryType.wants),
                rows: [for (final expense in wants) _ExpenseRow(expense: expense)],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Zobowiązania / Raty',
                total: state.liabilities.fold(0, (sum, l) => sum + l.monthlyAmount),
                onAdd: () => showLiabilityForm(context),
                rows: [
                  for (final liability in state.liabilities) _LiabilityRow(liability: liability),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.total,
    required this.onAdd,
    required this.rows,
  });

  final String title;
  final double total;
  final VoidCallback onAdd;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: textTheme.titleSmall)),
              IconButton(
                tooltip: 'Dodaj pozycję',
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle_outline, size: 20),
              ),
            ],
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Brak pozycji',
                style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            )
          else ...[
            const Divider(height: 16),
            for (var i = 0; i < rows.length; i++) ...[
              rows[i],
              if (i != rows.length - 1) const SizedBox(height: 4),
            ],
          ],
          const Divider(height: 16),
          Row(
            children: [
              Text('Suma', style: textTheme.labelMedium),
              const Spacer(),
              Text(
                CurrencyFormatter.format(total),
                style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IncomeRow extends StatelessWidget {
  const _IncomeRow({required this.income});

  final IncomeEntry income;

  Future<void> _handleSecondaryTap(BuildContext context, Offset position) async {
    final action = await showRowContextMenu(context, position);
    if (!context.mounted) return;
    final bloc = context.read<BudgetSheetBloc>();

    switch (action) {
      case RowMenuAction.edit:
        showIncomeForm(context, existing: income);
      case RowMenuAction.comment:
        showCommentEditor(
          context,
          initialComment: income.comment,
          onSave: (c) => bloc.add(UpdateIncomeEntry(income.copyWith(comment: c))),
        );
      case RowMenuAction.changeCategory:
        showQuickIncomeTypeMenu(
          context,
          income: income,
          position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
        );
      case RowMenuAction.delete:
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
    final bloc = context.read<BudgetSheetBloc>();

    return GestureDetector(
      onSecondaryTapDown: (details) => _handleSecondaryTap(context, details.globalPosition),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: EditableCell(
              value: income.title,
              onSubmit: (v) => bloc.add(UpdateIncomeEntry(income.copyWith(title: v))),
            ),
          ),
          Expanded(
            flex: 2,
            child: EditableCell(
              value: income.netAmount.toStringAsFixed(2),
              isNumeric: true,
              textAlign: TextAlign.end,
              style: const TextStyle(color: AppColors.positive, fontWeight: FontWeight.w600),
              onSubmit: (v) => bloc.add(
                UpdateIncomeEntry(income.copyWith(netAmount: double.parse(v))),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CommentIndicator(
            comment: income.comment,
            onTap: () => showCommentEditor(
              context,
              initialComment: income.comment,
              onSave: (c) => bloc.add(UpdateIncomeEntry(income.copyWith(comment: c))),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({required this.expense});

  final ExpenseEntry expense;

  Future<void> _handleSecondaryTap(BuildContext context, Offset position) async {
    final action = await showRowContextMenu(context, position);
    if (!context.mounted) return;
    final bloc = context.read<BudgetSheetBloc>();

    switch (action) {
      case RowMenuAction.edit:
        showExpenseForm(context, existing: expense);
      case RowMenuAction.comment:
        showCommentEditor(
          context,
          initialComment: expense.comment,
          onSave: (c) => bloc.add(UpdateExpenseEntry(expense.copyWith(comment: c))),
        );
      case RowMenuAction.changeCategory:
        showQuickExpenseCategoryMenu(
          context,
          expense: expense,
          position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
        );
      case RowMenuAction.delete:
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
    final bloc = context.read<BudgetSheetBloc>();

    return GestureDetector(
      onSecondaryTapDown: (details) => _handleSecondaryTap(context, details.globalPosition),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: EditableCell(
              value: expense.name,
              onSubmit: (v) => bloc.add(UpdateExpenseEntry(expense.copyWith(name: v))),
            ),
          ),
          Expanded(
            flex: 2,
            child: EditableCell(
              value: expense.amount.toStringAsFixed(2),
              isNumeric: true,
              textAlign: TextAlign.end,
              style: const TextStyle(color: AppColors.negative, fontWeight: FontWeight.w600),
              onSubmit: (v) => bloc.add(
                UpdateExpenseEntry(expense.copyWith(amount: double.parse(v))),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CommentIndicator(
            comment: expense.comment,
            onTap: () => showCommentEditor(
              context,
              initialComment: expense.comment,
              onSave: (c) => bloc.add(UpdateExpenseEntry(expense.copyWith(comment: c))),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiabilityRow extends StatelessWidget {
  const _LiabilityRow({required this.liability});

  final InstallmentLiability liability;

  Future<void> _handleSecondaryTap(BuildContext context, Offset position) async {
    final action = await showRowContextMenu(context, position, includeComment: false, includeCategory: false);
    if (!context.mounted) return;
    final bloc = context.read<BudgetSheetBloc>();

    switch (action) {
      case RowMenuAction.edit:
        showLiabilityForm(context, existing: liability);
      case RowMenuAction.delete:
        confirmDelete(
          context,
          title: liability.title,
          onConfirmed: () => bloc.add(DeleteInstallmentLiability(liability.id)),
        );
      case RowMenuAction.comment:
      case RowMenuAction.changeCategory:
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<BudgetSheetBloc>();

    return GestureDetector(
      onSecondaryTapDown: (details) => _handleSecondaryTap(context, details.globalPosition),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: EditableCell(
              value: liability.title,
              onSubmit: (v) => bloc.add(UpdateInstallmentLiability(liability.copyWith(title: v))),
            ),
          ),
          Expanded(
            flex: 2,
            child: EditableCell(
              value: liability.monthlyAmount.toStringAsFixed(2),
              isNumeric: true,
              textAlign: TextAlign.end,
              style: const TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.w600),
              onSubmit: (v) => bloc.add(
                UpdateInstallmentLiability(liability.copyWith(monthlyAmount: double.parse(v))),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Pozostało ${liability.remainingMonths} z ${liability.totalMonths} rat',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
