import 'package:budget_app/features/bank_import/domain/models/bank_transaction.dart';
import 'package:budget_app/features/bank_import/domain/services/bank_transaction_categorizer.dart';
import 'package:budget_app/features/budget_sheet/domain/models/expense_category_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('categorizeBankTransaction', () {
    test('a positive amount is always income, regardless of title', () {
      final (type, category, subCategory) = categorizeBankTransaction(
        title: 'Zwrot za zakupy',
        counterparty: 'Sklep',
        amount: 50,
      );

      expect(type, BankTransactionType.income);
      expect(category, isNull);
      expect(subCategory, 'Inny wpływ');
    });

    test('payroll keywords in title/counterparty are labeled Wynagrodzenie', () {
      final (type, category, subCategory) = categorizeBankTransaction(
        title: 'Wynagrodzenie za styczeń',
        counterparty: 'Pracodawca Sp. z o.o.',
        amount: 5500,
      );

      expect(type, BankTransactionType.income);
      expect(category, isNull);
      expect(subCategory, 'Wynagrodzenie');
    });

    test('grocery keywords map to mandatory/Zakupy spożywcze', () {
      final (type, category, subCategory) = categorizeBankTransaction(
        title: 'Zakupy',
        counterparty: 'Biedronka',
        amount: -50,
      );

      expect(type, BankTransactionType.expense);
      expect(category, ExpenseCategoryType.mandatory);
      expect(subCategory, 'Zakupy spożywcze');
    });

    test('fuel keywords map to utility/Paliwo', () {
      final (type, category, subCategory) = categorizeBankTransaction(
        title: 'Tankowanie',
        counterparty: 'Orlen',
        amount: -200,
      );

      expect(type, BankTransactionType.expense);
      expect(category, ExpenseCategoryType.utility);
      expect(subCategory, 'Paliwo');
    });

    test('bill keywords map to mandatory/Rachunki', () {
      final (type, category, subCategory) = categorizeBankTransaction(
        title: 'Opłata za prąd',
        counterparty: 'Tauron',
        amount: -180,
      );

      expect(type, BankTransactionType.expense);
      expect(category, ExpenseCategoryType.mandatory);
      expect(subCategory, 'Rachunki');
    });

    test('entertainment keywords map to wants/Rozrywka', () {
      final (type, category, subCategory) = categorizeBankTransaction(
        title: 'Subskrypcja',
        counterparty: 'Netflix',
        amount: -55,
      );

      expect(type, BankTransactionType.expense);
      expect(category, ExpenseCategoryType.wants);
      expect(subCategory, 'Rozrywka');
    });

    test('unmatched expenses fall back to wants/Inne', () {
      final (type, category, subCategory) = categorizeBankTransaction(
        title: 'Przelew własny',
        counterparty: 'Jan Kowalski',
        amount: -100,
      );

      expect(type, BankTransactionType.expense);
      expect(category, ExpenseCategoryType.wants);
      expect(subCategory, 'Inne');
    });
  });
}
