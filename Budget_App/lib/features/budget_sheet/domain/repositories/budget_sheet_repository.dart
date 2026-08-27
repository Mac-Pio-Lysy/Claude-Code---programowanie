import '../entities/sheet_entry.dart';

/// Source of the budget sheet's line items.
abstract interface class BudgetSheetRepository {
  Future<List<SheetEntry>> getEntries();
}
