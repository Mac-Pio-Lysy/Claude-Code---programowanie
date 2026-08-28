import 'package:equatable/equatable.dart';

import '../../domain/models/savings_goal.dart';
import '../../domain/models/sinking_fund.dart';

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

class AddSinkingFund extends SavingsEvent {
  const AddSinkingFund(this.fund);

  final SinkingFund fund;

  @override
  List<Object?> get props => [fund];
}

class UpdateSinkingFund extends SavingsEvent {
  const UpdateSinkingFund(this.fund);

  final SinkingFund fund;

  @override
  List<Object?> get props => [fund];
}

class DeleteSinkingFund extends SavingsEvent {
  const DeleteSinkingFund(this.fundId);

  final String fundId;

  @override
  List<Object?> get props => [fundId];
}

class ContributeToSinkingFund extends SavingsEvent {
  const ContributeToSinkingFund(this.fundId, this.amount);

  final String fundId;
  final double amount;

  @override
  List<Object?> get props => [fundId, amount];
}
