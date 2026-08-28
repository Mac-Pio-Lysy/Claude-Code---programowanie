import 'package:budget_app/features/budget_sheet/domain/models/expense_category_type.dart';
import 'package:budget_app/features/command_palette/domain/models/parsed_command.dart';
import 'package:budget_app/features/command_palette/domain/services/command_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseCommand — navigation keywords', () {
    test('"arkusz" navigates to the budget sheet', () {
      expect(parseCommand('arkusz'), const NavigateCommand(PaletteDestination.budgetSheet));
    });

    test('"oszczednosci" (and the diacritic form) navigates to savings', () {
      expect(parseCommand('oszczednosci'), const NavigateCommand(PaletteDestination.savings));
      expect(parseCommand('oszczędności'), const NavigateCommand(PaletteDestination.savings));
    });

    test('"skaner" navigates to the OCR scanner', () {
      expect(parseCommand('skaner'), const NavigateCommand(PaletteDestination.ocrScanner));
    });

    test('"import" navigates to the bank CSV import', () {
      expect(parseCommand('import'), const NavigateCommand(PaletteDestination.bankImport));
    });

    test('"podzial" (and the diacritic form) opens the fair-share dialog', () {
      expect(parseCommand('podzial'), const OpenFairShareDialogCommand());
      expect(parseCommand('podział'), const OpenFairShareDialogCommand());
    });

    test('navigation keywords are case-insensitive', () {
      expect(parseCommand('ARKUSZ'), const NavigateCommand(PaletteDestination.budgetSheet));
    });

    test('a navigation keyword followed by more text is not a bare shortcut', () {
      expect(parseCommand('arkusz proszę'), isA<UnknownCommand>());
    });
  });

  group('parseCommand — quick-add expense (spec examples)', () {
    test('"kino 45 zachcianki" -> wydatek Kino, 45 PLN, Zachcianki', () {
      final command = parseCommand('kino 45 zachcianki') as AddExpenseParsedCommand;

      expect(command.name, 'kino');
      expect(command.amount, 45.0);
      expect(command.currency, 'PLN');
      expect(command.categoryType, ExpenseCategoryType.wants);
    });

    test('"paliwo 250 eur" -> wydatek w EUR, kategoria Transport/Użytkowe', () {
      final command = parseCommand('paliwo 250 eur') as AddExpenseParsedCommand;

      expect(command.name, 'paliwo');
      expect(command.amount, 250.0);
      expect(command.currency, 'EUR');
      expect(command.categoryType, ExpenseCategoryType.utility);
      expect(command.subCategory, 'Transport');
    });

    test('a multi-word name is preserved up to the amount token', () {
      final command = parseCommand('kolacja w restauracji 120 zachcianki') as AddExpenseParsedCommand;

      expect(command.name, 'kolacja w restauracji');
      expect(command.amount, 120.0);
    });

    test('a comma decimal amount parses correctly', () {
      final command = parseCommand('kawa 12,50 zachcianki') as AddExpenseParsedCommand;
      expect(command.amount, 12.5);
    });

    test('without an explicit category, it is inferred from the name', () {
      final command = parseCommand('bilet 30') as AddExpenseParsedCommand;

      expect(command.categoryType, ExpenseCategoryType.utility);
      expect(command.subCategory, 'Transport');
    });

    test('an unrecognized name with no category keyword falls back to wants/Inne', () {
      final command = parseCommand('cos tam 10') as AddExpenseParsedCommand;
      expect(command.categoryType, ExpenseCategoryType.wants);
      expect(command.subCategory, 'Inne');
    });
  });

  group('parseCommand — quick-add income (spec example)', () {
    test('"premia 1500 wplyw" -> wpływ Premia, 1500 PLN', () {
      final command = parseCommand('premia 1500 wplyw') as AddIncomeParsedCommand;

      expect(command.title, 'premia');
      expect(command.amount, 1500.0);
      expect(command.currency, 'PLN');
    });

    test('the diacritic form "wpływ" also marks an income', () {
      final command = parseCommand('premia 1500 wpływ') as AddIncomeParsedCommand;
      expect(command.title, 'premia');
    });

    test('a foreign-currency income keeps its currency code', () {
      final command = parseCommand('dywidenda 200 usd wplyw') as AddIncomeParsedCommand;
      expect(command.amount, 200.0);
      expect(command.currency, 'USD');
    });
  });

  group('parseCommand — currency keyword coverage', () {
    test('recognizes usd/gbp/chf in addition to eur', () {
      expect((parseCommand('cos 10 usd') as AddExpenseParsedCommand).currency, 'USD');
      expect((parseCommand('cos 10 gbp') as AddExpenseParsedCommand).currency, 'GBP');
      expect((parseCommand('cos 10 chf') as AddExpenseParsedCommand).currency, 'CHF');
    });

    test('an explicit "pln"/"zl" keyword still resolves to PLN', () {
      expect((parseCommand('cos 10 pln') as AddExpenseParsedCommand).currency, 'PLN');
      expect((parseCommand('cos 10 zl') as AddExpenseParsedCommand).currency, 'PLN');
    });

    test('no currency keyword at all defaults to PLN', () {
      expect((parseCommand('kino 45') as AddExpenseParsedCommand).currency, 'PLN');
    });
  });

  group('parseCommand — unrecognized input', () {
    test('an empty or blank query is unknown', () {
      expect(parseCommand(''), isA<UnknownCommand>());
      expect(parseCommand('   '), isA<UnknownCommand>());
    });

    test('text with no parsable amount anywhere is unknown', () {
      expect(parseCommand('kupic mleko jutro'), isA<UnknownCommand>());
    });

    test('an amount with nothing before it (no name) is unknown', () {
      expect(parseCommand('45 zachcianki'), isA<UnknownCommand>());
    });

    test('UnknownCommand keeps the original raw input for display', () {
      const raw = '  totally not a command  ';
      final command = parseCommand(raw) as UnknownCommand;
      expect(command.rawInput, raw);
    });
  });
}
