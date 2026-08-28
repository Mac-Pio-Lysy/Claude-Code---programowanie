import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/glass_card.dart';
import '../bloc/savings_bloc.dart';
import '../bloc/savings_state.dart';
import 'savings_goal_card.dart';

/// Grid/list of every active savings goal, plus a summary of how much has
/// been saved across all of them.
class SavingsGoalsView extends StatelessWidget {
  const SavingsGoalsView({super.key});

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

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TotalSavedCard(totalSaved: state.totalSaved, goalCount: state.goals.length),
              const SizedBox(height: 16),
              if (state.goals.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text('Brak celów oszczędnościowych. Dodaj pierwszy!')),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 900
                        ? 3
                        : constraints.maxWidth >= 600
                            ? 2
                            : 1;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.goals.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisExtent: 300,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemBuilder: (context, index) =>
                          SavingsGoalCard(goal: state.goals[index]),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TotalSavedCard extends StatelessWidget {
  const _TotalSavedCard({required this.totalSaved, required this.goalCount});

  final double totalSaved;
  final int goalCount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      child: Row(
        children: [
          const Icon(Icons.savings, color: AppColors.positive, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Łącznie zgromadzono', style: textTheme.labelLarge),
                Text(
                  CurrencyFormatter.format(totalSaved),
                  style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  '$goalCount ${goalCount == 1 ? 'cel' : 'cele/celów'}',
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
