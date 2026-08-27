import 'package:equatable/equatable.dart';

/// Snapshot of the budget for a period, produced by `BudgetCalculator`.
class BudgetSummary extends Equatable {
  const BudgetSummary({
    required this.totalIncomeNet,
    required this.totalMandatoryExpenses,
    required this.totalUtilityExpenses,
    required this.totalWantsExpenses,
    required this.totalExpenses,
    required this.remainingBalance,
    required this.allocatedToSavings,
    required this.freeCash,
  });

  final double totalIncomeNet;
  final double totalMandatoryExpenses;
  final double totalUtilityExpenses;
  final double totalWantsExpenses;
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
        totalExpenses,
        remainingBalance,
        allocatedToSavings,
        freeCash,
      ];
}
