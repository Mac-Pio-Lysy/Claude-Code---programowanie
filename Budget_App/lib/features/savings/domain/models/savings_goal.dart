import 'package:equatable/equatable.dart';

import '../../../../core/utils/currency_math.dart';
import 'contribution_interval.dart';

/// A savings target (e.g. "Wakacje", "Wesele", "Poduszka finansowa") with an
/// optional deadline and a preferred contribution cadence.
class SavingsGoal extends Equatable {
  const SavingsGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.contributionInterval,
    this.targetDate,
  });

  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final ContributionInterval contributionInterval;

  /// Never negative, even if the goal has been overfunded.
  double get remainingAmount {
    final remaining = targetAmount - currentAmount;
    return remaining <= 0 ? 0.0 : roundCurrency(remaining);
  }

  /// 0.0 to 1.0. A non-positive [targetAmount] safely yields 0.0 instead of
  /// dividing by zero.
  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    final ratio = currentAmount / targetAmount;
    if (ratio.isNaN || !ratio.isFinite) return 0.0;
    return ratio.clamp(0.0, 1.0);
  }

  /// How much to set aside per [contributionInterval] to close
  /// [remainingAmount] by [targetDate].
  ///
  /// A goal that's already met returns 0.0. A [targetDate] that has already
  /// passed (or is now) returns the full [remainingAmount] as a single
  /// required contribution, rather than dividing by zero periods.
  double calculateRequiredContribution(DateTime targetDate) {
    final remaining = remainingAmount;
    if (remaining <= 0) return 0.0;

    final periods = _periodsUntil(targetDate);
    if (periods <= 0) return remaining;

    return roundCurrency(remaining / periods);
  }

  int _periodsUntil(DateTime targetDate) {
    final now = DateTime.now();
    if (!targetDate.isAfter(now)) return 0;

    switch (contributionInterval) {
      case ContributionInterval.weekly:
        return _periodsFromDays(now, targetDate, 7);
      case ContributionInterval.biWeekly:
        return _periodsFromDays(now, targetDate, 14);
      case ContributionInterval.monthly:
        return _periodsFromMonths(now, targetDate, 1);
      case ContributionInterval.quarterly:
        return _periodsFromMonths(now, targetDate, 3);
    }
  }

  static int _periodsFromDays(DateTime now, DateTime targetDate, int daysPerPeriod) {
    final totalDays = targetDate.difference(now).inDays;
    final periods = totalDays ~/ daysPerPeriod;
    return periods < 1 ? 1 : periods;
  }

  static int _periodsFromMonths(DateTime now, DateTime targetDate, int monthsPerPeriod) {
    final totalMonths = (targetDate.year - now.year) * 12 + (targetDate.month - now.month);
    final periods = totalMonths ~/ monthsPerPeriod;
    return periods < 1 ? 1 : periods;
  }

  static const _unset = Object();

  SavingsGoal copyWith({
    String? title,
    double? targetAmount,
    double? currentAmount,
    ContributionInterval? contributionInterval,
    Object? targetDate = _unset,
  }) {
    return SavingsGoal(
      id: id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      contributionInterval: contributionInterval ?? this.contributionInterval,
      targetDate: identical(targetDate, _unset) ? this.targetDate : targetDate as DateTime?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        targetAmount,
        currentAmount,
        targetDate,
        contributionInterval,
      ];
}
