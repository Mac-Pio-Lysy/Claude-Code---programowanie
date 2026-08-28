import 'package:equatable/equatable.dart';

import '../../../../core/utils/currency_math.dart';

/// Emergency-fund runway health: how many months of fixed costs
/// [BudgetSummary.totalSavingsBalance] would cover.
enum EmergencyRunwayStatus {
  /// 6+ months of fixed costs covered.
  healthy,

  /// 3 to under 6 months covered.
  caution,

  /// Under 3 months covered.
  critical,
}

/// Snapshot of the budget for a period, produced by `BudgetCalculator`.
class BudgetSummary extends Equatable {
  const BudgetSummary({
    required this.totalIncomeNet,
    required this.totalMandatoryExpenses,
    required this.totalUtilityExpenses,
    required this.totalWantsExpenses,
    required this.totalLiabilityPayments,
    required this.totalExpenses,
    required this.remainingBalance,
    required this.allocatedToSavings,
    required this.freeCash,
    required this.totalSavingsBalance,
  });

  final double totalIncomeNet;
  final double totalMandatoryExpenses;
  final double totalUtilityExpenses;
  final double totalWantsExpenses;

  /// Active loan/installment monthly payments — tracked separately from
  /// [totalMandatoryExpenses] so charts can show Raty/Zobowiązania as its
  /// own slice without double-counting.
  final double totalLiabilityPayments;

  /// totalMandatoryExpenses + totalUtilityExpenses + totalWantsExpenses +
  /// totalLiabilityPayments.
  final double totalExpenses;

  /// totalIncomeNet - totalExpenses.
  final double remainingBalance;
  final double allocatedToSavings;

  /// remainingBalance - allocatedToSavings.
  final double freeCash;

  /// Total money currently held across every savings goal and sinking fund
  /// — the pool an emergency-fund runway is measured against. This is a
  /// cumulative balance, unlike [allocatedToSavings] which is only this
  /// period's contribution.
  final double totalSavingsBalance;

  /// Fixed monthly costs an emergency fund would need to cover if income
  /// stopped: required expenses plus active loan/installment payments.
  double get fixedMonthlyCosts => totalMandatoryExpenses + totalLiabilityPayments;

  /// How many months [totalSavingsBalance] would cover [fixedMonthlyCosts]
  /// for. `double.infinity` when there are no fixed costs to cover, since
  /// any amount of savings then lasts forever.
  double get emergencyRunwayMonths {
    if (fixedMonthlyCosts <= 0) return double.infinity;
    return totalSavingsBalance / fixedMonthlyCosts;
  }

  /// [emergencyRunwayMonths] bucketed into a traffic-light status: healthy
  /// (>=6 months), caution (3-6) or critical (<3).
  EmergencyRunwayStatus get emergencyRunwayStatus {
    final months = emergencyRunwayMonths;
    if (months >= 6) return EmergencyRunwayStatus.healthy;
    if (months >= 3) return EmergencyRunwayStatus.caution;
    return EmergencyRunwayStatus.critical;
  }

  /// Share of [totalIncomeNet] spent on required costs + loan payments —
  /// the 50/30/20 rule's "Needs" bucket (target ~50%).
  double get mandatoryPercentage =>
      _percentageOfIncome(totalMandatoryExpenses + totalLiabilityPayments);

  /// Share of [totalIncomeNet] spent on non-essential costs — the "Wants"
  /// bucket (target ~30%).
  double get wantsPercentage => _percentageOfIncome(totalUtilityExpenses + totalWantsExpenses);

  /// Share of [totalIncomeNet] set aside or left over — the "Savings"
  /// bucket (target ~20%).
  double get savingsPercentage => _percentageOfIncome(allocatedToSavings + freeCash);

  /// Whether the current split satisfies the 50/30/20 rule: needs at most
  /// 50% of income, wants at most 30%, and savings at least 20%.
  bool get isRule502030Compliant =>
      mandatoryPercentage <= 50 && wantsPercentage <= 30 && savingsPercentage >= 20;

  double _percentageOfIncome(double amount) {
    if (totalIncomeNet <= 0) return 0.0;
    return roundCurrency(amount / totalIncomeNet * 100);
  }

  @override
  List<Object?> get props => [
        totalIncomeNet,
        totalMandatoryExpenses,
        totalUtilityExpenses,
        totalWantsExpenses,
        totalLiabilityPayments,
        totalExpenses,
        remainingBalance,
        allocatedToSavings,
        freeCash,
        totalSavingsBalance,
      ];
}
