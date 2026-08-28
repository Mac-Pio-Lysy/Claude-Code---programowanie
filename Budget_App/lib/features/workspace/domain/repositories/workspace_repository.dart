import '../entities/budget_category.dart';

/// Source of the dashboard chart's data. The headline balance itself now
/// comes from `BudgetSheetBloc` (the single source of truth for income,
/// expenses and liabilities); this repository only feeds the category
/// breakdown chart until that chart is wired to live sheet data too.
abstract interface class WorkspaceRepository {
  Future<List<BudgetCategory>> getCategories();

  /// Monthly spend trend for the line-chart view, oldest to newest.
  Future<List<double>> getSpendingTrend();
}
