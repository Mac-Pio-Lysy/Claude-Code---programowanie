import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/ad_banner_placeholder.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../monetization/presentation/cubit/monetization_cubit.dart';
import '../../../workspace/presentation/pages/workspace_page.dart' show workspaceNavDestinations;
import '../bloc/savings_bloc.dart';
import '../bloc/savings_event.dart';
import '../widgets/add_savings_goal_dialog.dart';
import '../widgets/savings_goals_view.dart';

class SavingsPage extends StatelessWidget {
  const SavingsPage({
    super.key,
    required this.selectedBottomIndex,
    required this.onBottomDestinationSelected,
  });

  final int selectedBottomIndex;
  final ValueChanged<int> onBottomDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SavingsBloc()..add(const LoadSavingsGoals()),
      child: Builder(
        builder: (context) {
          final shouldShowAds = context.watch<MonetizationCubit>().shouldShowAds;
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(title: const Text('Oszczędności')),
            body: const GradientBackground(child: SavingsGoalsView()),
            floatingActionButton: FloatingActionButton(
              onPressed: () => showAddSavingsGoalDialog(context),
              child: const Icon(Icons.add),
            ),
            bottomNavigationBar: AppBottomNavBar(
              destinations: workspaceNavDestinations,
              selectedIndex: selectedBottomIndex,
              onDestinationSelected: onBottomDestinationSelected,
              adBanner: shouldShowAds ? const AdBannerPlaceholder() : null,
            ),
          );
        },
      ),
    );
  }
}
