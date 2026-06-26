import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/checklist_item.dart';
import '../../models/wedding_data.dart';
import '../../services/schedule_service.dart';
import '../budget/budget_fields.dart';

/// Podzakładka „Checklista" — rzeczy do zrobienia na dzień ślubu,
/// pogrupowane w kategorie, z paskiem postępu.
class ChecklistTab extends StatelessWidget {
  const ChecklistTab({super.key, required this.data, required this.service});

  final WeddingData? data;
  final ScheduleService service;

  List<ChecklistItem> get _items => [
        for (final e in _rawList)
          if (e is Map) ChecklistItem(Map<String, dynamic>.from(e)),
      ];

  List<dynamic> get _rawList {
    final v = data?.raw['checklist'];
    return v is List ? v : const [];
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final total = items.length;
    final done = items.where((i) => i.done).length;
    final pct = total > 0 ? done / total : 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _progressCard(done, total, pct),
        const SizedBox(height: 16),
        for (final cat in kChecklistCategories)
          _categorySection(cat, items.where((i) => i.category == cat).toList()),
      ],
    );
  }

  Widget _progressCard(int done, int total, double pct) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EAF7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$done/$total ukończonych (${(pct * 100).round()}%)',
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: const Color(0xFFE5EBF5),
              valueColor:
                  const AlwaysStoppedAnimation(Color(0xFF10B981)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categorySection(String category, List<ChecklistItem> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2EAF7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(category,
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text)),
                ),
                IconButton(
                  onPressed: () => service.addChecklistItem(category),
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppColors.accent,
                  tooltip: 'Dodaj pozycję',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('Brak pozycji.',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textLight)),
              )
            else
              for (final item in items)
                _ChecklistRow(
                  key: ValueKey(item.id),
                  item: item,
                  service: service,
                ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({super.key, required this.item, required this.service});

  final ChecklistItem item;
  final ScheduleService service;

  int get _id => item.id ?? 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Checkbox(
            value: item.done,
            activeColor: const Color(0xFF10B981),
            onChanged: (v) =>
                service.updateChecklistItem(_id, done: v ?? false),
          ),
          Expanded(
            child: BudgetTextField(
              initial: item.text,
              hint: 'Co zrobić…',
              onSaved: (v) => service.updateChecklistItem(_id, text: v),
            ),
          ),
          IconButton(
            onPressed: () => service.deleteChecklistItem(_id),
            icon: const Icon(Icons.close, size: 18),
            color: const Color(0xFFC0392B),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
