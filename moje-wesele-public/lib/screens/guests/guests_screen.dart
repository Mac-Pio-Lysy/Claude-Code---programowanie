import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../layout/responsive.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_text.dart';
import '../../models/guest.dart';
import '../../models/wedding_data.dart';
import '../../services/firestore_service.dart';
import '../../services/guest_service.dart';
import 'guest_filters.dart';
import 'guest_form_sheet.dart';

/// Sekcja „Goście" — lista z Firestore, filtry, dodawanie/edycja/usuwanie.
class GuestsScreen extends StatefulWidget {
  GuestsScreen({
    super.key,
    required this.data,
    required FirestoreService firestore,
    this.embedded = false,
  }) : service = GuestService(firestore: firestore);

  final WeddingData? data;
  final GuestService service;

  /// Gdy true, pomija własny nagłówek „Goście" (używane w zakładkach sekcji).
  final bool embedded;

  @override
  State<GuestsScreen> createState() => _GuestsScreenState();
}

class _GuestsScreenState extends State<GuestsScreen> {
  GuestFilter _filter = const GuestFilter();
  bool _filtersVisible = false;

  List<String> get _menuOptions {
    final cfg = widget.data?.raw['appConfig'];
    final opts = (cfg is Map) ? cfg['menuOptions'] : null;
    if (opts is List) {
      final list = opts.whereType<String>().toList();
      if (list.isNotEmpty) return list;
    }
    return GuestOptions.defaultMenuOptions;
  }

