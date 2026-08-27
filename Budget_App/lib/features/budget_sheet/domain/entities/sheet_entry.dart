import 'package:equatable/equatable.dart';

import 'sheet_section.dart';

/// A single row (cell) of the budget sheet: one income or expense line.
class SheetEntry extends Equatable {
  const SheetEntry({
    required this.id,
    required this.label,
    required this.amount,
    required this.section,
    this.categoryId,
  });

  final String id;
  final String label;
  final double amount;
  final SheetSection section;

  /// Optional link to a [BudgetCategory] id, used to filter the sheet from
  /// the sidebar rail / pill tabs.
  final String? categoryId;

  @override
  List<Object?> get props => [id, label, amount, section, categoryId];
}
