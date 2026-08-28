import 'package:flutter/material.dart';

import '../../domain/entities/budget_category.dart';
import '../../domain/repositories/workspace_repository.dart';

/// Static sample data standing in for the real Supabase/Drift-backed
/// repository until the backend integration lands.
class MockWorkspaceRepository implements WorkspaceRepository {
  const MockWorkspaceRepository();

  static const List<BudgetCategory> _categories = [
    BudgetCategory(
      id: 'housing',
      label: 'Mieszkanie',
      icon: Icons.home_outlined,
      spent: 2200,
      chartColor: Color(0xFF1E88E5),
    ),
    BudgetCategory(
      id: 'loans',
      label: 'Raty / Kredyty',
      icon: Icons.credit_card_outlined,
      spent: 950,
      chartColor: Color(0xFF0A2540),
    ),
    BudgetCategory(
      id: 'media',
      label: 'Multimedia',
      icon: Icons.subscriptions_outlined,
      spent: 180,
      chartColor: Color(0xFF64B5F6),
    ),
    BudgetCategory(
      id: 'savings',
      label: 'Oszczędności',
      icon: Icons.savings_outlined,
      spent: 600,
      chartColor: Color(0xFF1B9C63),
    ),
  ];

  @override
  Future<List<BudgetCategory>> getCategories() async => _categories;

  @override
  Future<List<double>> getSpendingTrend() async =>
      const [3200, 3450, 3100, 3800, 3600, 3930];
}
