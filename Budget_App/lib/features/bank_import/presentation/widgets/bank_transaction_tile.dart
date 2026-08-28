import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../budget_sheet/domain/models/expense_category_type.dart';
import '../../../budget_sheet/presentation/widgets/expense_category_label.dart';
import '../../domain/models/bank_transaction.dart';
import '../bloc/bank_import_bloc.dart';
import '../bloc/bank_import_event.dart';

/// One row in the review table (step 2): a checkbox, the transaction's
/// date/counterparty/title, its amount (green for income, red for expense),
/// and — for expenses only — a category dropdown to correct the guess
/// before import.
class BankTransactionTile extends StatelessWidget {
  const BankTransactionTile({super.key, required this.transaction});

  final BankTransaction transaction;

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<BankImportBloc>();
    final textTheme = Theme.of(context).textTheme;
    final isIncome = transaction.amount >= 0;
    final accent = isIncome ? AppColors.positive : AppColors.negative;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Checkbox(
              value: transaction.isSelected,
              onChanged: (_) => bloc.add(ToggleTransactionSelection(transaction.id)),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title.isEmpty ? transaction.counterparty : transaction.title,
                    style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${_formatDate(transaction.bookingDate)} • ${transaction.counterparty}',
                    style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!isIncome)
              DropdownButton<ExpenseCategoryType>(
                value: transaction.suggestedCategory ?? ExpenseCategoryType.mandatory,
                underline: const SizedBox.shrink(),
                items: [
                  for (final type in ExpenseCategoryType.values)
                    DropdownMenuItem(value: type, child: Text(expenseCategoryTypeLabel(type))),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  bloc.add(
                    ChangeTransactionCategory(
                      id: transaction.id,
                      category: value,
                      subCategory: transaction.suggestedSubCategory,
                    ),
                  );
                },
              )
            else
              Text(
                transaction.suggestedSubCategory,
                style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
              ),
            const SizedBox(width: 8),
            SizedBox(
              width: 96,
              child: Text(
                '${isIncome ? '+' : ''}${CurrencyFormatter.format(transaction.amount)}',
                textAlign: TextAlign.end,
                style: textTheme.bodyMedium?.copyWith(color: accent, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
