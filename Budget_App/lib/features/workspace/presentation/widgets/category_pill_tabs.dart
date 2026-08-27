import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/budget_category.dart';
import '../cubit/category_filter_cubit.dart';

/// Horizontal pill switcher (mobile) for the same category sub-tabs shown
/// as a sidebar rail on wider screens.
class CategoryPillTabs extends StatelessWidget {
  const CategoryPillTabs({super.key, required this.categories});

  final List<BudgetCategory> categories;

  @override
  Widget build(BuildContext context) {
    final selectedId = context.watch<CategoryFilterCubit>().state;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = category.id == selectedId;
          return ChoiceChip(
            label: Text(category.label),
            avatar: Icon(category.icon, size: 16),
            selected: selected,
            selectedColor: AppColors.accentBlue.withValues(alpha: 0.15),
            onSelected: (_) => context
                .read<CategoryFilterCubit>()
                .select(selected ? null : category.id),
          );
        },
      ),
    );
  }
}
