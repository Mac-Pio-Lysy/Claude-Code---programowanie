import 'package:uuid/uuid.dart';

import '../../domain/entities/sheet_entry.dart';
import '../../domain/entities/sheet_section.dart';
import '../../domain/repositories/budget_sheet_repository.dart';

/// Static sample line items standing in for the real Drift-backed
/// repository until local persistence is wired in.
class MockBudgetSheetRepository implements BudgetSheetRepository {
  const MockBudgetSheetRepository();

  static const _uuid = Uuid();

  @override
  Future<List<SheetEntry>> getEntries() async => [
        SheetEntry(
          id: _uuid.v4(),
          label: 'Wynagrodzenie',
          amount: 7500,
          section: SheetSection.income,
        ),
        SheetEntry(
          id: _uuid.v4(),
          label: 'Czynsz',
          amount: 1800,
          section: SheetSection.fixedExpenses,
          categoryId: 'housing',
        ),
        SheetEntry(
          id: _uuid.v4(),
          label: 'Rata kredytu',
          amount: 950,
          section: SheetSection.fixedExpenses,
          categoryId: 'loans',
        ),
        SheetEntry(
          id: _uuid.v4(),
          label: 'Prąd i gaz',
          amount: 400,
          section: SheetSection.utilities,
          categoryId: 'housing',
        ),
        SheetEntry(
          id: _uuid.v4(),
          label: 'Internet i telefon',
          amount: 180,
          section: SheetSection.utilities,
          categoryId: 'media',
        ),
        SheetEntry(
          id: _uuid.v4(),
          label: 'Restauracje',
          amount: 320,
          section: SheetSection.wants,
        ),
        SheetEntry(
          id: _uuid.v4(),
          label: 'Fundusz awaryjny',
          amount: 600,
          section: SheetSection.savings,
          categoryId: 'savings',
        ),
      ];
}
