import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/checklist_item.dart';
import 'firestore_service.dart';

/// Dane wydarzenia harmonogramu z formularza.
class ScheduleEventDraft {
  ScheduleEventDraft({
    required this.hour,
    required this.minute,
    required this.name,
    required this.description,
    required this.location,
    required this.responsible,
    required this.category,
    required this.private,
    required this.locationUrl,
    required this.showLinkToGuests,
  });

  final int hour;
  final int minute;
  final String name;
  final String description;
  final String location;
  final String responsible;
  final String category;
  final bool private;
  final String locationUrl;
  final bool showLinkToGuests;

  Map<String, dynamic> toFields() => {
        'hour': hour,
        'minute': minute,
        'name': name,
        'description': description,
        'location': location,
        'responsible': responsible,
        'category': category,
        'private': private,
        'locationUrl': locationUrl,
        'showLinkToGuests': showLinkToGuests,
      };
}

/// Operacje na harmonogramie (`scheduleEvents`) i checkliście (`checklist`).
class ScheduleService {
  ScheduleService({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  final FirestoreService _firestore;

  // ── HARMONOGRAM ──────────────────────────────────────────────────────

  Future<void> addEvent(ScheduleEventDraft draft) async {
    final data = await _read();
    final list = _mapList(data['scheduleEvents']);
    final nextId = _nextId(data['nextScheduleId'], list);
    list.add({
      'id': nextId,
      'duration': 60,
      ...draft.toFields(),
    });
    await _firestore.mainDoc.set({
      'scheduleEvents': list,
      'nextScheduleId': nextId + 1,
    }, SetOptions(merge: true));
  }

  Future<void> updateEvent(int id, ScheduleEventDraft draft) async {
    final data = await _read();
    final list = _mapList(data['scheduleEvents']);
    final item = _find(list, id);
    if (item == null) return;
    item.addAll(draft.toFields());
    await _firestore.mainDoc
        .set({'scheduleEvents': list}, SetOptions(merge: true));
  }

  Future<void> deleteEvent(int id) async {
    final data = await _read();
    final list = _mapList(data['scheduleEvents'])
      ..removeWhere((m) => _idOf(m) == id);
    await _firestore.mainDoc
        .set({'scheduleEvents': list}, SetOptions(merge: true));
  }

  /// Ustawia, czy wydarzenie jest widoczne dla gości na stronie /harmonogram
  /// (przechowywane jako `private = !visibleToGuests`).
  Future<void> setEventVisibility(int id, bool visibleToGuests) async {
    final data = await _read();
    final list = _mapList(data['scheduleEvents']);
    final item = _find(list, id);
    if (item == null) return;
    item['private'] = !visibleToGuests;
    await _firestore.mainDoc
        .set({'scheduleEvents': list}, SetOptions(merge: true));
  }

  // ── CHECKLISTA ───────────────────────────────────────────────────────

  Future<void> addChecklistItem(String category) async {
    final data = await _read();
    final list = _mapList(data['checklist']);
    final nextId = _nextId(data['nextChecklistId'], list);
    list.add({
      'id': nextId,
      'category': kChecklistCategories.contains(category)
          ? category
          : kChecklistCategories.first,
      'text': '',
      'done': false,
    });
    await _firestore.mainDoc.set({
      'checklist': list,
      'nextChecklistId': nextId + 1,
    }, SetOptions(merge: true));
  }

  Future<void> updateChecklistItem(int id, {String? text, bool? done}) async {
    final data = await _read();
    final list = _mapList(data['checklist']);
    final item = _find(list, id);
    if (item == null) return;
    if (text != null) item['text'] = text;
    if (done != null) item['done'] = done;
    await _firestore.mainDoc.set({'checklist': list}, SetOptions(merge: true));
  }

  Future<void> deleteChecklistItem(int id) async {
    final data = await _read();
    final list = _mapList(data['checklist'])..removeWhere((m) => _idOf(m) == id);
    await _firestore.mainDoc.set({'checklist': list}, SetOptions(merge: true));
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
