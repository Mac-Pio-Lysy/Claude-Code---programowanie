import 'package:equatable/equatable.dart';

import 'income_type.dart';

/// A single source of income. Only [netAmount] feeds the main balance —
/// [grossAmount] is kept for reference/reporting only.
///
/// Both amounts are always in PLN. When the income was originally received
/// in another currency, [currency]/[originalAmount]/[exchangeRate] record
/// what was actually received and at what rate, purely for reference.
class IncomeEntry extends Equatable {
  const IncomeEntry({
    required this.id,
    required this.title,
    required this.type,
    required this.grossAmount,
    required this.netAmount,
    this.comment,
    this.currency = 'PLN',
    this.originalAmount,
    this.exchangeRate,
  });

  final String id;
  final String title;
  final IncomeType type;

  /// Always in PLN.
  final double grossAmount;

  /// Always in PLN.
  final double netAmount;
  final String? comment;

  /// ISO 4217 code the income was originally entered in — 'PLN' unless a
  /// foreign-currency conversion happened.
  final String currency;

  /// The (net) amount in [currency] before conversion; null when
  /// [currency] is 'PLN' (no conversion took place).
  final double? originalAmount;

  /// The NBP mid rate [originalAmount] was converted to PLN at; null when
  /// [currency] is 'PLN'.
  final double? exchangeRate;

  static const _unset = Object();

  IncomeEntry copyWith({
    String? title,
    IncomeType? type,
    double? grossAmount,
    double? netAmount,
    Object? comment = _unset,
    String? currency,
    Object? originalAmount = _unset,
    Object? exchangeRate = _unset,
  }) {
    return IncomeEntry(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      grossAmount: grossAmount ?? this.grossAmount,
      netAmount: netAmount ?? this.netAmount,
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
        title,
        type,
        grossAmount,
        netAmount,
        comment,
        currency,
        originalAmount,
        exchangeRate,
      ];
}
