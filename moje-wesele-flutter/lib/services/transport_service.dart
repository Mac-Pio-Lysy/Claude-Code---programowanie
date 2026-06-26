import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_service.dart';

/// Dane pojazdu z formularza.
class VehicleDraft {
  VehicleDraft({
    required this.type,
    required this.description,
    required this.driver,
    required this.seats,
    required this.route,
    required this.departureTime,
    required this.cost,
  });

  final String type;
  final String description;
  final String driver;
  final int seats;
  final String route;
  final String departureTime;
  final num cost;

  Map<String, dynamic> toFields() => {
        'type': type,
        'description': description,
        'driver': driver,
        'seats': seats,
        'route': route,
        'departureTime': departureTime,
        'cost': cost,
      };
}

/// Operacje na transporcie (`vehicles`, `internalTransport`) i przypisaniach
/// gości (`guest.vehicleId`, `guest.ownTransport`).
class TransportService {
  TransportService({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  final FirestoreService _firestore;

  // ── POJAZDY ──────────────────────────────────────────────────────────

  Future<void> addVehicle(VehicleDraft draft) async {
    final data = await _read();
    final vehicles = _mapList(data['vehicles']);
    final nextId = _nextId(data['nextVehicleId'], vehicles);
    vehicles.add({
      'id': nextId,
      'guestIds': <dynamic>[],
      ...draft.toFields(),
    });
    await _firestore.mainDoc.set(
      {'vehicles': vehicles, 'nextVehicleId': nextId + 1},
      SetOptions(merge: true),
    );
  }

  Future<void> updateVehicle(int id, VehicleDraft draft) async {
    final data = await _read();
    final vehicles = _mapList(data['vehicles']);
    final v = _find(vehicles, id);
    if (v == null) return;
    v.addAll(draft.toFields());
    await _firestore.mainDoc.set({'vehicles': vehicles}, SetOptions(merge: true));
  }

  Future<void> deleteVehicle(int id) async {
    final data = await _read();
    final vehicles = _mapList(data['vehicles']);
    final guests = _mapList(data['guests']);
    final v = _find(vehicles, id);
    if (v == null) return;
    for (final gid in _intList(v['guestIds'])) {
      final g = _find(guests, gid);
      if (g != null) g['vehicleId'] = null;
    }
    vehicles.removeWhere((x) => _idOf(x) == id);
    await _firestore.mainDoc
        .set({'vehicles': vehicles, 'guests': guests}, SetOptions(merge: true));
  }

  /// Przypisuje gościa do pojazdu (lub odpina, gdy [vehicleId] == null).
  Future<void> assignGuestToVehicle(int guestId, int? vehicleId) async {
    final data = await _read();
    final vehicles = _mapList(data['vehicles']);
    final guests = _mapList(data['guests']);

    // Usuń gościa ze wszystkich pojazdów.
    for (final v in vehicles) {
      v['guestIds'] = _intList(v['guestIds'])..remove(guestId);
    }

    final g = _find(guests, guestId);
    if (g != null) {
      g['vehicleId'] = vehicleId;
      if (vehicleId != null) g['ownTransport'] = false;
    }
    if (vehicleId != null) {
      final v = _find(vehicles, vehicleId);
      if (v != null) {
        v['guestIds'] = [..._intList(v['guestIds']), guestId];
      }
    }
    await _firestore.mainDoc
        .set({'vehicles': vehicles, 'guests': guests}, SetOptions(merge: true));
  }

  /// Włącza/wyłącza „transport własny" dla gościa.
  Future<void> setGuestOwnTransport(int guestId, bool on) async {
    final data = await _read();
    final vehicles = _mapList(data['vehicles']);
    final guests = _mapList(data['guests']);
    final g = _find(guests, guestId);
    if (g == null) return;
    if (on) {
      for (final v in vehicles) {
        v['guestIds'] = _intList(v['guestIds'])..remove(guestId);
      }
      g['vehicleId'] = null;
    }
    g['ownTransport'] = on;
    await _firestore.mainDoc
        .set({'vehicles': vehicles, 'guests': guests}, SetOptions(merge: true));
  }

  // ── TRANSPORT WEWNĘTRZNY ─────────────────────────────────────────────

  Future<void> addInternalTransport() async {
    final data = await _read();
    final list = _mapList(data['internalTransport']);
    final nextId = _nextId(data['nextInternalTransportId'], list);
    list.add({'id': nextId, 'type': 'Bolt', 'info': '', 'showToGuests': true});
    await _firestore.mainDoc.set(
      {'internalTransport': list, 'nextInternalTransportId': nextId + 1},
      SetOptions(merge: true),
    );
  }

  Future<void> updateInternalTransport(int id,
      {String? type, String? info, bool? showToGuests}) async {
    final data = await _read();
    final list = _mapList(data['internalTransport']);
    final it = _find(list, id);
    if (it == null) return;
    if (type != null) it['type'] = type;
    if (info != null) it['info'] = info;
    if (showToGuests != null) it['showToGuests'] = showToGuests;
    await _firestore.mainDoc
        .set({'internalTransport': list}, SetOptions(merge: true));
  }

  Future<void> deleteInternalTransport(int id) async {
    final data = await _read();
    final list = _mapList(data['internalTransport'])
      ..removeWhere((m) => _idOf(m) == id);
    await _firestore.mainDoc
        .set({'internalTransport': list}, SetOptions(merge: true));
  }

  // ── Pomocnicze ──
  Future<Map<String, dynamic>> _read() async =>
      await _firestore.readData() ?? <String, dynamic>{};

  List<Map<String, dynamic>> _mapList(dynamic value) => value is List
      ? value.map((e) => Map<String, dynamic>.from(e as Map)).toList()
      : <Map<String, dynamic>>[];

  List<int> _intList(dynamic value) => value is List
      ? value.map((e) => (e as num?)?.toInt()).whereType<int>().toList()
      : <int>[];

  int _nextId(dynamic stored, List<Map<String, dynamic>> list) {
    final s = (stored as num?)?.toInt() ?? 1;
    var maxId = 0;
    for (final m in list) {
      final i = _idOf(m) ?? 0;
      if (i > maxId) maxId = i;
    }
    return max(s, maxId + 1);
  }

  Map<String, dynamic>? _find(List<Map<String, dynamic>> list, int id) {
    for (final m in list) {
      if (_idOf(m) == id) return m;
    }
    return null;
  }

  int? _idOf(Map<String, dynamic> m) => (m['id'] as num?)?.toInt();
}
