import '../../../budget_sheet/domain/models/expense_category_type.dart';

/// Keyword-based category/sub-category guess for a receipt line item name.
/// Stands in for a real ML classifier — same input/output shape, so it can
/// be swapped later without touching callers.
(ExpenseCategoryType, String) categorizeReceiptItem(String itemName) {
  final normalized = itemName.toLowerCase();

  const transportKeywords = ['paliw', 'benzyn', 'diesel', 'bilet', 'parking', 'autostrad'];
  const wantsKeywords = ['kino', 'gra', 'netflix', 'spotify', 'hbo', 'książk', 'płyt'];
  const foodKeywords = [
    'chleb', 'mlek', 'masł', 'jabł', 'ser', 'jajk', 'mąk', 'cukier',
    'makaron', 'ryż', 'mięs', 'wędlin', 'warzyw', 'owoc',
  ];

  if (transportKeywords.any(normalized.contains)) {
    return (ExpenseCategoryType.utility, 'Transport');
  }
  if (wantsKeywords.any(normalized.contains)) {
    return (ExpenseCategoryType.wants, 'Rozrywka');
  }
  if (foodKeywords.any(normalized.contains)) {
    return (ExpenseCategoryType.mandatory, 'Jedzenie');
  }
  return (ExpenseCategoryType.wants, 'Inne');
}
