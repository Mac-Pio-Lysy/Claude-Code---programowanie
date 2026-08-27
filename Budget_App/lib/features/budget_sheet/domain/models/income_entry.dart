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

  @override
  List<Object?> get props => [id, title, type, grossAmount, netAmount, comment];
}
