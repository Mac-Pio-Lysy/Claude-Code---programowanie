import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../savings/presentation/bloc/savings_bloc.dart';
import '../../domain/models/expense_category_type.dart';
import '../../domain/models/expense_entry.dart';
import '../../domain/models/income_entry.dart';
import '../../domain/models/income_type.dart';
import '../../domain/models/installment_liability.dart';
import '../../domain/services/budget_calculator.dart';
import 'budget_sheet_event.dart';
import 'budget_sheet_state.dart';

class BudgetSheetBloc extends Bloc<BudgetSheetEvent, BudgetSheetState> {
  BudgetSheetBloc({BudgetCalculator? calculator, this.savingsBloc})
      : _calculator = calculator ?? const BudgetCalculator(),
        super(BudgetSheetState.initial()) {
    on<LoadBudgetSheet>(_onLoad);
    on<AddIncomeEntry>(_onAddIncome);
    on<UpdateIncomeEntry>(_onUpdateIncome);
    on<DeleteIncomeEntry>(_onDeleteIncome);
    on<AddExpenseEntry>(_onAddExpense);
    on<UpdateExpenseEntry>(_onUpdateExpense);
    on<DeleteExpenseEntry>(_onDeleteExpense);
    on<AddInstallmentLiability>(_onAddLiability);
    on<UpdateInstallmentLiability>(_onUpdateLiability);
    on<DeleteInstallmentLiability>(_onDeleteLiability);
    on<UpdateSavingsAllocation>(_onUpdateSavingsAllocation);
    on<SelectCategoryTab>(_onSelectCategoryTab);
  }

  final BudgetCalculator _calculator;

  /// Optional — when provided, its `totalSavingsBalance` feeds
  /// `BudgetSummary.emergencyRunwayMonths`. Read fresh on every
  /// recalculation rather than subscribed to, so a deposit made on the
  /// Savings page is reflected the next time this sheet changes.
  final SavingsBloc? savingsBloc;

  Future<void> _onLoad(LoadBudgetSheet event, Emitter<BudgetSheetState> emit) async {
    // Re-entering the same budget (e.g. after visiting Savings/Settings)
    // must not reseed and discard whatever was added/edited since the
    // first load — only a genuinely different budget gets fresh data.
    if (state.status == BudgetSheetStatus.loaded && state.loadedBudgetId == event.budgetId) {
      return;
    }

    emit(state.copyWith(status: BudgetSheetStatus.loading));
    try {
      final seed = _seedData();
      emit(
        _recalculate(
          state.copyWith(
            status: BudgetSheetStatus.loaded,
            incomes: seed.incomes,
            expenses: seed.expenses,
            liabilities: seed.liabilities,
            loadedBudgetId: event.budgetId,
          ),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: BudgetSheetStatus.error,
          errorMessage: 'Nie udało się wczytać danych budżetu.',
        ),
      );
    }
  }

  void _onAddIncome(AddIncomeEntry event, Emitter<BudgetSheetState> emit) {
    emit(_recalculate(state.copyWith(incomes: [...state.incomes, event.entry])));
  }

  void _onUpdateIncome(UpdateIncomeEntry event, Emitter<BudgetSheetState> emit) {
    emit(
      _recalculate(
        state.copyWith(
          incomes: [
            for (final income in state.incomes)
              if (income.id == event.entry.id) event.entry else income,
          ],
        ),
      ),
    );
  }

  void _onDeleteIncome(DeleteIncomeEntry event, Emitter<BudgetSheetState> emit) {
    emit(
      _recalculate(
        state.copyWith(
          incomes: state.incomes.where((i) => i.id != event.entryId).toList(),
        ),
      ),
    );
  }

  void _onAddExpense(AddExpenseEntry event, Emitter<BudgetSheetState> emit) {
    emit(_recalculate(state.copyWith(expenses: [...state.expenses, event.entry])));
  }

  void _onUpdateExpense(UpdateExpenseEntry event, Emitter<BudgetSheetState> emit) {
    emit(
      _recalculate(
        state.copyWith(
          expenses: [
            for (final expense in state.expenses)
              if (expense.id == event.entry.id) event.entry else expense,
          ],
        ),
      ),
    );
  }

