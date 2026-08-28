import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/budget_sheet/presentation/pages/ocr_scanner_page.dart';
import '../features/monetization/presentation/pages/support_us_page.dart';
import '../features/savings/presentation/pages/savings_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/workspace/presentation/cubit/active_workspace_cubit.dart';
import '../features/workspace/presentation/pages/workspace_page.dart';
import '../features/workspace/presentation/pages/workspace_selection_page.dart';

/// Bottom-nav index -> destination. 0/1 (Dashboard/Arkusz) are handled
/// locally by WorkspacePage itself; this only fires for 2-4, or when a
/// non-workspace page needs to jump back into the last-active budget.
void goToBottomNavIndex(BuildContext context, int index) {
  switch (index) {
    case 0:
    case 1:
      final activeId = context.read<ActiveWorkspaceCubit>().state;
      context.go(activeId == null ? '/workspace' : '/budget/$activeId');
    case 2:
      context.go('/savings');
    case 3:
      context.go('/ocr');
    default:
      context.go('/settings');
  }
}

final appRouter = GoRouter(
  initialLocation: '/workspace',
  routes: [
    GoRoute(
      path: '/workspace',
      builder: (context, state) => const WorkspaceSelectionPage(),
    ),
    GoRoute(
      path: '/budget/:budgetId',
      builder: (context, state) => WorkspacePage(
        budgetId: state.pathParameters['budgetId']!,
        onNavigate: (i) => goToBottomNavIndex(context, i),
      ),
    ),
    GoRoute(
      path: '/savings',
      builder: (context, state) => SavingsPage(
        selectedBottomIndex: 2,
        onBottomDestinationSelected: (i) => goToBottomNavIndex(context, i),
      ),
    ),
    GoRoute(
      path: '/ocr',
      builder: (context, state) => OcrScannerPage(
        selectedBottomIndex: 3,
        onBottomDestinationSelected: (i) => goToBottomNavIndex(context, i),
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => SettingsPage(
        selectedBottomIndex: 4,
        onBottomDestinationSelected: (i) => goToBottomNavIndex(context, i),
      ),
    ),
    GoRoute(
      path: '/support',
      builder: (context, state) => const SupportUsPage(),
    ),
  ],
);
