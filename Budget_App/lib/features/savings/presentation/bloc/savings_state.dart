import 'package:equatable/equatable.dart';

import '../../domain/models/savings_goal.dart';

enum SavingsStatus { initial, loading, loaded, error }

class SavingsState extends Equatable {
  const SavingsState({
    required this.status,
    required this.goals,
    this.errorMessage,
  });

  factory SavingsState.initial() =>
      const SavingsState(status: SavingsStatus.initial, goals: []);

  final SavingsStatus status;
  final List<SavingsGoal> goals;
  final String? errorMessage;

  /// Sum of currentAmount across every goal — the SavingsGoalsView summary.
  double get totalSaved => goals.fold(0.0, (sum, g) => sum + g.currentAmount);

  SavingsState copyWith({
    SavingsStatus? status,
    List<SavingsGoal>? goals,
    String? errorMessage,
  }) {
    return SavingsState(
      status: status ?? this.status,
      goals: goals ?? this.goals,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, goals, errorMessage];
}
