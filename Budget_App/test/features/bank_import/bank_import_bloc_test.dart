import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:budget_app/features/bank_import/domain/models/bank_profile.dart';
import 'package:budget_app/features/bank_import/presentation/bloc/bank_import_bloc.dart';
import 'package:budget_app/features/bank_import/presentation/bloc/bank_import_event.dart';
import 'package:budget_app/features/bank_import/presentation/bloc/bank_import_state.dart';
import 'package:budget_app/features/budget_sheet/domain/models/expense_category_type.dart';
import 'package:budget_app/features/budget_sheet/presentation/bloc/budget_sheet_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> _csv(String text) => utf8.encode(text);

final _validCsv = _csv(
  'Data,Tytuł,Kwota\n'
  '2026-01-05,Wynagrodzenie,5500.00\n'
  '2026-01-06,Zakupy Biedronka,-123.45',
);

void main() {
  group('SelectBankProfile', () {
    blocTest<BankImportBloc, BankImportState>(
      'sets selectedProfile without changing status',
      build: () => BankImportBloc(budgetSheetBloc: BudgetSheetBloc()),
      act: (bloc) => bloc.add(const SelectBankProfile(BankProfile.mBank)),
      expect: () => [
        isA<BankImportState>()
            .having((s) => s.selectedProfile, 'selectedProfile', BankProfile.mBank)
            .having((s) => s.status, 'status', BankImportStatus.pickingFile),
      ],
    );
  });

  group('LoadBankCsvFile', () {
    blocTest<BankImportBloc, BankImportState>(
      'parses a valid file into reviewable transactions',
      build: () => BankImportBloc(budgetSheetBloc: BudgetSheetBloc()),
      act: (bloc) => bloc.add(LoadBankCsvFile(_validCsv, BankProfile.universal)),
      expect: () => [
        isA<BankImportState>().having((s) => s.status, 'status', BankImportStatus.parsing),
        isA<BankImportState>()
            .having((s) => s.status, 'status', BankImportStatus.reviewing)
            .having((s) => s.transactions, 'transactions', hasLength(2))
            .having((s) => s.selectedCount, 'selectedCount', 2),
      ],
    );

    blocTest<BankImportBloc, BankImportState>(
      'an unparsable file emits failure with an error message',
      build: () => BankImportBloc(budgetSheetBloc: BudgetSheetBloc()),
      act: (bloc) => bloc.add(LoadBankCsvFile(_csv('Foo,Bar\n1,2'), BankProfile.universal)),
      expect: () => [
        isA<BankImportState>().having((s) => s.status, 'status', BankImportStatus.parsing),
        isA<BankImportState>()
            .having((s) => s.status, 'status', BankImportStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage', isNotNull),
      ],
    );
  });

  group('ToggleTransactionSelection / ChangeTransactionCategory', () {
    blocTest<BankImportBloc, BankImportState>(
      'toggling deselects exactly the matching transaction',
      build: () => BankImportBloc(budgetSheetBloc: BudgetSheetBloc()),
      act: (bloc) async {
        bloc.add(LoadBankCsvFile(_validCsv, BankProfile.universal));
        await Future<void>.delayed(Duration.zero);
        final expenseId = bloc.state.transactions.last.id;
        bloc.add(ToggleTransactionSelection(expenseId));
      },
      skip: 2,
      verify: (bloc) {
        expect(bloc.state.transactions.first.isSelected, isTrue);
        expect(bloc.state.transactions.last.isSelected, isFalse);
        expect(bloc.state.selectedCount, 1);
      },
    );

    blocTest<BankImportBloc, BankImportState>(
      'changes the category/subCategory for exactly the matching transaction',
      build: () => BankImportBloc(budgetSheetBloc: BudgetSheetBloc()),
      act: (bloc) async {
        bloc.add(LoadBankCsvFile(_validCsv, BankProfile.universal));
        await Future<void>.delayed(Duration.zero);
        final expenseId = bloc.state.transactions.last.id;
        bloc.add(
          ChangeTransactionCategory(
            id: expenseId,
            category: ExpenseCategoryType.wants,
            subCategory: 'Rozrywka',
          ),
        );
      },
      skip: 2,
      verify: (bloc) {
        final expense = bloc.state.transactions.last;
        expect(expense.suggestedCategory, ExpenseCategoryType.wants);
        expect(expense.suggestedSubCategory, 'Rozrywka');
      },
    );
  });

  group('ConfirmImportSelectedTransactions', () {
    late BudgetSheetBloc budgetSheetBloc;

    blocTest<BankImportBloc, BankImportState>(
      'sends the income row to AddIncomeEntry and the expense row to AddExpenseEntry',
      setUp: () => budgetSheetBloc = BudgetSheetBloc(),
      build: () => BankImportBloc(budgetSheetBloc: budgetSheetBloc),
      act: (bloc) async {
        bloc.add(LoadBankCsvFile(_validCsv, BankProfile.universal));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ConfirmImportSelectedTransactions());
      },
      skip: 2,
      expect: () => [
        isA<BankImportState>()
            .having((s) => s.status, 'status', BankImportStatus.imported)
            .having((s) => s.importedCount, 'importedCount', 2)
            .having((s) => s.importedTotal, 'importedTotal', 5376.55),
      ],
      verify: (_) {
        expect(budgetSheetBloc.state.incomes, hasLength(1));
        expect(budgetSheetBloc.state.incomes.single.netAmount, 5500.0);
        expect(budgetSheetBloc.state.expenses, hasLength(1));
        expect(budgetSheetBloc.state.expenses.single.amount, 123.45);
        expect(budgetSheetBloc.state.expenses.single.categoryType, ExpenseCategoryType.mandatory);
      },
      tearDown: () => budgetSheetBloc.close(),
    );

    blocTest<BankImportBloc, BankImportState>(
      'only imports checked-off transactions',
      setUp: () => budgetSheetBloc = BudgetSheetBloc(),
      build: () => BankImportBloc(budgetSheetBloc: budgetSheetBloc),
      act: (bloc) async {
        bloc.add(LoadBankCsvFile(_validCsv, BankProfile.universal));
        await Future<void>.delayed(Duration.zero);
        bloc.add(ToggleTransactionSelection(bloc.state.transactions.last.id));
        bloc.add(const ConfirmImportSelectedTransactions());
      },
      skip: 3,
      verify: (_) {
        expect(budgetSheetBloc.state.incomes, hasLength(1));
        expect(budgetSheetBloc.state.expenses, isEmpty);
      },
      tearDown: () => budgetSheetBloc.close(),
    );
  });
}
