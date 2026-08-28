import 'dart:convert';

import 'package:budget_app/features/bank_import/domain/models/bank_profile.dart';
import 'package:budget_app/features/bank_import/domain/models/bank_transaction.dart';
import 'package:budget_app/features/bank_import/domain/services/bank_csv_parser_service.dart';
import 'package:budget_app/features/budget_sheet/domain/models/expense_category_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// Encodes [text] as Windows-1250, for the three profiles that export in
/// that encoding. Only covers the handful of Polish characters these test
/// fixtures actually use (cross-checked against Python's stdlib `cp1250`
/// codec) — not a general-purpose encoder.
List<int> _encodeCp1250(String text) {
  const overrides = {'ż': 0xBF, 'Ż': 0xAF, 'ń': 0xF1};
  return text.runes.map((rune) {
    final char = String.fromCharCode(rune);
    return overrides[char] ?? rune;
  }).toList();
}

List<int> _utf8(String text) => utf8.encode(text);

void main() {
  const parser = BankCsvParserService();

  group('BankCsvParserService — PKO BP / Inteligo (";", Windows-1250)', () {
    final bytes = _encodeCp1250(
      'Data operacji;Data waluty;Opis operacji;Kontrahent;Kwota;Waluta\n'
      '05.01.2026;05.01.2026;Wynagrodzenie;Pracodawca Sp. z o.o.;5500,00;PLN\n'
      '06.01.2026;06.01.2026;Zakupy spożywcze;Biedronka;-123,45;PLN\n'
      '07.01.2026;07.01.2026;Tankowanie;Orlen;-200,00;PLN',
    );

    test('parses income and expenses with correct dates, amounts and categories', () {
      final transactions = parser.parse(fileBytes: bytes, profile: BankProfile.pkoBp);

      expect(transactions, hasLength(3));

      final salary = transactions[0];
      expect(salary.bookingDate, DateTime(2026, 1, 5));
      expect(salary.amount, 5500.0);
      expect(salary.matchedType, BankTransactionType.income);
      expect(salary.suggestedSubCategory, 'Wynagrodzenie');

      final groceries = transactions[1];
      expect(groceries.counterparty, 'Biedronka');
      expect(groceries.amount, -123.45);
      expect(groceries.matchedType, BankTransactionType.expense);
      expect(groceries.suggestedCategory, ExpenseCategoryType.mandatory);
      expect(groceries.suggestedSubCategory, 'Zakupy spożywcze');

      final fuel = transactions[2];
      expect(fuel.amount, -200.0);
      expect(fuel.suggestedCategory, ExpenseCategoryType.utility);
      expect(fuel.suggestedSubCategory, 'Paliwo');
    });

    test('skips a trailing summary row instead of failing the whole file', () {
      final withFooter = _encodeCp1250(
        'Data operacji;Data waluty;Opis operacji;Kontrahent;Kwota;Waluta\n'
        '05.01.2026;05.01.2026;Wynagrodzenie;Pracodawca Sp. z o.o.;5500,00;PLN\n'
        'Saldo końcowe: 5500,00 PLN',
      );

      final transactions = parser.parse(fileBytes: withFooter, profile: BankProfile.pkoBp);
      expect(transactions, hasLength(1));
    });
  });

  group('BankCsvParserService — mBank (";", Windows-1250, preamble before header)', () {
    final bytes = _encodeCp1250(
      '#Klient;Jan Kowalski\n'
      '#Za okres;2026-01-01 - 2026-01-31\n'
      '#Data operacji;#Opis operacji;#Kontrahent;#Kategoria;#Kwota\n'
      '2026-01-05;Wynagrodzenie;Pracodawca Sp. z o.o.;Wynagrodzenia;5500,00 PLN\n'
      '2026-01-06;Zakupy spożywcze;Lidl;Zakupy;-89,90 PLN',
    );

    test('locates the real header past the metadata preamble', () {
      final transactions = parser.parse(fileBytes: bytes, profile: BankProfile.mBank);

      expect(transactions, hasLength(2));
      expect(transactions[0].bookingDate, DateTime(2026, 1, 5));
      expect(transactions[0].amount, 5500.0);
      expect(transactions[0].matchedType, BankTransactionType.income);

      final groceries = transactions[1];
      expect(groceries.rawCategory, 'Zakupy');
      expect(groceries.amount, -89.90);
      expect(groceries.suggestedCategory, ExpenseCategoryType.mandatory);
    });

    test('throws when the "#Data operacji" header is missing entirely', () {
      final bytesWithoutHeader = _encodeCp1250('#Klient;Jan Kowalski\nnie ma tu tabeli');

      expect(
        () => parser.parse(fileBytes: bytesWithoutHeader, profile: BankProfile.mBank),
        throwsA(isA<BankCsvParseException>()),
      );
    });
  });

  group('BankCsvParserService — Santander Bank Polska (";", UTF-8)', () {
    test('parses using yyyy-MM-dd dates and the Tytuł/Odbiorca column order', () {
      final bytes = _utf8(
        'Data księgowania;Tytuł;Odbiorca/Nadawca;Kwota;Waluta\n'
        '2026-01-05;Wynagrodzenie;Pracodawca Sp. z o.o.;5500,00;PLN\n'
        '2026-01-06;Rachunek za prąd;Tauron;-180,00;PLN',
      );

      final transactions = parser.parse(fileBytes: bytes, profile: BankProfile.santander);

      expect(transactions, hasLength(2));
      expect(transactions[0].bookingDate, DateTime(2026, 1, 5));
      final bill = transactions[1];
      expect(bill.amount, -180.0);
      expect(bill.suggestedCategory, ExpenseCategoryType.mandatory);
      expect(bill.suggestedSubCategory, 'Rachunki');
    });
  });

  group('BankCsvParserService — ING Bank Śląski (";", UTF-8, dd-MM-yyyy)', () {
    test('parses using dash dates and the kontrahent/tytuł column order', () {
      final bytes = _utf8(
        'Data transakcji;Dane kontrahenta;Tytuł;Kwota;Waluta\n'
        '05-01-2026;Pracodawca Sp. z o.o.;Wynagrodzenie;5500,00;PLN\n'
        '06-01-2026;Netflix;Subskrypcja Netflix;-55,00;PLN',
      );

      final transactions = parser.parse(fileBytes: bytes, profile: BankProfile.ing);

      expect(transactions, hasLength(2));
      expect(transactions[0].bookingDate, DateTime(2026, 1, 5));
      final subscription = transactions[1];
      expect(subscription.amount, -55.0);
      expect(subscription.suggestedCategory, ExpenseCategoryType.wants);
      expect(subscription.suggestedSubCategory, 'Rozrywka');
    });
  });

  group('BankCsvParserService — Bank Millennium (";", Windows-1250)', () {
    test('parses the 4-column layout without a currency column', () {
      final bytes = _encodeCp1250(
        'Data operacji;Opis operacji;Kontrahent;Kwota\n'
        '05.01.2026;Wynagrodzenie;Pracodawca Sp. z o.o.;5500,00\n'
        '06.01.2026;Zakupy spożywcze;Żabka;-45,60',
      );

      final transactions = parser.parse(fileBytes: bytes, profile: BankProfile.millennium);

      expect(transactions, hasLength(2));
      final groceries = transactions[1];
      expect(groceries.counterparty, 'Żabka');
      expect(groceries.amount, -45.60);
      expect(groceries.suggestedCategory, ExpenseCategoryType.mandatory);
    });
  });

  group('BankCsvParserService — Revolut (",", UTF-8, English headers, dot-decimal)', () {
    test('parses Started Date/Description/Amount columns', () {
      final bytes = _utf8(
        'Type,Product,Started Date,Completed Date,Description,Amount,Fee,Currency,State,Balance\n'
        'TOPUP,Current,2026-01-05 10:00:00,2026-01-05 10:00:05,Wynagrodzenie,5500.00,0.00,PLN,COMPLETED,5500.00\n'
        'CARD_PAYMENT,Current,2026-01-06 12:30:00,2026-01-06 12:30:01,Netflix,-55.00,0.00,PLN,COMPLETED,5445.00',
      );

      final transactions = parser.parse(fileBytes: bytes, profile: BankProfile.revolut);

      expect(transactions, hasLength(2));
      expect(transactions[0].bookingDate, DateTime(2026, 1, 5));
      expect(transactions[0].amount, 5500.0);
      expect(transactions[0].matchedType, BankTransactionType.income);

      final netflix = transactions[1];
      expect(netflix.amount, -55.0);
      expect(netflix.suggestedCategory, ExpenseCategoryType.wants);
    });
  });

  group('BankCsvParserService — uniwersalny szablon (auto-detected delimiter/headers)', () {
    test('auto-detects a comma-delimited file with Data/Tytuł/Kwota headers', () {
      final bytes = _utf8(
        'Data,Tytuł,Kwota\n'
        '2026-01-05,Wynagrodzenie,5500.00\n'
        '2026-01-06,Zakupy Biedronka,-123.45',
      );

      final transactions = parser.parse(fileBytes: bytes, profile: BankProfile.universal);

      expect(transactions, hasLength(2));
      expect(transactions[0].matchedType, BankTransactionType.income);
      expect(transactions[1].amount, -123.45);
      expect(transactions[1].suggestedCategory, ExpenseCategoryType.mandatory);
    });

    test('auto-detects a semicolon-delimited file with a Kontrahent column and Polish decimals', () {
      final bytes = _utf8('Data;Kontrahent;Tytuł;Kwota\n05.01.2026;Orlen;Tankowanie;-200,00');

      final transactions = parser.parse(fileBytes: bytes, profile: BankProfile.universal);

      expect(transactions, hasLength(1));
      final transaction = transactions.single;
      expect(transaction.bookingDate, DateTime(2026, 1, 5));
      expect(transaction.amount, -200.0);
      expect(transaction.counterparty, 'Orlen');
      expect(transaction.suggestedSubCategory, 'Paliwo');
    });

    test('throws when no recognizable Data/Kwota/Tytuł headers are found', () {
      final bytes = _utf8('Foo,Bar,Baz\n1,2,3');

      expect(
        () => parser.parse(fileBytes: bytes, profile: BankProfile.universal),
        throwsA(isA<BankCsvParseException>()),
      );
    });
  });

  group('BankCsvParserService — general errors', () {
    test('throws on a completely empty file', () {
      expect(
        () => parser.parse(fileBytes: const [], profile: BankProfile.pkoBp),
        throwsA(isA<BankCsvParseException>()),
      );
    });
  });
}
