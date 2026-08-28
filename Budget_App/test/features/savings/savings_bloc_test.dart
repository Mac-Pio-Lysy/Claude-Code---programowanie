import 'package:bloc_test/bloc_test.dart';
import 'package:budget_app/features/savings/domain/models/contribution_interval.dart';
import 'package:budget_app/features/savings/domain/models/savings_goal.dart';
import 'package:budget_app/features/savings/presentation/bloc/savings_bloc.dart';
import 'package:budget_app/features/savings/presentation/bloc/savings_event.dart';
import 'package:budget_app/features/savings/presentation/bloc/savings_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const goal = SavingsGoal(
    id: 'goal-1',
    title: 'Wesele',
    targetAmount: 20000,
    currentAmount: 5000,
    contributionInterval: ContributionInterval.monthly,
  );

  group('LoadSavingsGoals', () {
    blocTest<SavingsBloc, SavingsState>(
      'seeds two starter goals: Wakacje 2026 and Poduszka finansowa',
      build: SavingsBloc.new,
      act: (bloc) => bloc.add(const LoadSavingsGoals()),
      expect: () => [
        isA<SavingsState>().having((s) => s.status, 'status', SavingsStatus.loading),
        isA<SavingsState>()
            .having((s) => s.status, 'status', SavingsStatus.loaded)
            .having((s) => s.goals.map((g) => g.title), 'titles',
                containsAll(['Wakacje 2026', 'Poduszka finansowa'])),
      ],
    );
  });

  group('AddSavingsGoal / UpdateSavingsGoal / DeleteSavingsGoal', () {
    blocTest<SavingsBloc, SavingsState>(
      'AddSavingsGoal appends the goal',
      build: SavingsBloc.new,
      act: (bloc) => bloc.add(const AddSavingsGoal(goal)),
      verify: (bloc) => expect(bloc.state.goals, [goal]),
    );

    blocTest<SavingsBloc, SavingsState>(
      'UpdateSavingsGoal replaces the matching goal',
      build: SavingsBloc.new,
      seed: () => SavingsState.initial().copyWith(goals: [goal]),
      act: (bloc) => bloc.add(UpdateSavingsGoal(goal.copyWith(targetAmount: 25000))),
      verify: (bloc) => expect(bloc.state.goals.single.targetAmount, 25000.0),
    );

    blocTest<SavingsBloc, SavingsState>(
      'DeleteSavingsGoal removes it',
      build: SavingsBloc.new,
      seed: () => SavingsState.initial().copyWith(goals: [goal]),
      act: (bloc) => bloc.add(const DeleteSavingsGoal('goal-1')),
      verify: (bloc) => expect(bloc.state.goals, isEmpty),
    );
  });

  group('DepositToGoal', () {
    blocTest<SavingsBloc, SavingsState>(
      'increases currentAmount for the matching goal only',
      build: SavingsBloc.new,
      seed: () => SavingsState.initial().copyWith(
        goals: const [
          goal,
          SavingsGoal(
            id: 'goal-2',
            title: 'Wakacje',
            targetAmount: 20000,
            currentAmount: 5000,
            contributionInterval: ContributionInterval.monthly,
          ),
        ],
      ),
      act: (bloc) => bloc.add(const DepositToGoal('goal-1', 500)),
      verify: (bloc) {
        final updated = bloc.state.goals.firstWhere((g) => g.id == 'goal-1');
        final other = bloc.state.goals.firstWhere((g) => g.id == 'goal-2');
        expect(updated.currentAmount, 5500.0);
        expect(other.currentAmount, 5000.0);
      },
    );
  });

  group('SavingsState.totalSaved', () {
    test('sums currentAmount across all goals', () {
      final state = SavingsState.initial().copyWith(
        goals: [goal, goal.copyWith(currentAmount: 1000)],
      );
      expect(state.totalSaved, 6000.0);
    });
  });
}
