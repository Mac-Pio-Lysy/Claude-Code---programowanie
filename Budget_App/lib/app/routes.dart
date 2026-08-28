import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/budget_sheet/presentation/pages/ocr_scanner_page.dart';
import '../features/monetization/presentation/pages/support_us_page.dart';
import '../features/savings/presentation/pages/savings_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/workspace/presentation/cubit/active_workspace_cubit.dart';
import '../features/workspace/presentation/pages/workspace_page.dart';
import '../features/workspace/presentation/pages/workspace_selection_page.dart';
import 'go_router_refresh_stream.dart';

/// AB-2 route guard: everything except /splash and /login requires
/// Authenticated. Signing out from anywhere bounces back to /login;
/// reaching /login or /splash while already signed in bounces to
/// /workspace. While the session check is still in flight, everything
/// routes through /splash — which is only ever a transient stop, never a
/// resting place, so once the check resolves we always leave it.
String? _authRedirect(AuthBloc authBloc, GoRouterState state) {
  final authState = authBloc.state;
  final location = state.matchedLocation;

  if (authState is AuthInitial || authState is AuthLoading) {
    return location == '/splash' ? null : '/splash';
  }
  if (authState is Authenticated) {
    return (location == '/splash' || location == '/login') ? '/workspace' : null;
  }
  // Unauthenticated or AuthFailure (a failed sign-in attempt on /login).
  return location == '/login' ? null : '/login';
}

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

/// A fresh router per call, rather than a module-level singleton — so each
/// [BudgetApp] instance (each real app launch, and each widget test's
/// `pumpWidget`) starts clean at `initialLocation` instead of inheriting
/// whatever location a previous instance was left on.
GoRouter createAppRouter({required AuthBloc authBloc}) => GoRouter(
  initialLocation: '/splash',
  refreshListenable: GoRouterRefreshStream(authBloc.stream),
  redirect: (context, state) => _authRedirect(authBloc, state),
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
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
