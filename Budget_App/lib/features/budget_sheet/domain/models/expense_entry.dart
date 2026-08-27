import 'package:equatable/equatable.dart';

import 'expense_category_type.dart';

/// A single expense line on the budget sheet.
class ExpenseEntry extends Equatable {
  const ExpenseEntry({
    required this.id,
    required this.name,
    required this.amount,
    required this.categoryType,
    required this.subCategory,
    required this.date,
    this.comment,
  });

  final String id;
  final String name;
  final double amount;
  final ExpenseCategoryType categoryType;

  /// e.g. "Mieszkanie", "Multimedia", "Telefon/Internet", "Jedzenie".
  final String subCategory;
  final String? comment;
  final DateTime date;

  @override
  List<Object?> get props =>
      [id, name, amount, categoryType, subCategory, comment, date];
}
