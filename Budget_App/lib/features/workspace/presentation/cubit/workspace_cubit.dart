import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/workspace_repository.dart';
import 'workspace_state.dart';

class WorkspaceCubit extends Cubit<WorkspaceState> {
  WorkspaceCubit(this._repository) : super(const WorkspaceLoading()) {
    load();
  }

  final WorkspaceRepository _repository;

  Future<void> load() async {
    emit(const WorkspaceLoading());
    final summary = await _repository.getBudgetSummary();
    final categories = await _repository.getCategories();
    final spendingTrend = await _repository.getSpendingTrend();

    emit(
      WorkspaceLoaded(
        summary: summary,
        categories: categories,
        spendingTrend: spendingTrend,
      ),
    );
  }
}
