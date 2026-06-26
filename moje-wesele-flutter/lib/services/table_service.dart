import 'dart:math';
import 'dart:ui' show Offset;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_service.dart';

/// Dane z formularza dodawania stołu.
class TableDraft {
  TableDraft({
    required this.name,
    required this.shape,
    required this.seats,
    required this.isHonor,
  });

  final String name;
  final String shape; // 'round' | 'rect'
  final int seats;
  final bool isHonor;
}

/// Operacje na stołach i przypisaniach gości w `weddingPlanner/main`.
///
/// KLUCZOWE: przypisanie utrzymuje spójność dwóch struktur (jak w wersji web):
///  • `table.seatsData[i] = guestId | null`
///  • `guest.tableId` / `guest.seatIndex`
/// Każdy zapis aktualizuje OBA pola (`tables` i `guests`) naraz, przez
/// `set(..., merge: true)`, więc reszta dokumentu pozostaje nietknięta.
class TableService {
  TableService({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  final FirestoreService _firestore;

  /// Dodaje nowy stół (jak `addTable()` w wersji web).
  Future<void> addTable(TableDraft draft) async {
    final data = await _firestore.readData() ?? <String, dynamic>{};
    final tables = _mapList(data['tables']);
    var nextId = _nextTableId(data, tables);
    final pos = _autoTablePos(tables.length);
    // Stół honorowy używa układu prostokątnego (jak w wersji web).
    final shape = draft.isHonor ? 'rect' : draft.shape;

    tables.add({
      'id': nextId,
      'name': draft.name.isNotEmpty ? draft.name : 'Stół $nextId',
      'shape': shape,
      'seats': draft.seats,
      'seatsData': List<dynamic>.filled(draft.seats, null, growable: true),
      'posX': pos.dx,
      'posY': pos.dy,
      'diamM': 0,
      'rectWM': 0,
      'rectLM': 0,
      if (draft.isHonor) 'isHonorTable': true,
    });
    nextId++;

    await _firestore.mainDoc.set(
      {'tables': tables, 'nextTableId': nextId},
      SetOptions(merge: true),
    );
  }

  /// Usuwa stół i zwalnia wszystkich przypisanych do niego gości.
  Future<void> deleteTable(int tableId) async {
    final data = await _firestore.readData() ?? <String, dynamic>{};
    final tables = _mapList(data['tables']);
    final guests = _mapList(data['guests']);
    final table = _find(tables, tableId);
    if (table == null) return;

    for (final gid in (table['seatsData'] as List? ?? const [])) {
      final id = (gid as num?)?.toInt();
      if (id == null) continue;
      final g = _find(guests, id);
      if (g != null) {
        g['tableId'] = null;
        g['seatIndex'] = null;
      }
    }
    tables.removeWhere((t) => _idOf(t) == tableId);

    await _firestore.mainDoc.set(
      {'tables': tables, 'guests': guests},
      SetOptions(merge: true),
    );
  }

  /// Przypisuje gościa do pierwszego wolnego miejsca przy stole
  /// (jak `_assignToTable()` w wersji web). Zwraca `false`, gdy stół pełny.
  Future<bool> assignGuestToTable(int tableId, int guestId) async {
    final data = await _firestore.readData() ?? <String, dynamic>{};
    final tables = _mapList(data['tables']);
    final guests = _mapList(data['guests']);
    final table = _find(tables, tableId);
    final guest = _find(guests, guestId);
    if (table == null || guest == null) return false;

    final seats = List<dynamic>.from(table['seatsData'] as List? ?? const []);
    final freeSeat = seats.indexOf(null);
    if (freeSeat == -1) return false; // stół pełny
    if ((guest['tableId'] as num?)?.toInt() == tableId) return true; // już tutaj

    _clearSeat(tables, guest);

    seats[freeSeat] = guestId;
    table['seatsData'] = seats;
    guest['tableId'] = tableId;
    guest['seatIndex'] = freeSeat;

    await _firestore.mainDoc.set(
      {'tables': tables, 'guests': guests},
      SetOptions(merge: true),
    );
    return true;
  }

  /// Usuwa gościa ze stołu (zwalnia miejsce).
  Future<void> unassignGuest(int guestId) async {
    final data = await _firestore.readData() ?? <String, dynamic>{};
    final tables = _mapList(data['tables']);
    final guests = _mapList(data['guests']);
    final guest = _find(guests, guestId);
    if (guest == null || guest['tableId'] == null) return;

    _clearSeat(tables, guest);
    guest['tableId'] = null;
    guest['seatIndex'] = null;

    await _firestore.mainDoc.set(
      {'tables': tables, 'guests': guests},
      SetOptions(merge: true),
    );
  }

  // ── Pomocnicze ─────────────────────────────────────────────────────────

  /// Zwalnia dotychczasowe miejsce gościa w tablicy [tables] (mutuje na miejscu).
  void _clearSeat(List<Map<String, dynamic>> tables, Map<String, dynamic> guest) {
    final oldTableId = (guest['tableId'] as num?)?.toInt();
    final oldSeat = (guest['seatIndex'] as num?)?.toInt();
    if (oldTableId == null) return;
    final oldTable = _find(tables, oldTableId);
    if (oldTable != null && oldSeat != null) {
      final seats = List<dynamic>.from(oldTable['seatsData'] as List? ?? const []);
      if (oldSeat >= 0 && oldSeat < seats.length) {
        seats[oldSeat] = null;
        oldTable['seatsData'] = seats;
      }
    }
  }

  /// Automatyczne położenie stołu w siatce (jak `autoTablePos()` w wersji web).
  Offset _autoTablePos(int index) {
    const cols = 5;
    final col = index % cols;
    final row = index ~/ cols;
    return Offset(60 + col * 230, 70 + row * 230);
  }

  int _nextTableId(Map<String, dynamic> data, List<Map<String, dynamic>> tables) {
    final stored = (data['nextTableId'] as num?)?.toInt() ?? 1;
    var maxId = 0;
    for (final t in tables) {
      final i = _idOf(t) ?? 0;
      if (i > maxId) maxId = i;
    }
    return max(stored, maxId + 1);
  }

  List<Map<String, dynamic>> _mapList(dynamic value) => value is List
      ? value.map((e) => Map<String, dynamic>.from(e as Map)).toList()
      : <Map<String, dynamic>>[];

  Map<String, dynamic>? _find(List<Map<String, dynamic>> list, int id) {
    for (final m in list) {
      if (_idOf(m) == id) return m;
    }
    return null;
  }

  int? _idOf(Map<String, dynamic> m) => (m['id'] as num?)?.toInt();
}
