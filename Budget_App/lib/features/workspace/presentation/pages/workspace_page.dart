import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/ad_banner_placeholder.dart';
import '../../../../core/widgets/app_nav_destination.dart';
import '../../../../core/widgets/responsive_budget_scaffold.dart';
import '../../../budget_sheet/presentation/bloc/budget_sheet_bloc.dart';
import '../../../budget_sheet/presentation/bloc/budget_sheet_event.dart';
import '../../../budget_sheet/presentation/bloc/budget_sheet_state.dart';
import '../../../budget_sheet/presentation/widgets/category_pill_tabs.dart';
import '../../../budget_sheet/presentation/widgets/category_sidebar_rail.dart';
import '../../../budget_sheet/presentation/widgets/entry_forms.dart';
import '../../../budget_sheet/presentation/widgets/excel_sheet_grid.dart';
import '../../../budget_sheet/presentation/widgets/mobile_budget_list.dart';
import '../../data/repositories/mock_workspace_repository.dart';
import '../cubit/chart_mode_cubit.dart';
import '../cubit/workspace_cubit.dart';
import '../cubit/workspace_state.dart';
import '../widgets/budget_chart_card.dart';
import '../widgets/budget_metadata_tiles.dart';
import '../widgets/budget_summary_card.dart';
import '../widgets/workspace_top_bar.dart';

/// Bottom-nav destinations shared across the app's top-level sections.
const workspaceNavDestinations = [
  AppNavDestination(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
  ),
  AppNavDestination(
    label: 'Arkusz',
    icon: Icons.table_chart_outlined,
    selectedIcon: Icons.table_chart,
  ),
  AppNavDestination(
    label: 'Oszczędności',
    icon: Icons.savings_outlined,
    selectedIcon: Icons.savings,
  ),
  AppNavDestination(
    label: 'Skaner OCR',
    icon: Icons.document_scanner_outlined,
    selectedIcon: Icons.document_scanner,
  ),
  AppNavDestination(
    label: 'Ustawienia',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
  ),
];

/// Combined dashboard + budget sheet workspace — the master-detail view
/// described by the responsive shell spec. [selectedBottomIndex] only
/// affects which bottom-nav item is highlighted; the content shown is the
/// same regardless of whether the user arrived via "Dashboard" or "Arkusz".
class WorkspacePage extends StatelessWidget {
  const WorkspacePage({
    super.key,
    required this.selectedBottomIndex,
    required this.onBottomDestinationSelected,
  });

  final int selectedBottomIndex;
  final ValueChanged<int> onBottomDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => WorkspaceCubit(const MockWorkspaceRepository()),
        ),
        BlocProvider(
          create: (_) => BudgetSheetBloc()..add(const LoadBudgetSheet('demo-budget')),
        ),
        BlocProvider(create: (_) => ChartModeCubit()),
      ],
      child: BlocBuilder<WorkspaceCubit, WorkspaceState>(
        builder: (context, workspaceState) {
          if (workspaceState is! WorkspaceLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          return BlocBuilder<BudgetSheetBloc, BudgetSheetState>(
            builder: (context, sheetState) {
              return ResponsiveBudgetScaffold(
                topBar: const WorkspaceTopBar(budgetName: 'Budżet domowy — Sierpień'),
                summaryCard: BudgetSummaryCard(summary: sheetState.summary),
                chartSection: BudgetChartCard(
                  categories: workspaceState.categories,
                  spendingTrend: workspaceState.spendingTrend,
                ),
                metadataTiles: const BudgetMetadataTiles(),
                categorySidebar: const CategorySidebarRail(),
                categoryPillTabs: const CategoryPillTabs(),
                desktopSheetContent: const ExcelSheetGrid(),
                mobileSheetContent: const MobileBudgetList(),
                bottomDestinations: workspaceNavDestinations,
                selectedBottomIndex: selectedBottomIndex,
                onBottomDestinationSelected: onBottomDestinationSelected,
                adBanner: const AdBannerPlaceholder(),
                floatingActionButton: FloatingActionButton(
                  onPressed: () => showAddEntryChooser(context),
                  child: const Icon(Icons.add),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
