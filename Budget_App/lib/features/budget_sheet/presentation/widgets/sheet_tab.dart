import 'package:flutter/material.dart';

/// A sheet sub-tab: filters the grid/list to one category, or "Wszystko"
/// for no filter. Dispatches [SelectCategoryTab] against [BudgetSheetBloc].
class SheetTab {
  const SheetTab({required this.id, required this.label, required this.icon});

  final String id;
  final String label;
  final IconData icon;
}

const sheetTabs = [
  SheetTab(id: 'all', label: 'Wszystko', icon: Icons.apps_rounded),
  SheetTab(id: 'housing', label: 'Mieszkanie', icon: Icons.home_outlined),
  SheetTab(
    id: 'loans',
    label: 'Raty / Kredyty',
    icon: Icons.credit_card_outlined,
  ),
  SheetTab(id: 'media', label: 'Multimedia', icon: Icons.subscriptions_outlined),
  SheetTab(id: 'savings', label: 'Oszczędności', icon: Icons.savings_outlined),
];
