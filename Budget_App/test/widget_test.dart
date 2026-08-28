import 'package:budget_app/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App boots into the workspace dashboard', (tester) async {
    await tester.pumpWidget(const BudgetApp());
    await tester.pumpAndSettle();

    expect(find.text('Bilans netto'), findsOneWidget);
    expect(find.text('Wpływy'), findsOneWidget);
  });

  testWidgets('Bottom nav switches to Ustawienia', (tester) async {
    await tester.pumpWidget(const BudgetApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ustawienia').last);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Ustawienia'), findsOneWidget);
  });
}
