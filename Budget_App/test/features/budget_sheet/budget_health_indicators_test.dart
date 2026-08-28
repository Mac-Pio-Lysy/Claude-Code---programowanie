import 'package:budget_app/features/budget_sheet/domain/models/budget_summary.dart';
import 'package:budget_app/features/budget_sheet/presentation/widgets/charts/budget_health_indicators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

BudgetSummary _summaryWith({
  required double totalIncomeNet,
  required double totalMandatoryExpenses,
  required double totalLiabilityPayments,
  required double totalUtilityExpenses,
  required double totalWantsExpenses,
  required double allocatedToSavings,
  required double totalSavingsBalance,
}) {
  final totalExpenses =
      totalMandatoryExpenses + totalUtilityExpenses + totalWantsExpenses + totalLiabilityPayments;
  final remainingBalance = totalIncomeNet - totalExpenses;
  return BudgetSummary(
    totalIncomeNet: totalIncomeNet,
    totalMandatoryExpenses: totalMandatoryExpenses,
    totalUtilityExpenses: totalUtilityExpenses,
    totalWantsExpenses: totalWantsExpenses,
    totalLiabilityPayments: totalLiabilityPayments,
    totalExpenses: totalExpenses,
    remainingBalance: remainingBalance,
    allocatedToSavings: allocatedToSavings,
    freeCash: remainingBalance - allocatedToSavings,
    totalSavingsBalance: totalSavingsBalance,
  );
}

void main() {
  Future<void> pump(WidgetTester tester, BudgetSummary summary) {
    return tester.pumpWidget(
      MaterialApp(home: Scaffold(body: BudgetHealthIndicators(summary: summary))),
    );
  }

  testWidgets('shows the runway in months and the 50/30/20 legend', (tester) async {
    final summary = _summaryWith(
      totalIncomeNet: 10000,
      totalMandatoryExpenses: 4000,
      totalLiabilityPayments: 1000,
      totalUtilityExpenses: 2000,
      totalWantsExpenses: 1000,
      allocatedToSavings: 1500,
      totalSavingsBalance: 10000, // 10000 / (4000+1000) = 2 months
    );

    await pump(tester, summary);

    expect(find.textContaining('Poduszka: 2.0 mies.'), findsOneWidget);
    expect(find.textContaining('Potrzeby 50%'), findsOneWidget);
    expect(find.textContaining('Zachcianki 30%'), findsOneWidget);
    expect(find.textContaining('Oszczędności 20%'), findsOneWidget);
  });

  testWidgets('shows an infinite runway when there are no fixed costs', (tester) async {
    final summary = _summaryWith(
      totalIncomeNet: 5000,
      totalMandatoryExpenses: 0,
      totalLiabilityPayments: 0,
      totalUtilityExpenses: 500,
      totalWantsExpenses: 500,
      allocatedToSavings: 0,
      totalSavingsBalance: 2000,
    );

    await pump(tester, summary);

    expect(find.textContaining('Poduszka: ∞ mies.'), findsOneWidget);
  });
}
