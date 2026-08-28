import 'package:budget_app/features/budget_sheet/domain/models/expense_category_type.dart';
import 'package:budget_app/features/receipt_scanner/data/services/mock_ocr_engine.dart';
import 'package:budget_app/features/receipt_scanner/domain/services/receipt_categorizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('categorizeReceiptItem', () {
    test('food keywords map to mandatory/Jedzenie', () {
      expect(categorizeReceiptItem('Chleb żytni'), (ExpenseCategoryType.mandatory, 'Jedzenie'));
      expect(categorizeReceiptItem('Mleko 3.2%'), (ExpenseCategoryType.mandatory, 'Jedzenie'));
    });

    test('entertainment keywords map to wants/Rozrywka', () {
      expect(categorizeReceiptItem('Gra planszowa'), (ExpenseCategoryType.wants, 'Rozrywka'));
      expect(categorizeReceiptItem('Karnet Netflix'), (ExpenseCategoryType.wants, 'Rozrywka'));
    });

    test('"bilet" is checked before "kino": a cinema ticket lands under Transport', () {
      // Documented, acceptable ambiguity for a keyword-based mock heuristic —
      // transport keywords are matched with higher precedence.
      expect(categorizeReceiptItem('Bilet do kina'), (ExpenseCategoryType.utility, 'Transport'));
    });

    test('transport keywords map to utility/Transport', () {
      expect(categorizeReceiptItem('Paliwo 95'), (ExpenseCategoryType.utility, 'Transport'));
      expect(categorizeReceiptItem('Bilet MPK'), (ExpenseCategoryType.utility, 'Transport'));
    });

    test('unmatched items fall back to wants/Inne', () {
      expect(categorizeReceiptItem('Gazeta codzienna'), (ExpenseCategoryType.wants, 'Inne'));
    });
  });

  group('MockOcrEngine', () {
    test('returns a realistic 5-item Biedronka receipt with a matching total', () async {
      const engine = MockOcrEngine();
      final result = await engine.processReceiptImage('mock/path.jpg');

      expect(result.merchantName, 'Biedronka');
      expect(result.items, hasLength(5));
      expect(result.items.map((i) => i.name), contains('Chleb żytni'));
      expect(result.totalAmount, closeTo(23.19, 0.001));
      expect(result.imagePath, 'mock/path.jpg');
    });

    test('every returned item defaults to selected', () async {
      const engine = MockOcrEngine();
      final result = await engine.processReceiptImage('mock/path.jpg');

      expect(result.items.every((item) => item.isSelected), isTrue);
    });
  });
}
