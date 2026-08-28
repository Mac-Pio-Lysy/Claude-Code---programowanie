import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../bloc/budget_sheet_bloc.dart';
import '../bloc/budget_sheet_event.dart';
import 'sheet_tab.dart';

/// Leftmost icon rail (desktop/tablet) for switching the sheet's category
/// sub-tab: Wszystko, Mieszkanie, Raty/Kredyty, Multimedia, Oszczędności.
class CategorySidebarRail extends StatelessWidget {
  const CategorySidebarRail({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedTab = context.watch<BudgetSheetBloc>().state.selectedTab;

    return Column(
      children: [
        const SizedBox(height: 12),
        for (final tab in sheetTabs)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: _RailButton(
              tab: tab,
              selected: tab.id == selectedTab,
              onTap: () =>
                  context.read<BudgetSheetBloc>().add(SelectCategoryTab(tab.id)),
            ),
          ),
      ],
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final SheetTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tab.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryIndigo.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            tab.icon,
            color: selected ? AppColors.primaryIndigo : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
