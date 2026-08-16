import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../layout/responsive.dart';
import '../../models/children.dart';
import '../../models/guest.dart';
import '../../models/room_plan.dart';
import '../../models/wedding_data.dart';
import '../../services/firestore_service.dart';
import '../../services/room_service.dart';
import '../../services/table_service.dart';
import '../tables/add_table_sheet.dart';
import 'room_canvas.dart';
import 'room_fullscreen.dart';
import '../../l10n/app_text.dart';

/// Sekcja „Plan sali" — pełny wizualny edytor (podgląd + tryb edycji).
class RoomPlanScreen extends StatefulWidget {
  RoomPlanScreen({
    super.key,
    required this.data,
    required FirestoreService firestore,
  })  : room = RoomService(firestore: firestore),
        tableSvc = TableService(firestore: firestore),
        _firestore = firestore;

  final WeddingData? data;
  final RoomService room;
  final TableService tableSvc;
  final FirestoreService _firestore;

  @override
  State<RoomPlanScreen> createState() => _RoomPlanScreenState();
}

class _RoomPlanScreenState extends State<RoomPlanScreen> {
  final _ctrl = TransformationController();
  Size _viewSize = Size.zero;
  bool _fitted = false;

  bool _editMode = false;
  bool _gridOn = false;
  int? _selectedTableId;
  int? _selectedElementId;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Dane ──
  RoomGeometry get _geo =>
      RoomGeometry.fromMeta(widget.data?.raw['roomMeta'] as Map?);

  List<Guest> get _guests => [
        for (final e in widget.data?.guests ?? const [])
          if (e is Map) Guest(Map<String, dynamic>.from(e)),
      ];

  List<Map<String, dynamic>> get _tables => [
        for (final e in widget.data?.tables ?? const [])
          if (e is Map) Map<String, dynamic>.from(e),
      ];

  List<Map<String, dynamic>> get _elements => [
        for (final e in widget.data?.raw['roomElements'] ?? const [])
          if (e is Map) Map<String, dynamic>.from(e),
      ];

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Zoom / fit ──
  void _fit() {
    final geo = _geo;
    if (_viewSize == Size.zero) return;
    final s = (_viewSize.width / RoomGeometry.canvasW)
        .clamp(RoomGeometry.zoomMin, RoomGeometry.zoomMax);
    final tx = (_viewSize.width - RoomGeometry.canvasW * s) / 2;
    final ty = ((_viewSize.height - geo.canvasH * s) / 2).clamp(0.0, 1e9);
    // Macierz kolumnowa: skala s + translacja (tx, ty).
    _ctrl.value = Matrix4(s, 0, 0, 0, 0, s, 0, 0, 0, 0, 1, 0, tx, ty, 0, 1);
    setState(() {});
  }

  void _zoomBy(double factor) {
    final m = _ctrl.value.clone();
    final current = m.getMaxScaleOnAxis();
    final target =
        (current * factor).clamp(RoomGeometry.zoomMin, RoomGeometry.zoomMax);
    final f = target / current;
    final cx = _viewSize.width / 2;
    final cy = _viewSize.height / 2;
    // Skalowanie o czynnik f wokół środka widoku (cx, cy).
    final around =
        Matrix4(f, 0, 0, 0, 0, f, 0, 0, 0, 0, 1, 0, cx * (1 - f), cy * (1 - f), 0, 1);
    _ctrl.value = around * m;
    setState(() {});
  }

