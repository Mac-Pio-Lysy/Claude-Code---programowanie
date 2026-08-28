import 'package:bloc_test/bloc_test.dart';
import 'package:budget_app/features/budget_sheet/domain/models/expense_category_type.dart';
import 'package:budget_app/features/budget_sheet/presentation/bloc/budget_sheet_bloc.dart';
import 'package:budget_app/features/receipt_scanner/data/services/mock_ocr_engine.dart';
import 'package:budget_app/features/receipt_scanner/domain/models/receipt_item.dart';
import 'package:budget_app/features/receipt_scanner/domain/models/scanned_receipt_result.dart';
import 'package:budget_app/features/receipt_scanner/presentation/bloc/receipt_scanner_bloc.dart';
import 'package:budget_app/features/receipt_scanner/presentation/bloc/receipt_scanner_event.dart';
import 'package:budget_app/features/receipt_scanner/presentation/bloc/receipt_scanner_state.dart';
import 'package:flutter_test/flutter_test.dart';

ScannedReceiptResult _sampleResult() {
  return ScannedReceiptResult(
    id: 'receipt-1',
    merchantName: 'Biedronka',
    transactionDate: DateTime(2026, 3, 1),
    totalAmount: 20,
    items: [
      ReceiptItem(
        id: 'item-1',
        name: 'Chleb żytni',
        price: 5,
        suggestedCategory: ExpenseCategoryType.mandatory,
        suggestedSubCategory: 'Jedzenie',
      ),
      ReceiptItem(
        id: 'item-2',
        name: 'Gazeta',
        price: 15,
        suggestedCategory: ExpenseCategoryType.wants,
        suggestedSubCategory: 'Inne',
      ),
    ],
  );
}

void main() {
  group('ProcessReceipt', () {
    blocTest<ReceiptScannerBloc, ReceiptScannerState>(
      'scans successfully via MockOcrEngine',
      build: () => ReceiptScannerBloc(
        scannerService: const MockOcrEngine(),
        budgetSheetBloc: BudgetSheetBloc(),
      ),
      act: (bloc) => bloc.add(const ProcessReceipt('mock/path.jpg')),
      wait: const Duration(milliseconds: 700),
      expect: () => [
        const ReceiptScanningInProgress(),
        isA<ReceiptScanSuccess>()
            .having((s) => s.result.merchantName, 'merchant', 'Biedronka')
            .having((s) => s.result.items.length, 'item count', 5),
      ],
    );
  });

  group('ToggleItemSelection', () {
    blocTest<ReceiptScannerBloc, ReceiptScannerState>(
      'flips isSelected for exactly the matching item',
      build: () => ReceiptScannerBloc(
        scannerService: const MockOcrEngine(),
        budgetSheetBloc: BudgetSheetBloc(),
      ),
      seed: () => ReceiptScanSuccess(_sampleResult()),
      act: (bloc) => bloc.add(const ToggleItemSelection('item-2')),
      verify: (bloc) {
        final state = bloc.state as ReceiptScanSuccess;
        final item1 = state.result.items.firstWhere((i) => i.id == 'item-1');
        final item2 = state.result.items.firstWhere((i) => i.id == 'item-2');
        expect(item1.isSelected, isTrue);
        expect(item2.isSelected, isFalse);
      },
    );
  });

  group('UpdateItemDetails', () {
    blocTest<ReceiptScannerBloc, ReceiptScannerState>(
      'edits name and price for exactly the matching item',
      build: () => ReceiptScannerBloc(
        scannerService: const MockOcrEngine(),
        budgetSheetBloc: BudgetSheetBloc(),
      ),
      seed: () => ReceiptScanSuccess(_sampleResult()),
      act: (bloc) =>
          bloc.add(const UpdateItemDetails(itemId: 'item-1', name: 'Chleb pełnoziarnisty', price: 6.5)),
      verify: (bloc) {
        final state = bloc.state as ReceiptScanSuccess;
        final item1 = state.result.items.firstWhere((i) => i.id == 'item-1');
        final item2 = state.result.items.firstWhere((i) => i.id == 'item-2');
        expect(item1.name, 'Chleb pełnoziarnisty');
        expect(item1.price, 6.5);
        expect(item2.name, 'Gazeta'); // untouched
      },
    );
  });

  group('UpdateItemCategory', () {
    blocTest<ReceiptScannerBloc, ReceiptScannerState>(
      'updates the category/subCategory for exactly the matching item',
      build: () => ReceiptScannerBloc(
        scannerService: const MockOcrEngine(),
        budgetSheetBloc: BudgetSheetBloc(),
      ),
      seed: () => ReceiptScanSuccess(_sampleResult()),
      act: (bloc) => bloc.add(
        const UpdateItemCategory(
          itemId: 'item-2',
          category: ExpenseCategoryType.utility,
          subCategory: 'Transport',
        ),
      ),
      verify: (bloc) {
        final state = bloc.state as ReceiptScanSuccess;
        final item2 = state.result.items.firstWhere((i) => i.id == 'item-2');
        expect(item2.suggestedCategory, ExpenseCategoryType.utility);
        expect(item2.suggestedSubCategory, 'Transport');
      },
    );
  });

  group('ConfirmImportToBudget', () {
    late BudgetSheetBloc budgetSheetBloc;

    blocTest<ReceiptScannerBloc, ReceiptScannerState>(
      'adds only the selected items to BudgetSheetBloc and updates its balance',
      setUp: () => budgetSheetBloc = BudgetSheetBloc(),
      build: () =>
          ReceiptScannerBloc(scannerService: const MockOcrEngine(), budgetSheetBloc: budgetSheetBloc),
      // item-2 (Gazeta, 15) starts deselected, so only item-1 (Chleb, 5) is imported.
      seed: () => ReceiptScanSuccess(
        _sampleResult().copyWith(
          items: [
            _sampleResult().items[0],
            _sampleResult().items[1].copyWith(isSelected: false),
          ],
        ),
      ),
      act: (bloc) => bloc.add(const ConfirmImportToBudget('budget-1')),
      expect: () => [
        const ReceiptImportedSuccessfully(importedCount: 1, totalImported: 5.0),
      ],
      verify: (_) {
        expect(budgetSheetBloc.state.expenses, hasLength(1));
        expect(budgetSheetBloc.state.expenses.single.name, 'Chleb żytni');
        expect(budgetSheetBloc.state.expenses.single.amount, 5.0);
        expect(budgetSheetBloc.state.summary.totalMandatoryExpenses, 5.0);
      },
      tearDown: () => budgetSheetBloc.close(),
    );
  });
}
