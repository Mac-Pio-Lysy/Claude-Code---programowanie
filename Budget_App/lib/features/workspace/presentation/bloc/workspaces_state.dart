import 'package:equatable/equatable.dart';

import '../../domain/models/budget_workspace.dart';

enum WorkspacesStatus { initial, loading, loaded, error }

class WorkspacesState extends Equatable {
  const WorkspacesState({
    required this.status,
    required this.workspaces,
    this.errorMessage,
  });

  factory WorkspacesState.initial() =>
      const WorkspacesState(status: WorkspacesStatus.initial, workspaces: []);

  final WorkspacesStatus status;
  final List<BudgetWorkspace> workspaces;
  final String? errorMessage;

  BudgetWorkspace? findById(String id) {
    for (final workspace in workspaces) {
      if (workspace.id == id) return workspace;
    }
    return null;
  }

  WorkspacesState copyWith({
    WorkspacesStatus? status,
    List<BudgetWorkspace>? workspaces,
    String? errorMessage,
  }) {
    return WorkspacesState(
      status: status ?? this.status,
      workspaces: workspaces ?? this.workspaces,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, workspaces, errorMessage];
}
