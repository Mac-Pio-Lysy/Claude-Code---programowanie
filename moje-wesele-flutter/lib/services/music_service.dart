import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_service.dart';

/// Operacje na liście piosenek (`songs`) w `weddingPlanner/main`.
class MusicService {
  MusicService({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  final FirestoreService _firestore;

  /// Dodaje utwór. [unmatched] = true dla utworów spoza Deezer (do weryfikacji).
  Future<void> addSong({
    required String title,
    required String artist,
    String cover = '',
    String preview = '',
    String moment = 'Inne',
    String genre = '',
    String status = 'proposal',
    bool fromGuest = false,
    String guestName = '',
    bool unmatched = false,
  }) async {
    final data = await _read();
    final list = _mapList(data['songs']);
    final nextId = _nextId(data['nextSongId'], list);
    list.add({
      'id': nextId,
      'title': title,
      'artist': artist,
      'cover': cover,
      'preview': preview,
      'moment': moment,
      'genre': genre,
      'status': status,
      'fromGuest': fromGuest,
      'guestName': guestName,
      'unmatched': unmatched,
    });
    await _firestore.mainDoc
        .set({'songs': list, 'nextSongId': nextId + 1}, SetOptions(merge: true));
  }

  Future<void> updateSong(int id,
      {String? title,
      String? artist,
      String? moment,
      String? genre,
      String? status}) async {
    final data = await _read();
    final list = _mapList(data['songs']);
    final item = _find(list, id);
    if (item == null) return;
    if (title != null) item['title'] = title;
    if (artist != null) item['artist'] = artist;
    if (moment != null) item['moment'] = moment;
    if (genre != null) item['genre'] = genre;
    if (status != null) item['status'] = status;
    await _firestore.mainDoc.set({'songs': list}, SetOptions(merge: true));
  }

  Future<void> deleteSong(int id) async {
    final data = await _read();
    final list = _mapList(data['songs'])..removeWhere((m) => _idOf(m) == id);
    await _firestore.mainDoc.set({'songs': list}, SetOptions(merge: true));
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
