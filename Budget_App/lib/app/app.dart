import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../features/monetization/presentation/cubit/monetization_cubit.dart';
import '../features/workspace/presentation/bloc/workspaces_bloc.dart';
import '../features/workspace/presentation/bloc/workspaces_event.dart';
import '../features/workspace/presentation/cubit/active_workspace_cubit.dart';
import 'routes.dart';

class BudgetApp extends StatelessWidget {
  const BudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => MonetizationCubit()),
        BlocProvider(create: (_) => WorkspacesBloc()..add(const LoadWorkspaces())),
        BlocProvider(create: (_) => ActiveWorkspaceCubit()),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: appRouter,
      ),
    );
  }
}
