import 'package:flutter/material.dart';

/// Best-effort icon for a goal based on its title (Wakacje, Wesele, Studia,
/// Poduszka, …), falling back to a generic savings icon. Purely a display
/// concern — the domain model itself has no notion of "category icon".
IconData iconForSavingsGoal(String title) {
  final normalized = title.toLowerCase();

  if (normalized.contains('wakacj') || normalized.contains('urlop')) {
    return Icons.beach_access_outlined;
  }
  if (normalized.contains('wesel') || normalized.contains('ślub')) {
    return Icons.favorite_border;
  }
  if (normalized.contains('studi') || normalized.contains('szkoł') || normalized.contains('nauk')) {
    return Icons.school_outlined;
  }
  if (normalized.contains('poduszk') || normalized.contains('awaryjn') || normalized.contains('bezpiecz')) {
    return Icons.shield_outlined;
  }
  if (normalized.contains('samoch') || normalized.contains('aut')) {
    return Icons.directions_car_outlined;
  }
  if (normalized.contains('mieszkan') || normalized.contains('dom')) {
    return Icons.home_outlined;
  }
  if (normalized.contains('dziecko') || normalized.contains('dzieci')) {
    return Icons.child_care_outlined;
  }

  return Icons.savings_outlined;
}
