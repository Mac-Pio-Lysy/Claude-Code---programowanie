import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/beverage.dart';
import '../../models/wedding_data.dart';
import '../../services/budget_service.dart';
import '../../utils/format.dart';
import 'budget_fields.dart';
import '../../l10n/app_text.dart';
import '../../utils/app_format.dart';

/// Podzakładka napojów — wspólna dla Alkoholu i Napojów bezalkoholowych.
class BeverageTab extends StatelessWidget {
  const BeverageTab({
    super.key,
    required this.kind,
    required this.data,
    required this.service,
  });

  final BeverageKind kind;
  final WeddingData? data;
  final BudgetService service;

  List<Map<String, dynamic>> get _items {
    final bd = data?.raw['budgetData'];
    final v = (bd is Map) ? bd[kind.itemsKey] : null;
    return v is List
        ? v.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];
  }

  @override
  Widget build(BuildContext context) {
    final s = BeverageSummary.from(data, kind);
    if (s.panelHidden) return _hiddenView();
    final items = _items;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _itemsCard(items),
        const SizedBox(height: 16),
        _summaryCard(s),
        const SizedBox(height: 16),
        _splitCard(s),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => service.setBeveragePanelHidden(kind, true),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: Text(AppText.t.budget_panelRemoveTitle(kind.title)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFC0392B),
              side: const BorderSide(color: Color(0xFFE9A8A8)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  /// Widok po usunięciu panelu — pozycje zachowane, panel niewliczany.
  Widget _hiddenView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _card(
          title: AppText.t.budget_panelRemovedToast,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppText.t.budget_panelRemovedInfo(kind.title),
                style:
                    GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => service.setBeveragePanelHidden(kind, false),
                  icon: const Icon(Icons.restore),
                  label: Text(AppText.t.budget_panelRestore),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _itemsCard(List<Map<String, dynamic>> items) {
    return _card(
      title: 'Pozycje',
      trailing: IconButton(
        onPressed: () => service.addBeverage(kind),
        icon: const Icon(Icons.add_circle_outline),
        color: AppColors.accent,
        tooltip: AppText.t.budget_addItem,
      ),
      child: items.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(AppText.t.budget_addItemHint,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textLight)),
            )
          : Column(
              children: [
                for (final item in items)
                  _BeverageRow(
                    key: ValueKey('${kind.itemsKey}-${item['id']}'),
                    kind: kind,
                    item: item,
                    service: service,
                  ),
              ],
            ),
    );
  }

  Widget _summaryCard(BeverageSummary s) {
    return _card(
      title: 'Podsumowanie',
      child: Column(
        children: [
          Row(
            children: [
              _stat(s.totalBottles.toStringAsFixed(0), AppText.t.budget_bottlesTotal),
              _stat(formatPlnZl(s.totalCost), AppText.t.budget_costTotal),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _stat(
                  s.personCount > 0 ? s.perBottles.toStringAsFixed(2) : '—',
                  'butelek / os.'),
              _stat(
                  s.personCount > 0 ? formatPlnZl(s.perCost) : '—',
                  s.personCount > 0
                      ? 'koszt / os. (${s.personCount.toStringAsFixed(0)} os.)'
                      : 'koszt / os.'),
            ],
          ),
          const SizedBox(height: 4),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.accent,
            title: Text(
              AppText.t.budget_includeVirtual,
              style: GoogleFonts.inter(fontSize: 13),
            ),
            value: s.perVirtual,
            onChanged: (v) => service.setBeveragePerPersonVirtual(kind, v),
          ),
        ],
      ),
    );
  }

  Widget _splitCard(BeverageSummary s) {
    final over = (s.splitP1 + s.splitP2) > s.totalCost + 0.01 && s.totalCost > 0;
    return _card(
      title: AppText.t.budget_splitHeader,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: BudgetNumberField(
                  key: ValueKey(kind.splitP1Key),
                  label: s.coupleNames[0],
                  suffix: AppFormat.currency.symbol,
                  initial: s.splitP1,
                  onSaved: (v) => service.setBeverageSplit(kind, p1: v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BudgetNumberField(
                  key: ValueKey(kind.splitP2Key),
                  label: s.coupleNames[1],
                  suffix: AppFormat.currency.symbol,
                  initial: s.splitP2,
                  onSaved: (v) => service.setBeverageSplit(kind, p2: v),
                ),
              ),
            ],
          ),
          if (over)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                AppText.t.budget_splitExceeds,
                style: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFFC0392B)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent)),
          Text(label,
              style:
                  GoogleFonts.inter(fontSize: 11, color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _card({required String title, Widget? trailing, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
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
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _BeverageRow extends StatelessWidget {
  const _BeverageRow({
    super.key,
    required this.kind,
    required this.item,
    required this.service,
  });

  final BeverageKind kind;
  final Map<String, dynamic> item;
  final BudgetService service;

  int get _id => (item['id'] as num?)?.toInt() ?? 0;
  double _d(dynamic v) => v is num ? v.toDouble() : 0.0;

  @override
  Widget build(BuildContext context) {
    final bottles = _d(item['bottles']);
    final price = _d(item['pricePerBottle']);
    final total = bottles * price;
    final type = (item['type'] as String?) ?? kind.types.first;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 4,
                child: DropdownButtonFormField<String>(
                  initialValue: kind.types.contains(type) ? type : kind.types.first,
                  isExpanded: true,
                  decoration: _dec(),
                  items: [
                    for (final t in kind.types)
                      DropdownMenuItem(value: t, child: Text(t)),
                  ],
                  onChanged: (v) =>
                      service.updateBeverage(kind, _id, type: v),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: () => service.deleteBeverage(kind, _id),
                icon: const Icon(Icons.close, size: 18),
                color: const Color(0xFFC0392B),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
          BudgetTextField(
            initial: (item['name'] as String?) ?? '',
            hint: 'Marka / nazwa (opcjonalnie)',
            onSaved: (v) => service.updateBeverage(kind, _id, name: v),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: BudgetNumberField(
                  suffix: 'szt.',
                  integer: true,
                  initial: bottles,
                  compact: true,
                  onSaved: (v) => service.updateBeverage(kind, _id, bottles: v),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('×'),
              ),
              Expanded(
                child: BudgetNumberField(
                  suffix: AppFormat.currency.symbol,
                  initial: price,
                  compact: true,
                  onSaved: (v) =>
                      service.updateBeverage(kind, _id, pricePerBottle: v),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '= ${formatPlnZl(total)}',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent),
            ),
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }

  InputDecoration _dec() => InputDecoration(
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF8FAFF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDCE4F2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDCE4F2)),
        ),
      );
}
