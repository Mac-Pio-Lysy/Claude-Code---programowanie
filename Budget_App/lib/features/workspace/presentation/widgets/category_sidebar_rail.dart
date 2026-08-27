import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/budget_category.dart';
import '../cubit/category_filter_cubit.dart';

/// Leftmost icon rail (desktop/tablet) for switching the sheet's category
/// sub-tab: Mieszkanie, Raty/Kredyty, Multimedia, Oszczędności...
class CategorySidebarRail extends StatelessWidget {
  const CategorySidebarRail({super.key, required this.categories});

  final List<BudgetCategory> categories;

  @override
  Widget build(BuildContext context) {
    final selectedId = context.watch<CategoryFilterCubit>().state;

    return Column(
      children: [
        const SizedBox(height: 12),
        for (final category in categories)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: _RailButton(
              category: category,
              selected: category.id == selectedId,
              onTap: () => context.read<CategoryFilterCubit>().select(
                    category.id == selectedId ? null : category.id,
                  ),
            ),
          ),
      ],
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final BudgetCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: category.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accentBlue.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            category.icon,
            color: selected ? AppColors.accentBlue : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
