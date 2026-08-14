import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/guest.dart';
import '../../models/guest_summary.dart';
import '../../models/wedding_data.dart';
import '../../l10n/app_text.dart';

/// Podzakładka „Podsumowanie" — zbiorcza tabela gości + agregaty.
class GuestsSummaryTab extends StatefulWidget {
  const GuestsSummaryTab({super.key, required this.data});

  final WeddingData? data;

  @override
  State<GuestsSummaryTab> createState() => _GuestsSummaryTabState();
}

class _GuestsSummaryTabState extends State<GuestsSummaryTab> {
  String _search = '';

  List<Guest> get _guests => [
        for (final e in widget.data?.guests ?? const [])
          if (e is Map) Guest(Map<String, dynamic>.from(e)),
      ];

  List<dynamic> _list(String key) {
    final v = widget.data?.raw[key];
    return v is List ? v : const [];
  }

  @override
  Widget build(BuildContext context) {
    final guests = _guests;
    final vehicles = _list('vehicles');
    final hotels = _list('hotels');
    final tables = widget.data?.tables ?? const [];
    final rsvp = _list('rsvpEntries');

    final stats = GuestSummaryStats.from(guests, vehicles, hotels, rsvp);

    final q = _search.trim().toLowerCase();
    final rows = q.isEmpty
        ? guests
        : guests.where((g) => g.fullName.toLowerCase().contains(q)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      children: [
        _aggregates(stats),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            hintText: '🔍 ${AppText.t.common_search}',
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFDCE4F2)),
            ),
          ),
          onChanged: (v) => setState(() => _search = v),
        ),
        const SizedBox(height: 8),
        Text(AppText.t.guests_shownOf(rows.length, guests.length),
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight)),
        const SizedBox(height: 8),
        _table(rows, vehicles, hotels, tables, rsvp),
      ],
    );
  }

  Widget _aggregates(GuestSummaryStats s) {
    final t = AppText.t;
    final menuItems = s.menu.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final dietItems = s.diet.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final witnessGroom =
        _guests.where((g) => g.witness == 'witness_groom').length;
    final witnessBride =
        _guests.where((g) => g.witness == 'witness_bride').length;
    final witnessTarget = widget.data?.witnessCount ?? 2;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _aggCard(t.guests_summaryWitnesses(witnessTarget), [
          (GuestOptions.witnessLabel('witness_groom'), witnessGroom),
          (GuestOptions.witnessLabel('witness_bride'), witnessBride),
          (t.guests_summaryWitnessesTotal, witnessGroom + witnessBride),
        ]),
        // Karta pojawia się dopiero, gdy ktoś jest oznaczony jako dziecko —
        // wesela bez dzieci nie oglądają pustej rubryki z zerami.
        if (s.children > 0)
          _aggCard(t.guests_summaryChildren, [
            (t.guests_summaryChildrenLabel, s.children),
            (t.guests_summaryAdults, s.adults),
          ]),
        _aggCard(t.guests_summaryMenu, [
          for (final e in menuItems) (GuestOptions.menuLabel(e.key), e.value),
          if (s.noMenu > 0) (t.guests_summaryNoMenu, s.noMenu),
        ]),
        _aggCard(t.guests_summaryDiets, [
          for (final e in dietItems) (e.key, e.value),
        ]),
        _aggCard(t.guests_summaryTransport, [
          (t.guests_summaryTransportOwn, s.transOwn),
          (t.guests_summaryTransportOrganized, s.transOrg),
          (t.guests_summaryTransportNone, s.transNone),
        ]),
        _aggCard(t.guests_summaryAccommodation, [
          (t.guests_summaryAccommodationNeeds, s.accomNeeds),
          (t.guests_summaryAccommodationAssigned, s.accomAssigned),
        ]),
        _aggCard(t.guests_summaryRsvp, [
          (t.guests_rsvpAttending, s.attending),
          (t.guests_rsvpNotAttending, s.notAttending),
          (t.guests_rsvpNoAnswer, s.noRsvp),
        ]),
      ],
    );
  }

  Widget _aggCard(String title, List<(String, int)> items) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text)),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text(AppText.t.common_none,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textLight))
          else
            for (final (label, n) in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(label,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.textLight)),
                    ),
                    Text(AppText.t.guests_menuTimes(n),
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent)),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _table(List<Guest> rows, List<dynamic> vehicles, List<dynamic> hotels,
      List<dynamic> tables, List<dynamic> rsvp) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.text),
          dataTextStyle:
              GoogleFonts.inter(fontSize: 12, color: AppColors.text),
          columns: [
            DataColumn(label: Text(AppText.t.guests_cardFullName)),
            DataColumn(label: Text(AppText.t.guests_cardStatus)),
            DataColumn(label: Text(AppText.t.guests_cardWith)),
            DataColumn(label: Text(AppText.t.guests_cardMenu)),
            DataColumn(label: Text(AppText.t.guests_cardDietAllergies)),
            DataColumn(label: Text(AppText.t.guests_summaryTransport)),
            DataColumn(label: Text(AppText.t.guests_summaryAccommodation)),
            DataColumn(label: Text(AppText.t.guests_cardTable)),
          ],
          rows: [
            for (final g in rows)
              DataRow(cells: [
                // Dziecko oznaczamy ikoną przy nazwisku zamiast dokładać
                // kolumnę — tabela i tak jest szeroka.
                DataCell(Text('${g.isChild ? '🧒 ' : ''}'
                    '${g.fullName.isEmpty ? AppText.t.guests_noName : g.fullName}')),
                DataCell(Text(GuestSummary.rsvpLabel(
                    GuestSummary.rsvpStatus(g.id, rsvp)))),
                DataCell(Text(GuestSummary.companion(g, _guests))),
                DataCell(Text(g.menuChoice.isEmpty
                    ? AppText.t.common_none
                    : GuestOptions.menuLabel(g.menuChoice))),
                DataCell(Text(GuestSummary.dietAllergies(g))),
                DataCell(Text(GuestSummary.transport(g, vehicles).$3)),
                DataCell(Text(GuestSummary.accommodation(g, hotels).$2)),
                DataCell(Text(GuestSummary.tableName(g, tables))),
              ]),
          ],
        ),
      ),
    );
  }
}
