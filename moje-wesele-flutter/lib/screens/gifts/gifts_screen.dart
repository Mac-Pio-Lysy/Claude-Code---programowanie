import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/gift.dart';
import '../../models/guest.dart';
import '../../models/wedding_data.dart';
import '../../navigation/app_sections.dart';
import '../../onboarding/tour_tab_sync.dart';
import '../../services/firestore_service.dart';
import '../../services/gift_service.dart';
import '../../utils/format.dart';
import '../budget/budget_fields.dart';

/// Sekcja „Prezenty" — otrzymane, upominki dla gości, propozycje (lista życzeń).
class GiftsScreen extends StatelessWidget {
  GiftsScreen({
    super.key,
    required this.data,
    required FirestoreService firestore,
  }) : service = GiftService(firestore: firestore);

  final WeddingData? data;
  final GiftService service;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: TourTabSync(
        section: AppSection.gifts,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prezenty',
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
                const SizedBox(height: 4),
                Container(
                  width: 44,
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(
                        colors: AppColors.dividerGradient),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textLight,
            indicatorColor: AppColors.accent,
            dividerColor: const Color(0xFFE2EAF7),
            labelStyle:
                GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'Otrzymane'),
              Tab(text: 'Dla gości'),
              Tab(text: 'Propozycje'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ReceivedTab(data: data, service: service),
                _ForGuestsTab(data: data, service: service),
                _ProposalsTab(data: data, service: service),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}

// ── PREZENTY OTRZYMANE ──────────────────────────────────────────────────

class _ReceivedTab extends StatelessWidget {
  const _ReceivedTab({required this.data, required this.service});
  final WeddingData? data;
  final GiftService service;

  List<Gift> get _gifts => [
        for (final e in data?.raw['gifts'] ?? const [])
          if (e is Map) Gift(Map<String, dynamic>.from(e)),
      ];

  @override
  Widget build(BuildContext context) {
    final gifts = _gifts;
    final totalValue =
        gifts.fold<double>(0, (s, g) => s + (g.value ?? 0));
    final thanked = gifts.where((g) => g.thanked).length;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            children: [
              _summaryCard([
                ('${gifts.length}', 'Prezentów'),
                (formatPlnZl(totalValue), 'Łączna wartość'),
                ('$thanked', 'Podziękowano'),
              ]),
              const SizedBox(height: 12),
              for (final g in gifts)
                _giftCard(g),
            ],
          ),
        ),
        _addBar('Dodaj prezent', () => service.addGift()),
      ],
    );
  }

  Widget _giftCard(Gift g) {
    final id = g.id ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: g.thanked ? const Color(0xFFBBF7D0) : const Color(0xFFE2EAF7)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: BudgetTextField(
                  key: ValueKey('gift-from-$id'),
                  initial: g.from,
                  hint: 'Od kogo…',
                  onSaved: (v) => service.updateGift(id, from: v),
                ),
              ),
              IconButton(
                onPressed: () => service.deleteGift(id),
                icon: const Icon(Icons.delete_outline, size: 18),
                color: const Color(0xFFC0392B),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
          BudgetTextField(
            key: ValueKey('gift-desc-$id'),
            initial: g.description,
            hint: 'Opis prezentu…',
            onSaved: (v) => service.updateGift(id, description: v),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: BudgetNumberField(
                  key: ValueKey('gift-val-$id'),
                  initial: g.value ?? 0,
                  suffix: 'zł',
                  compact: true,
                  onSaved: (v) => v == 0
                      ? service.updateGift(id, clearValue: true)
                      : service.updateGift(id, value: v),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  Checkbox(
                    value: g.thanked,
                    activeColor: const Color(0xFF059669),
                    onChanged: (v) =>
                        service.updateGift(id, thanked: v ?? false),
                  ),
                  Text('Podziękowano',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.text)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── UPOMINKI DLA GOŚCI ──────────────────────────────────────────────────

class _ForGuestsTab extends StatelessWidget {
  const _ForGuestsTab({required this.data, required this.service});
  final WeddingData? data;
  final GiftService service;

  List<GiftForGuest> get _items => [
        for (final e in data?.raw['giftsForGuests'] ?? const [])
          if (e is Map) GiftForGuest(Map<String, dynamic>.from(e)),
      ];

  List<Guest> get _guests => [
        for (final e in data?.guests ?? const [])
          if (e is Map) Guest(Map<String, dynamic>.from(e)),
      ];

  String get _basis {
    final b = data?.raw['giftForGuestsBasis'];
    return (b == 'real' || b == 'realvirtual') ? b as String : '';
  }

  int get _virtualGuests {
    final bd = data?.raw['budgetData'];
    final venueMin = (bd is Map ? (bd['venueMinGuests'] as num?)?.toInt() : 0) ?? 0;
    final seated =
        _guests.where((g) => g.raw['tableId'] != null).length;
    return max(0, venueMin - seated);
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final guests = _guests;
    final basis = _basis;
    final personCount = basis == 'real'
        ? guests.length
        : basis == 'realvirtual'
            ? guests.length + _virtualGuests
            : 0;
    double effQty(GiftForGuest it) =>
        basis.isNotEmpty ? personCount.toDouble() : it.qty;

    var grand = 0.0;
    var count = 0;
    for (final it in items) {
      grand += effQty(it) * it.cost;
      count++;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        _summaryCard([
          ('$count', 'Upominków'),
          (formatPlnZl(grand),
              'Łączny koszt${basis.isNotEmpty ? ' ($personCount os.)' : ''}'),
        ]),
        const SizedBox(height: 12),
        _basisCard(basis, personCount),
        const SizedBox(height: 12),
        for (final cat in GiftGuestCat.all)
          _categorySection(cat, items.where((it) => it.category == cat.key).toList(),
              guests, basis, effQty),
      ],
    );
  }

  Widget _basisCard(String basis, int personCount) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Column(
        children: [
          _basisRow('Przelicz na gości rzeczywistych', 'real', basis,
              personCount),
          _basisRow('Przelicz na rzeczywistych + wirtualnych', 'realvirtual',
              basis, personCount),
        ],
      ),
    );
  }

  Widget _basisRow(String label, String which, String basis, int personCount) {
    final checked = basis == which;
    return Row(
      children: [
        Checkbox(
          value: checked,
          activeColor: AppColors.accent,
          onChanged: (v) => service.setGiftForGuestsBasis(which, v ?? false),
        ),
        Expanded(
          child: Text(
            checked ? '$label ($personCount os.)' : label,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.text),
          ),
        ),
      ],
    );
  }

  Widget _categorySection(GiftGuestCat cat, List<GiftForGuest> items,
      List<Guest> guests, String basis, double Function(GiftForGuest) effQty) {
    final catTotal = items.fold<double>(0, (s, it) => s + effQty(it) * it.cost);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2EAF7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('${cat.icon} ${cat.label}',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text)),
                ),
                Text(formatPlnZl(catTotal),
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent)),
                IconButton(
                  onPressed: () => service.addGiftForGuest(cat.key),
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  color: AppColors.accent,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (items.isEmpty)
              Text('Brak upominków.',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textLight))
            else
              for (final it in items)
                _itemRow(it, guests, basis, effQty(it),
                    cat.key == 'distinction'),
          ],
        ),
      ),
    );
  }

  Widget _itemRow(GiftForGuest it, List<Guest> guests, String basis,
      double effQty, bool distinction) {
    final id = it.id ?? 0;
    final lineTotal = effQty * it.cost;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: BudgetTextField(
                  key: ValueKey('gfg-name-$id'),
                  initial: it.name,
                  hint: 'Upominek…',
                  onSaved: (v) => service.updateGiftForGuest(id, name: v),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 56,
                child: basis.isNotEmpty
                    ? _disabledQty(effQty)
                    : BudgetNumberField(
                        key: ValueKey('gfg-qty-$id'),
                        initial: it.qty,
                        integer: true,
                        compact: true,
                        onSaved: (v) =>
                            service.updateGiftForGuest(id, qty: v),
                      ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('×'),
              ),
              SizedBox(
                width: 70,
                child: BudgetNumberField(
                  key: ValueKey('gfg-cost-$id'),
                  initial: it.cost,
                  compact: true,
                  onSaved: (v) => service.updateGiftForGuest(id, cost: v),
                ),
              ),
              IconButton(
                onPressed: () => service.deleteGiftForGuest(id),
                icon: const Icon(Icons.close, size: 18),
                color: const Color(0xFFC0392B),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text('= ${formatPlnZl(lineTotal)}',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent)),
          ),
          if (distinction) _distinctionPicker(it, guests),
        ],
      ),
    );
  }

  Widget _disabledQty(double effQty) => Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFEDF1F8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(effQty.toStringAsFixed(0),
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textLight)),
      );

  Widget _distinctionPicker(GiftForGuest it, List<Guest> guests) {
    final id = it.id ?? 0;
    final byId = {for (final g in guests) g.id: g};
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final gid in it.guestIds)
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(byId[gid]?.fullName ?? 'Gość',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF7C3AED))),
                      InkWell(
                        onTap: () =>
                            service.removeDistinctionGuest(id, gid),
                        child: const Icon(Icons.close,
                            size: 14, color: Color(0xFF7C3AED)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<int>(
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFDCE4F2)),
              ),
            ),
            hint: const Text('+ Dodaj osobę…'),
            items: [
              for (final g in guests)
                DropdownMenuItem(
                    value: g.id,
                    child: Text(g.fullName.isEmpty ? 'Gość' : g.fullName)),
            ],
            onChanged: (v) {
              if (v != null) service.addDistinctionGuest(id, v);
            },
          ),
        ],
      ),
    );
  }
}

