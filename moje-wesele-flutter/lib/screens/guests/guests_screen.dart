import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/guest.dart';
import '../../models/wedding_data.dart';
import '../../services/firestore_service.dart';
import '../../services/guest_service.dart';
import 'guest_form_sheet.dart';

enum _Quick { all, assigned, unassigned, groom, bride }

/// Sekcja „Goście" — lista z Firestore, filtry, dodawanie/edycja/usuwanie.
class GuestsScreen extends StatefulWidget {
  GuestsScreen({
    super.key,
    required this.data,
    required FirestoreService firestore,
  }) : service = GuestService(firestore: firestore);

  final WeddingData? data;
  final GuestService service;

  @override
  State<GuestsScreen> createState() => _GuestsScreenState();
}

class _GuestsScreenState extends State<GuestsScreen> {
  _Quick _quick = _Quick.all;
  String? _category; // null = wszyscy

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
        if (id != null) res[id] = (t['name'] as String?) ?? 'Stół';
      }
    }
    return res;
  }

  bool _matches(Guest g) {
    switch (_quick) {
      case _Quick.assigned:
        if (!g.isAssigned) return false;
      case _Quick.unassigned:
        if (g.isAssigned) return false;
      case _Quick.groom:
        if (g.invitedBy != 'groom') return false;
      case _Quick.bride:
        if (g.invitedBy != 'bride') return false;
      case _Quick.all:
        break;
    }
    if (_category != null && g.category != _category) return false;
    return true;
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<GuestDraft?> _showForm({Guest? existing}) {
    return showModalBottomSheet<GuestDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          GuestFormSheet(existing: existing, menuOptions: _menuOptions),
    );
  }

  Future<void> _addGuest() async {
    final draft = await _showForm();
    if (draft == null) return;
    try {
      await widget.service.addGuest(draft);
      _toast('Dodano gościa: ${draft.firstName}');
    } catch (e) {
      _toast('Błąd zapisu: $e');
    }
  }

  Future<void> _editGuest(Guest guest) async {
    final draft = await _showForm(existing: guest);
    if (draft == null || guest.id == null) return;
    try {
      await widget.service.updateGuest(guest.id!, draft);
      _toast('Zapisano zmiany');
    } catch (e) {
      _toast('Błąd zapisu: $e');
    }
  }

  Future<void> _deleteGuest(Guest guest) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć gościa?'),
        content: Text(
          'Czy na pewno usunąć gościa „${guest.fullName}"? '
          'Zostanie też zwolnione jego miejsce przy stole.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC0392B)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (confirmed != true || guest.id == null) return;
    try {
      await widget.service.deleteGuest(guest.id!);
      _toast('Usunięto gościa');
    } catch (e) {
      _toast('Błąd usuwania: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final guests = [
      for (final e in widget.data?.guests ?? const [])
        if (e is Map) Guest(Map<String, dynamic>.from(e)),
    ];
    final filtered = guests.where(_matches).toList();
    final tableNames = _tableNames;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Goście',
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
          Row(
            children: [
              Expanded(
                child: Text(
                  filtered.length == guests.length
                      ? '${guests.length} ${_guestWord(guests.length)}'
                      : '${filtered.length} z ${guests.length} ${_guestWord(guests.length)}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textLight,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addGuest,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Dodaj gościa'),
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
          _filterRow1(),
          const SizedBox(height: 8),
          _filterRow2(),
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

  Widget _filterRow1() {
    return _ChipRow(
      chips: [
        _ChipData('Wszyscy', _quick == _Quick.all,
            () => setState(() => _quick = _Quick.all)),
        _ChipData('Przypisani', _quick == _Quick.assigned,
            () => setState(() => _quick = _Quick.assigned)),
        _ChipData('Nieprzypisani', _quick == _Quick.unassigned,
            () => setState(() => _quick = _Quick.unassigned)),
        _ChipData('Od Pana Młodego', _quick == _Quick.groom,
            () => setState(() => _quick = _Quick.groom)),
        _ChipData('Od Panny Młodej', _quick == _Quick.bride,
            () => setState(() => _quick = _Quick.bride)),
      ],
    );
  }

  Widget _filterRow2() {
    _ChipData cat(String label, String? value) => _ChipData(
          label,
          _category == value,
          () => setState(() => _category = value),
        );
    return _ChipRow(
      chips: [
        cat('Wszyscy', null),
        cat('Rodzina', 'Rodzina'),
        cat('Znajomi', 'Znajomi'),
        cat('Praca', 'Praca'),
        cat('Inne', 'Inne'),
      ],
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
            'Brak gości spełniających kryteria.',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  static String _guestWord(int n) => n == 1 ? 'gość' : 'gości';
}

class _ChipData {
  _ChipData(this.label, this.selected, this.onTap);
  final String label;
  final bool selected;
  final VoidCallback onTap;
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.chips});
  final List<_ChipData> chips;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final c in chips)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(c.label),
                selected: c.selected,
                onSelected: (_) => c.onTap(),
                showCheckmark: false,
                labelStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.selected ? Colors.white : AppColors.textLight,
                ),
                selectedColor: AppColors.accent,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: c.selected ? AppColors.accent : const Color(0xFFDCE4F2),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
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
  });

  final Guest guest;
  final String? tableName;
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
        _Badge(g.category, const Color(0xFFEEF3FF), AppColors.accent),
      if (widget.tableName != null)
        _Badge('✓ ${widget.tableName}', const Color(0xFFECFDF5),
            const Color(0xFF059669))
      else
        _Badge('Bez stołu', const Color(0xFFFFF7ED), const Color(0xFFB45309)),
      if (g.invitedBy == 'groom')
        _Badge('🤵 Pan Młody', const Color(0xFFEFF6FF), const Color(0xFF1D4ED8)),
      if (g.invitedBy == 'bride')
        _Badge('👰 Panna Młoda', const Color(0xFFFDF2F8), const Color(0xFFDB2777)),
      if (g.witness == 'witness_groom')
        _Badge('● Świadek', const Color(0xFFEFF6FF), const Color(0xFF1D4ED8)),
      if (g.witness == 'witness_bride')
        _Badge('● Świadkowa', const Color(0xFFFDF2F8), const Color(0xFFDB2777)),
      if (g.needsAccommodation)
        _Badge('🏨 Nocleg', const Color(0xFFF5F3FF), const Color(0xFF7C3AED)),
      if (g.hasCompanion)
        _Badge(
          '👥 +1${g.companionName.isNotEmpty ? ' ${g.companionName}' : ''}',
          const Color(0xFFF1F5F9),
          const Color(0xFF475569),
        ),
    ];
  }

  Widget _details(Guest g) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 16),
          _detailRow('Płeć', GuestOptions.genderLabel(g.gender)),
          _detailRow('Zaproszony przez', GuestOptions.invitedByLabel(g.invitedBy)),
          _detailRow('Rola', GuestOptions.witnessLabel(g.witness)),
          if (g.menuChoice.isNotEmpty) _detailRow('Dieta / menu', g.menuChoice),
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
                  label: const Text('Usuń'),
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
