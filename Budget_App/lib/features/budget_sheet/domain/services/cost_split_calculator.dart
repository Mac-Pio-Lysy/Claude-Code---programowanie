import 'package:equatable/equatable.dart';

import '../../../../core/utils/currency_math.dart';

/// The outcome of splitting [sharedExpensesTotal] proportionally to each
/// partner's income, plus a 50/50 variant for comparison.
class CostSplitResult extends Equatable {
  const CostSplitResult({
    required this.partnerAIncome,
    required this.partnerBIncome,
    required this.sharedExpensesTotal,
    required this.partnerASharePercent,
    required this.partnerBSharePercent,
    required this.partnerAContribution,
    required this.partnerBContribution,
    required this.equalSplitAmount,
  });

  final double partnerAIncome;
  final double partnerBIncome;
  final double sharedExpensesTotal;

  /// 0-100, proportional to income. Sums to exactly 100 with
  /// [partnerBSharePercent] (B is derived as the complement of A rather
  /// than independently rounded, so the pair never drifts off 100%).
  final double partnerASharePercent;
  final double partnerBSharePercent;

  /// Proportional-to-income contribution toward [sharedExpensesTotal]. B is
  /// derived as the remainder of the total after A's (rounded) share, so
  /// the pair always sums back to exactly [sharedExpensesTotal] — never off
  /// by a rounding cent.
  final double partnerAContribution;
  final double partnerBContribution;

  /// What each partner would pay under a plain 50/50 split, for comparison
  /// against the proportional contributions above.
  final double equalSplitAmount;

  @override
  List<Object?> get props => [
        partnerAIncome,
        partnerBIncome,
        sharedExpensesTotal,
        partnerASharePercent,
        partnerBSharePercent,
        partnerAContribution,
        partnerBContribution,
        equalSplitAmount,
      ];
}

/// Splits a household's shared expenses between two partners in proportion
/// to their income — "sprawiedliwy podział kosztów" for a shared budget,
/// rather than a plain 50/50 that ignores earning gaps.
class CostSplitCalculator {
  const CostSplitCalculator();

  CostSplitResult calculate({
    required double partnerAIncome,
    required double partnerBIncome,
    required double sharedExpensesTotal,
  }) {
    final safeAIncome = partnerAIncome < 0 ? 0.0 : partnerAIncome;
    final safeBIncome = partnerBIncome < 0 ? 0.0 : partnerBIncome;
    final safeTotal = sharedExpensesTotal < 0 ? 0.0 : sharedExpensesTotal;
    final totalIncome = safeAIncome + safeBIncome;

    // No income on either side: fall back to an even 50/50 split rather
    // than dividing by zero.
    final aShare = totalIncome > 0 ? safeAIncome / totalIncome : 0.5;

    final aSharePercent = _roundToOneDecimal(aShare * 100);
    final bSharePercent = _roundToOneDecimal(100 - aSharePercent);

    final aContribution = roundCurrency(safeTotal * aShare);
    final bContribution = roundCurrency(safeTotal - aContribution);

    final equalSplit = roundCurrency(safeTotal / 2);

    return CostSplitResult(
      partnerAIncome: safeAIncome,
      partnerBIncome: safeBIncome,
      sharedExpensesTotal: safeTotal,
      partnerASharePercent: aSharePercent,
      partnerBSharePercent: bSharePercent,
      partnerAContribution: aContribution,
      partnerBContribution: bContribution,
      equalSplitAmount: equalSplit,
    );
  }

  double _roundToOneDecimal(double value) => (value * 10).round() / 10;
}