// ── PROPOZYCJE / LISTA ŻYCZEŃ ───────────────────────────────────────────

class _ProposalsTab extends StatelessWidget {
  const _ProposalsTab({required this.data, required this.service});
  final WeddingData? data;
  final GiftService service;

  List<GiftProposal> get _items => [
        for (final e in data?.raw['giftProposals'] ?? const [])
          if (e is Map) GiftProposal(Map<String, dynamic>.from(e)),
      ];

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            children: [
              Text(
                'Lista życzeń od Pary Młodej. Zaznaczone propozycje są widoczne dla gości na stronie harmonogramu.',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textLight),
              ),
              const SizedBox(height: 12),
              for (final p in items) _proposalCard(p),
            ],
          ),
        ),
        _addBar('Dodaj propozycję', () => service.addProposal()),
      ],
    );
  }

  Widget _proposalCard(GiftProposal p) {
    final id = p.id ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: p.showToGuests
                ? const Color(0xFFBBF7D0)
                : const Color(0xFFE2EAF7)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: BudgetTextField(
                  key: ValueKey('prop-title-$id'),
                  initial: p.title,
                  hint: 'Tytuł propozycji…',
                  onSaved: (v) => service.updateProposal(id, title: v),
                ),
              ),
              IconButton(
                onPressed: () => service.deleteProposal(id),
                icon: const Icon(Icons.delete_outline, size: 18),
                color: const Color(0xFFC0392B),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
          BudgetTextField(
            key: ValueKey('prop-desc-$id'),
            initial: p.desc,
            hint: 'Opis…',
            onSaved: (v) => service.updateProposal(id, desc: v),
          ),
          const SizedBox(height: 6),
          BudgetTextField(
            key: ValueKey('prop-link-$id'),
            initial: p.link,
            hint: 'Link (https://…)',
            onSaved: (v) => service.updateProposal(id, link: v),
          ),
          Row(
            children: [
              const Icon(Icons.visibility_outlined,
                  size: 16, color: AppColors.textLight),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Pokaż gościom na stronie harmonogramu',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.text)),
              ),
              Switch.adaptive(
                value: p.showToGuests,
                activeThumbColor: AppColors.accent,
                onChanged: (v) =>
                    service.updateProposal(id, showToGuests: v),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Wspólne ──

Widget _summaryCard(List<(String, String)> stats) {
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
    child: Row(
      children: [
        for (final (value, label) in stats)
          Expanded(
            child: Column(
              children: [
                Text(value,
                    style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent)),
                Text(label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textLight)),
              ],
            ),
          ),
      ],
    ),
  );
}

Widget _addBar(String label, VoidCallback onPressed) {
  return SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.add),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle:
                GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    ),
  );
}
