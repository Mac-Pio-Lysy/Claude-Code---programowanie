import 'package:equatable/equatable.dart';

import '../../domain/models/savings_goal.dart';

sealed class SavingsEvent extends Equatable {
  const SavingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSavingsGoals extends SavingsEvent {
  const LoadSavingsGoals();
}

class AddSavingsGoal extends SavingsEvent {
  const AddSavingsGoal(this.goal);

  final SavingsGoal goal;

  @override
  List<Object?> get props => [goal];
}

class UpdateSavingsGoal extends SavingsEvent {
  const UpdateSavingsGoal(this.goal);

  final SavingsGoal goal;

  @override
  List<Object?> get props => [goal];
}

class DeleteSavingsGoal extends SavingsEvent {
  const DeleteSavingsGoal(this.goalId);

  final String goalId;

  @override
  List<Object?> get props => [goalId];
}

class DepositToGoal extends SavingsEvent {
  const DepositToGoal(this.goalId, this.amount);

  final String goalId;
  final double amount;

  @override
  List<Object?> get props => [goalId, amount];
}
