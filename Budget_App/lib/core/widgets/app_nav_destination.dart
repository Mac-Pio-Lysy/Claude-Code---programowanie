import 'package:flutter/material.dart';

/// A single navigation target, reused for the mobile bottom bar, the desktop
/// sidebar rail and the mobile pill-tab switcher alike.
class AppNavDestination {
  const AppNavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
