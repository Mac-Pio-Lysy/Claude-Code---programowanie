import 'package:budget_app/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// End-to-end check of the Sinking Funds section (module Oszczędności) and
/// its "Dodaj do arkusza" integration point with the active budget's sheet.
void main() {
  Future<void> enterFirstBudget(WidgetTester tester) async {
    await tester.pumpWidget(const BudgetApp());
    await tester.pumpAndSettle();

    final guestButton = find.text('Kontynuuj jako gość (Demo / Tryb testowy)');
    await tester.ensureVisible(guestButton);
    await tester.pumpAndSettle();
    await tester.tap(guestButton);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Budżet Domowy 2026'));
    await tester.pumpAndSettle();
  }

  testWidgets('Fundusze celowe tab lists the seeded funds with their monthly provision',
      (tester) async {
    await enterFirstBudget(tester);

    await tester.tap(find.text('Oszczędności'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fundusze celowe'));
    await tester.pumpAndSettle();

    expect(find.text('Ubezpieczenie OC/AC'), findsOneWidget);
    expect(find.text('Święta'), findsOneWidget);
    expect(find.textContaining('Miesięczny odpis:'), findsWidgets);
  });

  testWidgets('"Dodaj do arkusza" pushes the monthly provision into BudgetSheetBloc',
      (tester) async {
    await enterFirstBudget(tester);

    await tester.tap(find.text('Oszczędności'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fundusze celowe'));
    await tester.pumpAndSettle();

    final addToSheetButton = find.widgetWithText(OutlinedButton, 'Dodaj do arkusza').first;
    await tester.ensureVisible(addToSheetButton);
    await tester.pumpAndSettle();
    await tester.tap(addToSheetButton);
    // A single pump (not pumpAndSettle) — pumpAndSettle would fast-forward
    // past the SnackBar's auto-dismiss timer before we can see it.
    await tester.pump();

    expect(find.textContaining('Dodano do arkusza:'), findsOneWidget);

    // Head back to the budget sheet and confirm the expense actually
    // landed in the shared BudgetSheetBloc, not just a UI-only toast.
    await tester.tap(find.text('Arkusz').first);
    await tester.pumpAndSettle();

    // Scroll the sheet's mobile list down to reveal the newly-added expense.
    for (var i = 0; i < 5; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
    expect(find.textContaining('Fundusz: Ubezpieczenie OC/AC'), findsOneWidget);
  });
}
