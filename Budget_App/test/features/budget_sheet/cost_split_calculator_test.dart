import 'package:budget_app/features/budget_sheet/domain/services/cost_split_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = CostSplitCalculator();

  group('CostSplitCalculator — proportional split', () {
    test('splits 6000 zł between 8000/5000 incomes matching the spec example', () {
      final result = calculator.calculate(
        partnerAIncome: 8000,
        partnerBIncome: 5000,
        sharedExpensesTotal: 6000,
      );

      expect(result.partnerASharePercent, 61.5);
      expect(result.partnerBSharePercent, 38.5);
      expect(result.partnerAContribution, 3692.31);
      expect(result.partnerBContribution, 2307.69);
      expect(result.equalSplitAmount, 3000.0);
    });

    test('contributions always sum back to exactly sharedExpensesTotal', () {
      final result = calculator.calculate(
        partnerAIncome: 7333.33,
        partnerBIncome: 2222.22,
        sharedExpensesTotal: 4999.99,
      );

      expect(result.partnerAContribution + result.partnerBContribution, 4999.99);
    });

    test('percentages always sum back to exactly 100', () {
      final result = calculator.calculate(
        partnerAIncome: 3333,
        partnerBIncome: 6667,
        sharedExpensesTotal: 1000,
      );

      expect(result.partnerASharePercent + result.partnerBSharePercent, 100.0);
    });

    test('equal incomes yield an exact 50/50 proportional split too', () {
      final result = calculator.calculate(
        partnerAIncome: 5000,
        partnerBIncome: 5000,
        sharedExpensesTotal: 2000,
      );

      expect(result.partnerASharePercent, 50.0);
      expect(result.partnerBSharePercent, 50.0);
      expect(result.partnerAContribution, 1000.0);
      expect(result.partnerBContribution, 1000.0);
    });
  });

  group('CostSplitCalculator — edge cases', () {
    test('zero income on both sides falls back to 50/50 instead of dividing by zero', () {
      final result = calculator.calculate(
        partnerAIncome: 0,
        partnerBIncome: 0,
        sharedExpensesTotal: 4000,
      );

      expect(result.partnerASharePercent, 50.0);
      expect(result.partnerBSharePercent, 50.0);
      expect(result.partnerAContribution, 2000.0);
      expect(result.partnerBContribution, 2000.0);
      expect(result.equalSplitAmount, 2000.0);
    });

    test('zero shared expenses yields zero contributions without error', () {
      final result = calculator.calculate(
        partnerAIncome: 8000,
        partnerBIncome: 5000,
        sharedExpensesTotal: 0,
      );

      expect(result.partnerAContribution, 0.0);
      expect(result.partnerBContribution, 0.0);
      expect(result.equalSplitAmount, 0.0);
      // Income-derived percentages are unaffected by there being no cost to split.
      expect(result.partnerASharePercent, 61.5);
    });

    test('negative income is clamped to zero rather than distorting the split', () {
      final result = calculator.calculate(
        partnerAIncome: -1000,
        partnerBIncome: 5000,
        sharedExpensesTotal: 1000,
      );

      expect(result.partnerAIncome, 0.0);
      expect(result.partnerASharePercent, 0.0);
      expect(result.partnerBSharePercent, 100.0);
      expect(result.partnerAContribution, 0.0);
      expect(result.partnerBContribution, 1000.0);
    });

    test('one partner earning everything pays the whole shared total', () {
      final result = calculator.calculate(
        partnerAIncome: 10000,
        partnerBIncome: 0,
        sharedExpensesTotal: 3000,
      );

      expect(result.partnerASharePercent, 100.0);
      expect(result.partnerBSharePercent, 0.0);
      expect(result.partnerAContribution, 3000.0);
      expect(result.partnerBContribution, 0.0);
    });
  });
}
