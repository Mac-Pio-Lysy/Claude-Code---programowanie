import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/models/savings_goal.dart';
import '../bloc/savings_bloc.dart';
import '../bloc/savings_event.dart';
import 'add_savings_goal_dialog.dart';
import 'contribution_interval_label.dart';
import 'deposit_dialog.dart';
import 'gradient_progress_bar.dart';
import 'savings_goal_icon.dart';

/// A single savings goal: progress, pacing calculator and quick actions.
class SavingsGoalCard extends StatelessWidget {
  const SavingsGoalCard({super.key, required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final progressPercent = (goal.progressPercentage * 100).round();
    final pacing = goal.targetDate == null
        ? null
        : pacingMessage(
            targetDate: goal.targetDate,
            requiredContribution: goal.calculateRequiredContribution(goal.targetDate!),
            interval: goal.contributionInterval,
            formatCurrency: CurrencyFormatter.format,
          );

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.positive.withValues(alpha: 0.12),
                child: Icon(iconForSavingsGoal(goal.title), color: AppColors.positive),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  goal.title,
                  style: textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    showAddSavingsGoalDialog(context, existing: goal);
                  } else if (value == 'delete') {
                    context.read<SavingsBloc>().add(DeleteSavingsGoal(goal.id));
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edytuj')),
                  PopupMenuItem(value: 'delete', child: Text('Usuń')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          GradientProgressBar(progress: goal.progressPercentage),
          const SizedBox(height: 8),
          Text(
            'Zebrano: ${CurrencyFormatter.format(goal.currentAmount)} '
            'z ${CurrencyFormatter.format(goal.targetAmount)} ($progressPercent%)',
            style: textTheme.bodySmall,
          ),
          if (pacing != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.insights_outlined, size: 16, color: AppColors.accentBlue),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    pacing,
                    style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Odkładaj ${contributionIntervalLabel(goal.contributionInterval)}, '
              'aby regularnie zasilać ten cel.',
              style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: () => showDepositDialog(context, goalId: goal.id, goalTitle: goal.title),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Wpłać'),
            ),
          ),
        ],
      ),
    );
  }
}
