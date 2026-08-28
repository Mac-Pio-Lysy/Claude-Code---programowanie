import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/contribution_interval.dart';
import '../../domain/models/savings_goal.dart';
import '../../domain/models/sinking_fund.dart';
import 'savings_event.dart';
import 'savings_state.dart';

class SavingsBloc extends Bloc<SavingsEvent, SavingsState> {
  SavingsBloc() : super(SavingsState.initial()) {
    on<LoadSavingsGoals>(_onLoad);
    on<AddSavingsGoal>(_onAdd);
    on<UpdateSavingsGoal>(_onUpdate);
    on<DeleteSavingsGoal>(_onDelete);
    on<DepositToGoal>(_onDeposit);
    on<AddSinkingFund>(_onAddFund);
    on<UpdateSinkingFund>(_onUpdateFund);
    on<DeleteSinkingFund>(_onDeleteFund);
    on<ContributeToSinkingFund>(_onContributeToFund);
  }

  Future<void> _onLoad(LoadSavingsGoals event, Emitter<SavingsState> emit) async {
    emit(state.copyWith(status: SavingsStatus.loading));
    try {
      emit(
        state.copyWith(
          status: SavingsStatus.loaded,
          goals: _seedGoals(),
          sinkingFunds: _seedSinkingFunds(),
        ),
      );
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

  void _onAddFund(AddSinkingFund event, Emitter<SavingsState> emit) {
    emit(state.copyWith(sinkingFunds: [...state.sinkingFunds, event.fund]));
  }

  void _onUpdateFund(UpdateSinkingFund event, Emitter<SavingsState> emit) {
    emit(
      state.copyWith(
        sinkingFunds: [
          for (final fund in state.sinkingFunds)
            if (fund.id == event.fund.id) event.fund else fund,
        ],
      ),
    );
  }

  void _onDeleteFund(DeleteSinkingFund event, Emitter<SavingsState> emit) {
    emit(
      state.copyWith(
        sinkingFunds: state.sinkingFunds.where((f) => f.id != event.fundId).toList(),
      ),
    );
  }

  void _onContributeToFund(ContributeToSinkingFund event, Emitter<SavingsState> emit) {
    emit(
      state.copyWith(
        sinkingFunds: [
          for (final fund in state.sinkingFunds)
            if (fund.id == event.fundId)
              fund.copyWith(currentAccumulated: fund.currentAccumulated + event.amount)
            else
              fund,
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

  List<SinkingFund> _seedSinkingFunds() {
    return [
      SinkingFund(
        id: 'fund-oc-ac',
        title: 'Ubezpieczenie OC/AC',
        targetAmount: 1800,
        currentAccumulated: 600,
        targetDate: _nextOccurrenceOf(month: 3),
      ),
      SinkingFund(
        id: 'fund-swieta',
        title: 'Święta',
        targetAmount: 2000,
        currentAccumulated: 300,
        targetDate: _nextOccurrenceOf(month: 12),
      ),
    ];
  }

  /// The next 1st-of-[month] that is still in the future (this year, or
  /// next year if this year's has already passed).
  DateTime _nextOccurrenceOf({required int month}) {
    final now = DateTime.now();
    final thisYear = DateTime(now.year, month, 1);
    return thisYear.isAfter(now) ? thisYear : DateTime(now.year + 1, month, 1);
  }
}
