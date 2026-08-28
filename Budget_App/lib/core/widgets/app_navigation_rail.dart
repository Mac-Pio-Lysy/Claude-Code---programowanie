import 'package:flutter/material.dart';

import 'app_nav_destination.dart';

/// Desktop/tablet counterpart to [AppBottomNavBar]: the same top-level
/// destinations as a vertical rail with a label under every icon, so every
/// section (Dashboard, Arkusz, Oszczędności, Skaner OCR, Ustawienia) stays
/// reachable once the responsive shell switches away from the bottom bar.
class AppNavigationRail extends StatelessWidget {
  const AppNavigationRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<AppNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      backgroundColor: Colors.transparent,
      labelType: NavigationRailLabelType.all,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: [
        for (final destination in destinations)
          NavigationRailDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selectedIcon),
            label: Text(destination.label, textAlign: TextAlign.center),
          ),
      ],
    );
  }
}
