import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/guest.dart';
import '../../models/guest_summary.dart';
import '../../models/wedding_data.dart';

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
            hintText: '🔍 Szukaj po nazwisku…',
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
        Text('Wyświetlono ${rows.length} z ${guests.length} gości',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight)),
        const SizedBox(height: 8),
        _table(rows, vehicles, hotels, tables, rsvp),
      ],
    );
  }

  Widget _aggregates(GuestSummaryStats s) {
    final menuItems = s.menu.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final dietItems = s.diet.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _aggCard('🍽 Menu (co je)', [
          for (final e in menuItems) (e.key, e.value),
          if (s.noMenu > 0) ('Bez wyboru menu', s.noMenu),
        ]),
        _aggCard('🥗 Diety', [
          for (final e in dietItems) (e.key, e.value),
        ]),
        _aggCard('🚌 Transport', [
          ('Własny', s.transOwn),
          ('Zorganizowany', s.transOrg),
          ('Bez transportu', s.transNone),
        ]),
        _aggCard('🏨 Nocleg', [
          ('Potrzebuje', s.accomNeeds),
          ('Przypisani do hotelu', s.accomAssigned),
        ]),
        _aggCard('✉ Potwierdzenia', [
          ('Przyjdzie', s.attending),
          ('Nie przyjdzie', s.notAttending),
          ('Brak odpowiedzi', s.noRsvp),
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
            Text('Brak danych',
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
                    Text('$n×',
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
          columns: const [
            DataColumn(label: Text('Imię i nazwisko')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Z kim')),
            DataColumn(label: Text('Menu')),
            DataColumn(label: Text('Dieta / alergie')),
            DataColumn(label: Text('Transport')),
            DataColumn(label: Text('Nocleg')),
            DataColumn(label: Text('Stolik')),
          ],
          rows: [
            for (final g in rows)
              DataRow(cells: [
                DataCell(Text(g.fullName.isEmpty ? '(bez imienia)' : g.fullName)),
                DataCell(Text(GuestSummary.rsvpLabel(
                    GuestSummary.rsvpStatus(g.id, rsvp)))),
                DataCell(Text(GuestSummary.companion(g))),
                DataCell(Text(g.menuChoice.isEmpty ? '—' : g.menuChoice)),
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