  Future<void> _openFullscreen() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => RoomFullscreenScreen(firestore: widget._firestore),
    ));
  }

  // ── Akcje ──
  Future<void> _addTable() async {
    final bd = widget.data?.raw['budgetData'];
    final withChildren = bd is Map && bd['withChildren'] == true;
    final draft = await showModalBottomSheet<TableDraft>(
      context: context,
      constraints: const BoxConstraints(maxWidth: kSheetMaxWidth),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTableSheet(allowChildTable: withChildren),
    );
    if (draft == null) return;
    await widget.tableSvc.addTable(draft);
    _toast(AppText.t.tables_addedToast);
  }

  Future<void> _addElement() async {
    final draft = await showModalBottomSheet<_ElementDraft>(
      context: context,
      constraints: const BoxConstraints(maxWidth: kSheetMaxWidth),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddElementSheet(),
    );
    if (draft == null) return;
    await widget.room.addElement(name: draft.name, wM: draft.wM, lM: draft.lM);
    _toast(AppText.t.roomplan_addedElement(draft.name));
  }

  Future<void> _onTableTap(Map<String, dynamic> t) async {
    setState(() => _selectedTableId = (t['id'] as num?)?.toInt());
    await _showTableSheet(t);
    if (mounted) setState(() => _selectedTableId = null);
  }

  Future<void> _onElementTap(Map<String, dynamic> e) async {
    if (!_editMode) return;
    setState(() => _selectedElementId = (e['id'] as num?)?.toInt());
    await _showElementSheet(e);
    if (mounted) setState(() => _selectedElementId = null);
  }

  Future<void> _assignGuest(int tableId, int guestId) async {
    final ok = await widget.tableSvc.assignGuestToTable(tableId, guestId);
    if (!ok) {
      _toast(AppText.t.tables_full);
      return;
    }
    // Miękka podpowiedź (dorosły przy stole dzieci itp.) — po zapisie,
    // bo przypisania nie blokujemy.
    final tables = _tables;
    final table = tables.where((t) => (t['id'] as num?)?.toInt() == tableId);
    final guest = _guests.where((g) => g.id == guestId);
    if (table.isEmpty || guest.isEmpty) return;

    final hint = ChildrenSettings.seatingHint(
      guestIsChild: guest.first.isChild,
      tableIsChildTable: table.first['isChildTable'] == true,
      childTableExists: ChildrenSettings.hasChildTable(tables),
    );
    if (hint != null) _toast(hint);
  }

  @override
  Widget build(BuildContext context) {
    final guests = _guests;
    final tables = _tables;
    final guestById = {for (final g in guests) if (g.id != null) g.id!: g};
    final unassigned = guests.where((g) => !g.isAssigned).toList();

    final totalSeats = tables.fold<int>(
        0, (s, t) => s + ((t['seats'] as num?)?.toInt() ?? 0));
    final assigned = guests.where((g) => g.isAssigned).length;
    final free = totalSeats - assigned;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(AppText.t.roomplan_title,
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
              ),
              OutlinedButton.icon(
                onPressed: () => setState(() => _editMode = !_editMode),
                icon: Icon(_editMode ? Icons.check : Icons.edit_outlined,
                    size: 18),
                label: Text(_editMode ? AppText.t.common_done : AppText.t.roomplan_editPlan),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _statsBar(guests.length, assigned, unassigned.length, tables.length,
            free < 0 ? 0 : free),
        if (_editMode) _editPanel(),
        _toolbar(),
        _unassignedPool(unassigned),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: const Color(0xFFEAF1FB),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size =
                        Size(constraints.maxWidth, constraints.maxHeight);
                    if (size != _viewSize) {
                      _viewSize = size;
                      if (!_fitted) {
                        _fitted = true;
                        WidgetsBinding.instance
                            .addPostFrameCallback((_) => _fit());
                      }
                    }
                    return RoomCanvas(
                      geo: _geo,
                      tables: tables,
                      elements: _elements,
                      guestById: guestById,
                      controller: _ctrl,
                      editMode: _editMode,
                      gridOn: _gridOn,
                      selectedTableId: _selectedTableId,
                      selectedElementId: _selectedElementId,
                      onTableMoved: widget.room.moveTable,
                      onElementMoved: widget.room.moveElement,
                      onTableTap: _onTableTap,
                      onElementTap: _onElementTap,
                      onTableAcceptGuest: _assignGuest,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statsBar(int total, int assigned, int unassigned, int tables, int free) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _stat(AppText.t.tables_statGuests, '$total', AppColors.accent),
          _stat(AppText.t.guests_filterAssigned, '$assigned', const Color(0xFF059669)),
          _stat(AppText.t.guests_filterUnassigned, '$unassigned',
              const Color(0xFFB45309)),
          _stat(AppText.t.tables_statTables, '$tables', const Color(0xFF7C3AED)),
          _stat(AppText.t.room_freeSeats, '$free', const Color(0xFF0891B2)),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) => Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2EAF7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w800, color: color)),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 10, color: AppColors.textLight)),
          ],
        ),
      );

  Widget _toolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          _toolBtn(Icons.remove, AppText.t.roomplan_zoomOut, () => _zoomBy(1 / RoomGeometry.zoomStep)),
          _toolBtn(Icons.fit_screen, AppText.t.roomplan_fit, _fit),
          _toolBtn(Icons.add, AppText.t.roomplan_zoomIn, () => _zoomBy(RoomGeometry.zoomStep)),
          const Spacer(),
          _toolBtn(_gridOn ? Icons.grid_on : Icons.grid_off, 'Siatka',
              () => setState(() => _gridOn = !_gridOn),
              active: _gridOn),
          _toolBtn(Icons.fullscreen, AppText.t.roomplan_fullscreen, _openFullscreen),
        ],
      ),
    );
  }

  Widget _toolBtn(IconData icon, String tip, VoidCallback onTap,
      {bool active = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: active ? AppColors.accent : Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Tooltip(
            message: tip,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(icon,
                  size: 20,
                  color: active ? Colors.white : AppColors.accent),
            ),
          ),
        ),
      ),
    );
  }

  Widget _editPanel() {
    final geo = _geo;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppText.t.roomplan_roomDimsLabel,
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Row(
            children: [
              _metaStepper(AppText.t.roomplan_widthShort, geo.widthM, 'widthM'),
              const SizedBox(width: 8),
              _metaStepper(AppText.t.roomplan_lengthShort, geo.lengthM, 'lengthM'),
              const SizedBox(width: 8),
              _metaStepper(AppText.t.roomplan_tableDiameterShort, geo.tableDiameterM,
                  'tableDiameterM'),
            ],
          ),
          const Divider(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addTable,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(AppText.t.tables_addButton),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addElement,
                  icon: const Icon(Icons.add_box_outlined, size: 18),
                  label: Text(AppText.t.roomplan_addElement),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(AppText.t.roomplan_hint,
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _metaStepper(String label, double value, String field) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  GoogleFonts.inter(fontSize: 11, color: AppColors.textLight)),
          const SizedBox(height: 2),
          Row(
            children: [
              _miniBtn(Icons.remove, () {
                final v = (value - 0.5).clamp(0, 999).toDouble();
                widget.room.setMeta(field, v);
              }),
              Expanded(
                child: Text(value == 0 ? '—' : value.toStringAsFixed(1),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              _miniBtn(Icons.add, () => widget.room.setMeta(field, value + 0.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniBtn(IconData icon, VoidCallback onTap) => Material(
        color: const Color(0xFFEEF3FF),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(icon, size: 16, color: AppColors.accent),
          ),
        ),
      );

  Widget _unassignedPool(List<Guest> unassigned) {
    if (unassigned.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppText.t.roomplan_unassignedDrag(unassigned.length),
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: AppColors.textLight)),
          const SizedBox(height: 6),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final g in unassigned)
                  if (g.id != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: LongPressDraggable<int>(
                        data: g.id!,
                        feedback: _chip(g, dragging: true),
                        childWhenDragging:
                            Opacity(opacity: 0.4, child: _chip(g)),
                        child: _chip(g),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(Guest g, {bool dragging = false}) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE4F2)),
      ),
      child: Text(g.fullName.isEmpty ? AppText.t.roomplan_guest : g.fullName,
          style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent)),
    );
    return dragging ? Material(color: Colors.transparent, child: chip) : chip;
  }

  // ── Arkusze stołu / elementu ──
  Future<void> _showTableSheet(Map<String, dynamic> t) async {
    final id = (t['id'] as num?)?.toInt() ?? 0;
    await showModalBottomSheet<void>(
      context: context,
      constraints: const BoxConstraints(maxWidth: kSheetMaxWidth),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _TableSheet(
        table: t,
        guests: _guests,
        editMode: _editMode,
        // Świeże dane na żądanie: panel po każdej zmianie dociąga aktualny stan
        // z ekranu (a ten ma go ze strumienia Firestore), zamiast trzymać
        // migawkę z chwili otwarcia.
        liveTable: () {
          for (final x in _tables) {
            if ((x['id'] as num?)?.toInt() == id) return x;
          }
          return null;
        },
        liveGuests: () => _guests,
        onAssign: (gid) => _assignGuest(id, gid),
        onUnassign: (gid) => widget.tableSvc.unassignGuest(gid),
        onResize: ({diamM, rectWM, rectLM}) => widget.room
            .resizeTable(id, diamM: diamM, rectWM: rectWM, rectLM: rectLM),
        onDelete: () async {
          await widget.tableSvc.deleteTable(id);
          if (context.mounted) Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _showElementSheet(Map<String, dynamic> e) async {
    final id = (e['id'] as num?)?.toInt() ?? 0;
    await showModalBottomSheet<void>(
      context: context,
      constraints: const BoxConstraints(maxWidth: kSheetMaxWidth),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _ElementSheet(
        element: e,
        onResize: ({wM, lM}) => widget.room.resizeElement(id, wM: wM, lM: lM),
        onRotate: () => widget.room.rotateElement(id),
        onDelete: () async {
          await widget.room.deleteElement(id);
          if (context.mounted) Navigator.of(context).pop();
        },
      ),
    );
  }
}

// ── Arkusz stołu (przypisania + rozmiar) ──
/// Panel stołu (arkusz dolny).
///
/// BYŁ bezstanowy i pracował na MIGAWCE mapy stołu z chwili otwarcia — stąd dwa
/// zgłoszone błędy:
///  • #10 rozmiar stołu: każde kliknięcie „+" liczyło `wartość + 0,1` od tej
///    samej, nieaktualnej wartości, więc rozmiar nigdy się nie kumulował,
///    a wyświetlana liczba w ogóle się nie zmieniała,
///  • #14 przypisanie gościa: lista gości przy stole pochodziła z migawki, więc
///    dodany gość pojawiał się dopiero po zamknięciu i ponownym otwarciu panelu.
///
/// Teraz panel jest stanowy: po każdej zmianie dociąga świeży stan przez
/// [liveTable] / [liveGuests] i przerysowuje się sam.
class _TableSheet extends StatefulWidget {
  const _TableSheet({
    required this.table,
    required this.guests,
    required this.editMode,
    required this.liveTable,
    required this.liveGuests,
    required this.onAssign,
    required this.onUnassign,
    required this.onResize,
    required this.onDelete,
  });

  /// Stan początkowy (z chwili otwarcia).
  final Map<String, dynamic> table;

  /// Aktualny stół z danych ekranu; `null`, gdy stół zniknął (np. usunięty).
  final Map<String, dynamic>? Function() liveTable;

  /// Aktualna lista gości z danych ekranu.
  final List<Guest> Function() liveGuests;
  final List<Guest> guests;
  final bool editMode;
  final void Function(int guestId) onAssign;
  final void Function(int guestId) onUnassign;
  final void Function({num? diamM, num? rectWM, num? rectLM}) onResize;
  final VoidCallback onDelete;

  @override
  State<_TableSheet> createState() => _TableSheetState();
}

class _TableSheetState extends State<_TableSheet> {
  late Map<String, dynamic> _table = Map<String, dynamic>.from(widget.table);
  late List<Guest> _guests = widget.guests;

  /// Dociąga aktualny stan stołu i gości po zapisie.
  ///
  /// Firestore stosuje zapisy najpierw lokalnie, więc zanim `await` wróci,
  /// strumień zdążył już przerysować ekran nadrzędny nowymi danymi.
  void _sync() {
    final fresh = widget.liveTable();
    if (!mounted) return;
    setState(() {
      if (fresh != null) _table = Map<String, dynamic>.from(fresh);
      _guests = widget.liveGuests();
    });
  }

  double _dim(String key) => (_table[key] as num?)?.toDouble() ?? 0;

  /// Zmiana rozmiaru: najpierw lokalnie (natychmiastowa reakcja i poprawne
  /// kumulowanie kolejnych kliknięć), potem zapis i odświeżenie.
  Future<void> _resize({num? diamM, num? rectWM, num? rectLM}) async {
    setState(() {
      if (diamM != null) _table['diamM'] = diamM;
      if (rectWM != null) _table['rectWM'] = rectWM;
      if (rectLM != null) _table['rectLM'] = rectLM;
    });
    widget.onResize(diamM: diamM, rectWM: rectWM, rectLM: rectLM);
  }

  Future<void> _assign(int guestId, String name) async {
    final seatsBefore = _seatedCount;
    widget.onAssign(guestId);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _sync();
    if (!mounted) return;
    // Potwierdzenie tylko wtedy, gdy gość faktycznie usiadł — przy pełnym stole
    // ekran nadrzędny pokazuje własny komunikat „Stół jest pełny!".
    if (_seatedCount > seatsBefore) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(AppText.t.roomplan_addedToTable(name)),
          duration: const Duration(seconds: 2),
        ));
    }
  }

  Future<void> _unassign(int guestId) async {
    widget.onUnassign(guestId);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _sync();
  }

  int get _seatedCount {
    final seats = (_table['seatsData'] as List?) ?? const [];
    return seats.where((s) => s != null).length;
  }

  @override
  Widget build(BuildContext context) {
    final table = _table;
    final guests = _guests;
    final shape = (table['shape'] as String?) ?? 'round';
    final seats = (table['seatsData'] as List?) ?? const [];
    final guestById = {for (final g in guests) g.id: g};
    final seated = [
      for (final s in seats)
        if (s != null) guestById[(s as num).toInt()],
    ].whereType<Guest>().toList();
    final unassigned = guests.where((g) => !g.isAssigned).toList();
    final full = seated.length >= seats.length;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text('${table['name'] ?? 'Stół'} (${seated.length}/${seats.length})',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text(AppText.t.roomplan_guestsAtTable,
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          if (seated.isEmpty)
            Text(AppText.t.roomplan_noGuestsAtTable,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textLight))
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final g in seated)
                  Chip(
                    label: Text(g.fullName),
                    onDeleted: g.id != null ? () => _unassign(g.id!) : null,
                  ),
              ],
            ),
          const SizedBox(height: 12),
          if (!full)
            OutlinedButton.icon(
              onPressed: () => _pickGuest(context, unassigned),
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: Text(AppText.t.tables_assignGuestAction),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
              ),
            ),
          if (widget.editMode) ...[
            const Divider(height: 24),
            Text(AppText.t.roomplan_tableSize,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (shape == 'round')
              _RoomDimRow(
                label: AppText.t.roomplan_diameterMeters,
                value: _dim('diamM'),
                onChanged: (v) => _resize(diamM: v),
              )
            else ...[
              _RoomDimRow(
                label: AppText.t.roomplan_widthMeters,
                value: _dim('rectWM'),
                onChanged: (v) => _resize(rectWM: v),
              ),
              _RoomDimRow(
                label: AppText.t.roomplan_lengthMeters,
                value: _dim('rectLM'),
                onChanged: (v) => _resize(rectLM: v),
              ),
            ],
            const SizedBox(height: 8),
            Text(AppText.t.roomplan_autoSizeHint,
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.textLight)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: widget.onDelete,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(AppText.t.tables_deleteTable),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFC0392B),
                side: const BorderSide(color: Color(0xFFE9A8A8)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickGuest(BuildContext context, List<Guest> options) async {
    final gid = await showModalBottomSheet<int>(
      context: context,
      constraints: const BoxConstraints(maxWidth: kSheetMaxWidth),
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          for (final g in options)
            ListTile(
              title: Text(g.fullName.isEmpty ? AppText.t.roomplan_guest : g.fullName),
              onTap: () => Navigator.of(context).pop(g.id),
            ),
        ],
      ),
    );
    if (gid == null) return;
    final picked = options.firstWhere((g) => g.id == gid,
        orElse: () => options.isNotEmpty ? options.first : throw StateError('brak'));
    final name = picked.fullName.isEmpty ? AppText.t.roomplan_guest : picked.fullName;
    await _assign(gid, name);
  }
}

