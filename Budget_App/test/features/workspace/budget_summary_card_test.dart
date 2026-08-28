import 'package:budget_app/core/theme/app_theme.dart';
import 'package:budget_app/features/budget_sheet/domain/models/budget_summary.dart';
import 'package:budget_app/features/workspace/presentation/widgets/budget_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _summary = BudgetSummary(
  totalIncomeNet: 5000,
  totalMandatoryExpenses: 2000,
  totalUtilityExpenses: 500,
  totalWantsExpenses: 250,
  totalLiabilityPayments: 0,
  totalExpenses: 2750,
  remainingBalance: 2250,
  allocatedToSavings: 0,
  freeCash: 2250,
  totalSavingsBalance: 0,
);

/// The "privacy view" toggle (AB-UX-2): the eye icon collapses the full
/// breakdown down to a single balance line, and back.
void main() {
  Future<void> pumpCard(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: BudgetSummaryCard(summary: _summary)),
      ),
    );
  }

  testWidgets('collapses to a single remaining-balance line and back', (tester) async {
    await pumpCard(tester);

    expect(find.text('Bilans netto'), findsOneWidget);
    expect(find.text('Wpływy'), findsOneWidget);
    expect(find.text('Wydatki'), findsOneWidget);

    await tester.tap(find.byTooltip('Zwiń do bilansu'));
    await tester.pumpAndSettle();

    expect(find.text('Bilans netto'), findsNothing);
    expect(find.text('Wpływy'), findsNothing);
    expect(find.textContaining('Pozostało:'), findsOneWidget);

    await tester.tap(find.byTooltip('Pokaż pełne podsumowanie'));
    await tester.pumpAndSettle();

    expect(find.text('Bilans netto'), findsOneWidget);
    expect(find.text('Wpływy'), findsOneWidget);
  });
}
