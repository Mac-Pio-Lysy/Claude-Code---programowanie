import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/ad_banner_placeholder.dart';
import '../../../../core/widgets/top_level_page_scaffold.dart';
import '../../../monetization/presentation/cubit/monetization_cubit.dart';
import '../../../workspace/presentation/pages/workspace_page.dart' show workspaceNavDestinations;
import '../widgets/add_savings_goal_dialog.dart';
import '../widgets/add_sinking_fund_dialog.dart';
import '../widgets/savings_goals_view.dart';

/// SavingsBloc lives at the app root (see app.dart) so goals/sinking funds
/// survive leaving and re-entering this page, and so BudgetSheetBloc can
/// read its balance for the dashboard's emergency-runway indicator.
class SavingsPage extends StatefulWidget {
  const SavingsPage({
    super.key,
    required this.selectedBottomIndex,
    required this.onBottomDestinationSelected,
  });

  final int selectedBottomIndex;
  final ValueChanged<int> onBottomDestinationSelected;

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shouldShowAds = context.watch<MonetizationCubit>().shouldShowAds;

    return TopLevelPageScaffold(
      title: 'Oszczędności',
      destinations: workspaceNavDestinations,
      selectedIndex: widget.selectedBottomIndex,
      onDestinationSelected: widget.onBottomDestinationSelected,
      adBanner: shouldShowAds ? const AdBannerPlaceholder() : null,
      // The active tab decides whether "+" adds a goal or a sinking fund.
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) => FloatingActionButton(
          onPressed: () => _tabController.index == 0
              ? showAddSavingsGoalDialog(context)
              : showAddSinkingFundDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
      body: SavingsGoalsView(tabController: _tabController),
    );
  }
}
