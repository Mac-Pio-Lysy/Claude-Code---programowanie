import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import 'app_bottom_nav_bar.dart';
import 'app_nav_destination.dart';
import 'gradient_background.dart';

/// Single-window master-detail shell for the budget workspace.
///
/// At [AppConstants.desktopBreakpoint] and above it lays out a persistent top
/// bar, a leftmost icon rail for category sub-tabs, a ~38% master column
/// (summary + chart + metadata) and a ~62% detail column (the budget sheet).
/// Below that width it stacks the same pieces vertically, swaps the sidebar
/// rail for a horizontal pill switcher, and adds a bottom navigation bar
/// (plus an ad banner slot) for moving between top-level sections.
///
/// The scaffold itself holds no business logic — every region is supplied by
/// the caller, so it stays reusable across features.
class ResponsiveBudgetScaffold extends StatelessWidget {
  const ResponsiveBudgetScaffold({
    super.key,
    required this.topBar,
    required this.summaryCard,
    required this.chartSection,
    required this.metadataTiles,
    required this.categorySidebar,
    required this.categoryPillTabs,
    required this.sheetContent,
    required this.bottomDestinations,
    required this.selectedBottomIndex,
    required this.onBottomDestinationSelected,
    this.adBanner,
  });

  final Widget topBar;
  final Widget summaryCard;
  final Widget chartSection;
  final Widget metadataTiles;

  /// Leftmost icon rail shown on desktop/tablet widths.
  final Widget categorySidebar;

  /// Horizontal pill tab switcher shown on mobile widths, same destinations
  /// as [categorySidebar] in a form that fits a narrow screen.
  final Widget categoryPillTabs;

  final Widget sheetContent;

  final List<AppNavDestination> bottomDestinations;
  final int selectedBottomIndex;
  final ValueChanged<int> onBottomDestinationSelected;

  /// Ad banner reserved for the very bottom of the screen (mobile only, free
  /// tier). Omit once the user is subscribed to Premium.
  final Widget? adBanner;

  bool _isDesktop(double width) => width >= AppConstants.desktopBreakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = _isDesktop(constraints.maxWidth);

        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: GradientBackground(
            child: SafeArea(
              child: isDesktop ? _buildDesktop(context) : _buildMobile(context),
            ),
          ),
          bottomNavigationBar: isDesktop
              ? null
              : AppBottomNavBar(
                  destinations: bottomDestinations,
                  selectedIndex: selectedBottomIndex,
                  onDestinationSelected: onBottomDestinationSelected,
                  adBanner: adBanner,
                ),
        );
      },
    );
  }

  Widget _buildDesktop(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 64, child: topBar),
        const Divider(height: 1),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 88, child: categorySidebar),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 38,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      summaryCard,
                      const SizedBox(height: 20),
                      chartSection,
                      const SizedBox(height: 20),
                      metadataTiles,
                    ],
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 62,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: sheetContent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobile(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 56, child: topBar),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              summaryCard,
              const SizedBox(height: 16),
              chartSection,
              const SizedBox(height: 16),
              categoryPillTabs,
              const SizedBox(height: 16),
              sheetContent,
            ],
          ),
        ),
      ],
    );
  }
}
