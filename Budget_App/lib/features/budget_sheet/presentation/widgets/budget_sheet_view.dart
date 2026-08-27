import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/sheet_entry.dart';
import '../../domain/entities/sheet_section.dart';

/// The budget sheet grid, sectioned into Wpływy / Wydatki stałe / Użytkowe /
/// Zachcianki / Oszczędności. Filters to [selectedCategoryId] when set, from
/// either the desktop sidebar rail or the mobile pill tabs.
class BudgetSheetView extends StatelessWidget {
  const BudgetSheetView({
    super.key,
    required this.entries,
    this.selectedCategoryId,
  });

  final List<SheetEntry> entries;
  final String? selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final visible = selectedCategoryId == null
        ? entries
        : entries.where((e) => e.categoryId == selectedCategoryId).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final section in SheetSection.values)
          _SheetSectionCard(
            section: section,
            entries: visible.where((e) => e.section == section).toList(),
          ),
      ],
    );
  }
}

class _SheetSectionCard extends StatelessWidget {
  const _SheetSectionCard({required this.section, required this.entries});

  final SheetSection section;
  final List<SheetEntry> entries;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final total = entries.fold<double>(0, (sum, e) => sum + e.amount);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(section.label, style: textTheme.titleSmall)),
                Text(
                  CurrencyFormatter.format(total),
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Brak pozycji',
                  style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              )
            else ...[
              const Divider(height: 20),
              for (final entry in entries) _SheetRow(entry: entry),
            ],
          ],
        ),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({required this.entry});

  final SheetEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(entry.label)),
          Text(CurrencyFormatter.format(entry.amount)),
        ],
      ),
    );
  }
}
