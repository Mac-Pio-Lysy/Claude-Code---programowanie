import '../../../budget_sheet/domain/models/expense_category_type.dart';
import '../../../receipt_scanner/domain/services/receipt_categorizer.dart';
import '../models/parsed_command.dart';

const _navigationKeywords = {
  'arkusz': PaletteDestination.budgetSheet,
  'oszczednosci': PaletteDestination.savings,
  'oszczędności': PaletteDestination.savings,
  'skaner': PaletteDestination.ocrScanner,
  'import': PaletteDestination.bankImport,
};

const _fairShareKeywords = {'podzial', 'podział'};

const _incomeKeywords = {
  'wplyw', 'wpływ', 'przychod', 'przychód', 'dochod', 'dochód',
};

const _expenseCategoryKeywords = {
  'zachcianki': ExpenseCategoryType.wants,
  'zachcianka': ExpenseCategoryType.wants,
  'wymagane': ExpenseCategoryType.mandatory,
  'stale': ExpenseCategoryType.mandatory,
  'stałe': ExpenseCategoryType.mandatory,
  'uzytkowe': ExpenseCategoryType.utility,
  'użytkowe': ExpenseCategoryType.utility,
};

const _currencyKeywords = {
  'pln': 'PLN', 'zl': 'PLN', 'zł': 'PLN', 'zloty': 'PLN', 'złoty': 'PLN',
  'zlotych': 'PLN', 'złotych': 'PLN',
  'eur': 'EUR', 'euro': 'EUR',
  'usd': 'USD', 'dolar': 'USD', 'dolary': 'USD', 'dolarow': 'USD', 'dolarów': 'USD',
  'gbp': 'GBP', 'funt': 'GBP', 'funty': 'GBP', 'funtow': 'GBP', 'funtów': 'GBP',
  'chf': 'CHF', 'frank': 'CHF', 'franki': 'CHF', 'frankow': 'CHF', 'franków': 'CHF',
};

/// Parses one Command Palette query into a [ParsedCommand]:
/// - A bare navigation keyword ("arkusz", "oszczednosci", "skaner",
///   "import") or "podzial" — jumps straight to that section/dialog.
/// - `<name...> <amount> [currency] [category-or-wpływ]` — a quick-add
///   expense or income. The category, if omitted, is inferred from [name]
///   via the same heuristic receipt_scanner uses for line items.
/// - Anything else (including an empty query) — [UnknownCommand].
ParsedCommand parseCommand(String rawInput) {
  final trimmed = rawInput.trim();
  if (trimmed.isEmpty) return UnknownCommand(rawInput);

  final normalized = trimmed.toLowerCase();
  final firstToken = normalized.split(RegExp(r'\s+')).first;

  // A bare keyword (nothing else typed) is a navigation/dialog shortcut.
  if (normalized == firstToken) {
    final destination = _navigationKeywords[firstToken];
    if (destination != null) return NavigateCommand(destination);
    if (_fairShareKeywords.contains(firstToken)) return const OpenFairShareDialogCommand();
  }

  return _parseQuickAdd(trimmed, rawInput);
}

ParsedCommand _parseQuickAdd(String trimmed, String rawInput) {
  final tokens = trimmed.split(RegExp(r'\s+'));

  var amountIndex = -1;
  double? amount;
  for (var i = 0; i < tokens.length; i++) {
    final parsed = _tryParseAmount(tokens[i]);
    if (parsed != null) {
      amountIndex = i;
      amount = parsed;
      break;
    }
  }

  // No amount found, or nothing before it to use as a name.
  if (amountIndex <= 0 || amount == null) {
    return UnknownCommand(rawInput);
  }

  final name = tokens.sublist(0, amountIndex).join(' ');
  final remainderTokens = tokens.sublist(amountIndex + 1).map((t) => t.toLowerCase());

  var currency = 'PLN';
  final remaining = <String>[];
  for (final token in remainderTokens) {
    final currencyCode = _currencyKeywords[token];
    if (currencyCode != null) {
      currency = currencyCode;
    } else {
      remaining.add(token);
    }
  }

  if (remaining.any(_incomeKeywords.contains)) {
    return AddIncomeParsedCommand(title: name, amount: amount, currency: currency);
  }

  ExpenseCategoryType? explicitCategory;
  for (final token in remaining) {
    final category = _expenseCategoryKeywords[token];
    if (category != null) {
      explicitCategory = category;
      break;
    }
  }

  final (inferredCategory, inferredSubCategory) = categorizeReceiptItem(name);

  return AddExpenseParsedCommand(
    name: name,
    amount: amount,
    currency: currency,
    categoryType: explicitCategory ?? inferredCategory,
    subCategory: inferredSubCategory,
  );
}

double? _tryParseAmount(String token) => double.tryParse(token.replaceAll(',', '.'));
