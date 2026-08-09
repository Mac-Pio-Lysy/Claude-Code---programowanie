import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/true_false.dart';
import 'firestore_service.dart';
import 'legacy_scope.dart';

/// Operacje gry „Prawda czy Fałsz".
///
/// STWIERDZENIA są w `weddingPlanner/main` (tablica `tfStatements` + flaga
/// `tfActive`) — czytane publicznie przez `prawdafalsz.html`. WYNIKI są w
/// OSOBNEJ kolekcji `trueFalseResults` (publiczny zapis, jak quizResults).
class TrueFalseService {
  TrueFalseService({FirestoreService? firestore, FirebaseFirestore? db})
      : _firestore = firestore ?? FirestoreService(),
        _db = db ?? FirebaseFirestore.instance;

  final FirestoreService _firestore;
  final FirebaseFirestore _db;

  static const String resultsCollection = 'trueFalseResults';

  /// Przykładowe stwierdzenia na start.
  static const List<({String text, bool isTrue, String explanation})> examples = [
    (
      text: 'Para Młoda poznała się w pracy',
      isTrue: false,
      explanation: 'Poznali się przez wspólnych znajomych.'
    ),
    (
      text: 'Pierwsza randka była w kinie',
      isTrue: false,
      explanation: 'Pierwsza randka była w kawiarni.'
    ),
    (
      // Bez rodzaju gramatycznego — to samo zdanie pasuje do każdej pary.
      text: 'Oświadczyny odbyły się za granicą',
      isTrue: true,
      explanation: 'Oświadczyny odbyły się podczas wspólnego wyjazdu.'
    ),
  ];

  // ── STWIERDZENIA (w main doc) ────────────────────────────────────────

  Future<void> addStatement(String text, bool isTrue, String explanation) async {
    final t = text.trim();
    if (t.isEmpty) return;
    final data = await _read();
    final list = _mapList(data['tfStatements']);
    final nextId = _nextId(data['nextTfId'], list);
    list.add({
      'id': nextId,
      'text': t,
      'isTrue': isTrue,
      'explanation': explanation.trim(),
    });
    await _firestore.setAndSync(
      {'tfStatements': list, 'nextTfId': nextId + 1},
      SetOptions(merge: true),
    );
  }

  Future<void> updateStatement(int id,
      {String? text, bool? isTrue, String? explanation}) async {
    final data = await _read();
    final list = _mapList(data['tfStatements']);
    final item = _find(list, id);
    if (item == null) return;
    if (text != null) item['text'] = text.trim();
    if (isTrue != null) item['isTrue'] = isTrue;
    if (explanation != null) item['explanation'] = explanation.trim();
    await _firestore.setAndSync({'tfStatements': list}, SetOptions(merge: true));
  }

  Future<void> deleteStatement(int id) async {
    final data = await _read();
    final list = _mapList(data['tfStatements'])
      ..removeWhere((m) => _idOf(m) == id);
    await _firestore.setAndSync({'tfStatements': list}, SetOptions(merge: true));
  }

  /// Zapisuje nową kolejność stwierdzeń (po przeciągnięciu na liście).
  Future<void> reorderStatements(List<int> orderedIds) async {
    final data = await _read();
    final list = _mapList(data['tfStatements']);
    final byId = {for (final m in list) _idOf(m): m};
    final result = <Map<String, dynamic>>[];
    for (final id in orderedIds) {
      final m = byId.remove(id);
      if (m != null) result.add(m);
    }
    result.addAll(byId.values);
    await _firestore.setAndSync({'tfStatements': result}, SetOptions(merge: true));
  }

  Future<void> setActive(bool value) =>
      _firestore.setAndSync({'tfActive': value}, SetOptions(merge: true));

  /// Dodaje przykładowe stwierdzenia (tylko gdy lista jest pusta).
  Future<void> seedExamples() async {
    final data = await _read();
    final list = _mapList(data['tfStatements']);
    if (list.isNotEmpty) return;
    var nextId = _nextId(data['nextTfId'], list);
    for (final e in examples) {
      list.add({
        'id': nextId,
        'text': e.text,
        'isTrue': e.isTrue,
        'explanation': e.explanation,
      });
      nextId++;
    }
    await _firestore.setAndSync(
      {'tfStatements': list, 'nextTfId': nextId},
      SetOptions(merge: true),
    );
  }

  // ── WYNIKI (osobna kolekcja) ─────────────────────────────────────────

  Stream<List<TFResult>> watchResults() =>
      LegacyScope.scoped(_db.collection(resultsCollection))
          .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(TFResult.fromDoc).toList());

  Future<void> deleteResult(String id) =>
      _db.collection(resultsCollection).doc(id).delete();

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
