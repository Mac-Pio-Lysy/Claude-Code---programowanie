import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/guest.dart';
import '../../models/wedding_data.dart';
import '../../services/firestore_service.dart';
import '../../services/table_service.dart';
import 'add_table_sheet.dart';
import 'table_visual.dart';

/// Sekcja „Plan stołów" — graficzne stoły, statystyki i przypisywanie gości
/// (drag & drop z long-press lub wybór z listy).
class TablesScreen extends StatefulWidget {
  TablesScreen({
    super.key,
    required this.data,
    required FirestoreService firestore,
  }) : service = TableService(firestore: firestore);

  final WeddingData? data;
  final TableService service;

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  List<Guest> get _guests => [
        for (final e in widget.data?.guests ?? const [])
          if (e is Map) Guest(Map<String, dynamic>.from(e)),
      ];

  List<Map<String, dynamic>> get _tables => [
        for (final e in widget.data?.tables ?? const [])
          if (e is Map) Map<String, dynamic>.from(e),
      ];

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addTable() async {
    final draft = await showModalBottomSheet<TableDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTableSheet(),
    );
    if (draft == null) return;
    try {
      await widget.service.addTable(draft);
      _toast('Dodano stół');
    } catch (e) {
      _toast('Błąd zapisu: $e');
    }
  }

  Future<void> _deleteTable(Map<String, dynamic> table) async {
    final id = (table['id'] as num?)?.toInt();
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć stół?'),
        content: Text(
          'Czy na pewno usunąć stół „${table['name'] ?? ''}"? '
          'Przypisani goście wrócą do nieprzypisanych.',
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
    if (confirmed != true) return;
    try {
      await widget.service.deleteTable(id);
      _toast('Stół usunięty');
    } catch (e) {
      _toast('Błąd usuwania: $e');
    }
  }

  Future<void> _assign(int tableId, int guestId) async {
    try {
      final ok = await widget.service.assignGuestToTable(tableId, guestId);
      if (!ok) _toast('Stół jest pełny!');
    } catch (e) {
      _toast('Błąd zapisu: $e');
    }
  }

  Future<void> _unassign(int guestId) async {
    try {
      await widget.service.unassignGuest(guestId);
    } catch (e) {
      _toast('Błąd zapisu: $e');
    }
  }

  Future<void> _openAssignPicker(Map<String, dynamic> table) async {
    final tableId = (table['id'] as num?)?.toInt();
    if (tableId == null) return;
    final unassigned =
        _guests.where((g) => !g.isAssigned).toList();

    final guestId = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _GuestPickerSheet(
        title: 'Przypisz do: ${table['name'] ?? ''}',
        guests: unassigned,
      ),
    );
    if (guestId != null) await _assign(tableId, guestId);
  }

  Future<void> _onSeatTap(Guest guest) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(guest.fullName,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.event_seat_outlined,
                  color: Color(0xFFC0392B)),
              title: const Text('Usuń ze stołu'),
              onTap: () => Navigator.of(context).pop('unassign'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == 'unassign' && guest.id != null) {
      await _unassign(guest.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final guests = _guests;
    final tables = _tables;
    final guestById = {for (final g in guests) if (g.id != null) g.id!: g};
    final unassigned = guests.where((g) => !g.isAssigned).toList();

    final totalSeats = tables.fold<int>(
        0, (s, t) => s + ((t['seats'] as num?)?.toInt() ?? 0));
    final assignedCount = guests.where((g) => g.isAssigned).length;
    final freeSeats = totalSeats - assignedCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plan stołów',
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
          _statsBar(
            total: guests.length,
            assigned: assignedCount,
            unassigned: unassigned.length,
            tables: tables.length,
            freeSeats: freeSeats < 0 ? 0 : freeSeats,
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: _addTable,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Dodaj stół'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                textStyle:
                    GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _unassignedPool(unassigned),
          const SizedBox(height: 14),
          Expanded(
            child: tables.isEmpty
                ? _emptyTables()
                : SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        for (final t in tables)
                          _tableCard(t, guestById),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statsBar({
    required int total,
    required int assigned,
    required int unassigned,
    required int tables,
    required int freeSeats,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _statChip('Goście', '$total', AppColors.accent),
          _statChip('Przypisani', '$assigned', const Color(0xFF059669)),
          _statChip('Nieprzypisani', '$unassigned', const Color(0xFFB45309)),
          _statChip('Stoły', '$tables', const Color(0xFF7C3AED)),
          _statChip('Wolne miejsca', '$freeSeats', const Color(0xFF0891B2)),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _unassignedPool(List<Guest> unassigned) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => _unassign(details.data),
      builder: (context, candidate, rejected) {
        final highlight = candidate.isNotEmpty;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: highlight ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlight ? AppColors.accent : const Color(0xFFE2EAF7),
              width: highlight ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nieprzypisani goście (${unassigned.length})',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Przeciągnij (przytrzymaj) gościa na stół lub użyj „Przypisz".',
                style:
                    GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
              ),
              const SizedBox(height: 10),
              if (unassigned.isEmpty)
                Text(
                  '🎉 Wszyscy goście mają miejsce!',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: const Color(0xFF059669)),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final g in unassigned) _draggableChip(g),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _draggableChip(Guest guest) {
    final chip = _GuestChip(guest: guest);
    if (guest.id == null) return Padding(padding: const EdgeInsets.only(right: 8), child: chip);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: LongPressDraggable<int>(
        data: guest.id!,
        feedback: _GuestChip(guest: guest, dragging: true),
        childWhenDragging: Opacity(opacity: 0.4, child: chip),
        child: chip,
      ),
    );
  }

  Widget _tableCard(Map<String, dynamic> table, Map<int, Guest> guestById) {
    final seats = (table['seats'] as num?)?.toInt() ?? 0;
    final seatsData = (table['seatsData'] as List?) ?? const [];
    final occupied = seatsData.where((e) => e != null).length;
    final tableId = (table['id'] as num?)?.toInt();
    final isFull = occupied >= seats;

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) {
        if (tableId == null || isFull) return false;
        final g = guestById[details.data];
        return g?.tableId != tableId; // nie upuszczaj na ten sam stół
      },
      onAcceptWithDetails: (details) {
        if (tableId != null) _assign(tableId, details.data);
      },
      builder: (context, candidate, rejected) {
        final highlight = candidate.isNotEmpty;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: highlight
                  ? AppColors.accent
                  : (isFull ? const Color(0xFFBBF7D0) : const Color(0xFFE2EAF7)),
              width: highlight ? 2 : 1,
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
            mainAxisSize: MainAxisSize.min,
            children: [
              TableVisual(
                table: table,
                guestById: guestById,
                onGuestTap: _onSeatTap,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isFull
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFEEF3FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$occupied/$seats miejsc',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isFull
                            ? const Color(0xFF059669)
                            : AppColors.accent,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Przypisz gościa',
                    onPressed: isFull ? null : () => _openAssignPicker(table),
                    icon: const Icon(Icons.person_add_alt_1, size: 20),
                    color: AppColors.accent,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    tooltip: 'Usuń stół',
                    onPressed: () => _deleteTable(table),
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: const Color(0xFFC0392B),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyTables() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.table_restaurant_outlined,
              size: 48, color: AppColors.accent2),
          const SizedBox(height: 12),
          Text(
            'Brak stołów. Dodaj pierwszy stół przyciskiem powyżej.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}

/// Mała „pigułka" z inicjałami i imieniem gościa (źródło przeciągania).
class _GuestChip extends StatelessWidget {
  const _GuestChip({required this.guest, this.dragging = false});
  final Guest guest;
  final bool dragging;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE4F2)),
        boxShadow: dragging
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.accent, AppColors.accent2],
              ),
            ),
            child: Text(
              guest.initials.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            guest.fullName.isEmpty ? '(bez imienia)' : guest.fullName,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
    return dragging ? Material(color: Colors.transparent, child: chip) : chip;
  }
}

/// Arkusz wyboru gościa do przypisania (gdy nie chcemy przeciągać).
class _GuestPickerSheet extends StatelessWidget {
  const _GuestPickerSheet({required this.title, required this.guests});
  final String title;
  final List<Guest> guests;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
          ),
          if (guests.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Wszyscy goście są już przypisani.',
                style:
                    GoogleFonts.inter(fontSize: 14, color: AppColors.textLight),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: guests.length,
                itemBuilder: (context, i) {
                  final g = guests[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.accent,
                      child: Text(
                        g.initials.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    title: Text(g.fullName.isEmpty ? '(bez imienia)' : g.fullName),
                    subtitle: g.category.isNotEmpty ? Text(g.category) : null,
                    onTap: () => Navigator.of(context).pop(g.id),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
