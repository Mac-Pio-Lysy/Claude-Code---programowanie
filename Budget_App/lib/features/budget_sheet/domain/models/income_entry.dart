import 'package:equatable/equatable.dart';

import 'income_type.dart';

/// A single source of income. Only [netAmount] feeds the main balance —
/// [grossAmount] is kept for reference/reporting only.
class IncomeEntry extends Equatable {
  const IncomeEntry({
    required this.id,
    required this.title,
    required this.type,
    required this.grossAmount,
    required this.netAmount,
    this.comment,
  });

  final String id;
  final String title;
  final IncomeType type;
  final double grossAmount;
  final double netAmount;
  final String? comment;

  static const _unset = Object();

  IncomeEntry copyWith({
    String? title,
    IncomeType? type,
    double? grossAmount,
    double? netAmount,
    Object? comment = _unset,
  }) {
    return IncomeEntry(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      grossAmount: grossAmount ?? this.grossAmount,
      netAmount: netAmount ?? this.netAmount,
      comment: identical(comment, _unset) ? this.comment : comment as String?,
    );
  }

  @override
  List<Object?> get props => [id, title, type, grossAmount, netAmount, comment];
}