class _RoomDimRow extends StatelessWidget {
  const _RoomDimRow(
      {required this.label, required this.value, required this.onChanged});
  final String label;
  final double value;
  final ValueChanged<num> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              child: Text(label, style: GoogleFonts.inter(fontSize: 13))),
          IconButton(
            onPressed: () => onChanged((value - 0.1).clamp(0, 99)),
            icon: const Icon(Icons.remove_circle_outline),
            color: AppColors.accent,
          ),
          SizedBox(
            width: 48,
            child: Text(value == 0 ? 'auto' : value.toStringAsFixed(1),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w700)),
          ),
          IconButton(
            onPressed: () => onChanged(value + 0.1),
            icon: const Icon(Icons.add_circle_outline),
            color: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

// ── Arkusz elementu ──
class _ElementSheet extends StatelessWidget {
  const _ElementSheet({
    required this.element,
    required this.onResize,
    required this.onRotate,
    required this.onDelete,
  });

  final Map<String, dynamic> element;
  final void Function({num? wM, num? lM}) onResize;
  final VoidCallback onRotate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${element['name'] ?? 'Element'}',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _RoomDimRow(
              label: AppText.t.roomplan_widthMeters,
              value: (element['wM'] as num?)?.toDouble() ?? 0,
              onChanged: (v) => onResize(wM: v),
            ),
            _RoomDimRow(
              label: AppText.t.roomplan_lengthMeters,
              value: (element['lM'] as num?)?.toDouble() ?? 0,
              onChanged: (v) => onResize(lM: v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRotate,
                    icon: const Icon(Icons.rotate_90_degrees_cw, size: 18),
                    label: Text(AppText.t.roomplan_rotate90),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(AppText.t.common_delete),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFC0392B),
                      side: const BorderSide(color: Color(0xFFE9A8A8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dodawanie elementu ──
class _ElementDraft {
  _ElementDraft(this.name, this.wM, this.lM);
  final String name;
  final double wM;
  final double lM;
}

class _AddElementSheet extends StatefulWidget {
  const _AddElementSheet();

  @override
  State<_AddElementSheet> createState() => _AddElementSheetState();
}

class _AddElementSheetState extends State<_AddElementSheet> {
  String _type = 'Parkiet';
  final _custom = TextEditingController();
  double _w = 3;
  double _l = 2;

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppText.t.roomplan_addElementSheet,
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(
                      labelText: 'Rodzaj', border: OutlineInputBorder()),
                  items: [
                    for (final o in RoomElementType.options)
                      DropdownMenuItem(
                          value: o.label,
                          child: Text('${o.icon} ${o.label}')),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? 'Parkiet'),
                ),
                if (_type == 'Inne') ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _custom,
                    decoration: const InputDecoration(
                        labelText: 'Nazwa', border: OutlineInputBorder()),
                  ),
                ],
                const SizedBox(height: 12),
                _RoomDimRow(
                    label: AppText.t.roomplan_widthMeters,
                    value: _w,
                    onChanged: (v) => setState(() => _w = v.toDouble())),
                _RoomDimRow(
                    label: AppText.t.roomplan_lengthMeters,
                    value: _l,
                    onChanged: (v) => setState(() => _l = v.toDouble())),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      var name = _type;
                      if (name == 'Inne') {
                        name = _custom.text.trim().isEmpty
                            ? 'Element'
                            : _custom.text.trim();
                      }
                      Navigator.of(context).pop(_ElementDraft(
                          name, _w <= 0 ? 1 : _w, _l <= 0 ? 1 : _l));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Dodaj'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
