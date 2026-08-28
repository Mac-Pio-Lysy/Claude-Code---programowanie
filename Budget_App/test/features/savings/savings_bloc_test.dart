import 'package:bloc_test/bloc_test.dart';
import 'package:budget_app/features/savings/domain/models/contribution_interval.dart';
import 'package:budget_app/features/savings/domain/models/savings_goal.dart';
import 'package:budget_app/features/savings/domain/models/sinking_fund.dart';
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

  final fund = SinkingFund(
    id: 'fund-1',
    title: 'Ubezpieczenie OC/AC',
    targetAmount: 1800,
    currentAccumulated: 300,
    targetDate: DateTime.now().add(const Duration(days: 300)),
  );

  final fund2 = SinkingFund(
    id: 'fund-2',
    title: 'Święta',
    targetAmount: 2000,
    currentAccumulated: 100,
    targetDate: DateTime.now().add(const Duration(days: 300)),
  );

  group('LoadSavingsGoals', () {
    blocTest<SavingsBloc, SavingsState>(
      'seeds two starter goals and two starter sinking funds',
      build: SavingsBloc.new,
      act: (bloc) => bloc.add(const LoadSavingsGoals()),
      expect: () => [
        isA<SavingsState>().having((s) => s.status, 'status', SavingsStatus.loading),
        isA<SavingsState>()
            .having((s) => s.status, 'status', SavingsStatus.loaded)
            .having((s) => s.goals.map((g) => g.title), 'titles',
                containsAll(['Wakacje 2026', 'Poduszka finansowa']))
            .having((s) => s.sinkingFunds.map((f) => f.title), 'sinking fund titles',
                containsAll(['Ubezpieczenie OC/AC', 'Święta'])),
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

  group('AddSinkingFund / UpdateSinkingFund / DeleteSinkingFund', () {
    blocTest<SavingsBloc, SavingsState>(
      'AddSinkingFund appends the fund',
      build: SavingsBloc.new,
      act: (bloc) => bloc.add(AddSinkingFund(fund)),
      verify: (bloc) => expect(bloc.state.sinkingFunds, [fund]),
    );

    blocTest<SavingsBloc, SavingsState>(
      'UpdateSinkingFund replaces the matching fund',
      build: SavingsBloc.new,
      seed: () => SavingsState.initial().copyWith(sinkingFunds: [fund]),
      act: (bloc) => bloc.add(UpdateSinkingFund(fund.copyWith(targetAmount: 2400))),
      verify: (bloc) => expect(bloc.state.sinkingFunds.single.targetAmount, 2400.0),
    );

    blocTest<SavingsBloc, SavingsState>(
      'DeleteSinkingFund removes it',
      build: SavingsBloc.new,
      seed: () => SavingsState.initial().copyWith(sinkingFunds: [fund]),
      act: (bloc) => bloc.add(const DeleteSinkingFund('fund-1')),
      verify: (bloc) => expect(bloc.state.sinkingFunds, isEmpty),
    );
  });

  group('ContributeToSinkingFund', () {
    blocTest<SavingsBloc, SavingsState>(
      'increases currentAccumulated for the matching fund only',
      build: SavingsBloc.new,
      seed: () => SavingsState.initial().copyWith(sinkingFunds: [fund, fund2]),
      act: (bloc) => bloc.add(const ContributeToSinkingFund('fund-1', 200)),
      verify: (bloc) {
        final updated = bloc.state.sinkingFunds.firstWhere((f) => f.id == 'fund-1');
        final other = bloc.state.sinkingFunds.firstWhere((f) => f.id == 'fund-2');
        expect(updated.currentAccumulated, 500.0);
        expect(other.currentAccumulated, 100.0);
      },
    );
  });

  group('SavingsState — totals', () {
    test('totalSaved sums currentAmount across all goals', () {
      final state = SavingsState.initial().copyWith(
        goals: [goal, goal.copyWith(currentAmount: 1000)],
      );
      expect(state.totalSaved, 6000.0);
    });

    test('totalSinkingFundsAccumulated sums currentAccumulated across all funds', () {
      final state = SavingsState.initial().copyWith(
        sinkingFunds: [fund, fund2.copyWith(currentAccumulated: 700)],
      );
      expect(state.totalSinkingFundsAccumulated, 1000.0);
    });

    test('totalSavingsBalance combines goals and sinking funds', () {
      final state = SavingsState.initial().copyWith(
        goals: [goal], // currentAmount 5000
        sinkingFunds: [fund], // currentAccumulated 300
      );
      expect(state.totalSavingsBalance, 5300.0);
    });
  });
}
