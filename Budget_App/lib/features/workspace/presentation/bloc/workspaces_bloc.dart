import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/budget_workspace.dart';
import '../../domain/models/workspace_tag.dart';
import 'workspaces_event.dart';
import 'workspaces_state.dart';

/// Owns the list of budgets the user has access to. A single app-lifetime
/// instance is provided above the router so the list (and any edits) stay
/// intact while navigating between a budget's workspace and other tabs.
class WorkspacesBloc extends Bloc<WorkspacesEvent, WorkspacesState> {
  WorkspacesBloc() : super(WorkspacesState.initial()) {
    on<LoadWorkspaces>(_onLoad);
    on<AddWorkspace>(_onAdd);
    on<UpdateWorkspace>(_onUpdate);
    on<DeleteWorkspace>(_onDelete);
  }

  Future<void> _onLoad(LoadWorkspaces event, Emitter<WorkspacesState> emit) async {
    emit(state.copyWith(status: WorkspacesStatus.loading));
    try {
      emit(state.copyWith(status: WorkspacesStatus.loaded, workspaces: _seedWorkspaces()));
    } catch (_) {
      emit(
        state.copyWith(
          status: WorkspacesStatus.error,
          errorMessage: 'Nie udało się wczytać budżetów.',
        ),
      );
    }
  }

  void _onAdd(AddWorkspace event, Emitter<WorkspacesState> emit) {
    emit(state.copyWith(workspaces: [...state.workspaces, event.workspace]));
  }

  void _onUpdate(UpdateWorkspace event, Emitter<WorkspacesState> emit) {
    emit(
      state.copyWith(
        workspaces: [
          for (final workspace in state.workspaces)
            if (workspace.id == event.workspace.id) event.workspace else workspace,
        ],
      ),
    );
  }

  void _onDelete(DeleteWorkspace event, Emitter<WorkspacesState> emit) {
    emit(
      state.copyWith(
        workspaces: state.workspaces.where((w) => w.id != event.workspaceId).toList(),
      ),
    );
  }

  List<BudgetWorkspace> _seedWorkspaces() {
    return [
      BudgetWorkspace(
        id: 'workspace-home-2026',
        title: 'Budżet Domowy 2026',
        tag: WorkspaceTag.general,
        isShared: false,
        isOnline: true,
        ownerId: 'demo-user',
        createdAt: DateTime.now(),
      ),
    ];
  }
}
