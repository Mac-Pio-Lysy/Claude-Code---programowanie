import 'package:equatable/equatable.dart';

import '../../domain/models/savings_goal.dart';
import '../../domain/models/sinking_fund.dart';

enum SavingsStatus { initial, loading, loaded, error }

class SavingsState extends Equatable {
  const SavingsState({
    required this.status,
    required this.goals,
    required this.sinkingFunds,
    this.errorMessage,
  });

  factory SavingsState.initial() =>
      const SavingsState(status: SavingsStatus.initial, goals: [], sinkingFunds: []);

  final SavingsStatus status;
  final List<SavingsGoal> goals;
  final List<SinkingFund> sinkingFunds;
  final String? errorMessage;

  /// Sum of currentAmount across every goal — the SavingsGoalsView summary.
  double get totalSaved => goals.fold(0.0, (sum, g) => sum + g.currentAmount);

  /// Sum of currentAccumulated across every sinking fund.
  double get totalSinkingFundsAccumulated =>
      sinkingFunds.fold(0.0, (sum, f) => sum + f.currentAccumulated);

  /// Every złoty currently set aside, goals and sinking funds combined —
  /// the pool an emergency-fund runway is measured against (see
  /// `BudgetSummary.emergencyRunwayMonths`).
  double get totalSavingsBalance => totalSaved + totalSinkingFundsAccumulated;

  SavingsState copyWith({
    SavingsStatus? status,
    List<SavingsGoal>? goals,
    List<SinkingFund>? sinkingFunds,
    String? errorMessage,
  }) {
    return SavingsState(
      status: status ?? this.status,
      goals: goals ?? this.goals,
      sinkingFunds: sinkingFunds ?? this.sinkingFunds,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, goals, sinkingFunds, errorMessage];
}
