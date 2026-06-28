import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/guest.dart';
import '../../models/room_plan.dart';

/// Interaktywne płótno planu sali: zoom/pan, przeciąganie stołów i elementów,
/// wykrywanie kolizji, siatka pomocnicza i przypisywanie gości (drag & drop).
class RoomCanvas extends StatefulWidget {
  const RoomCanvas({
    super.key,
    required this.geo,
    required this.tables,
    required this.elements,
    required this.guestById,
    required this.controller,
    required this.editMode,
    required this.gridOn,
    required this.selectedTableId,
    required this.selectedElementId,
    required this.onTableMoved,
    required this.onElementMoved,
    required this.onTableTap,
    required this.onElementTap,
    required this.onTableAcceptGuest,
  });

  final RoomGeometry geo;
  final List<Map<String, dynamic>> tables;
  final List<Map<String, dynamic>> elements;
  final Map<int, Guest> guestById;
  final TransformationController controller;
  final bool editMode;
  final bool gridOn;
  final int? selectedTableId;
  final int? selectedElementId;
  final void Function(int id, double x, double y) onTableMoved;
  final void Function(int id, double x, double y) onElementMoved;
  final void Function(Map<String, dynamic> table) onTableTap;
  final void Function(Map<String, dynamic> element) onElementTap;
  final void Function(int tableId, int guestId) onTableAcceptGuest;

  @override
  State<RoomCanvas> createState() => _RoomCanvasState();
}

class _RoomCanvasState extends State<RoomCanvas> {
  // Pozycje na żywo podczas przeciągania (id → offset), przed zapisem.
  final Map<int, Offset> _liveTable = {};
  final Map<int, Offset> _liveElement = {};

  // Pozycja startowa bieżącego przeciągania. Musi być w polu stanu (nie w
  // zmiennej lokalnej buildera) — inaczej setState podczas przeciągania
  // przebudowuje GestureDetector i kasuje punkt startu, blokując ruch.
  Offset? _tableDragStart;
  Offset? _elementDragStart;

  double get _scale => widget.controller.value.getMaxScaleOnAxis();

  int? _idOf(Map<String, dynamic> m) => (m['id'] as num?)?.toInt();
  double _num(dynamic v) => v is num ? v.toDouble() : 0;

  Offset _tablePos(Map<String, dynamic> t) {
    final id = _idOf(t);
    if (id != null && _liveTable.containsKey(id)) return _liveTable[id]!;
    return Offset(_num(t['posX']), _num(t['posY']));
  }

  Offset _elementPos(Map<String, dynamic> e) {
    final id = _idOf(e);
    if (id != null && _liveElement.containsKey(id)) return _liveElement[id]!;
    return Offset(_num(e['posX']), _num(e['posY']));
  }

  void _onTableDrag(Map<String, dynamic> t, Offset deltaScreen, Offset start) {
    final id = _idOf(t);
    if (id == null) return;
    final scale = _scale <= 0 ? 1 : _scale;
    final cand = start + Offset(deltaScreen.dx / scale, deltaScreen.dy / scale);
    final (cx, cy) = widget.geo.clampTable(t, cand.dx, cand.dy);
    // Kolizja: nie pozwól nachodzić na inne stoły.
    if (widget.geo.tableOverlaps(widget.tables, id, cx, cy)) return;
    setState(() => _liveTable[id] = Offset(cx, cy));
  }

  void _onElementDrag(Map<String, dynamic> e, Offset deltaScreen, Offset start) {
    final id = _idOf(e);
    if (id == null) return;
    final scale = _scale <= 0 ? 1 : _scale;
    final cand = start + Offset(deltaScreen.dx / scale, deltaScreen.dy / scale);
    final (cx, cy) = widget.geo.clampElement(e, cand.dx, cand.dy);
    setState(() => _liveElement[id] = Offset(cx, cy));
  }

