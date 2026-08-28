import 'package:uuid/uuid.dart';

import '../../../../core/utils/currency_math.dart';
import '../../domain/models/receipt_item.dart';
import '../../domain/models/scanned_receipt_result.dart';
import '../../domain/services/receipt_categorizer.dart';
import '../../domain/services/receipt_scanner_service.dart';

const _uuid = Uuid();

/// Simulates scanning a grocery receipt, for development and tests, until
/// a real OCR backend is wired in. Returns a realistic 5-item basket and
/// runs each item name through [categorizeReceiptItem].
class MockOcrEngine implements ReceiptScannerService {
  const MockOcrEngine();

  static const _mockLineItems = [
    ('Chleb żytni', 4.50),
    ('Mleko 3.2%', 3.20),
    ('Masło extra', 6.99),
    ('Jabłka 1kg', 5.50),
    ('Gazeta codzienna', 3.00),
  ];

  @override
  Future<ScannedReceiptResult> processReceiptImage(String filePathOrBytes) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final items = [
      for (final (name, price) in _mockLineItems)
        _buildItem(name: name, price: price),
    ];

    final total = roundCurrency(
      items.fold(0.0, (sum, item) => sum + item.price * item.quantity),
    );

    return ScannedReceiptResult(
      id: _uuid.v4(),
      merchantName: 'Biedronka',
      transactionDate: DateTime.now(),
      totalAmount: total,
      items: items,
      imagePath: filePathOrBytes,
    );
  }

  ReceiptItem _buildItem({required String name, required double price}) {
    final (category, subCategory) = categorizeReceiptItem(name);
    return ReceiptItem(
      id: _uuid.v4(),
      name: name,
      price: price,
      suggestedCategory: category,
      suggestedSubCategory: subCategory,
    );
  }
}
