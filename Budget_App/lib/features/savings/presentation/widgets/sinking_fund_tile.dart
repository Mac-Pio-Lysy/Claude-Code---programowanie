import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../budget_sheet/domain/models/expense_category_type.dart';
import '../../../budget_sheet/domain/models/expense_entry.dart';
import '../../../budget_sheet/presentation/bloc/budget_sheet_bloc.dart';
import '../../../budget_sheet/presentation/bloc/budget_sheet_event.dart';
import '../../domain/models/sinking_fund.dart';
import '../bloc/savings_bloc.dart';
import '../bloc/savings_event.dart';
import 'add_sinking_fund_dialog.dart';
import 'contribute_to_fund_dialog.dart';
import 'gradient_progress_bar.dart';

const _uuid = Uuid();

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

/// A single sinking fund: progress toward its target, due date, the
/// monthly amount it takes to get there on time, and quick actions —
/// including pushing that monthly provision straight into the active
/// budget's sheet as a mandatory expense.
class SinkingFundTile extends StatelessWidget {
  const SinkingFundTile({super.key, required this.fund});

  final SinkingFund fund;

  double get _progress => fund.targetAmount <= 0
      ? 0
      : (fund.currentAccumulated / fund.targetAmount).clamp(0.0, 1.0);

  void _addAsFixedExpense(BuildContext context) {
    context.read<BudgetSheetBloc>().add(
          AddExpenseEntry(
            ExpenseEntry(
              id: _uuid.v4(),
              name: 'Fundusz: ${fund.title}',
              amount: fund.monthlyProvision,
              categoryType: ExpenseCategoryType.mandatory,
              subCategory: 'Fundusz celowy',
              date: DateTime.now(),
              comment: 'Miesięczny odpis na termin ${_formatDate(fund.targetDate)}',
            ),
          ),
        );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Dodano do arkusza: ${CurrencyFormatter.format(fund.monthlyProvision)} / mies.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final progressPercent = (_progress * 100).round();
    final canAddToSheet = fund.monthlyProvision > 0;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryIndigo.withValues(alpha: 0.12),
                child: const Icon(Icons.event_repeat_outlined, color: AppColors.primaryIndigo),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  fund.title,
                  style: textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    showAddSinkingFundDialog(context, existing: fund);
                  } else if (value == 'delete') {
                    context.read<SavingsBloc>().add(DeleteSinkingFund(fund.id));
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edytuj')),
                  PopupMenuItem(value: 'delete', child: Text('Usuń')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          GradientProgressBar(progress: _progress),
          const SizedBox(height: 8),
          Text(
            'Zebrano: ${CurrencyFormatter.format(fund.currentAccumulated)} '
            'z ${CurrencyFormatter.format(fund.targetAmount)} ($progressPercent%)',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Termin: ${_formatDate(fund.targetDate)}',
            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.calendar_month_outlined, size: 16, color: AppColors.primaryIndigo),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Miesięczny odpis: ${CurrencyFormatter.format(fund.monthlyProvision)}',
                  style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: canAddToSheet ? () => _addAsFixedExpense(context) : null,
                icon: const Icon(Icons.playlist_add_check_outlined, size: 18),
                label: const Text('Dodaj do arkusza'),
              ),
              FilledButton.tonalIcon(
                onPressed: () =>
                    showContributeToFundDialog(context, fundId: fund.id, fundTitle: fund.title),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Wpłać'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
