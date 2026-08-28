import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/ad_banner_placeholder.dart';
import '../../../../core/widgets/app_nav_destination.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/responsive_budget_scaffold.dart';
import '../../../budget_sheet/presentation/bloc/budget_sheet_bloc.dart';
import '../../../budget_sheet/presentation/bloc/budget_sheet_event.dart';
import '../../../budget_sheet/presentation/bloc/budget_sheet_state.dart';
import '../../../budget_sheet/presentation/widgets/category_pill_tabs.dart';
import '../../../budget_sheet/presentation/widgets/category_sidebar_rail.dart';
import '../../../budget_sheet/presentation/widgets/charts/analytics_panel_card.dart';
import '../../../budget_sheet/presentation/widgets/entry_forms.dart';
import '../../../budget_sheet/presentation/widgets/excel_sheet_grid.dart';
import '../../../budget_sheet/presentation/widgets/mobile_budget_list.dart';
import '../../../monetization/presentation/cubit/monetization_cubit.dart';
import '../../../settings/presentation/widgets/budget_settings_dialog.dart';
import '../bloc/workspaces_bloc.dart';
import '../cubit/active_workspace_cubit.dart';
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

/// Combined dashboard + budget sheet workspace for one specific budget
/// (`/budget/:budgetId`) — the master-detail view described by the
/// responsive shell spec. "Dashboard" and "Arkusz" show the same content,
/// so switching between them is handled locally without re-navigating;
/// tapping any other destination hands off to [onNavigate].
class WorkspacePage extends StatefulWidget {
  const WorkspacePage({super.key, required this.budgetId, required this.onNavigate});

  final String budgetId;
  final ValueChanged<int> onNavigate;

  @override
  State<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<WorkspacePage> {
  int _localTabIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<ActiveWorkspaceCubit>().setActive(widget.budgetId);
  }

  @override
  void didUpdateWidget(covariant WorkspacePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.budgetId != widget.budgetId) {
      context.read<ActiveWorkspaceCubit>().setActive(widget.budgetId);
    }
  }

  void _handleBottomTap(int index) {
    if (index <= 1) {
      setState(() => _localTabIndex = index);
    } else {
      widget.onNavigate(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspace = context.watch<WorkspacesBloc>().state.findById(widget.budgetId);

    if (workspace == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: GradientBackground(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Nie znaleziono tego budżetu.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => context.go('/workspace'),
                  child: const Text('Wróć do wyboru budżetu'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final shouldShowAds = context.watch<MonetizationCubit>().shouldShowAds;

    return BlocProvider(
      create: (_) => BudgetSheetBloc()..add(LoadBudgetSheet(widget.budgetId)),
      child: BlocBuilder<BudgetSheetBloc, BudgetSheetState>(
        builder: (context, sheetState) {
          return ResponsiveBudgetScaffold(
            topBar: WorkspaceTopBar(
              budgetName: workspace.title,
              onViewSwitch: () => context.go('/workspace'),
              onBudgetSettingsTap: () => showBudgetSettingsDialog(context, workspace: workspace),
            ),
            summaryCard: BudgetSummaryCard(summary: sheetState.summary),
            chartSection: AnalyticsPanelCard(summary: sheetState.summary),
            categorySidebar: const CategorySidebarRail(),
            categoryPillTabs: const CategoryPillTabs(),
            desktopSheetContent: const ExcelSheetGrid(),
            mobileSheetContent: const MobileBudgetList(),
            bottomDestinations: workspaceNavDestinations,
            selectedBottomIndex: _localTabIndex,
            onBottomDestinationSelected: _handleBottomTap,
            adBanner: shouldShowAds ? const AdBannerPlaceholder() : null,
            floatingActionButton: FloatingActionButton(
              onPressed: () => showAddEntryChooser(context),
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }
}
