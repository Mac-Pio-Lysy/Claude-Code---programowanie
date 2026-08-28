import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/glass_card.dart';
import '../bloc/savings_bloc.dart';
import '../bloc/savings_state.dart';
import 'savings_goal_card.dart';
import 'sinking_fund_tile.dart';

/// Two tabs: "Cele" (open-ended savings goals) and "Fundusze celowe"
/// (sinking funds for known, irregular future expenses) — sharing
/// [tabController] with the page's FAB so "+" adds the right kind of
/// item for whichever tab is active.
class SavingsGoalsView extends StatelessWidget {
  const SavingsGoalsView({super.key, required this.tabController});

  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SavingsBloc, SavingsState>(
      builder: (context, state) {
        if (state.status == SavingsStatus.loading || state.status == SavingsStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == SavingsStatus.error) {
          return Center(child: Text(state.errorMessage ?? 'Błąd wczytywania.'));
        }

        return Column(
          children: [
            TabBar(
              controller: tabController,
              tabs: const [
                Tab(text: 'Cele'),
                Tab(text: 'Fundusze celowe'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [
                  _GoalsTab(state: state),
                  _SinkingFundsTab(state: state),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GoalsTab extends StatelessWidget {
  const _GoalsTab({required this.state});

  final SavingsState state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TotalCard(
            icon: Icons.savings,
            label: 'Łącznie zgromadzono',
            total: state.totalSaved,
            count: state.goals.length,
            countLabel: (n) => '$n ${n == 1 ? 'cel' : 'cele/celów'}',
          ),
          const SizedBox(height: 16),
          if (state.goals.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('Brak celów oszczędnościowych. Dodaj pierwszy!')),
            )
          else
            _ResponsiveGrid(
              itemCount: state.goals.length,
              mainAxisExtent: 300,
              itemBuilder: (context, index) => SavingsGoalCard(goal: state.goals[index]),
            ),
        ],
      ),
    );
  }
}

class _SinkingFundsTab extends StatelessWidget {
  const _SinkingFundsTab({required this.state});

  final SavingsState state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TotalCard(
            icon: Icons.event_repeat_outlined,
            label: 'Zgromadzono na fundusze celowe',
            total: state.totalSinkingFundsAccumulated,
            count: state.sinkingFunds.length,
            countLabel: (n) => '$n ${n == 1 ? 'fundusz' : 'fundusze/funduszy'}',
          ),
          const SizedBox(height: 16),
          if (state.sinkingFunds.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Brak funduszy na wydatki nieregularne. Dodaj pierwszy (np. OC/AC, '
                  'podatek, święta)!',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            _ResponsiveGrid(
              itemCount: state.sinkingFunds.length,
              mainAxisExtent: 340,
              itemBuilder: (context, index) => SinkingFundTile(fund: state.sinkingFunds[index]),
            ),
        ],
      ),
    );
  }
}

/// 1/2/3-column grid, matching the breakpoints the rest of the dashboard
/// uses (600px, 900px).
class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({
    required this.itemCount,
    required this.mainAxisExtent,
    required this.itemBuilder,
  });

  final int itemCount;
  final double mainAxisExtent;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 600
                ? 2
                : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: mainAxisExtent,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemBuilder: itemBuilder,
        );
      },
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.icon,
    required this.label,
    required this.total,
    required this.count,
    required this.countLabel,
  });

  final IconData icon;
  final String label;
  final double total;
  final int count;
  final String Function(int) countLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      child: Row(
        children: [
          Icon(icon, color: AppColors.positive, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: textTheme.labelLarge),
                Text(
                  CurrencyFormatter.format(total),
                  style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  countLabel(count),
                  style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
