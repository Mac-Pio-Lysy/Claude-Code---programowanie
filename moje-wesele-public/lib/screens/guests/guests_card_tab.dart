import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../layout/responsive.dart';
import '../../models/guest.dart';
import '../../models/wedding_data.dart';
import '../../services/guest_service.dart';
import '../budget/budget_fields.dart';
import 'guest_filters.dart';
import 'guest_form_sheet.dart';

/// Podzakładka „Kartoteka" — rozszerzony widok gości (menu, preferencje,
/// alergie, notatki) w trybie listy lub siatki 3 kolumn.
class GuestsCardTab extends StatefulWidget {
  const GuestsCardTab({super.key, required this.data, required this.service});

  final WeddingData? data;
  final GuestService service;

  @override
  State<GuestsCardTab> createState() => _GuestsCardTabState();
}

class _GuestsCardTabState extends State<GuestsCardTab> {
  bool _grid = false;
  bool _filtersVisible = false;
  GuestFilter _filter = const GuestFilter();

  List<Guest> get _guests => [
        for (final e in widget.data?.guests ?? const [])
          if (e is Map) Guest(Map<String, dynamic>.from(e)),
      ];

  List<String> get _menuOptions {
    final cfg = widget.data?.raw['appConfig'];
    final opts = (cfg is Map) ? cfg['menuOptions'] : null;
    if (opts is List) {
      final list = opts.whereType<String>().toList();
      if (list.isNotEmpty) return list;
    }
    return GuestOptions.defaultMenuOptions;
  }

  Future<void> _addGuest() async {
    final draft = await showModalBottomSheet<GuestDraft>(
      context: context,
      constraints: const BoxConstraints(maxWidth: kSheetMaxWidth),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GuestFormSheet(menuOptions: _menuOptions),
    );
    if (draft == null) return;
    await widget.service.addGuest(draft);
  }

  @override
  Widget build(BuildContext context) {
    final guests = _guests;
    final filtered = filterGuests(guests, _filter);
    final menus = _menuOptions;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                    filtered.length == guests.length
                        ? '${guests.length} gości'
                        : '${filtered.length} z ${guests.length} gości',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppColors.textLight)),
              ),
              IconButton(
                tooltip: _filtersVisible ? 'Ukryj filtry' : 'Pokaż filtry',
                onPressed: () =>
                    setState(() => _filtersVisible = !_filtersVisible),
                icon: Icon(Icons.filter_list,
                    color:
                        _filtersVisible ? AppColors.accent : AppColors.textLight),
              ),
              IconButton(
                tooltip: 'Lista',
                onPressed: () => setState(() => _grid = false),
                icon: Icon(Icons.view_list,
                    color: _grid ? AppColors.textLight : AppColors.accent),
              ),
              IconButton(
                tooltip: 'Siatka',
                onPressed: () => setState(() => _grid = true),
                icon: Icon(Icons.grid_view,
                    color: _grid ? AppColors.accent : AppColors.textLight),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          curve: Curves.easeInOut,
          child: _filtersVisible
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: GuestFilterControls(
                    filter: _filter,
                    onChanged: (f) => setState(() => _filter = f),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                      guests.isEmpty
                          ? 'Brak gości.'
                          : 'Brak gości spełniających kryteria.',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.textLight)),
                )
              : _grid
                  ? _gridView(filtered, menus)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                      children: [
                        for (final g in filtered) _card(g, menus),
                      ],
                    ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addGuest,
                icon: const Icon(Icons.add),
                label: const Text('Dodaj gościa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _gridView(List<Guest> guests, List<String> menus) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = gridColumns(context, phone: 2, tablet: 3, wide: 4)
            .clamp(2, constraints.maxWidth >= 720 ? 4 : 2);
        return GridView.count(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          crossAxisCount: cols,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.72,
          children: [for (final g in guests) _card(g, menus, compact: true)],
        );
      },
    );
  }

  Widget _card(Guest g, List<String> menus, {bool compact = false}) {
    final id = g.id ?? 0;
    final menu = menus.contains(g.menuChoice) ? g.menuChoice : '';
    return Container(
      margin: compact ? EdgeInsets.zero : const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: SingleChildScrollView(
        physics: compact ? null : const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.accent,
                  child: Text(g.initials.toUpperCase(),
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(g.fullName.isEmpty ? '(bez imienia)' : g.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            // Powiązanie: kogo zaprosił / przez kogo został zaproszony (#4).
            ..._relationLines(g),
            const SizedBox(height: 8),
            _label('Menu'),
            DropdownButtonFormField<String>(
              initialValue: menu,
              isExpanded: true,
              decoration: _dec(),
              items: [
                const DropdownMenuItem(value: '', child: Text('— brak —')),
                for (final m in menus)
                  DropdownMenuItem(value: m, child: Text(m)),
              ],
              onChanged: (v) =>
                  widget.service.setField(id, 'menuChoice', v ?? ''),
            ),
            const SizedBox(height: 8),
            _label('Preferencje'),
            BudgetTextField(
              key: ValueKey('pref-$id'),
              initial: (g.raw['preferences'] as String?) ?? '',
              hint: 'np. miejsce przy rodzinie',
              onSaved: (v) => widget.service.setField(id, 'preferences', v),
            ),
            const SizedBox(height: 8),
            _label('Alergie'),
            BudgetTextField(
              key: ValueKey('alerg-$id'),
              initial: (g.raw['allergies'] as String?) ?? '',
              hint: 'np. orzechy, gluten',
              onSaved: (v) => widget.service.setField(id, 'allergies', v),
            ),
            const SizedBox(height: 8),
            _label('Notatki'),
            BudgetTextField(
              key: ValueKey('notes-$id'),
              initial: (g.raw['cardNotes'] as String?) ?? '',
              hint: 'Dodatkowe informacje…',
              onSaved: (v) => widget.service.setField(id, 'cardNotes', v),
            ),
          ],
        ),
      ),
    );
  }

  /// Wiersze powiązania w kartotece: „towarzyszy X (Para)" u osoby
  /// towarzyszącej oraz „przychodzi z Y" u zapraszającego.
  List<Widget> _relationLines(Guest g) {
    final all = _guests;
    final lines = <Widget>[];

    if (g.companionOfId != null) {
      final inviter =
          all.where((x) => x.id == g.companionOfId).firstOrNull;
      final relation = g.relationType == null
          ? ''
          : ' (${CompanionRelation.label(g.relationType)})';
      lines.add(_relationChip(
        '↳ towarzyszy: ${inviter?.fullName ?? 'nieznany gość'}$relation',
        AppColors.accent,
      ));
    }

    final own = all.where((x) => x.companionOfId == g.id).toList();
    for (final c in own) {
      lines.add(_relationChip(
        '👥 przychodzi z: '
        '${c.namePending ? 'osoba towarzysząca (imię do potwierdzenia)' : c.fullName}',
        const Color(0xFF475569),
      ));
    }

    if (g.namePending) {
      lines.add(_relationChip(
          '✎ imię do potwierdzenia', const Color(0xFFB45309)));
    }

    return lines.isEmpty
        ? const []
        : [const SizedBox(height: 6), ...lines];
  }

  Widget _relationChip(String text, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600, color: color),
        ),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4, left: 2),
        child: Text(text,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textLight)),
      );

  InputDecoration _dec() => InputDecoration(
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF8FAFF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
