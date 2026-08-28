import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/contribution_interval.dart';
import '../../domain/models/savings_goal.dart';
import 'savings_event.dart';
import 'savings_state.dart';

class SavingsBloc extends Bloc<SavingsEvent, SavingsState> {
  SavingsBloc() : super(SavingsState.initial()) {
    on<LoadSavingsGoals>(_onLoad);
    on<AddSavingsGoal>(_onAdd);
    on<UpdateSavingsGoal>(_onUpdate);
    on<DeleteSavingsGoal>(_onDelete);
    on<DepositToGoal>(_onDeposit);
  }

  Future<void> _onLoad(LoadSavingsGoals event, Emitter<SavingsState> emit) async {
    emit(state.copyWith(status: SavingsStatus.loading));
    try {
      emit(state.copyWith(status: SavingsStatus.loaded, goals: _seedGoals()));
    } catch (_) {
      emit(
        state.copyWith(
          status: SavingsStatus.error,
          errorMessage: 'Nie udało się wczytać celów oszczędnościowych.',
        ),
      );
    }
  }

  void _onAdd(AddSavingsGoal event, Emitter<SavingsState> emit) {
    emit(state.copyWith(goals: [...state.goals, event.goal]));
  }

  void _onUpdate(UpdateSavingsGoal event, Emitter<SavingsState> emit) {
    emit(
      state.copyWith(
        goals: [
          for (final goal in state.goals)
            if (goal.id == event.goal.id) event.goal else goal,
        ],
      ),
    );
  }

  void _onDelete(DeleteSavingsGoal event, Emitter<SavingsState> emit) {
    emit(state.copyWith(goals: state.goals.where((g) => g.id != event.goalId).toList()));
  }

  void _onDeposit(DepositToGoal event, Emitter<SavingsState> emit) {
    emit(
      state.copyWith(
        goals: [
          for (final goal in state.goals)
            if (goal.id == event.goalId)
              goal.copyWith(currentAmount: goal.currentAmount + event.amount)
            else
              goal,
        ],
      ),
    );
  }

  List<SavingsGoal> _seedGoals() {
    final now = DateTime.now();
    return [
      SavingsGoal(
        id: 'goal-wakacje-2026',
        title: 'Wakacje 2026',
        targetAmount: 6000,
        currentAmount: 1800,
        contributionInterval: ContributionInterval.monthly,
        targetDate: DateTime(2026, 6, 1),
      ),
      SavingsGoal(
        id: 'goal-poduszka',
        title: 'Poduszka finansowa',
        targetAmount: 15000,
        currentAmount: 4000,
        contributionInterval: ContributionInterval.monthly,
        targetDate: DateTime(now.year + 1, now.month, 1),
      ),
    ];
  }
}
