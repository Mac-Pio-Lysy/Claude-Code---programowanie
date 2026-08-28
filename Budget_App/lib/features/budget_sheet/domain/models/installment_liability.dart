import 'package:equatable/equatable.dart';

import '../../../../core/utils/currency_math.dart';

/// A recurring loan/installment liability (e.g. mortgage, laptop
/// installment plan), paid monthly from [startDate] to [endDate] inclusive.
class InstallmentLiability extends Equatable {
  const InstallmentLiability({
    required this.id,
    required this.title,
    required this.monthlyAmount,
    required this.startDate,
    required this.endDate,
  });

  final String id;
  final String title;
  final double monthlyAmount;
  final DateTime startDate;
  final DateTime endDate;

  /// Whole calendar months from [startDate] to [endDate], inclusive of both.
  int get totalMonths => _monthsBetween(startDate, endDate) + 1;

  /// Installments left to pay, counted from the current calendar month.
  ///
  /// If today is before [startDate], every installment is still remaining.
  /// If today is after [endDate], none are.
  int get remainingMonths {
    final now = DateTime.now();
    final reference = now.isBefore(startDate) ? startDate : now;
    final months = _monthsBetween(reference, endDate) + 1;
    return months.clamp(0, totalMonths);
  }

  double get remainingAmountToPay =>
      roundCurrency(remainingMonths * monthlyAmount);

  static int _monthsBetween(DateTime from, DateTime to) =>
      (to.year - from.year) * 12 + (to.month - from.month);

  InstallmentLiability copyWith({
    String? title,
    double? monthlyAmount,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return InstallmentLiability(
      id: id,
      title: title ?? this.title,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  List<Object?> get props => [id, title, monthlyAmount, startDate, endDate];
}
