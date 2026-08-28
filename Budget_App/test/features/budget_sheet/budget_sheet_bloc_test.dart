import 'package:bloc_test/bloc_test.dart';
import 'package:budget_app/features/budget_sheet/domain/models/expense_category_type.dart';
import 'package:budget_app/features/budget_sheet/domain/models/expense_entry.dart';
import 'package:budget_app/features/budget_sheet/domain/models/income_entry.dart';
import 'package:budget_app/features/budget_sheet/domain/models/income_type.dart';
import 'package:budget_app/features/budget_sheet/domain/models/installment_liability.dart';
import 'package:budget_app/features/budget_sheet/presentation/bloc/budget_sheet_bloc.dart';
import 'package:budget_app/features/budget_sheet/presentation/bloc/budget_sheet_event.dart';
import 'package:budget_app/features/budget_sheet/presentation/bloc/budget_sheet_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const income = IncomeEntry(
    id: 'income-1',
    title: 'Pensja',
    type: IncomeType.uop,
    grossAmount: 6000,
    netAmount: 4500,
  );

  final expense = ExpenseEntry(
    id: 'expense-1',
    name: 'Czynsz',
    amount: 1500,
    categoryType: ExpenseCategoryType.mandatory,
    subCategory: 'Mieszkanie',
    date: DateTime(2026, 1, 1),
  );

  group('LoadBudgetSheet', () {
    blocTest<BudgetSheetBloc, BudgetSheetState>(
      'loads realistic mock data and computes the summary',
      build: BudgetSheetBloc.new,
      act: (bloc) => bloc.add(const LoadBudgetSheet('demo-budget')),
      expect: () => [
        isA<BudgetSheetState>().having((s) => s.status, 'status', BudgetSheetStatus.loading),
        isA<BudgetSheetState>()
            .having((s) => s.status, 'status', BudgetSheetStatus.loaded)
            .having((s) => s.incomes, 'incomes', isNotEmpty)
            .having((s) => s.expenses, 'expenses', isNotEmpty)
            .having((s) => s.liabilities, 'liabilities', isNotEmpty)
            .having((s) => s.summary.totalIncomeNet, 'totalIncomeNet', greaterThan(0)),
      ],
    );
  });

  group('Add/Update/Delete immediately recalculate the balance', () {
    blocTest<BudgetSheetBloc, BudgetSheetState>(
      'AddIncomeEntry raises totalIncomeNet and remainingBalance',
      build: BudgetSheetBloc.new,
      act: (bloc) => bloc.add(const AddIncomeEntry(income)),
      verify: (bloc) {
        expect(bloc.state.incomes, [income]);
        expect(bloc.state.summary.totalIncomeNet, 4500.0);
        expect(bloc.state.summary.remainingBalance, 4500.0);
      },
    );

    blocTest<BudgetSheetBloc, BudgetSheetState>(
      'UpdateIncomeEntry recalculates using the new amount',
      build: BudgetSheetBloc.new,
      seed: () => BudgetSheetState.initial().copyWith(incomes: [income]),
      act: (bloc) => bloc.add(UpdateIncomeEntry(income.copyWith(netAmount: 5000))),
      verify: (bloc) {
        expect(bloc.state.incomes.single.netAmount, 5000.0);
        expect(bloc.state.summary.totalIncomeNet, 5000.0);
      },
    );

    blocTest<BudgetSheetBloc, BudgetSheetState>(
      'DeleteIncomeEntry removes it and zeroes totalIncomeNet',
      build: BudgetSheetBloc.new,
      seed: () => BudgetSheetState.initial().copyWith(incomes: [income]),
      act: (bloc) => bloc.add(const DeleteIncomeEntry('income-1')),
      verify: (bloc) {
        expect(bloc.state.incomes, isEmpty);
        expect(bloc.state.summary.totalIncomeNet, 0.0);
      },
    );

    blocTest<BudgetSheetBloc, BudgetSheetState>(
      'AddExpenseEntry raises totalMandatoryExpenses and lowers remainingBalance',
      build: BudgetSheetBloc.new,
      seed: () => BudgetSheetState.initial().copyWith(incomes: [income]),
      act: (bloc) => bloc.add(AddExpenseEntry(expense)),
      verify: (bloc) {
        expect(bloc.state.summary.totalMandatoryExpenses, 1500.0);
        expect(bloc.state.summary.remainingBalance, 3000.0);
      },
    );

    blocTest<BudgetSheetBloc, BudgetSheetState>(
      'UpdateExpenseEntry recalculates the balance with the new amount',
      build: BudgetSheetBloc.new,
      seed: () => BudgetSheetState.initial().copyWith(incomes: [income], expenses: [expense]),
      act: (bloc) => bloc.add(UpdateExpenseEntry(expense.copyWith(amount: 1800))),
      verify: (bloc) {
        expect(bloc.state.summary.totalMandatoryExpenses, 1800.0);
        expect(bloc.state.summary.remainingBalance, 2700.0);
      },
    );

    blocTest<BudgetSheetBloc, BudgetSheetState>(
      'DeleteExpenseEntry removes it and restores the balance',
      build: BudgetSheetBloc.new,
      seed: () => BudgetSheetState.initial().copyWith(incomes: [income], expenses: [expense]),
      act: (bloc) => bloc.add(const DeleteExpenseEntry('expense-1')),
      verify: (bloc) {
        expect(bloc.state.expenses, isEmpty);
        expect(bloc.state.summary.remainingBalance, 4500.0);
      },
    );

    blocTest<BudgetSheetBloc, BudgetSheetState>(
      'AddInstallmentLiability folds an active payment into mandatory expenses',
      build: BudgetSheetBloc.new,
      seed: () => BudgetSheetState.initial().copyWith(incomes: [income]),
      act: (bloc) {
        final now = DateTime.now();
        bloc.add(
          AddInstallmentLiability(
            InstallmentLiability(
              id: 'liability-1',
              title: 'Rata za laptopa',
              monthlyAmount: 200,
              startDate: DateTime(now.year, now.month - 1, 1),
              endDate: DateTime(now.year, now.month + 5, 1),
            ),
          ),
        );
      },
      verify: (bloc) {
        expect(bloc.state.summary.totalMandatoryExpenses, 200.0);
        expect(bloc.state.summary.remainingBalance, 4300.0);
      },
    );

    blocTest<BudgetSheetBloc, BudgetSheetState>(
      'DeleteInstallmentLiability removes its payment from the balance',
      build: BudgetSheetBloc.new,
      seed: () {
        final now = DateTime.now();
        final liability = InstallmentLiability(
          id: 'liability-1',
          title: 'Rata za laptopa',
          monthlyAmount: 200,
          startDate: DateTime(now.year, now.month - 1, 1),
          endDate: DateTime(now.year, now.month + 5, 1),
        );
        return BudgetSheetState.initial().copyWith(incomes: [income], liabilities: [liability]);
      },
      act: (bloc) => bloc.add(const DeleteInstallmentLiability('liability-1')),
      verify: (bloc) {
        expect(bloc.state.liabilities, isEmpty);
        expect(bloc.state.summary.remainingBalance, 4500.0);
      },
    );
  });

  group('UpdateSavingsAllocation', () {
    blocTest<BudgetSheetBloc, BudgetSheetState>(
      'recalculates freeCash without touching remainingBalance',
      build: BudgetSheetBloc.new,
      seed: () => BudgetSheetState.initial().copyWith(incomes: [income]),
      act: (bloc) => bloc.add(const UpdateSavingsAllocation(1000)),
      verify: (bloc) {
        expect(bloc.state.allocatedToSavings, 1000.0);
        expect(bloc.state.summary.remainingBalance, 4500.0);
        expect(bloc.state.summary.freeCash, 3500.0);
      },
    );
  });

  group('SelectCategoryTab', () {
    blocTest<BudgetSheetBloc, BudgetSheetState>(
      'filters visibleExpenses by the matching subCategory',
      build: BudgetSheetBloc.new,
      seed: () => BudgetSheetState.initial().copyWith(
        expenses: [
          expense, // subCategory: Mieszkanie
          expense.copyWith(
            name: 'Netflix',
            subCategory: 'Multimedia',
            categoryType: ExpenseCategoryType.wants,
          ),
        ],
      ),
      act: (bloc) => bloc.add(const SelectCategoryTab('housing')),
      verify: (bloc) {
        expect(bloc.state.selectedTab, 'housing');
        expect(bloc.state.visibleExpenses, [expense]);
      },
    );

    blocTest<BudgetSheetBloc, BudgetSheetState>(
      'the "loans" tab shows no expenses — liabilities have their own section',
      build: BudgetSheetBloc.new,
      seed: () => BudgetSheetState.initial().copyWith(expenses: [expense]),
      act: (bloc) => bloc.add(const SelectCategoryTab('loans')),
      verify: (bloc) => expect(bloc.state.visibleExpenses, isEmpty),
    );

    blocTest<BudgetSheetBloc, BudgetSheetState>(
      '"all" shows every expense regardless of subCategory',
      build: BudgetSheetBloc.new,
      seed: () => BudgetSheetState.initial().copyWith(expenses: [expense]),
      act: (bloc) => bloc.add(const SelectCategoryTab('all')),
      verify: (bloc) => expect(bloc.state.visibleExpenses, [expense]),
    );
  });
}
