import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../bloc/budget_sheet_bloc.dart';
import '../bloc/budget_sheet_event.dart';
import 'sheet_tab.dart';

/// Horizontal pill switcher (mobile) for the same category sub-tabs shown
/// as a sidebar rail on wider screens: Wszystko, Mieszkanie, Raty/Kredyty,
/// Multimedia, Oszczędności.
class CategoryPillTabs extends StatelessWidget {
  const CategoryPillTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedTab = context.watch<BudgetSheetBloc>().state.selectedTab;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sheetTabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = sheetTabs[index];
          final selected = tab.id == selectedTab;
          return ChoiceChip(
            label: Text(tab.label),
            avatar: Icon(tab.icon, size: 16),
            selected: selected,
            selectedColor: AppColors.primaryIndigo.withValues(alpha: 0.15),
            onSelected: (_) =>
                context.read<BudgetSheetBloc>().add(SelectCategoryTab(tab.id)),
          );
        },
      ),
    );
  }
}
