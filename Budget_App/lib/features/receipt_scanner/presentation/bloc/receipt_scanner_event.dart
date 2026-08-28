import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

import '../../../budget_sheet/domain/models/expense_category_type.dart';

sealed class ReceiptScannerEvent extends Equatable {
  const ReceiptScannerEvent();

  @override
  List<Object?> get props => [];
}

class PickReceiptImage extends ReceiptScannerEvent {
  const PickReceiptImage(this.source);

  final ImageSource source;

  @override
  List<Object?> get props => [source];
}

class ProcessReceipt extends ReceiptScannerEvent {
  const ProcessReceipt(this.imagePath);

  final String imagePath;

  @override
  List<Object?> get props => [imagePath];
}

class ToggleItemSelection extends ReceiptScannerEvent {
  const ToggleItemSelection(this.itemId);

  final String itemId;

  @override
  List<Object?> get props => [itemId];
}

/// Not in the original spec's event list, but required for the "edycja
/// nazwy i kwoty" requirement on the item list — added for symmetry with
/// UpdateItemCategory.
class UpdateItemDetails extends ReceiptScannerEvent {
  const UpdateItemDetails({required this.itemId, this.name, this.price});

  final String itemId;
  final String? name;
  final double? price;

  @override
  List<Object?> get props => [itemId, name, price];
}

class UpdateItemCategory extends ReceiptScannerEvent {
  const UpdateItemCategory({
    required this.itemId,
    required this.category,
    required this.subCategory,
  });

  final String itemId;
  final ExpenseCategoryType category;
  final String subCategory;

  @override
  List<Object?> get props => [itemId, category, subCategory];
}

class ConfirmImportToBudget extends ReceiptScannerEvent {
  const ConfirmImportToBudget(this.targetBudgetId);

  final String targetBudgetId;

  @override
  List<Object?> get props => [targetBudgetId];
}
