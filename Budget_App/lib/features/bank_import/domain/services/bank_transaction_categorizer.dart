import '../../../budget_sheet/domain/models/expense_category_type.dart';
import '../models/bank_transaction.dart';

/// Keyword-based category/sub-category guess for one imported bank
/// statement line — the bank-import analogue of receipt_scanner's
/// `categorizeReceiptItem`. Stands in for a real merchant-classification
/// service, same input/output shape, so it can be swapped later.
///
/// [amount]'s sign decides [BankTransactionType]; the keyword matching only
/// runs for expenses, since incomes in this app aren't split into
/// mandatory/utility/wants.
(BankTransactionType, ExpenseCategoryType?, String) categorizeBankTransaction({
  required String title,
  required String counterparty,
  required double amount,
}) {
  if (amount >= 0) {
    final normalized = '$title $counterparty'.toLowerCase();
    const payrollKeywords = ['wynagrodzenie', 'pensja', 'payroll', 'salary'];
    final subCategory = payrollKeywords.any(normalized.contains) ? 'Wynagrodzenie' : 'Inny wpływ';
    return (BankTransactionType.income, null, subCategory);
  }

  final normalized = '$title $counterparty'.toLowerCase();

  const groceryKeywords = [
    'biedronka', 'lidl', 'żabka', 'zabka', 'carrefour', 'auchan', 'kaufland',
    'aldi', 'spożyw', 'spozyw', 'stokrotka', 'delikatesy',
  ];
  const fuelKeywords = ['orlen', 'bp ', 'shell', 'circle k', 'paliw', 'stacja paliw', 'lotos'];
  const billsKeywords = [
    'prąd', 'prad', 'gaz', 'czynsz', 'energa', 'pge', 'tauron', 'orange',
    'play', 'plus', 'netia', 'ubezpiecz', 'woda', 'wodociąg', 'wodociag',
  ];
  const wantsKeywords = ['netflix', 'spotify', 'hbo', 'kino', 'steam', 'restauracj', 'kawiarni'];

  if (groceryKeywords.any(normalized.contains)) {
    return (BankTransactionType.expense, ExpenseCategoryType.mandatory, 'Zakupy spożywcze');
  }
  if (fuelKeywords.any(normalized.contains)) {
    return (BankTransactionType.expense, ExpenseCategoryType.utility, 'Paliwo');
  }
  if (billsKeywords.any(normalized.contains)) {
    return (BankTransactionType.expense, ExpenseCategoryType.mandatory, 'Rachunki');
  }
  if (wantsKeywords.any(normalized.contains)) {
    return (BankTransactionType.expense, ExpenseCategoryType.wants, 'Rozrywka');
  }
  return (BankTransactionType.expense, ExpenseCategoryType.wants, 'Inne');
}
