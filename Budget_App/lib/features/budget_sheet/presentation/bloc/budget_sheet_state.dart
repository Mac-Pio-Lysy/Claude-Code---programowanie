import 'package:equatable/equatable.dart';

import '../../domain/models/budget_summary.dart';
import '../../domain/models/expense_entry.dart';
import '../../domain/models/income_entry.dart';
import '../../domain/models/installment_liability.dart';

enum BudgetSheetStatus { initial, loading, loaded, error }

/// Tab id used to mean "no filter, show everything".
const allCategoriesTabId = 'all';

/// Maps a sub-tab id to the [ExpenseEntry.subCategory] values it shows.
/// The "loans" tab intentionally matches no expense sub-category — loan
/// payments live in [BudgetSheetState.liabilities] instead, so selecting it
/// naturally isolates the Zobowiązania/Raty section.
const _tabSubCategories = {
  'housing': {'Mieszkanie'},
  'media': {'Multimedia', 'Telefon/Internet'},
  'savings': {'Oszczędności'},
  'loans': <String>{},
};

class BudgetSheetState extends Equatable {
  const BudgetSheetState({
    required this.status,
    required this.incomes,
    required this.expenses,
    required this.liabilities,
    required this.allocatedToSavings,
    required this.summary,
    required this.selectedTab,
    this.loadedBudgetId,
    this.errorMessage,
  });

  factory BudgetSheetState.initial() => const BudgetSheetState(
        status: BudgetSheetStatus.initial,
        incomes: [],
        expenses: [],
        liabilities: [],
        allocatedToSavings: 0,
        summary: BudgetSummary(
          totalIncomeNet: 0,
          totalMandatoryExpenses: 0,
          totalUtilityExpenses: 0,
          totalWantsExpenses: 0,
          totalLiabilityPayments: 0,
          totalExpenses: 0,
          remainingBalance: 0,
          allocatedToSavings: 0,
          freeCash: 0,
          totalSavingsBalance: 0,
        ),
        selectedTab: allCategoriesTabId,
      );

  final BudgetSheetStatus status;
  final List<IncomeEntry> incomes;
  final List<ExpenseEntry> expenses;
  final List<InstallmentLiability> liabilities;
  final double allocatedToSavings;
  final BudgetSummary summary;
  final String selectedTab;

  /// Which budget's data is currently loaded — so re-dispatching
  /// LoadBudgetSheet for the same id (e.g. re-entering WorkspacePage after
  /// visiting another route) doesn't reseed and discard live edits. See
  /// BudgetSheetBloc._onLoad.
  final String? loadedBudgetId;

  final String? errorMessage;

  /// Expenses matching [selectedTab], or all of them when it's "all".
  List<ExpenseEntry> get visibleExpenses {
    if (selectedTab == allCategoriesTabId) return expenses;
    final allowed = _tabSubCategories[selectedTab] ?? const <String>{};
    return expenses.where((e) => allowed.contains(e.subCategory)).toList();
  }

  BudgetSheetState copyWith({
    BudgetSheetStatus? status,
    List<IncomeEntry>? incomes,
    List<ExpenseEntry>? expenses,
    List<InstallmentLiability>? liabilities,
    double? allocatedToSavings,
    BudgetSummary? summary,
    String? selectedTab,
    String? loadedBudgetId,
    String? errorMessage,
  }) {
    return BudgetSheetState(
      status: status ?? this.status,
      incomes: incomes ?? this.incomes,
      expenses: expenses ?? this.expenses,
      liabilities: liabilities ?? this.liabilities,
      allocatedToSavings: allocatedToSavings ?? this.allocatedToSavings,
      summary: summary ?? this.summary,
      selectedTab: selectedTab ?? this.selectedTab,
      loadedBudgetId: loadedBudgetId ?? this.loadedBudgetId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        incomes,
        expenses,
        liabilities,
        allocatedToSavings,
        summary,
        selectedTab,
        loadedBudgetId,
        errorMessage,
      ];
}
