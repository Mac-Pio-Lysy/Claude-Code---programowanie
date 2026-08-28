import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/data/repositories/mock_auth_repository.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_event.dart';
import '../features/budget_sheet/presentation/bloc/budget_sheet_bloc.dart';
import '../features/monetization/presentation/cubit/monetization_cubit.dart';
import '../features/savings/presentation/bloc/savings_bloc.dart';
import '../features/savings/presentation/bloc/savings_event.dart';
import '../features/workspace/presentation/bloc/workspaces_bloc.dart';
import '../features/workspace/presentation/bloc/workspaces_event.dart';
import '../features/workspace/presentation/cubit/active_workspace_cubit.dart';
import 'routes.dart';

class BudgetApp extends StatefulWidget {
  const BudgetApp({super.key});

  @override
  State<BudgetApp> createState() => _BudgetAppState();
}

class _BudgetAppState extends State<BudgetApp> {
  // Created once per BudgetApp instance (not per rebuild), so navigation
  // and auth state don't leak between app launches / widget-test pumps.
  late final _authBloc = AuthBloc(MockAuthRepository())..add(const CheckAuthSession());
  late final _router = createAppRouter(authBloc: _authBloc);

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider(create: (_) => MonetizationCubit()),
        BlocProvider(create: (_) => WorkspacesBloc()..add(const LoadWorkspaces())),
        BlocProvider(create: (_) => ActiveWorkspaceCubit()),
        // App-lifetime so goals/sinking funds survive leaving and
        // re-entering the Savings page, and so BudgetSheetBloc below can
        // read its totalSavingsBalance for the emergency-runway indicator.
        BlocProvider(create: (_) => SavingsBloc()..add(const LoadSavingsGoals())),
        // App-lifetime so WorkspacePage and the receipt scanner's /ocr
        // route share the same active budget's sheet.
        BlocProvider(
          create: (context) => BudgetSheetBloc(savingsBloc: context.read<SavingsBloc>()),
        ),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: _router,
      ),
    );
  }
}