  void _onDeleteExpense(DeleteExpenseEntry event, Emitter<BudgetSheetState> emit) {
    emit(
      _recalculate(
        state.copyWith(
          expenses: state.expenses.where((e) => e.id != event.entryId).toList(),
        ),
      ),
    );
  }

  void _onAddLiability(AddInstallmentLiability event, Emitter<BudgetSheetState> emit) {
    emit(
      _recalculate(
        state.copyWith(liabilities: [...state.liabilities, event.liability]),
      ),
    );
  }

  void _onUpdateLiability(
    UpdateInstallmentLiability event,
    Emitter<BudgetSheetState> emit,
  ) {
    emit(
      _recalculate(
        state.copyWith(
          liabilities: [
            for (final liability in state.liabilities)
              if (liability.id == event.liability.id) event.liability else liability,
          ],
        ),
      ),
    );
  }

  void _onDeleteLiability(
    DeleteInstallmentLiability event,
    Emitter<BudgetSheetState> emit,
  ) {
    emit(
      _recalculate(
        state.copyWith(
          liabilities:
              state.liabilities.where((l) => l.id != event.liabilityId).toList(),
        ),
      ),
    );
  }

  void _onUpdateSavingsAllocation(
    UpdateSavingsAllocation event,
    Emitter<BudgetSheetState> emit,
  ) {
    emit(_recalculate(state.copyWith(allocatedToSavings: event.amount)));
  }

  void _onSelectCategoryTab(SelectCategoryTab event, Emitter<BudgetSheetState> emit) {
    emit(state.copyWith(selectedTab: event.tabId));
  }

  BudgetSheetState _recalculate(BudgetSheetState newState) {
    final summary = _calculator.calculateSummary(
      incomes: newState.incomes,
      expenses: newState.expenses,
      liabilities: newState.liabilities,
      allocatedToSavings: newState.allocatedToSavings,
      totalSavingsBalance: savingsBloc?.state.totalSavingsBalance ?? 0.0,
    );
    return newState.copyWith(summary: summary);
  }

  /// Realistic starter data: a UoP salary, rent + electricity, a laptop
  /// installment plan, and a couple of "wants" (Netflix, going out).
  ({
    List<IncomeEntry> incomes,
    List<ExpenseEntry> expenses,
    List<InstallmentLiability> liabilities,
  }) _seedData() {
    final now = DateTime.now();

    return (
      incomes: const [
        IncomeEntry(
          id: 'income-salary',
          title: 'Pensja główna',
          type: IncomeType.uop,
          grossAmount: 9500,
          netAmount: 6800,
        ),
      ],
      expenses: [
        ExpenseEntry(
          id: 'expense-rent',
          name: 'Czynsz',
          amount: 1800,
          categoryType: ExpenseCategoryType.mandatory,
          subCategory: 'Mieszkanie',
          date: DateTime(now.year, now.month, 1),
        ),
        ExpenseEntry(
          id: 'expense-electricity',
          name: 'Prąd',
          amount: 220,
          categoryType: ExpenseCategoryType.mandatory,
          subCategory: 'Mieszkanie',
          date: DateTime(now.year, now.month, 5),
        ),
        ExpenseEntry(
          id: 'expense-transport',
          name: 'Bilet miesięczny',
          amount: 110,
          categoryType: ExpenseCategoryType.utility,
          subCategory: 'Transport',
          date: DateTime(now.year, now.month, 1),
        ),
        ExpenseEntry(
          id: 'expense-netflix',
          name: 'Netflix',
          amount: 43,
          categoryType: ExpenseCategoryType.wants,
          subCategory: 'Multimedia',
          date: DateTime(now.year, now.month, 10),
        ),
        ExpenseEntry(
          id: 'expense-night-out',
          name: 'Wyjście do kina',
          amount: 120,
          categoryType: ExpenseCategoryType.wants,
          subCategory: 'Rozrywka',
          date: DateTime(now.year, now.month, 15),
          comment: 'Premiera z znajomymi',
        ),
      ],
      liabilities: [
        InstallmentLiability(
          id: 'liability-laptop',
          title: 'Rata za laptopa',
          monthlyAmount: 180,
          startDate: DateTime(now.year, now.month - 6, 1),
          endDate: DateTime(now.year, now.month + 5, 1),
        ),
      ],
    );
  }
}
