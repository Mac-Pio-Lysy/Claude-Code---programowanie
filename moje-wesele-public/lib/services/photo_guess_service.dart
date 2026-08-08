import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/photo_guess.dart';
import 'firestore_service.dart';
import 'legacy_scope.dart';

/// Operacje gry „Zgadnij zdjęcie".
///
/// PYTANIA (ze zdjęciami) są w `weddingPlanner/main` (tablica `photoQuestions`
/// + flaga `photoGuessActive`) — czytane publicznie przez `zgadnijzdjecie.html`.
/// WYNIKI są w OSOBNEJ kolekcji `photoGuessResults` (publiczny zapis).
/// Zdjęcia trzyma Cloudinary — tu zapisujemy tylko URL.
class PhotoGuessService {
  PhotoGuessService({FirestoreService? firestore, FirebaseFirestore? db})
      : _firestore = firestore ?? FirestoreService(),
        _db = db ?? FirebaseFirestore.instance;

  final FirestoreService _firestore;
  final FirebaseFirestore _db;

  static const String resultsCollection = 'photoGuessResults';

  // ── PYTANIA (w main doc) ─────────────────────────────────────────────

  Future<void> addQuestion({
    required String photoUrl,
    required String photoPublicId,
    required String question,
    required List<String> answers,
    required int correctIndex,
  }) async {
    final ans = _cleanAnswers(answers);
    if (photoUrl.isEmpty || question.trim().isEmpty || ans.length < 2) return;
    final data = await _read();
    final list = _mapList(data['photoQuestions']);
    final nextId = _nextId(data['nextPhotoQuestionId'], list);
    list.add({
      'id': nextId,
      'photoUrl': photoUrl,
      'photoPublicId': photoPublicId,
      'question': question.trim(),
      'answers': ans,
      'correctIndex': correctIndex.clamp(0, ans.length - 1),
    });
    await _firestore.mainDoc.set(
      {'photoQuestions': list, 'nextPhotoQuestionId': nextId + 1},
      SetOptions(merge: true),
    );
  }

  Future<void> updateQuestion(int id,
      {String? photoUrl,
      String? photoPublicId,
      String? question,
      List<String>? answers,
      int? correctIndex}) async {
    final data = await _read();
    final list = _mapList(data['photoQuestions']);
    final item = _find(list, id);
    if (item == null) return;
    if (photoUrl != null) item['photoUrl'] = photoUrl;
    if (photoPublicId != null) item['photoPublicId'] = photoPublicId;
    if (question != null) item['question'] = question.trim();
    if (answers != null) {
      final ans = _cleanAnswers(answers);
      if (ans.length >= 2) item['answers'] = ans;
    }
    if (correctIndex != null) {
      final len = (item['answers'] as List?)?.length ?? 1;
      item['correctIndex'] = correctIndex.clamp(0, len - 1);
    }
    await _firestore.mainDoc
        .set({'photoQuestions': list}, SetOptions(merge: true));
  }

  Future<void> deleteQuestion(int id) async {
    final data = await _read();
    final list = _mapList(data['photoQuestions'])
      ..removeWhere((m) => _idOf(m) == id);
    await _firestore.mainDoc
        .set({'photoQuestions': list}, SetOptions(merge: true));
  }

  Future<void> reorderQuestions(List<int> orderedIds) async {
    final data = await _read();
    final list = _mapList(data['photoQuestions']);
    final byId = {for (final m in list) _idOf(m): m};
    final result = <Map<String, dynamic>>[];
    for (final id in orderedIds) {
      final m = byId.remove(id);
      if (m != null) result.add(m);
    }
    result.addAll(byId.values);
    await _firestore.mainDoc
        .set({'photoQuestions': result}, SetOptions(merge: true));
  }

  Future<void> setActive(bool value) => _firestore.mainDoc
      .set({'photoGuessActive': value}, SetOptions(merge: true));

  // ── WYNIKI (osobna kolekcja) ─────────────────────────────────────────

  Stream<List<PhotoGuessResult>> watchResults() =>
      LegacyScope.scoped(_db.collection(resultsCollection))
          .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(PhotoGuessResult.fromDoc).toList());

  Future<void> deleteResult(String id) =>
      _db.collection(resultsCollection).doc(id).delete();

  // ── Pomocnicze ──
  List<String> _cleanAnswers(List<String> answers) => answers
      .map((a) => a.trim())
      .where((a) => a.isNotEmpty)
      .take(4)
      .toList();

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
