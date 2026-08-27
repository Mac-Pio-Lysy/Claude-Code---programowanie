import 'package:go_router/go_router.dart';

import '../features/budget_sheet/presentation/pages/ocr_scanner_page.dart';
import '../features/savings/presentation/pages/savings_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/workspace/presentation/pages/workspace_page.dart';

/// Top-level destinations, in the same order as [workspaceNavDestinations]:
/// Dashboard, Arkusz, Oszczędności, Skaner OCR, Ustawienia.
const _paths = ['/dashboard', '/sheet', '/savings', '/ocr', '/settings'];

void _goToIndex(GoRouter router, int index) => router.go(_paths[index]);

final appRouter = GoRouter(
  initialLocation: _paths[0],
  routes: [
    GoRoute(
      path: _paths[0],
      builder: (context, state) => WorkspacePage(
        selectedBottomIndex: 0,
        onBottomDestinationSelected: (i) => _goToIndex(GoRouter.of(context), i),
      ),
    ),
    GoRoute(
      path: _paths[1],
      builder: (context, state) => WorkspacePage(
        selectedBottomIndex: 1,
        onBottomDestinationSelected: (i) => _goToIndex(GoRouter.of(context), i),
      ),
    ),
    GoRoute(
      path: _paths[2],
      builder: (context, state) => SavingsPage(
        selectedBottomIndex: 2,
        onBottomDestinationSelected: (i) => _goToIndex(GoRouter.of(context), i),
      ),
    ),
    GoRoute(
      path: _paths[3],
      builder: (context, state) => OcrScannerPage(
        selectedBottomIndex: 3,
        onBottomDestinationSelected: (i) => _goToIndex(GoRouter.of(context), i),
      ),
    ),
    GoRoute(
      path: _paths[4],
      builder: (context, state) => SettingsPage(
        selectedBottomIndex: 4,
        onBottomDestinationSelected: (i) => _goToIndex(GoRouter.of(context), i),
      ),
    ),
  ],
);
