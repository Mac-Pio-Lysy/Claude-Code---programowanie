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

  static const _unset = Object();

  ExpenseEntry copyWith({
    String? name,
    double? amount,
    ExpenseCategoryType? categoryType,
    String? subCategory,
    DateTime? date,
    Object? comment = _unset,
  }) {
    return ExpenseEntry(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      categoryType: categoryType ?? this.categoryType,
      subCategory: subCategory ?? this.subCategory,
      date: date ?? this.date,
      comment: identical(comment, _unset) ? this.comment : comment as String?,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, amount, categoryType, subCategory, comment, date];
}
