import 'package:budget_app/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// End-to-end check of AB-1's Free-tier gate: with the seeded single budget
/// already at the Free limit, tapping "+" must show SupportUsView, not
/// CreateBudgetDialog — and activating Premium there must lift the gate.
void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const BudgetApp());
    await tester.pumpAndSettle();
  }

  testWidgets('Free tier: "+" opens SupportUsView instead of creating a second budget',
      (tester) async {
    await pumpApp(tester);

    expect(find.text('Budżet Domowy 2026'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Wesprzyj / Przejdź na Premium'), findsOneWidget);
    expect(find.text('Nowy budżet'), findsNothing);
  });

  testWidgets('Activating Premium in the gate dialog lifts the limit', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aktywuj Premium'));
    await tester.pumpAndSettle();

    // Close the gate dialog, then "+" again should now open CreateBudgetDialog.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Nowy budżet'), findsOneWidget);
  });

  testWidgets('Creating a second budget as Premium adds it to the grid', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aktywuj Premium'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Nazwa budżetu'), 'Wakacje');
    await tester.tap(find.widgetWithText(FilledButton, 'Utwórz'));
    await tester.pumpAndSettle();

    expect(find.text('Budżet Domowy 2026'), findsOneWidget);
    expect(find.text('Wakacje'), findsOneWidget);
  });
}