  Map<int, String> get _tableNames {
    final res = <int, String>{};
    for (final t in widget.data?.tables ?? const []) {
      if (t is Map) {
        final id = (t['id'] as num?)?.toInt();
        if (id != null) res[id] = (t['name'] as String?) ?? AppText.t.tables_defaultName;
      }
    }
    return res;
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Ile osób ma już kategorię Pary Młodej (bez gościa właśnie edytowanego).
  int _coupleTaken({Guest? except}) => GuestService.coupleCount(
        [
          for (final e in widget.data?.guests ?? const [])
            if (e is Map) Map<String, dynamic>.from(e),
        ],
        exceptId: except?.id,
      );

  Future<GuestDraft?> _showForm({Guest? existing}) {
    return showModalBottomSheet<GuestDraft>(
      context: context,
      constraints: const BoxConstraints(maxWidth: kSheetMaxWidth),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GuestFormSheet(
        existing: existing,
        menuOptions: _menuOptions,
        coupleTaken: _coupleTaken(except: existing),
      ),
    );
  }

  Future<void> _addGuest() async {
    // Tłumaczenia pobieramy PRZED `await` — po nim `context` może już nie
    // należeć do zamontowanego widgetu.
    final t = AppLocalizations.of(context);
    final draft = await _showForm();
    if (draft == null) return;
    try {
      await widget.service.addGuest(draft);
      _toast(t.guests_addedToast(draft.firstName));
    } on GuestRuleException catch (e) {
      // Złamana reguła listy gości ma gotowy komunikat — pokazujemy go wprost,
      // bez „Błąd zapisu", bo to nie awaria tylko świadoma blokada.
      _toast(e.message);
    } catch (e) {
      _toast(t.common_saveErrorToast('$e'));
    }
  }

  Future<void> _editGuest(Guest guest) async {
    final t = AppLocalizations.of(context);
    final draft = await _showForm(existing: guest);
    if (draft == null || guest.id == null) return;
    try {
      await widget.service.updateGuest(guest.id!, draft);
      _toast(t.common_savedToast);
    } on GuestRuleException catch (e) {
      _toast(e.message);
    } catch (e) {
      _toast(t.common_saveErrorToast('$e'));
    }
  }

  Future<void> _deleteGuest(Guest guest) async {
    final t = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).guests_deleteTitle),
        content: Text(AppLocalizations.of(context)
            .guests_deleteBody(guest.fullName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).common_cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC0392B)),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context).common_delete),
          ),
        ],
      ),
    );
    if (confirmed != true || guest.id == null) return;
    try {
      await widget.service.deleteGuest(guest.id!);
      _toast(t.guests_deletedToast);
    } catch (e) {
      _toast(t.common_deleteErrorToast('$e'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final guests = [
      for (final e in widget.data?.guests ?? const [])
        if (e is Map) Guest(Map<String, dynamic>.from(e)),
    ];
    final filtered = _withCompanionsGrouped(filterGuests(guests, _filter));
    final tableNames = _tableNames;
    // Podpowiedzi powiązań: kto kogo zaprosił (po ID, na pełnej liście — także
    // gdy zapraszający wypadł z filtra).
    final byId = {for (final g in guests) if (g.id != null) g.id!: g};

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.embedded) ...[
            Text(
              t.guests_title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 44,
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: const LinearGradient(colors: AppColors.dividerGradient),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  filtered.length == guests.length
                      ? t.common_guestCount(guests.length)
                      : t.guests_countOf(filtered.length, guests.length),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textLight,
                  ),
                ),
              ),
              _filtersToggle(),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _addGuest,
                icon: const Icon(Icons.add, size: 18),
                label: Text(t.guests_addButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  textStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            curve: Curves.easeInOut,
            child: _filtersVisible
                ? GuestFilterControls(
                    filter: _filter,
                    onChanged: (f) => setState(() => _filter = f),
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? _emptyState()
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final g = filtered[i];
                      return _GuestCard(
                        key: ValueKey(g.id),
                        guest: g,
                        tableName:
                            g.tableId != null ? tableNames[g.tableId] : null,
                        inviter: g.companionOfId != null
                            ? byId[g.companionOfId]
                            : null,
                        companions: [
                          for (final c in guests)
                            if (c.companionOfId == g.id) c,
                        ],
                        onEdit: () => _editGuest(g),
                        onDelete: () => _deleteGuest(g),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Układa listę tak, żeby osoba towarzysząca stała ZARAZ POD zapraszającym.
  ///
  /// Dzięki temu na pierwszy rzut oka widać, kto z kim przychodzi, bez szukania
  /// po całej liście. Osoba towarzysząca, której zapraszający wypadł z filtra,
  /// zostaje na swoim miejscu jako samodzielna pozycja — inaczej zniknęłaby
  /// z widoku mimo pasowania do filtra.
  List<Guest> _withCompanionsGrouped(List<Guest> filtered) {
    final ids = {for (final g in filtered) g.id};
    final companionsByInviter = <int, List<Guest>>{};
    for (final g in filtered) {
      final inviterId = g.companionOfId;
      if (inviterId != null && ids.contains(inviterId)) {
        companionsByInviter.putIfAbsent(inviterId, () => []).add(g);
      }
    }
    if (companionsByInviter.isEmpty) return filtered;

    final grouped = <Guest>[];
    for (final g in filtered) {
      // Towarzyszącą wstawiamy przy zapraszającym, więc pomijamy ją tutaj.
      final inviterId = g.companionOfId;
      if (inviterId != null && ids.contains(inviterId)) continue;
      grouped.add(g);
      final own = companionsByInviter[g.id];
      if (own != null) grouped.addAll(own);
    }
    return grouped;
  }

  /// Mała strzałka obok „Dodaj gościa" — chowa/pokazuje wiersze filtrów,
  /// dając więcej miejsca na listę.
  Widget _filtersToggle() {
    return Tooltip(
      message: _filtersVisible
          ? AppLocalizations.of(context).guests_hideFilters
          : AppLocalizations.of(context).guests_showFilters,
      child: Material(
        color: _filtersVisible ? const Color(0xFFEEF3FF) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _filtersVisible = !_filtersVisible),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDCE4F2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.filter_list,
                    size: 18, color: AppColors.accent),
                AnimatedRotation(
                  turns: _filtersVisible ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.expand_more,
                      size: 18, color: AppColors.accent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline, size: 48, color: AppColors.accent2),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).guests_emptyFiltered,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

}

/// Rozwijana karta gościa.
class _GuestCard extends StatefulWidget {
  const _GuestCard({
    super.key,
    required this.guest,
    required this.tableName,
    required this.onEdit,
    required this.onDelete,
    this.inviter,
    this.companions = const [],
  });

  final Guest guest;
  final String? tableName;

  /// Gość, który zaprosił tę osobę (gdy to osoba towarzysząca).
  final Guest? inviter;

  /// Osoby towarzyszące zaproszone przez tego gościa.
  final List<Guest> companions;

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_GuestCard> createState() => _GuestCardState();
}

class _GuestCardState extends State<_GuestCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final g = widget.guest;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: g.isAssigned ? const Color(0xFFBBF7D0) : const Color(0xFFE2EAF7),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _Avatar(initials: g.initials),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g.fullName.isEmpty ? '(bez imienia)' : g.fullName,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _badges(g),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.keyboard_arrow_down,
                        color: AppColors.textLight),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) _details(g),
        ],
      ),
    );
  }

  List<Widget> _badges(Guest g) {
    return [
      if (g.category.isNotEmpty)
        _Badge(
            // Kategoria Pary Młodej ma etykietę zależną od typu uroczystości;
            // pozostałe kategorie wyświetlamy dosłownie.
            GuestOptions.categoryLabel(g.category),
            const Color(0xFFEEF3FF),
            AppColors.accent),
      if (widget.tableName != null)
        _Badge(AppText.t.guests_badgeSeatedAt(widget.tableName!), const Color(0xFFECFDF5),
            const Color(0xFF059669))
      else
        _Badge(AppText.t.guests_badgeNoTable, const Color(0xFFFFF7ED),
            const Color(0xFFB45309)),
      if (g.invitedBy == 'groom')
        _Badge(GuestOptions.invitedByLabel('groom'), const Color(0xFFEFF6FF),
            const Color(0xFF1D4ED8)),
      if (g.invitedBy == 'bride')
        _Badge(GuestOptions.invitedByLabel('bride'), const Color(0xFFFDF2F8),
            const Color(0xFFDB2777)),
      if (g.witness == 'witness_groom')
        _Badge('● ${GuestOptions.witnessLabel('witness_groom')}',
            const Color(0xFFEFF6FF), const Color(0xFF1D4ED8)),
      if (g.witness == 'witness_bride')
        _Badge('● ${GuestOptions.witnessLabel('witness_bride')}',
            const Color(0xFFFDF2F8), const Color(0xFFDB2777)),
      if (g.isChild)
        _Badge(AppText.t.guests_badgeChild, const Color(0xFFECFEFF),
            const Color(0xFF0E7490)),
      if (g.needsAccommodation)
        _Badge(AppText.t.guests_badgeAccommodation, const Color(0xFFF5F3FF),
            const Color(0xFF7C3AED)),
      // Stary „+1" bez własnego rekordu (dane sprzed powiązań).
      if (g.hasCompanion)
        _Badge(
          '👥 +1${g.companionName.isNotEmpty ? ' ${g.companionName}' : ''}',
          const Color(0xFFF1F5F9),
          const Color(0xFF475569),
        ),
      // Powiązane osoby towarzyszące — widać, kto z kim przychodzi (#4).
      for (final c in widget.companions)
        _Badge(
          '👥 z: ${c.namePending ? 'osoba towarzysząca' : c.fullName}',
          const Color(0xFFF1F5F9),
          const Color(0xFF475569),
        ),
      // Ten gość JEST czyjąś osobą towarzyszącą.
      if (widget.inviter != null)
        _Badge(
          AppText.t.guests_companionOfLine(widget.inviter!.fullName),
          const Color(0xFFEEF3FF),
          AppColors.accent,
        ),
      if (g.isCompanion && g.relationType != null)
        _Badge(
          CompanionRelation.label(g.relationType),
          const Color(0xFFF5F3FF),
          const Color(0xFF7C3AED),
        ),
      if (g.namePending)
        _Badge(AppText.t.guests_namePendingBadge, const Color(0xFFFFF7ED),
            const Color(0xFFB45309)),
    ];
  }

  Widget _details(Guest g) {
    final t = AppText.t;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 16),
          _detailRow(t.guests_formGender, GuestOptions.genderLabel(g.gender)),
          _detailRow(t.guests_detailInvitedBy,
              GuestOptions.invitedByLabel(g.invitedBy)),
          _detailRow(t.guests_formRole, GuestOptions.witnessLabel(g.witness)),
          if (g.menuChoice.isNotEmpty)
            _detailRow(t.guests_formDiet, GuestOptions.menuLabel(g.menuChoice)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edytuj'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(AppText.t.common_delete),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC0392B),
                    side: const BorderSide(color: Color(0xFFE9A8A8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style:
                  GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent, AppColors.accent2],
        ),
      ),
      child: Text(
        initials.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, this.bg, this.fg);
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
