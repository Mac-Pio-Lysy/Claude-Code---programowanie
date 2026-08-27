import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// A budget sub-category, shown in the desktop sidebar rail and the mobile
/// pill-tab switcher (e.g. Mieszkanie, Raty/Kredyty, Multimedia, Oszczędności).
class BudgetCategory extends Equatable {
  const BudgetCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.spent,
    required this.chartColor,
  });

  final String id;
  final String label;
  final IconData icon;

  /// Amount spent in this category this period, used to size the chart.
  final double spent;
  final Color chartColor;

  @override
  List<Object?> get props => [id, label, spent];
}
