import 'package:equatable/equatable.dart';

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
      ];
}
