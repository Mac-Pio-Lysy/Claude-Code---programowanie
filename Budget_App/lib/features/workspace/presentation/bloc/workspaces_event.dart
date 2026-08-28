import 'package:equatable/equatable.dart';

import '../../domain/models/budget_workspace.dart';

sealed class WorkspacesEvent extends Equatable {
  const WorkspacesEvent();

  @override
  List<Object?> get props => [];
}

class LoadWorkspaces extends WorkspacesEvent {
  const LoadWorkspaces();
}

class AddWorkspace extends WorkspacesEvent {
  const AddWorkspace(this.workspace);

  final BudgetWorkspace workspace;

  @override
  List<Object?> get props => [workspace];
}

class UpdateWorkspace extends WorkspacesEvent {
  const UpdateWorkspace(this.workspace);

  final BudgetWorkspace workspace;

  @override
  List<Object?> get props => [workspace];
}

class DeleteWorkspace extends WorkspacesEvent {
  const DeleteWorkspace(this.workspaceId);

  final String workspaceId;

  @override
  List<Object?> get props => [workspaceId];
}
