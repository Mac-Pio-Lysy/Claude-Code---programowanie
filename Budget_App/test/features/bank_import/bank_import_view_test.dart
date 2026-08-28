import 'dart:convert';

import 'package:budget_app/features/bank_import/domain/models/bank_profile.dart';
import 'package:budget_app/features/bank_import/presentation/bloc/bank_import_bloc.dart';
import 'package:budget_app/features/bank_import/presentation/bloc/bank_import_event.dart';
import 'package:budget_app/features/bank_import/presentation/views/bank_import_view.dart';
import 'package:budget_app/features/budget_sheet/presentation/bloc/budget_sheet_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget-level check that reviewing a parsed statement and confirming
/// import actually lands entries in BudgetSheetBloc — exercised through
/// real taps, bypassing only the OS file picker (a platform-channel
/// concern, not ours) the same way receipt_scanner bypasses the camera.
void main() {
  testWidgets('reviewing an imported statement and confirming adds entries to BudgetSheetBloc',
      (tester) async {
    final budgetSheetBloc = BudgetSheetBloc();
    final bankImportBloc = BankImportBloc(budgetSheetBloc: budgetSheetBloc);
    addTearDown(bankImportBloc.close);
    addTearDown(budgetSheetBloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: budgetSheetBloc),
            BlocProvider.value(value: bankImportBloc),
          ],
          child: const Scaffold(body: BankImportView()),
        ),
      ),
    );

    final csvBytes = utf8.encode(
      'Data,Tytuł,Kwota\n'
      '2026-01-05,Wynagrodzenie,5500.00\n'
      '2026-01-06,Zakupy Biedronka,-123.45\n'
      '2026-01-07,Netflix,-55.00',
    );
    bankImportBloc.add(LoadBankCsvFile(csvBytes, BankProfile.universal));
    await tester.pumpAndSettle();

    // Appears twice: as the row's title and as its (matching) subCategory.
    expect(find.text('Wynagrodzenie'), findsWidgets);
    expect(find.text('Zakupy Biedronka'), findsOneWidget);
    expect(find.text('Netflix'), findsOneWidget);

    // Deselect Netflix so only 2 of the 3 rows get imported.
    final netflixRow =
        find.ancestor(of: find.text('Netflix'), matching: find.byType(Row)).first;
    await tester.tap(find.descendant(of: netflixRow, matching: find.byType(Checkbox)));
    await tester.pumpAndSettle();

    final importButton = find.textContaining('Zaimportuj 2 pozycji');
    await tester.ensureVisible(importButton);
    await tester.pumpAndSettle();
    await tester.tap(importButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('Zaimportowano 2 pozycji'), findsOneWidget);

    expect(budgetSheetBloc.state.incomes, hasLength(1));
    expect(budgetSheetBloc.state.incomes.single.netAmount, 5500.0);
    expect(budgetSheetBloc.state.expenses, hasLength(1));
    expect(budgetSheetBloc.state.expenses.single.name, 'Zakupy Biedronka');
    expect(
      budgetSheetBloc.state.expenses.map((e) => e.name),
      isNot(contains('Netflix')),
    );
  });
}
