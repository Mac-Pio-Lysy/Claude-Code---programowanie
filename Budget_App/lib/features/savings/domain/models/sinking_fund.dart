import 'package:equatable/equatable.dart';

import '../../../../core/utils/currency_math.dart';

/// A pot set aside for a known, irregular future expense (car/home
/// insurance, property tax, Christmas, a planned repair) — as opposed to
/// [SavingsGoal], which is an open-ended target. Unlike a goal, a sinking
/// fund always has a fixed [targetDate] (the bill's due date), which is
/// what [monthlyProvision] paces against.
class SinkingFund extends Equatable {
  const SinkingFund({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.targetDate,
    required this.currentAccumulated,
  });

  final String id;
  final String title;
  final double targetAmount;
  final DateTime targetDate;
  final double currentAccumulated;

  /// Never negative, even if the fund has been overfunded.
  double get remainingAmount {
    final remaining = targetAmount - currentAccumulated;
    return remaining <= 0 ? 0.0 : roundCurrency(remaining);
  }

  /// How much to set aside each month to reach [targetAmount] by
  /// [targetDate]. A due date that has already passed (or is today)
  /// requires the full [remainingAmount] right away, rather than dividing
  /// by zero months.
  double get monthlyProvision {
    final remaining = remainingAmount;
    if (remaining <= 0) return 0.0;

    final now = DateTime.now();
    final totalMonths = (targetDate.year - now.year) * 12 + (targetDate.month - now.month);
    if (totalMonths <= 0) return remaining;

    return roundCurrency(remaining / totalMonths);
  }

  SinkingFund copyWith({
    String? title,
    double? targetAmount,
    DateTime? targetDate,
    double? currentAccumulated,
  }) {
    return SinkingFund(
      id: id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      targetDate: targetDate ?? this.targetDate,
      currentAccumulated: currentAccumulated ?? this.currentAccumulated,
    );
  }

  @override
  List<Object?> get props => [id, title, targetAmount, targetDate, currentAccumulated];
}
