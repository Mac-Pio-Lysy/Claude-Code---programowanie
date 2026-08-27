import 'package:equatable/equatable.dart';

/// Net balance for the active budget period: income minus expenses.
class BudgetSummary extends Equatable {
  const BudgetSummary({
    required this.income,
    required this.expenses,
  });

  final double income;
  final double expenses;

  double get remaining => income - expenses;

  @override
  List<Object?> get props => [income, expenses];
}
