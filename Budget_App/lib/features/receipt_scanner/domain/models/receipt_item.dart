import 'package:equatable/equatable.dart';

import '../../../budget_sheet/domain/models/expense_category_type.dart';

/// One line item recognized on a scanned receipt, pending the user's
/// review before import into the budget sheet.
class ReceiptItem extends Equatable {
  const ReceiptItem({
    required this.id,
    required this.name,
    required this.price,
    required this.suggestedCategory,
    required this.suggestedSubCategory,
    this.quantity = 1.0,
    this.isSelected = true,
  });

  final String id;
  final String name;
  final double price;
  final double quantity;
  final ExpenseCategoryType suggestedCategory;

  /// e.g. "Jedzenie", "Transport", "Dom".
  final String suggestedSubCategory;

  /// Whether the user has approved this line for import.
  final bool isSelected;

  ReceiptItem copyWith({
    String? name,
    double? price,
    double? quantity,
    ExpenseCategoryType? suggestedCategory,
    String? suggestedSubCategory,
    bool? isSelected,
  }) {
    return ReceiptItem(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      suggestedCategory: suggestedCategory ?? this.suggestedCategory,
      suggestedSubCategory: suggestedSubCategory ?? this.suggestedSubCategory,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, price, quantity, suggestedCategory, suggestedSubCategory, isSelected];
}
