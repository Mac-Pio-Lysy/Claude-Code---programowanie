import 'package:budget_app/features/budget_sheet/domain/models/budget_summary.dart';
import 'package:budget_app/features/budget_sheet/presentation/widgets/charts/analytics_panel_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _summary = BudgetSummary(
  totalIncomeNet: 7500,
  totalMandatoryExpenses: 1800,
  totalUtilityExpenses: 300,
  totalWantsExpenses: 250,
  totalLiabilityPayments: 180,
  totalExpenses: 2530,
  remainingBalance: 4970,
  allocatedToSavings: 600,
  freeCash: 4370,
);

void main() {
  testWidgets('arrow header toggles between BudgetPieChart and BudgetComparisonBarChart',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AnalyticsPanelCard(summary: _summary)),
      ),
    );
    await tester.pump();

    expect(find.text('Podsumowanie Budżetu'), findsOneWidget);
    expect(find.byType(PieChart), findsOneWidget);
    expect(find.byType(BarChart), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(PieChart), findsNothing);
    expect(find.byType(BarChart), findsOneWidget);

    // Toggling back returns to the pie chart.
    await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(PieChart), findsOneWidget);
    expect(find.byType(BarChart), findsNothing);
  });

  testWidgets('shows the metadata tiles below the chart', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AnalyticsPanelCard(summary: _summary)),
      ),
    );
    await tester.pump();

    expect(find.text('Wskaźnik oszczędności'), findsOneWidget);
    // "Wolne środki" also labels the pie chart's freeCash legend entry, so
    // it's expected to appear more than once on screen.
    expect(find.text('Wolne środki'), findsWidgets);
    expect(find.text('Status'), findsOneWidget);
  });
}
