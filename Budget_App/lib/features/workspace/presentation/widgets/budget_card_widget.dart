import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/models/budget_workspace.dart';
import 'workspace_tag_ui.dart';

/// A budget tile on WorkspaceSelectionPage: title, colored tag badge,
/// shared/individual icon and an Online indicator.
///
/// Deliberately has NO delete affordance (AB-3) — destructive deletion only
/// lives behind BudgetSettingsDialog's danger zone, reached from inside the
/// budget itself.
class BudgetCardWidget extends StatelessWidget {
  const BudgetCardWidget({super.key, required this.workspace, required this.onTap});

  final BudgetWorkspace workspace;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tagColor = workspaceTagColor(workspace.tag);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  workspace.isShared ? Icons.group_outlined : Icons.person_outline,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const Spacer(),
                _OnlineDot(isOnline: workspace.isOnline),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              workspace.title,
              style: textTheme.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: tagColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                workspaceTagLabel(workspace.tag),
                style: textTheme.labelSmall?.copyWith(color: tagColor, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnlineDot extends StatelessWidget {
  const _OnlineDot({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? AppColors.positive : AppColors.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          isOnline ? 'Online' : 'Offline',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
