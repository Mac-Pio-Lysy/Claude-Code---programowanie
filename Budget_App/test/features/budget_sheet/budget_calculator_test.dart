import 'package:budget_app/features/budget_sheet/domain/models/budget_summary.dart';
import 'package:budget_app/features/budget_sheet/domain/models/expense_category_type.dart';
import 'package:budget_app/features/budget_sheet/domain/models/expense_entry.dart';
import 'package:budget_app/features/budget_sheet/domain/models/income_entry.dart';
import 'package:budget_app/features/budget_sheet/domain/models/income_type.dart';
import 'package:budget_app/features/budget_sheet/domain/models/installment_liability.dart';
import 'package:budget_app/features/budget_sheet/domain/services/budget_calculator.dart';
import 'package:budget_app/features/savings/domain/models/contribution_interval.dart';
import 'package:budget_app/features/savings/domain/models/savings_goal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = BudgetCalculator();

  group('BudgetCalculator — income summation', () {
    test('sums only netAmount, ignoring grossAmount', () {
      final incomes = [
        const IncomeEntry(
          id: '1',
          title: 'Pensja główna',
          type: IncomeType.uop,
          grossAmount: 9000,
          netAmount: 6500,
        ),
        const IncomeEntry(
          id: '2',
          title: 'Zlecenie',
          type: IncomeType.mandateContract,
          grossAmount: 2000,
          netAmount: 1600,
        ),
      ];

      final summary = calculator.calculateSummary(incomes: incomes, expenses: const []);

      expect(summary.totalIncomeNet, 8100.0);
    });

    test('empty income list yields zero, no crash', () {
      final summary = calculator.calculateSummary(incomes: const [], expenses: const []);
      expect(summary.totalIncomeNet, 0.0);
    });
  });

  group('BudgetCalculator — full balance flow', () {
    ExpenseEntry expense(String id, double amount, ExpenseCategoryType type) {
      return ExpenseEntry(
        id: id,
        name: id,
        amount: amount,
        categoryType: type,
        subCategory: 'Test',
        date: DateTime(2026, 1, 1),
      );
    }

    test('Wpływy -> Wydatki -> Pozostało -> Oszczędności', () {
      final incomes = [
        const IncomeEntry(
          id: 'i1',
          title: 'Pensja',
          type: IncomeType.uop,
          grossAmount: 10000,
          netAmount: 7500,
        ),
      ];

      final expenses = [
        expense('e1', 1800, ExpenseCategoryType.mandatory), // Czynsz
        expense('e2', 950, ExpenseCategoryType.mandatory), // Rata kredytu
        expense('e3', 300, ExpenseCategoryType.utility), // Transport
        expense('e4', 250, ExpenseCategoryType.wants), // Wyjścia
      ];

      final summary = calculator.calculateSummary(
        incomes: incomes,
        expenses: expenses,
        allocatedToSavings: 600,
      );

      expect(summary.totalIncomeNet, 7500.0);
      expect(summary.totalMandatoryExpenses, 2750.0);
      expect(summary.totalUtilityExpenses, 300.0);
      expect(summary.totalWantsExpenses, 250.0);
      expect(summary.totalExpenses, 3300.0);
      expect(summary.remainingBalance, 4200.0); // 7500 - 3300
      expect(summary.allocatedToSavings, 600.0);
      expect(summary.freeCash, 3600.0); // 4200 - 600
    });

    test('a negative allocatedToSavings is clamped to zero, never inflating freeCash', () {
      final summary = calculator.calculateSummary(
        incomes: [
          const IncomeEntry(
            id: 'i1',
            title: 'Pensja',
            type: IncomeType.uop,
            grossAmount: 5000,
            netAmount: 4000,
          ),
        ],
        expenses: [expense('e1', 1000, ExpenseCategoryType.mandatory)],
        allocatedToSavings: -500,
      );

      expect(summary.allocatedToSavings, 0.0);
      expect(summary.freeCash, summary.remainingBalance);
    });

    test('rounds currency to 2 decimal places without floating-point drift', () {
      final incomes = [
        const IncomeEntry(
          id: 'i1',
          title: 'A',
          type: IncomeType.b2b,
          grossAmount: 0,
          netAmount: 100.10,
        ),
        const IncomeEntry(
          id: 'i2',
          title: 'B',
          type: IncomeType.other,
          grossAmount: 0,
          netAmount: 200.20,
        ),
      ];

      final summary = calculator.calculateSummary(incomes: incomes, expenses: const []);

      // Naive double addition of 100.10 + 200.20 is 300.29999999999995.
      expect(summary.totalIncomeNet, 300.30);
    });
  });

  group('BudgetCalculator — liabilities', () {
    test('active installment payments count toward mandatory expenses', () {
      final now = DateTime.now();
      final activeLiability = InstallmentLiability(
        id: 'l1',
        title: 'Rata za laptopa',
        monthlyAmount: 180,
        startDate: DateTime(now.year, now.month - 1, 1),
        endDate: DateTime(now.year, now.month + 5, 1),
      );
      final finishedLiability = InstallmentLiability(
        id: 'l2',
        title: 'Spłacona pożyczka',
        monthlyAmount: 300,
        startDate: DateTime(now.year, now.month - 10, 1),
        endDate: DateTime(now.year, now.month - 2, 1),
      );

      final summary = calculator.calculateSummary(
        incomes: const [
          IncomeEntry(
            id: 'i1',
            title: 'Pensja',
            type: IncomeType.uop,
            grossAmount: 5000,
            netAmount: 4000,
          ),
        ],
        expenses: const [],
        liabilities: [activeLiability, finishedLiability],
      );

      // Only the still-active liability's monthly payment counts; the
      // finished one no longer costs anything each month. Liability
      // payments are tracked separately from totalMandatoryExpenses so
      // charts can show Raty/Zobowiązania as their own slice.
      expect(summary.totalLiabilityPayments, 180.0);
      expect(summary.totalMandatoryExpenses, 0.0);
      expect(summary.totalExpenses, 180.0);
      expect(summary.remainingBalance, 3820.0);
    });
  });

  group('BudgetSummary — emergency runway', () {
    ExpenseEntry expense(String id, double amount, ExpenseCategoryType type) {
      return ExpenseEntry(
        id: id,
        name: id,
        amount: amount,
        categoryType: type,
        subCategory: 'Test',
        date: DateTime(2026, 1, 1),
      );
    }

    const income = IncomeEntry(
      id: 'i1',
      title: 'Pensja',
      type: IncomeType.uop,
      grossAmount: 6000,
      netAmount: 5000,
    );

    test('divides total savings by fixed costs (mandatory + liabilities)', () {
      final now = DateTime.now();
      final summary = calculator.calculateSummary(
        incomes: [income],
        expenses: [expense('e1', 1500, ExpenseCategoryType.mandatory)],
        liabilities: [
          InstallmentLiability(
            id: 'l1',
            title: 'Rata',
            monthlyAmount: 500,
            startDate: DateTime(now.year, now.month - 1, 1),
            endDate: DateTime(now.year, now.month + 5, 1),
          ),
        ],
        totalSavingsBalance: 12000,
      );

      // fixedMonthlyCosts = 1500 + 500 = 2000 -> 12000 / 2000 = 6 months.
      expect(summary.fixedMonthlyCosts, 2000.0);
      expect(summary.emergencyRunwayMonths, 6.0);
      expect(summary.emergencyRunwayStatus, EmergencyRunwayStatus.healthy);
    });

    test('zero fixed costs yields an infinite runway rather than dividing by zero', () {
      final summary = calculator.calculateSummary(
        incomes: [income],
        expenses: const [],
        totalSavingsBalance: 5000,
      );

      expect(summary.fixedMonthlyCosts, 0.0);
      expect(summary.emergencyRunwayMonths, double.infinity);
      expect(summary.emergencyRunwayStatus, EmergencyRunwayStatus.healthy);
    });

    test('a negative totalSavingsBalance is clamped to zero', () {
      final summary = calculator.calculateSummary(
        incomes: [income],
        expenses: [expense('e1', 1000, ExpenseCategoryType.mandatory)],
        totalSavingsBalance: -500,
      );

      expect(summary.totalSavingsBalance, 0.0);
      expect(summary.emergencyRunwayMonths, 0.0);
    });

    test('runway status thresholds: healthy >=6, caution 3-6, critical <3', () {
      BudgetSummary summaryWithSavings(double savings) => calculator.calculateSummary(
            incomes: [income],
            expenses: [expense('e1', 1000, ExpenseCategoryType.mandatory)],
            totalSavingsBalance: savings,
          );

      expect(summaryWithSavings(6000).emergencyRunwayStatus, EmergencyRunwayStatus.healthy);
      expect(summaryWithSavings(3000).emergencyRunwayStatus, EmergencyRunwayStatus.caution);
      expect(summaryWithSavings(5999).emergencyRunwayStatus, EmergencyRunwayStatus.caution);
      expect(summaryWithSavings(2999).emergencyRunwayStatus, EmergencyRunwayStatus.critical);
      expect(summaryWithSavings(0).emergencyRunwayStatus, EmergencyRunwayStatus.critical);
    });
  });

  group('BudgetSummary — 50/30/20 rule', () {
    ExpenseEntry expense(String id, double amount, ExpenseCategoryType type) {
      return ExpenseEntry(
        id: id,
        name: id,
        amount: amount,
        categoryType: type,
        subCategory: 'Test',
        date: DateTime(2026, 1, 1),
      );
    }

    test('splits income into mandatory/wants/savings percentages', () {
      final now = DateTime.now();
      final summary = calculator.calculateSummary(
        incomes: const [
          IncomeEntry(
            id: 'i1',
            title: 'Pensja',
            type: IncomeType.uop,
            grossAmount: 12000,
            netAmount: 10000,
          ),
        ],
        expenses: [
          expense('e1', 4000, ExpenseCategoryType.mandatory), // 40%
          expense('e2', 2000, ExpenseCategoryType.utility), // 20%
          expense('e3', 1000, ExpenseCategoryType.wants), // 10%
        ],
        liabilities: [
          InstallmentLiability(
            id: 'l1',
            title: 'Rata',
            monthlyAmount: 1000, // 10% -> mandatory bucket = 50%
            startDate: DateTime(now.year, now.month - 1, 1),
            endDate: DateTime(now.year, now.month + 5, 1),
          ),
        ],
        allocatedToSavings: 1500,
      );

      expect(summary.mandatoryPercentage, 50.0);
      expect(summary.wantsPercentage, 30.0);
      expect(summary.savingsPercentage, 20.0); // remainingBalance (2000) / 10000
      expect(summary.isRule502030Compliant, isTrue);
    });

    test('flags a split that overspends on wants as non-compliant', () {
      final summary = calculator.calculateSummary(
        incomes: const [
          IncomeEntry(
            id: 'i1',
            title: 'Pensja',
            type: IncomeType.uop,
            grossAmount: 6000,
            netAmount: 5000,
          ),
        ],
        expenses: [
          expense('e1', 1500, ExpenseCategoryType.mandatory), // 30%
          expense('e2', 2500, ExpenseCategoryType.wants), // 50% -> over the 30% target
        ],
      );

      expect(summary.mandatoryPercentage, 30.0);
      expect(summary.wantsPercentage, 50.0);
      expect(summary.isRule502030Compliant, isFalse);
    });

    test('zero income yields zero percentages instead of dividing by zero', () {
      final summary = calculator.calculateSummary(incomes: const [], expenses: const []);

      expect(summary.mandatoryPercentage, 0.0);
      expect(summary.wantsPercentage, 0.0);
      expect(summary.savingsPercentage, 0.0);
    });
  });

  group('InstallmentLiability — remaining months', () {
    test('mid-way through the loan counts the current month plus what remains', () {
      final now = DateTime.now();
      final liability = InstallmentLiability(
        id: 'l1',
        title: 'Kredyt hipoteczny',
        monthlyAmount: 500,
        startDate: DateTime(now.year, now.month - 3, 1),
        endDate: DateTime(now.year, now.month + 2, 1),
      );

      expect(liability.totalMonths, 6); // 3 past + current + 2 future
      expect(liability.remainingMonths, 3); // current + 2 future
      expect(liability.remainingAmountToPay, 1500.0);
    });

    test('a loan that has not started yet has every installment remaining', () {
      final now = DateTime.now();
      final liability = InstallmentLiability(
        id: 'l2',
        title: 'Raty za laptopa',
        monthlyAmount: 200,
        startDate: DateTime(now.year, now.month + 2, 1),
        endDate: DateTime(now.year, now.month + 8, 1),
      );

      expect(liability.remainingMonths, liability.totalMonths);
      expect(liability.remainingAmountToPay, liability.totalMonths * 200.0);
    });

    test('a fully paid-off loan has zero installments remaining', () {
      final now = DateTime.now();
      final liability = InstallmentLiability(
        id: 'l3',
        title: 'Stara pożyczka',
        monthlyAmount: 300,
        startDate: DateTime(now.year, now.month - 10, 1),
        endDate: DateTime(now.year, now.month - 2, 1),
      );

      expect(liability.remainingMonths, 0);
      expect(liability.remainingAmountToPay, 0.0);
    });
  });

  group('SavingsGoal — required contribution pacing', () {
    test('weekly interval divides the remaining amount by whole weeks left', () {
      final now = DateTime.now();
      final goal = SavingsGoal(
        id: 's1',
        title: 'Wakacje',
        targetAmount: 1000,
        currentAmount: 0,
        contributionInterval: ContributionInterval.weekly,
      );

      final required = goal.calculateRequiredContribution(now.add(const Duration(days: 30)));

      expect(required, 250.0); // 30 days ≈ 4 whole weeks -> 1000 / 4
    });

    test('monthly interval divides the remaining amount by whole months left', () {
      final now = DateTime.now();
      final goal = SavingsGoal(
        id: 's2',
        title: 'Wesele',
        targetAmount: 12000,
        currentAmount: 6000,
        contributionInterval: ContributionInterval.monthly,
      );

      final target = DateTime(now.year, now.month + 6, now.day);
      final required = goal.calculateRequiredContribution(target);

      expect(goal.remainingAmount, 6000.0);
      expect(required, 1000.0); // 6000 / 6 months
    });

    test('quarterly interval divides the remaining amount by whole quarters left', () {
      final now = DateTime.now();
      final goal = SavingsGoal(
        id: 's3',
        title: 'Poduszka finansowa',
        targetAmount: 9000,
        currentAmount: 0,
        contributionInterval: ContributionInterval.quarterly,
      );

      final target = DateTime(now.year, now.month + 9, now.day);
      final required = goal.calculateRequiredContribution(target);

      expect(required, 3000.0); // 9000 / 3 quarters
    });

    test('an already-met goal requires no further contribution', () {
      const goal = SavingsGoal(
        id: 's4',
        title: 'Cel osiągnięty',
        targetAmount: 500,
        currentAmount: 800,
        contributionInterval: ContributionInterval.monthly,
      );

      expect(goal.remainingAmount, 0.0);
      expect(
        goal.calculateRequiredContribution(DateTime.now().add(const Duration(days: 30))),
        0.0,
      );
    });

    test('a deadline that has already passed requires the full remaining amount at once', () {
      const goal = SavingsGoal(
        id: 's5',
        title: 'Spóźniony cel',
        targetAmount: 1000,
        currentAmount: 400,
        contributionInterval: ContributionInterval.monthly,
      );

      final pastDate = DateTime.now().subtract(const Duration(days: 5));
      expect(goal.calculateRequiredContribution(pastDate), 600.0);
    });

    test('progressPercentage guards against division by zero and is capped at 1.0', () {
      const zeroTarget = SavingsGoal(
        id: 's6',
        title: 'Zerowy cel',
        targetAmount: 0,
        currentAmount: 0,
        contributionInterval: ContributionInterval.monthly,
      );
      expect(zeroTarget.progressPercentage, 0.0);

      const overfunded = SavingsGoal(
        id: 's7',
        title: 'Przekroczony cel',
        targetAmount: 100,
        currentAmount: 250,
        contributionInterval: ContributionInterval.monthly,
      );
      expect(overfunded.progressPercentage, 1.0);
      expect(overfunded.remainingAmount, 0.0);
    });
  });
}
