import 'package:equatable/equatable.dart';

import 'expense_category_type.dart';

/// A single expense line on the budget sheet.
///
/// [amount] is always in PLN — [BudgetCalculator] and every balance/summary
/// figure operate on it directly. When the expense was originally entered
/// in another currency, [currency]/[originalAmount]/[exchangeRate] record
/// what was actually paid and at what rate, purely for reference/display
/// (e.g. "250,00 EUR (kurs 4.30) = 1 075,00 zł").
class ExpenseEntry extends Equatable {
  const ExpenseEntry({
    required this.id,
    required this.name,
    required this.amount,
    required this.categoryType,
    required this.subCategory,
    required this.date,
    this.comment,
    this.currency = 'PLN',
    this.originalAmount,
    this.exchangeRate,
  });

  final String id;
  final String name;

  /// Always in PLN.
  final double amount;
  final ExpenseCategoryType categoryType;

  /// e.g. "Mieszkanie", "Multimedia", "Telefon/Internet", "Jedzenie".
  final String subCategory;
  final String? comment;
  final DateTime date;

  /// ISO 4217 code the expense was originally entered in — 'PLN' unless a
  /// foreign-currency conversion happened.
  final String currency;

  /// The amount in [currency] before conversion; null when [currency] is
  /// 'PLN' (no conversion took place).
  final double? originalAmount;

  /// The NBP mid rate [originalAmount] was converted to PLN at; null when
  /// [currency] is 'PLN'.
  final double? exchangeRate;

  static const _unset = Object();

  ExpenseEntry copyWith({
    String? name,
    double? amount,
    ExpenseCategoryType? categoryType,
    String? subCategory,
    DateTime? date,
    Object? comment = _unset,
    String? currency,
    Object? originalAmount = _unset,
    Object? exchangeRate = _unset,
  }) {
    return ExpenseEntry(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      categoryType: categoryType ?? this.categoryType,
      subCategory: subCategory ?? this.subCategory,
      date: date ?? this.date,
      comment: identical(comment, _unset) ? this.comment : comment as String?,
      currency: currency ?? this.currency,
      originalAmount:
          identical(originalAmount, _unset) ? this.originalAmount : originalAmount as double?,
      exchangeRate: identical(exchangeRate, _unset) ? this.exchangeRate : exchangeRate as double?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        amount,
        categoryType,
        subCategory,
        comment,
        date,
        currency,
        originalAmount,
        exchangeRate,
      ];
}
