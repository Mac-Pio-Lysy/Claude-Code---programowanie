import 'package:equatable/equatable.dart';

import '../../domain/models/expense_entry.dart';
import '../../domain/models/income_entry.dart';
import '../../domain/models/installment_liability.dart';

sealed class BudgetSheetEvent extends Equatable {
  const BudgetSheetEvent();

  @override
  List<Object?> get props => [];
}

class LoadBudgetSheet extends BudgetSheetEvent {
  const LoadBudgetSheet(this.budgetId);

  final String budgetId;

  @override
  List<Object?> get props => [budgetId];
}

class AddIncomeEntry extends BudgetSheetEvent {
  const AddIncomeEntry(this.entry);

  final IncomeEntry entry;

  @override
  List<Object?> get props => [entry];
}

class UpdateIncomeEntry extends BudgetSheetEvent {
  const UpdateIncomeEntry(this.entry);

  final IncomeEntry entry;

  @override
  List<Object?> get props => [entry];
}

class DeleteIncomeEntry extends BudgetSheetEvent {
  const DeleteIncomeEntry(this.entryId);

  final String entryId;

  @override
  List<Object?> get props => [entryId];
}

class AddExpenseEntry extends BudgetSheetEvent {
  const AddExpenseEntry(this.entry);

  final ExpenseEntry entry;

  @override
  List<Object?> get props => [entry];
}

class UpdateExpenseEntry extends BudgetSheetEvent {
  const UpdateExpenseEntry(this.entry);

  final ExpenseEntry entry;

  @override
  List<Object?> get props => [entry];
}

class DeleteExpenseEntry extends BudgetSheetEvent {
  const DeleteExpenseEntry(this.entryId);

  final String entryId;

  @override
  List<Object?> get props => [entryId];
}

class AddInstallmentLiability extends BudgetSheetEvent {
  const AddInstallmentLiability(this.liability);

  final InstallmentLiability liability;

  @override
  List<Object?> get props => [liability];
}

/// Not in the original spec's event list, but required for the "Edytuj" /
/// "Usuń wiersz" context-menu actions to work on the Zobowiązania/Raty
/// section too — added for symmetry with income/expense entries.
class UpdateInstallmentLiability extends BudgetSheetEvent {
  const UpdateInstallmentLiability(this.liability);

  final InstallmentLiability liability;

  @override
  List<Object?> get props => [liability];
}

class DeleteInstallmentLiability extends BudgetSheetEvent {
  const DeleteInstallmentLiability(this.liabilityId);

  final String liabilityId;

  @override
  List<Object?> get props => [liabilityId];
}

class UpdateSavingsAllocation extends BudgetSheetEvent {
  const UpdateSavingsAllocation(this.amount);

  final double amount;

  @override
  List<Object?> get props => [amount];
}

class SelectCategoryTab extends BudgetSheetEvent {
  const SelectCategoryTab(this.tabId);

  final String tabId;

  @override
  List<Object?> get props => [tabId];
}
