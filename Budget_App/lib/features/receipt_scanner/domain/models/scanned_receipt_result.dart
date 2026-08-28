import 'package:equatable/equatable.dart';

import 'receipt_item.dart';

/// The outcome of running OCR over one receipt image.
class ScannedReceiptResult extends Equatable {
  const ScannedReceiptResult({
    required this.id,
    required this.merchantName,
    required this.transactionDate,
    required this.totalAmount,
    required this.items,
    this.imagePath,
  });

  final String id;
  final String merchantName;
  final DateTime transactionDate;
  final double totalAmount;
  final List<ReceiptItem> items;
  final String? imagePath;

  /// Sum of price*quantity across only the checked-off items — what would
  /// actually be imported right now.
  double get selectedTotal => items
      .where((item) => item.isSelected)
      .fold(0.0, (sum, item) => sum + item.price * item.quantity);

  ScannedReceiptResult copyWith({List<ReceiptItem>? items}) {
    return ScannedReceiptResult(
      id: id,
      merchantName: merchantName,
      transactionDate: transactionDate,
      totalAmount: totalAmount,
      items: items ?? this.items,
      imagePath: imagePath,
    );
  }

  @override
  List<Object?> get props =>
      [id, merchantName, transactionDate, totalAmount, items, imagePath];
}
