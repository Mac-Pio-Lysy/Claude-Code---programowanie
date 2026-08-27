import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/budget_sheet_repository.dart';
import 'budget_sheet_state.dart';

class BudgetSheetCubit extends Cubit<BudgetSheetState> {
  BudgetSheetCubit(this._repository) : super(const BudgetSheetLoading()) {
    load();
  }

  final BudgetSheetRepository _repository;

  Future<void> load() async {
    emit(const BudgetSheetLoading());
    final entries = await _repository.getEntries();
    emit(BudgetSheetLoaded(entries));
  }
}
