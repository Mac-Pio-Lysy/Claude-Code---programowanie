import 'package:budget_app/features/budget_sheet/presentation/bloc/budget_sheet_bloc.dart';
import 'package:budget_app/features/receipt_scanner/data/services/mock_ocr_engine.dart';
import 'package:budget_app/features/receipt_scanner/presentation/bloc/receipt_scanner_bloc.dart';
import 'package:budget_app/features/receipt_scanner/presentation/bloc/receipt_scanner_event.dart';
import 'package:budget_app/features/receipt_scanner/presentation/views/receipt_scanner_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget-level check that a scanned receipt's checked items actually land
/// in BudgetSheetBloc (not just that ReceiptScannerBloc computes the right
/// numbers internally) — exercised through real taps on the rendered UI.
void main() {
  testWidgets('reviewing a scan and confirming import adds expenses to BudgetSheetBloc',
      (tester) async {
    final budgetSheetBloc = BudgetSheetBloc();
    final receiptBloc = ReceiptScannerBloc(
      scannerService: const MockOcrEngine(),
      budgetSheetBloc: budgetSheetBloc,
    );
    addTearDown(receiptBloc.close);
    addTearDown(budgetSheetBloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: budgetSheetBloc),
            BlocProvider.value(value: receiptBloc),
          ],
          child: const Scaffold(body: ReceiptScannerView(targetBudgetId: 'budget-1')),
        ),
      ),
    );

    // Bypasses the OS image picker (a platform-channel concern, not ours)
    // by driving the same OCR pipeline PickReceiptImage would have.
    receiptBloc.add(const ProcessReceipt('mock/path.jpg'));
    await tester.pumpAndSettle();

    expect(find.text('Biedronka'), findsOneWidget);
    expect(find.text('Chleb żytni'), findsOneWidget);
    expect(find.text('Gazeta codzienna'), findsOneWidget);

    // Deselect "Gazeta codzienna" so only 4 of the 5 items get imported.
    final gazetaRow = find.ancestor(
      of: find.text('Gazeta codzienna'),
      matching: find.byType(Row),
    ).first;
    await tester.tap(find.descendant(of: gazetaRow, matching: find.byType(Checkbox)));
    await tester.pumpAndSettle();

    final importButton = find.text('Dodaj zaznaczone wydatki do bieżącego budżetu');
    await tester.ensureVisible(importButton);
    await tester.pumpAndSettle();
    await tester.tap(importButton);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Zaimportowano 4 pozycji'),
      findsOneWidget,
    );

    expect(budgetSheetBloc.state.expenses, hasLength(4));
    expect(
      budgetSheetBloc.state.expenses.map((e) => e.name),
      isNot(contains('Gazeta codzienna')),
    );
    expect(
      budgetSheetBloc.state.expenses.map((e) => e.name),
      containsAll(['Chleb żytni', 'Mleko 3.2%', 'Masło extra', 'Jabłka 1kg']),
    );
    // 4.50 + 3.20 + 6.99 + 5.50
    expect(budgetSheetBloc.state.summary.totalExpenses, closeTo(20.19, 0.001));
  });
}
