import '../entities/budget_category.dart';
import '../entities/budget_summary.dart';

/// Source of the data shown on the workspace dashboard (summary card, chart,
/// category sidebar). Implemented by the data layer against local cache
/// and/or the Supabase backend.
abstract interface class WorkspaceRepository {
  Future<BudgetSummary> getBudgetSummary();
  Future<List<BudgetCategory>> getCategories();

  /// Monthly spend trend for the line-chart view, oldest to newest.
  Future<List<double>> getSpendingTrend();
}