  @override
  Widget build(BuildContext context) {
    final geo = widget.geo;
    return InteractiveViewer(
      transformationController: widget.controller,
      constrained: false,
      minScale: RoomGeometry.zoomMin,
      maxScale: RoomGeometry.zoomMax,
      boundaryMargin: const EdgeInsets.all(2000),
      child: SizedBox(
        width: RoomGeometry.canvasW,
        height: geo.canvasH,
        child: Stack(
          children: [
            // Tło sali + obrys + siatka
            Positioned.fill(
              child: CustomPaint(
                painter: _RoomBackgroundPainter(geo: geo, grid: widget.gridOn),
              ),
            ),
            if (geo.hasDimensions)
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${geo.widthM} m × ${geo.lengthM} m',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.textLight)),
                ),
              ),
            // Elementy sali
            for (final e in widget.elements) _buildElement(e),
            // Stoły
            for (final t in widget.tables) _buildTable(t),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(Map<String, dynamic> t) {
    final id = _idOf(t) ?? 0;
    final pos = _tablePos(t);
    final (wrapW, wrapH) = widget.geo.tableWrap(t);
    final selected = widget.selectedTableId == id;

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: DragTarget<int>(
        onWillAcceptWithDetails: (_) => true,
        onAcceptWithDetails: (d) => widget.onTableAcceptGuest(id, d.data),
        builder: (context, candidate, rejected) {
          final highlight = candidate.isNotEmpty;
          return GestureDetector(
            onTap: () => widget.onTableTap(t),
            onLongPressStart: (_) => _tableDragStart = _tablePos(t),
            onLongPressMoveUpdate: (d) {
              final start = _tableDragStart;
              if (start != null) _onTableDrag(t, d.offsetFromOrigin, start);
            },
            onLongPressEnd: (_) {
              final id2 = _idOf(t);
              if (id2 != null && _liveTable.containsKey(id2)) {
                final p = _liveTable.remove(id2)!;
                widget.onTableMoved(id2, p.dx, p.dy);
              }
              _tableDragStart = null;
            },
            child: SizedBox(
              width: wrapW,
              height: wrapH,
              child: _RoomTableVisual(
                geo: widget.geo,
                table: t,
                guestById: widget.guestById,
                selected: selected || highlight,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildElement(Map<String, dynamic> e) {
    final id = _idOf(e) ?? 0;
    final pos = _elementPos(e);
    final g = widget.geo.elementGeom(e);
    final wrapW = g.fpW + RoomGeometry.elPad * 2;
    final wrapH = g.fpH + RoomGeometry.elPad * 2;
    final selected = widget.selectedElementId == id;
    final type = (e['type'] as String?) ?? RoomElementType.typeOf((e['name'] as String?) ?? '');

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: GestureDetector(
        onTap: () => widget.onElementTap(e),
        onLongPressStart: (_) => _elementDragStart = _elementPos(e),
        onLongPressMoveUpdate: (d) {
          final start = _elementDragStart;
          if (start != null) _onElementDrag(e, d.offsetFromOrigin, start);
        },
        onLongPressEnd: (_) {
          if (_liveElement.containsKey(id)) {
            final p = _liveElement.remove(id)!;
            widget.onElementMoved(id, p.dx, p.dy);
          }
          _elementDragStart = null;
        },
        child: Container(
          width: wrapW,
          height: wrapH,
          padding: const EdgeInsets.all(RoomGeometry.elPad),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? AppColors.accent : const Color(0xFFB9CBEC),
                width: selected ? 2 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Transform.rotate(
              angle: g.rotation * 3.14159265 / 180,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(RoomElementType.iconOf(type),
                      style: const TextStyle(fontSize: 18)),
                  Text(
                    (e['name'] as String?) ?? 'Element',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wizualizacja stołu na planie (blat + miejsca z inicjałami).
class _RoomTableVisual extends StatelessWidget {
  const _RoomTableVisual({
    required this.geo,
    required this.table,
    required this.guestById,
    required this.selected,
  });

  final RoomGeometry geo;
  final Map<String, dynamic> table;
  final Map<int, Guest> guestById;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final (tw, th) = geo.tableDims(table);
    final shape = (table['shape'] as String?) ?? 'round';
    final isRound = shape == 'round';
    final honor = table['isHonorTable'] == true;
    final name = (table['name'] as String?) ?? 'Stół';
    final seats = (table['seatsData'] as List?) ?? const [];
    final seatPos = geo.seatPositions(table);
    final occupied = seats.where((e) => e != null).length;

    final bodyGradient = honor
        ? const [Color(0xFFB45309), Color(0xFFF59E0B)]
        : const [AppColors.accent, AppColors.accent2];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Miejsca
        for (var i = 0; i < seatPos.length; i++)
          Positioned(
            left: seatPos[i].x - 11,
            top: seatPos[i].y - 11,
            child: _seat(seats.length > i ? seats[i] : null),
          ),
        // Blat
        Positioned(
          left: RoomGeometry.tablePad,
          top: RoomGeometry.tablePad,
          child: Container(
            width: tw,
            height: th,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: bodyGradient),
              shape: isRound ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: isRound ? null : BorderRadius.circular(10),
              border: selected
                  ? Border.all(color: AppColors.accent, width: 3)
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${honor ? '★ ' : ''}$name',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                Text('$occupied/${seats.length}',
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.9))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _seat(dynamic guestId) {
    final id = (guestId as num?)?.toInt();
    final guest = id != null ? guestById[id] : null;
    if (guest == null) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF1F5F9),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
      );
    }
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [AppColors.accent, AppColors.accent2]),
      ),
      child: Text(guest.initials.toUpperCase(),
          style: GoogleFonts.inter(
              fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
    );
  }
}

class _RoomBackgroundPainter extends CustomPainter {
  _RoomBackgroundPainter({required this.geo, required this.grid});
  final RoomGeometry geo;
  final bool grid;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = Colors.white;
    final rect = Offset.zero & size;
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(12)), bg);

    if (grid) {
      final gridPaint = Paint()
        ..color = const Color(0xFFDCE7F6)
        ..strokeWidth = 1;
      final step = geo.widthM > 0 ? geo.ppm : 40.0;
      for (var x = step; x < size.width; x += step) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
      for (var y = step; y < size.height; y += step) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }

    final border = Paint()
      ..color = const Color(0xFFB9CBEC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(12)),
        border);
  }

  @override
  bool shouldRepaint(covariant _RoomBackgroundPainter old) =>
      old.grid != grid || old.geo.ppm != geo.ppm;
}
