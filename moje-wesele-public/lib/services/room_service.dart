import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/room_plan.dart';
import 'firestore_service.dart';

/// Operacje na planie sali: wymiary (`roomMeta`), pozycje/rozmiary stołów
/// (`tables`) oraz elementy sali (`roomElements`).
///
/// Przypisywanie gości i dodawanie/usuwanie stołów obsługuje [TableService].
class RoomService {
  RoomService({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  final FirestoreService _firestore;

  // ── WYMIARY SALI ─────────────────────────────────────────────────────

  Future<void> setMeta(String field, num value) => _firestore.mainDoc.set({
        'roomMeta': {field: max(0, value)},
      }, SetOptions(merge: true));

  // ── STOŁY (pozycja / rozmiar na planie) ──────────────────────────────

  Future<void> moveTable(int id, double x, double y) async {
    final data = await _read();
    final tables = _mapList(data['tables']);
    final t = _find(tables, id);
    if (t == null) return;
    t['posX'] = x.round();
    t['posY'] = y.round();
    await _firestore.mainDoc.set({'tables': tables}, SetOptions(merge: true));
  }

  Future<void> resizeTable(int id,
      {num? diamM, num? rectWM, num? rectLM}) async {
    final data = await _read();
    final tables = _mapList(data['tables']);
    final t = _find(tables, id);
    if (t == null) return;
    if (diamM != null) t['diamM'] = diamM;
    if (rectWM != null) t['rectWM'] = rectWM;
    if (rectLM != null) t['rectLM'] = rectLM;
    // Po zmianie rozmiaru: docinamy pozycję do obrysu sali.
    final geo = RoomGeometry.fromMeta(data['roomMeta'] as Map?);
    final (cx, cy) = geo.clampTable(
        t, (t['posX'] as num?)?.toDouble() ?? 0, (t['posY'] as num?)?.toDouble() ?? 0);
    t['posX'] = cx.round();
    t['posY'] = cy.round();
    await _firestore.mainDoc.set({'tables': tables}, SetOptions(merge: true));
  }

  // ── ELEMENTY SALI ────────────────────────────────────────────────────

  Future<void> addElement({
    required String name,
    required num wM,
    required num lM,
  }) async {
    final data = await _read();
    final list = _mapList(data['roomElements']);
    final nextId = _nextId(data['nextRoomElementId'], list);
    final idx = list.length;
    final el = <String, dynamic>{
      'id': nextId,
      'name': name,
      'type': RoomElementType.typeOf(name),
      'wM': wM,
      'lM': lM,
      'posX': 40 + (idx % 6) * 130,
      'posY': 40 + (idx ~/ 6) * 110,
      'rotation': 0,
    };
    final geo = RoomGeometry.fromMeta(data['roomMeta'] as Map?);
    final (cx, cy) = geo.clampElement(
        el, (el['posX'] as num).toDouble(), (el['posY'] as num).toDouble());
    el['posX'] = cx.round();
    el['posY'] = cy.round();
    list.add(el);
    await _firestore.mainDoc.set(
      {'roomElements': list, 'nextRoomElementId': nextId + 1},
      SetOptions(merge: true),
    );
  }

  Future<void> moveElement(int id, double x, double y) async {
    final data = await _read();
    final list = _mapList(data['roomElements']);
    final el = _find(list, id);
    if (el == null) return;
    el['posX'] = x.round();
    el['posY'] = y.round();
    await _firestore.mainDoc
        .set({'roomElements': list}, SetOptions(merge: true));
  }

  Future<void> resizeElement(int id, {num? wM, num? lM}) async {
    final data = await _read();
    final list = _mapList(data['roomElements']);
    final el = _find(list, id);
    if (el == null) return;
    if (wM != null) el['wM'] = wM;
    if (lM != null) el['lM'] = lM;
    await _firestore.mainDoc
        .set({'roomElements': list}, SetOptions(merge: true));
  }

  Future<void> rotateElement(int id) async {
    final data = await _read();
    final list = _mapList(data['roomElements']);
    final el = _find(list, id);
    if (el == null) return;
    el['rotation'] = (((el['rotation'] as num?)?.toInt() ?? 0) + 90) % 360;
    await _firestore.mainDoc
        .set({'roomElements': list}, SetOptions(merge: true));
  }

  Future<void> deleteElement(int id) async {
    final data = await _read();
    final list = _mapList(data['roomElements'])
      ..removeWhere((m) => _idOf(m) == id);
    await _firestore.mainDoc
        .set({'roomElements': list}, SetOptions(merge: true));
  }

  // ── Pomocnicze ──
  Future<Map<String, dynamic>> _read() async =>
      await _firestore.readData() ?? <String, dynamic>{};

  List<Map<String, dynamic>> _mapList(dynamic value) => value is List
      ? value.map((e) => Map<String, dynamic>.from(e as Map)).toList()
      : <Map<String, dynamic>>[];

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
