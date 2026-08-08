import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/photo_challenge.dart';
import 'firestore_service.dart';
import 'legacy_scope.dart';

/// Operacje gry „Foto-wyzwania".
///
/// WYZWANIA (zadania) są w `weddingPlanner/main` (tablica `photoChallengeTasks`
/// + flaga `photoChallengesActive`) — czytane publicznie przez
/// `fotowyzwania.html`. ZDJĘCIA gości są w OSOBNEJ kolekcji `photoChallenges`
/// (publiczny zapis; upload przez Cloudinary). Tu zapisujemy tylko URL.
class PhotoChallengeService {
  PhotoChallengeService({FirestoreService? firestore, FirebaseFirestore? db})
      : _firestore = firestore ?? FirestoreService(),
        _db = db ?? FirebaseFirestore.instance;

  final FirestoreService _firestore;
  final FirebaseFirestore _db;

  static const String submissionsCollection = 'photoChallenges';

  /// Przykładowe wyzwania na start.
  static const List<({String text, int points})> examples = [
    (text: 'Zrób selfie z Parą Młodą', points: 3),
    (text: 'Sfotografuj najpiękniejszy toast', points: 2),
    (text: 'Znajdź i sfotografuj najstarszego gościa', points: 2),
    (text: 'Zdjęcie z parkietu', points: 1),
    (text: 'Grupowe zdjęcie Twojego stolika', points: 2),
    (text: 'Uchwyć pierwszy taniec', points: 3),
  ];

  // ── WYZWANIA (w main doc) ────────────────────────────────────────────

  Future<void> addTask(String text, int points) async {
    final t = text.trim();
    if (t.isEmpty) return;
    final data = await _read();
    final list = _mapList(data['photoChallengeTasks']);
    final nextId = _nextId(data['nextPhotoChallengeId'], list);
    list.add({'id': nextId, 'text': t, 'points': points < 0 ? 0 : points});
    await _firestore.setAndSync(
      {'photoChallengeTasks': list, 'nextPhotoChallengeId': nextId + 1},
      SetOptions(merge: true),
    );
  }

  Future<void> updateTask(int id, {String? text, int? points}) async {
    final data = await _read();
    final list = _mapList(data['photoChallengeTasks']);
    final item = _find(list, id);
    if (item == null) return;
    if (text != null) item['text'] = text.trim();
    if (points != null) item['points'] = points < 0 ? 0 : points;
    await _firestore.setAndSync({'photoChallengeTasks': list}, SetOptions(merge: true));
  }

  Future<void> deleteTask(int id) async {
    final data = await _read();
    final list = _mapList(data['photoChallengeTasks'])
      ..removeWhere((m) => _idOf(m) == id);
    await _firestore.setAndSync({'photoChallengeTasks': list}, SetOptions(merge: true));
  }

  Future<void> reorderTasks(List<int> orderedIds) async {
    final data = await _read();
    final list = _mapList(data['photoChallengeTasks']);
    final byId = {for (final m in list) _idOf(m): m};
    final result = <Map<String, dynamic>>[];
    for (final id in orderedIds) {
      final m = byId.remove(id);
      if (m != null) result.add(m);
    }
    result.addAll(byId.values);
    await _firestore.setAndSync({'photoChallengeTasks': result}, SetOptions(merge: true));
  }

  Future<void> setActive(bool value) => _firestore.setAndSync({'photoChallengesActive': value}, SetOptions(merge: true));

  Future<void> seedExamples() async {
    final data = await _read();
    final list = _mapList(data['photoChallengeTasks']);
    if (list.isNotEmpty) return;
    var nextId = _nextId(data['nextPhotoChallengeId'], list);
    for (final e in examples) {
      list.add({'id': nextId, 'text': e.text, 'points': e.points});
      nextId++;
    }
    await _firestore.setAndSync(
      {'photoChallengeTasks': list, 'nextPhotoChallengeId': nextId},
      SetOptions(merge: true),
    );
  }

  // ── ZDJĘCIA (osobna kolekcja) ────────────────────────────────────────

  Stream<List<PhotoChallengeSubmission>> watchSubmissions() =>
      LegacyScope.scoped(_db.collection(submissionsCollection))
          .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map(PhotoChallengeSubmission.fromDoc).toList());

  Future<void> deleteSubmission(String id) =>
      _db.collection(submissionsCollection).doc(id).delete();

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
