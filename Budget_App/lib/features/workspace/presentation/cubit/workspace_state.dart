import 'package:equatable/equatable.dart';

import '../../domain/entities/budget_category.dart';

sealed class WorkspaceState extends Equatable {
  const WorkspaceState();

  @override
  List<Object?> get props => [];
}

class WorkspaceLoading extends WorkspaceState {
  const WorkspaceLoading();
}

class WorkspaceLoaded extends WorkspaceState {
  const WorkspaceLoaded({
    required this.categories,
    required this.spendingTrend,
  });

  final List<BudgetCategory> categories;
  final List<double> spendingTrend;

  @override
  List<Object?> get props => [categories, spendingTrend];
}
