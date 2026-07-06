import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/guest.dart';
import '../../models/room_plan.dart';
import '../../models/wedding_data.dart';
import '../../services/firestore_service.dart';
import '../../services/room_service.dart';
import '../../services/table_service.dart';
import 'room_canvas.dart';

/// Pełnoekranowy widok planu sali — zoom/pan, przeciąganie i przypisywanie.
class RoomFullscreenScreen extends StatefulWidget {
  RoomFullscreenScreen({super.key, required this.firestore})
      : room = RoomService(firestore: firestore),
        tableSvc = TableService(firestore: firestore);

  final FirestoreService firestore;
  final RoomService room;
  final TableService tableSvc;

  @override
  State<RoomFullscreenScreen> createState() => _RoomFullscreenScreenState();
}

class _RoomFullscreenScreenState extends State<RoomFullscreenScreen> {
  final _ctrl = TransformationController();
  Size _viewSize = Size.zero;
  bool _fitted = false;
  bool _gridOn = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _fit(RoomGeometry geo) {
    if (_viewSize == Size.zero) return;
    final s = (_viewSize.width / RoomGeometry.canvasW)
        .clamp(RoomGeometry.zoomMin, RoomGeometry.zoomMax);
    final tx = (_viewSize.width - RoomGeometry.canvasW * s) / 2;
    final ty = ((_viewSize.height - geo.canvasH * s) / 2).clamp(0.0, 1e9);
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
    final around =
        Matrix4(f, 0, 0, 0, 0, f, 0, 0, 0, 0, 1, 0, cx * (1 - f), cy * (1 - f), 0, 1);
    _ctrl.value = around * m;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF1FB),
      body: SafeArea(
        child: StreamBuilder<WeddingData?>(
          stream: widget.firestore.watchWeddingData(),
          builder: (context, snapshot) {
            final data = snapshot.data;
            final geo = RoomGeometry.fromMeta(data?.raw['roomMeta'] as Map?);
            final guests = [
              for (final e in data?.guests ?? const [])
                if (e is Map) Guest(Map<String, dynamic>.from(e)),
            ];
            final guestById = {
              for (final g in guests)
                if (g.id != null) g.id!: g
            };
            final tables = [
              for (final e in data?.tables ?? const [])
                if (e is Map) Map<String, dynamic>.from(e),
            ];
            final elements = [
              for (final e in data?.raw['roomElements'] ?? const [])
                if (e is Map) Map<String, dynamic>.from(e),
            ];

            return Stack(
              children: [
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size =
                          Size(constraints.maxWidth, constraints.maxHeight);
                      if (size != _viewSize) {
                        _viewSize = size;
                        if (!_fitted) {
                          _fitted = true;
                          WidgetsBinding.instance
                              .addPostFrameCallback((_) => _fit(geo));
                        }
                      }
                      return RoomCanvas(
                        geo: geo,
                        tables: tables,
                        elements: elements,
                        guestById: guestById,
                        controller: _ctrl,
                        editMode: false,
                        gridOn: _gridOn,
                        selectedTableId: null,
                        selectedElementId: null,
                        onTableMoved: widget.room.moveTable,
                        onElementMoved: widget.room.moveElement,
                        onTableTap: (t) => _assignPicker(context, t, guests),
                        onElementTap: (_) {},
                        onTableAcceptGuest: (tableId, guestId) =>
                            widget.tableSvc.assignGuestToTable(tableId, guestId),
                      );
                    },
                  ),
                ),
                // Pasek narzędzi
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      _btn(Icons.remove, () => _zoomBy(1 / RoomGeometry.zoomStep)),
                      _btn(Icons.fit_screen, () => _fit(geo)),
                      _btn(Icons.add, () => _zoomBy(RoomGeometry.zoomStep)),
                      _btn(_gridOn ? Icons.grid_on : Icons.grid_off,
                          () => setState(() => _gridOn = !_gridOn)),
                      _btn(Icons.close, () => Navigator.of(context).pop()),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          elevation: 1,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(icon, size: 20, color: AppColors.accent),
            ),
          ),
        ),
      );

  Future<void> _assignPicker(
      BuildContext context, Map<String, dynamic> t, List<Guest> guests) async {
    final id = (t['id'] as num?)?.toInt();
    if (id == null) return;
    final unassigned = guests.where((g) => !g.isAssigned).toList();
    final gid = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Przypisz do: ${t['name'] ?? 'Stół'}',
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            if (unassigned.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Wszyscy goście są przypisani.'),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final g in unassigned)
                      ListTile(
                        title: Text(g.fullName.isEmpty ? 'Gość' : g.fullName),
                        onTap: () => Navigator.of(context).pop(g.id),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
    if (gid != null) await widget.tableSvc.assignGuestToTable(id, gid);
  }
}
