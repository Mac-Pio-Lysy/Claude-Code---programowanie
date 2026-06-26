import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/guest.dart';
import '../../models/vehicle.dart';
import '../../models/wedding_data.dart';
import '../../services/firestore_service.dart';
import '../../services/transport_service.dart';
import '../budget/budget_fields.dart';
import 'vehicle_form_sheet.dart';

/// Sekcja „Transport" — pojazdy, przypisania gości, transport własny i wewnętrzny.
class TransportScreen extends StatefulWidget {
  TransportScreen({
    super.key,
    required this.data,
    required FirestoreService firestore,
  }) : service = TransportService(firestore: firestore);

  final WeddingData? data;
  final TransportService service;

  @override
  State<TransportScreen> createState() => _TransportScreenState();
}

class _TransportScreenState extends State<TransportScreen> {
  bool _showOwn = true;

  List<Guest> get _guests => [
        for (final e in widget.data?.guests ?? const [])
          if (e is Map) Guest(Map<String, dynamic>.from(e)),
      ];

  List<Vehicle> get _vehicles => [
        for (final e in widget.data?.raw['vehicles'] ?? const [])
          if (e is Map) Vehicle(Map<String, dynamic>.from(e)),
      ];

  List<InternalTransport> get _internal => [
        for (final e in widget.data?.raw['internalTransport'] ?? const [])
          if (e is Map) InternalTransport(Map<String, dynamic>.from(e)),
      ];

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _addVehicle() async {
    final draft = await showModalBottomSheet<VehicleDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const VehicleFormSheet(),
    );
    if (draft == null) return;
    await widget.service.addVehicle(draft);
    _toast('Dodano pojazd');
  }

  Future<void> _editVehicle(Vehicle v) async {
    final draft = await showModalBottomSheet<VehicleDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VehicleFormSheet(existing: v),
    );
    if (draft == null || v.id == null) return;
    await widget.service.updateVehicle(v.id!, draft);
  }

  Future<void> _pickGuest(String title, List<Guest> options,
      ValueChanged<int> onPick) async {
    if (options.isEmpty) {
      _toast('Brak dostępnych gości');
      return;
    }
    final id = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(title,
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final g in options)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.accent,
                        child: Text(g.initials.toUpperCase(),
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                      title: Text(g.fullName.isEmpty ? '(bez imienia)' : g.fullName),
                      onTap: () => Navigator.of(context).pop(g.id),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (id != null) onPick(id);
  }

  @override
  Widget build(BuildContext context) {
    final guests = _guests;
    final vehicles = _vehicles;
    final byId = {for (final g in guests) g.id: g};

    final assigned = <int>{for (final v in vehicles) ...v.guestIds};
    final ownGuests = guests
        .where((g) => g.raw['ownTransport'] == true && !assigned.contains(g.id))
        .toList();
    final ownSet = {for (final g in ownGuests) g.id};
    final unassigned = guests
        .where((g) => !assigned.contains(g.id) && !ownSet.contains(g.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Transport',
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
                  gradient:
                      const LinearGradient(colors: AppColors.dividerGradient),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            children: [
              _breakdownBar(vehicles, ownGuests.length, unassigned.length),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.visibility_outlined,
                      size: 18, color: AppColors.textLight),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Pokaż transport własny',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.text)),
                  ),
                  Switch.adaptive(
                    value: _showOwn,
                    activeThumbColor: AppColors.accent,
                    onChanged: (v) => setState(() => _showOwn = v),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              for (final v in vehicles)
                _vehicleCard(v, byId, guests),
              const SizedBox(height: 8),
              if (_showOwn) _ownTransportCard(ownGuests, unassigned),
              const SizedBox(height: 12),
              _unassignedCard(unassigned),
              const SizedBox(height: 12),
              _internalCard(),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addVehicle,
                  icon: const Icon(Icons.add),
                  label: const Text('Dodaj pojazd'),
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _breakdownBar(List<Vehicle> vehicles, int own, int unassigned) {
    final inVehicles =
        vehicles.fold<int>(0, (s, v) => s + v.guestIds.length);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _stat('🚗', '$inVehicles', 'w pojazdach', AppColors.accent),
          _stat('🚶', '$own', 'transport własny', const Color(0xFF059669)),
          _stat('❓', '$unassigned', 'bez przydziału',
              const Color(0xFFB45309)),
          _stat('🚙', '${vehicles.length}', 'pojazdów',
              const Color(0xFF7C3AED)),
        ],
      ),
    );
  }

  Widget _stat(String icon, String value, String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: color)),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.textLight)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vehicleCard(Vehicle v, Map<int?, Guest> byId, List<Guest> guests) {
    final passengers = v.guestIds;
    final available =
        guests.where((g) => g.id != null && !passengers.contains(g.id)).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: v.isFull ? const Color(0xFFBBF7D0) : const Color(0xFFE2EAF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🚗 ', style: TextStyle(fontSize: 18)),
              Expanded(
                child: Text(v.type.isEmpty ? 'Pojazd' : v.type,
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: v.isFull
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFEEF3FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${v.occupied}/${v.seats} miejsc',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: v.isFull
                            ? const Color(0xFF059669)
                            : AppColors.accent)),
              ),
              IconButton(
                onPressed: () => _editVehicle(v),
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: AppColors.accent,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: () => widget.service.deleteVehicle(v.id ?? 0),
                icon: const Icon(Icons.delete_outline, size: 18),
                color: const Color(0xFFC0392B),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (v.driver.isNotEmpty ||
              v.route.isNotEmpty ||
              v.departureTime.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 4),
              child: Text(
                [
                  if (v.driver.isNotEmpty) '👤 ${v.driver}',
                  if (v.route.isNotEmpty) '🛣 ${v.route}',
                  if (v.departureTime.isNotEmpty) '🕐 ${v.departureTime}',
                ].join('  ·  '),
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textLight),
              ),
            ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final gid in passengers)
                _guestChip(byId[gid]?.fullName ?? 'Gość',
                    () => widget.service.assignGuestToVehicle(gid, null)),
              if (!v.isFull)
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16),
                  label: const Text('Przypisz'),
                  onPressed: () => _pickGuest(
                    'Przypisz do: ${v.type}',
                    available,
                    (gid) => widget.service.assignGuestToVehicle(gid, v.id),
                  ),
                  backgroundColor: const Color(0xFFEEF3FF),
                  side: BorderSide.none,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ownTransportCard(List<Guest> ownGuests, List<Guest> unassigned) {
    return _card(
      title: '🚶 Transport własny',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ownGuests.isEmpty)
            Text('Brak gości z własnym dojazdem.',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textLight))
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final g in ownGuests)
                  _guestChip(g.fullName,
                      () => widget.service.setGuestOwnTransport(g.id ?? 0, false)),
              ],
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _pickGuest(
              'Dodaj do transportu własnego',
              unassigned,
              (gid) => widget.service.setGuestOwnTransport(gid, true),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Dodaj gościa'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _unassignedCard(List<Guest> unassigned) {
    return _card(
      title: '❓ Bez przydziału (${unassigned.length})',
      child: unassigned.isEmpty
          ? Text('Wszyscy goście mają transport.',
              style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF059669)))
          : Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final g in unassigned)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFDCE4F2)),
                    ),
                    child: Text(g.fullName.isEmpty ? '(bez imienia)' : g.fullName,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.text)),
                  ),
              ],
            ),
    );
  }

  Widget _internalCard() {
    final items = _internal;
    return _card(
      title: '🚕 Transport wewnętrzny',
      trailing: IconButton(
        onPressed: () => widget.service.addInternalTransport(),
        icon: const Icon(Icons.add_circle_outline),
        color: AppColors.accent,
        tooltip: 'Dodaj',
      ),
      child: items.isEmpty
          ? Text('Brak. Dodaj Bolt / Taxi / inny.',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textLight))
          : Column(
              children: [
                for (final it in items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: BudgetTextField(
                                key: ValueKey('it-type-${it.id}'),
                                initial: it.type,
                                hint: 'Bolt / Taxi',
                                onSaved: (v) => widget.service
                                    .updateInternalTransport(it.id ?? 0,
                                        type: v),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              flex: 3,
                              child: BudgetTextField(
                                key: ValueKey('it-info-${it.id}'),
                                initial: it.info,
                                hint: 'Info / kod / telefon',
                                onSaved: (v) => widget.service
                                    .updateInternalTransport(it.id ?? 0,
                                        info: v),
                              ),
                            ),
                            IconButton(
                              onPressed: () => widget.service
                                  .deleteInternalTransport(it.id ?? 0),
                              icon: const Icon(Icons.close, size: 18),
                              color: const Color(0xFFC0392B),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const SizedBox(width: 4),
                            Text('Pokaż gościom w harmonogramie',
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.textLight)),
                            const Spacer(),
                            Switch.adaptive(
                              value: it.showToGuests,
                              activeThumbColor: AppColors.accent,
                              onChanged: (v) => widget.service
                                  .updateInternalTransport(it.id ?? 0,
                                      showToGuests: v),
                            ),
                          ],
                        ),
                        const Divider(height: 8),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _guestChip(String name, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 4, 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name.isEmpty ? 'Gość' : name,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent)),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(10),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.close, size: 14, color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required String title, Widget? trailing, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                child: Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
