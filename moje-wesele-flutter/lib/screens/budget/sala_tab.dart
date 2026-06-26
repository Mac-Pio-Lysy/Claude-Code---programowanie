import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/sala_summary.dart';
import '../../models/wedding_data.dart';
import '../../services/budget_service.dart';
import '../../utils/format.dart';
import 'budget_fields.dart';

/// Podzakładka „Sala" — catering: cena/os., goście wirtualni, dodatki menu,
/// dekoracje stołów oraz podsumowanie kosztów.
class SalaTab extends StatelessWidget {
  const SalaTab({super.key, required this.data, required this.service});

  final WeddingData? data;
  final BudgetService service;

  List<Map<String, dynamic>> get _menuAddons => _list('menuAddons');
  List<Map<String, dynamic>> get _honorAddons => _decoList('honorAddons');
  List<Map<String, dynamic>> get _regularAddons => _decoList('regularAddons');

  List<Map<String, dynamic>> _list(String key) {
    final bd = data?.raw['budgetData'];
    final v = (bd is Map) ? bd[key] : null;
    return v is List
        ? v.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];
  }

  List<Map<String, dynamic>> _decoList(String key) {
    final bd = data?.raw['budgetData'];
    final deco = (bd is Map) ? bd['tableDeco'] : null;
    final v = (deco is Map) ? deco[key] : null;
    return v is List
        ? v.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];
  }

  @override
  Widget build(BuildContext context) {
    final s = SalaSummary.from(data);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _cateringCard(s),
        const SizedBox(height: 16),
        _menuAddonsCard(s),
        const SizedBox(height: 16),
        _tableDecoCard(s),
        const SizedBox(height: 16),
        _summaryCard(s),
      ],
    );
  }

  Widget _cateringCard(SalaSummary s) {
    return _card(
      title: 'Catering',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BudgetNumberField(
            key: const ValueKey('pricePerPerson'),
            label: 'Cena za osobę',
            suffix: 'zł',
            initial: s.pricePerPerson,
            onSaved: service.setPricePerPerson,
          ),
          const SizedBox(height: 12),
          BudgetNumberField(
            key: const ValueKey('venueMinGuests'),
            label: 'Minimalna liczba osób (próg sali)',
            suffix: 'os.',
            integer: true,
            initial: s.venueMinGuests,
            onSaved: service.setVenueMinGuests,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _infoRow('Goście przy stołach', '${s.seated}'),
                _infoRow('Goście wirtualni (do progu)',
                    '${s.virtualGuests.round()}'),
                _infoRow('Koszt gości wirtualnych', formatPlnZl(s.virtualCost)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.accent,
            title: Text('Uwzględnij gości wirtualnych w obliczeniach',
                style: GoogleFonts.inter(fontSize: 13)),
            value: s.includeVirtual,
            onChanged: service.setIncludeVirtual,
          ),
        ],
      ),
    );
  }

  Widget _menuAddonsCard(SalaSummary s) {
    final addons = _menuAddons;
    return _card(
      title: 'Dodatki do menu (per osoba)',
      trailing: _addButton(() => service.addMenuAddon()),
      child: Column(
        children: [
          if (addons.isEmpty)
            _emptyHint('Brak dodatków. Dodaj przyciskiem +.')
          else
            for (final a in addons)
              _AddonRow(
                key: ValueKey('menu-${a['id']}'),
                name: (a['name'] as String?) ?? '',
                amount: _d(a['pricePerPerson']),
                amountSuffix: 'zł/os.',
                lineTotal: _d(a['pricePerPerson']) * s.effectiveGuestCount,
                onNameSaved: (v) =>
                    service.updateMenuAddon(_id(a), name: v),
                onAmountSaved: (v) =>
                    service.updateMenuAddon(_id(a), pricePerPerson: v),
                onDelete: () => service.deleteMenuAddon(_id(a)),
              ),
          if (addons.isNotEmpty) ...[
            const Divider(height: 20),
            _infoRow('Liczba osób do przeliczeń',
                '${s.effectiveGuestCount.round()}'),
            _infoRow('Łącznie dodatki do menu',
                formatPlnZl(s.menuAddonsTotal),
                bold: true),
          ],
        ],
      ),
    );
  }

  Widget _tableDecoCard(SalaSummary s) {
    final honor = _honorAddons;
    final regular = _regularAddons;
    return _card(
      title: 'Dekoracje stołów (per stolik)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _subHeader('⭐ Stół Pary Młodej', () => service.addTableDeco('honor')),
          if (honor.isEmpty)
            _emptyHint('Brak dekoracji stołu Pary Młodej.')
          else
            for (final a in honor)
              _AddonRow(
                key: ValueKey('honor-${a['id']}'),
                name: (a['name'] as String?) ?? '',
                amount: _d(a['price']),
                amountSuffix: 'zł',
                onNameSaved: (v) =>
                    service.updateTableDeco('honor', _id(a), name: v),
                onAmountSaved: (v) =>
                    service.updateTableDeco('honor', _id(a), value: v),
                onDelete: () => service.deleteTableDeco('honor', _id(a)),
              ),
          const SizedBox(height: 12),
          _subHeader('Pozostałe stoły (×${s.regularTableCount})',
              () => service.addTableDeco('regular')),
          if (regular.isEmpty)
            _emptyHint('Brak dekoracji pozostałych stołów.')
          else
            for (final a in regular)
              _AddonRow(
                key: ValueKey('regular-${a['id']}'),
                name: (a['name'] as String?) ?? '',
                amount: _d(a['pricePerTable']),
                amountSuffix: 'zł/stół',
                lineTotal: _d(a['pricePerTable']) * s.regularTableCount,
                onNameSaved: (v) =>
                    service.updateTableDeco('regular', _id(a), name: v),
                onAmountSaved: (v) =>
                    service.updateTableDeco('regular', _id(a), value: v),
                onDelete: () => service.deleteTableDeco('regular', _id(a)),
              ),
          const Divider(height: 20),
          _infoRow('Dekoracje stołu Pary Młodej',
              formatPlnZl(s.honorDecoTotal)),
          _infoRow('Dekoracje pozostałych stołów',
              formatPlnZl(s.regularDecoTotal)),
          _infoRow('Łącznie dekoracje', formatPlnZl(s.tableDecoTotal),
              bold: true),
        ],
      ),
    );
  }

  Widget _summaryCard(SalaSummary s) {
    return _card(
      title: 'Podsumowanie kosztów sali',
      child: Column(
        children: [
          _infoRow('Catering bazowy (${s.guestCount} os.)',
              formatPlnZl(s.cateringBase)),
          _infoRow('Goście wirtualni', formatPlnZl(s.virtualCost)),
          _infoRow('Dodatki do menu', formatPlnZl(s.menuAddonsTotal)),
          _infoRow('Dekoracje stołów', formatPlnZl(s.tableDecoTotal)),
          const Divider(height: 20),
          _infoRow('Razem sala / catering', formatPlnZl(s.cateringTotal),
              bold: true, big: true),
        ],
      ),
    );
  }

  // ── Pomocnicze widgety ──

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
                child: Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
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

  Widget _addButton(VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: const Icon(Icons.add_circle_outline),
      color: AppColors.accent,
      tooltip: 'Dodaj',
    );
  }

  Widget _subHeader(String text, VoidCallback onAdd) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
          InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.add, size: 20, color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyHint(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(text,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight)),
      );

  Widget _infoRow(String label, String value,
      {bool bold = false, bool big = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: big ? 14 : 13,
                    color: bold ? AppColors.text : AppColors.textLight,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
          ),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: big ? 17 : 14,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: bold ? AppColors.accent : AppColors.text)),
        ],
      ),
    );
  }

  static double _d(dynamic v) => v is num ? v.toDouble() : 0.0;
  static int _id(Map<String, dynamic> m) => (m['id'] as num?)?.toInt() ?? 0;
}

/// Wiersz dodatku: nazwa + kwota + (opcjonalny) wynik linii + usuń.
class _AddonRow extends StatelessWidget {
  const _AddonRow({
    super.key,
    required this.name,
    required this.amount,
    required this.amountSuffix,
    required this.onNameSaved,
    required this.onAmountSaved,
    required this.onDelete,
    this.lineTotal,
  });

  final String name;
  final double amount;
  final String amountSuffix;
  final double? lineTotal;
  final ValueChanged<String> onNameSaved;
  final ValueChanged<num> onAmountSaved;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: BudgetTextField(
                  hint: 'Nazwa',
                  initial: name,
                  onSaved: onNameSaved,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: BudgetNumberField(
                  suffix: amountSuffix,
                  initial: amount,
                  compact: true,
                  onSaved: onAmountSaved,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.close, size: 18),
                color: const Color(0xFFC0392B),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (lineTotal != null && lineTotal! > 0)
            Padding(
              padding: const EdgeInsets.only(right: 40, top: 2),
              child: Text(
                '= ${formatPlnZl(lineTotal!)}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
