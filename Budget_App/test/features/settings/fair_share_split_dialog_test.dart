import 'package:budget_app/features/settings/presentation/widgets/fair_share_split_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('entering both incomes computes and displays the proportional split',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showFairShareSplitDialog(context, initialSharedExpensesTotal: 6000),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Sprawiedliwy podział kosztów'), findsOneWidget);
    // The shared-expenses field is pre-filled from initialSharedExpensesTotal.
    expect(find.widgetWithText(TextField, '6000.00'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Dochód Partnera A'), '8000');
    await tester.enterText(find.widgetWithText(TextField, 'Dochód Partnera B'), '5000');
    await tester.pump();

    expect(find.textContaining('Partner A 61.5%'), findsOneWidget);
    expect(find.textContaining('Partner B 38.5%'), findsOneWidget);

    // Proportional contributions (3 692,31 / 2 307,69) from CostSplitCalculator.
    expect(find.textContaining('692,31'), findsOneWidget);
    expect(find.textContaining('307,69'), findsOneWidget);
    // The 50/50 comparison column (3 000,00 each — CurrencyFormatter
    // uses a non-breaking space as the thousands separator).
    expect(find.textContaining('3 000,00'), findsWidgets);
  });
}
