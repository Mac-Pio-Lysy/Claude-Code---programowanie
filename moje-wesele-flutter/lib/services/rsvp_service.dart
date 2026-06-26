import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_service.dart';

/// Operacje na potwierdzeniach (`rsvpEntries`) w `weddingPlanner/main`.
class RsvpService {
  RsvpService({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  final FirestoreService _firestore;

  /// Ręczne ustawienie statusu gościa (np. „za babcię") — zastępuje wpisy gościa.
  Future<void> setGuestStatus(int guestId, String status) async {
    final data = await _read();
    final list = _mapList(data['rsvpEntries'])
      ..removeWhere((e) => (e['guestId'] as num?)?.toInt() == guestId);
    final nextId = _nextId(data['nextRsvpId'], list);
    list.add({
      'id': nextId,
      'rawName': '',
      'status': status,
      'message': '',
      'guestId': guestId,
      'manual': true,
      'timestamp': DateTime.now().toIso8601String(),
      'companionName': '',
    });
    await _firestore.mainDoc.set(
      {'rsvpEntries': list, 'nextRsvpId': nextId + 1},
      SetOptions(merge: true),
    );
  }

  /// Czyści status gościa (powrót do „brak odpowiedzi").
  Future<void> clearGuestStatus(int guestId) async {
    final data = await _read();
    final list = _mapList(data['rsvpEntries'])
      ..removeWhere((e) => (e['guestId'] as num?)?.toInt() == guestId);
    await _firestore.mainDoc.set({'rsvpEntries': list}, SetOptions(merge: true));
  }

  /// Przypisuje nierozpoznany wpis do konkretnego gościa.
  Future<void> assignEntry(int entryId, int guestId) async {
    final data = await _read();
    final list = _mapList(data['rsvpEntries']);
    final entry = _find(list, entryId);
    if (entry == null) return;
    entry['guestId'] = guestId;
    entry['manual'] = true;
    await _firestore.mainDoc.set({'rsvpEntries': list}, SetOptions(merge: true));
  }

  Future<void> deleteEntry(int entryId) async {
    final data = await _read();
    final list = _mapList(data['rsvpEntries'])
      ..removeWhere((e) => _idOf(e) == entryId);
    await _firestore.mainDoc.set({'rsvpEntries': list}, SetOptions(merge: true));
  }

  Future<void> clearAll() =>
      _firestore.mainDoc.set({'rsvpEntries': <dynamic>[]}, SetOptions(merge: true));

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
