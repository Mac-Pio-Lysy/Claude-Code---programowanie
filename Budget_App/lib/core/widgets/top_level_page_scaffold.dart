import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import 'app_bottom_nav_bar.dart';
import 'app_nav_destination.dart';
import 'app_navigation_rail.dart';
import 'gradient_background.dart';

/// Shared shell for every top-level page reached via the bottom nav /
/// desktop rail (Oszczędności, Skaner OCR, Ustawienia): an [AppBar], [body]
/// over the signature gradient, and — depending on width — either a bottom
/// [AppBottomNavBar] (mobile) or a leftmost [AppNavigationRail] (desktop/
/// tablet), mirroring [ResponsiveBudgetScaffold]'s breakpoint so every
/// section stays reachable regardless of window size.
class TopLevelPageScaffold extends StatelessWidget {
  const TopLevelPageScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.floatingActionButton,
    this.adBanner,
  });

  final String title;
  final Widget body;
  final List<AppNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget? floatingActionButton;
  final Widget? adBanner;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= AppConstants.desktopBreakpoint;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: Text(title)),
          floatingActionButton: floatingActionButton,
          body: GradientBackground(
            child: SafeArea(
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 96,
                          child: AppNavigationRail(
                            destinations: destinations,
                            selectedIndex: selectedIndex,
                            onDestinationSelected: onDestinationSelected,
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(child: body),
                      ],
                    )
                  : body,
            ),
          ),
          bottomNavigationBar: isDesktop
              ? null
              : AppBottomNavBar(
                  destinations: destinations,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  adBanner: adBanner,
                ),
        );
      },
    );
  }
}
