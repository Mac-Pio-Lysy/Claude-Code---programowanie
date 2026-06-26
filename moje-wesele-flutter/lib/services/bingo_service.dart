import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_service.dart';

/// Operacje na bazie pól bingo i ustawieniach generatora.
class BingoService {
  BingoService({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  final FirestoreService _firestore;

  Future<void> addField(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    final data = await _read();
    final list = _mapList(data['bingoFields']);
    final nextId = _nextId(data['nextBingoFieldId'], list);
    list.add({'id': nextId, 'text': t, 'enabled': true});
    await _firestore.mainDoc.set(
      {'bingoFields': list, 'nextBingoFieldId': nextId + 1},
      SetOptions(merge: true),
    );
  }

  Future<void> updateField(int id, {String? text, bool? enabled}) async {
    final data = await _read();
    final list = _mapList(data['bingoFields']);
    final item = _find(list, id);
    if (item == null) return;
    if (text != null) item['text'] = text;
    if (enabled != null) item['enabled'] = enabled;
    await _firestore.mainDoc.set({'bingoFields': list}, SetOptions(merge: true));
  }

  Future<void> deleteField(int id) async {
    final data = await _read();
    final list = _mapList(data['bingoFields'])
      ..removeWhere((m) => _idOf(m) == id);
    await _firestore.mainDoc.set({'bingoFields': list}, SetOptions(merge: true));
  }

  Future<void> setUseSchedule(bool value) => _firestore.mainDoc
      .set({'bingoUseSchedule': value}, SetOptions(merge: true));

  Future<void> setCenterMode(String mode) => _firestore.mainDoc
      .set({'bingoCenterMode': mode}, SetOptions(merge: true));

  /// Ustawia, czy wydarzenie harmonogramu jest wykluczone z puli bingo.
  Future<void> setScheduleEventExcluded(int eventId, bool excluded) async {
    final data = await _read();
    final list = _intList(data['bingoScheduleExclude']);
    if (excluded) {
      if (!list.contains(eventId)) list.add(eventId);
    } else {
      list.remove(eventId);
    }
    await _firestore.mainDoc
        .set({'bingoScheduleExclude': list}, SetOptions(merge: true));
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
