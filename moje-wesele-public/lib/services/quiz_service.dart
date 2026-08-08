import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/quiz.dart';
import 'firestore_service.dart';
import 'legacy_scope.dart';

/// Operacje quizu o Parze Młodej.
///
/// PYTANIA są w `weddingPlanner/main` (tablica `quizQuestions` + flaga
/// `quizActive`) — czytane publicznie przez `quiz.html` (reguła weddingPlanner).
/// WYNIKI są w OSOBNEJ kolekcji `quizResults` (publiczny zapis, jak guestbook/
/// musicProposals) — nie ruszają danych planera.
class QuizService {
  QuizService({FirestoreService? firestore, FirebaseFirestore? db})
      : _firestore = firestore ?? FirestoreService(),
        _db = db ?? FirebaseFirestore.instance;

  final FirestoreService _firestore;
  final FirebaseFirestore _db;

  static const String resultsCollection = 'quizResults';

  /// Przykładowe pytania na start (gdy organizator nie ma jeszcze własnych).
  static const List<({String q, List<String> a, int correct})> examples = [
    (
      q: 'Gdzie się poznaliśmy?',
      a: ['W pracy', 'Na studiach', 'Przez znajomych', 'W wakacje'],
      correct: 0
    ),
    (
      q: 'Ulubiony film Pana Młodego?',
      a: ['Incepcja', 'Gladiator', 'Forrest Gump', 'Skazani na Shawshank'],
      correct: 3
    ),
    (
      q: 'Gdzie była nasza pierwsza randka?',
      a: ['W kinie', 'W restauracji', 'Na spacerze', 'W kawiarni'],
      correct: 3
    ),
    (
      q: 'Kto się pierwszy oświadczył?',
      a: ['Pan Młody', 'Panna Młoda'],
      correct: 0
    ),
  ];

  // ── PYTANIA (w main doc) ─────────────────────────────────────────────

  Future<void> addQuestion(
      String question, List<String> answers, int correctIndex) async {
    final q = question.trim();
    final ans = _cleanAnswers(answers);
    if (q.isEmpty || ans.length < 2) return;
    final data = await _read();
    final list = _mapList(data['quizQuestions']);
    final nextId = _nextId(data['nextQuizQuestionId'], list);
    list.add({
      'id': nextId,
      'question': q,
      'answers': ans,
      'correctIndex': correctIndex.clamp(0, ans.length - 1),
    });
    await _firestore.setAndSync(
      {'quizQuestions': list, 'nextQuizQuestionId': nextId + 1},
      SetOptions(merge: true),
    );
  }

  Future<void> updateQuestion(int id,
      {String? question, List<String>? answers, int? correctIndex}) async {
    final data = await _read();
    final list = _mapList(data['quizQuestions']);
    final item = _find(list, id);
    if (item == null) return;
    if (question != null) item['question'] = question.trim();
    if (answers != null) {
      final ans = _cleanAnswers(answers);
      if (ans.length >= 2) item['answers'] = ans;
    }
    if (correctIndex != null) {
      final len = (item['answers'] as List?)?.length ?? 1;
      item['correctIndex'] = correctIndex.clamp(0, len - 1);
    }
    await _firestore.setAndSync({'quizQuestions': list}, SetOptions(merge: true));
  }

  Future<void> deleteQuestion(int id) async {
    final data = await _read();
    final list = _mapList(data['quizQuestions'])
      ..removeWhere((m) => _idOf(m) == id);
    await _firestore.setAndSync({'quizQuestions': list}, SetOptions(merge: true));
  }

  /// Zapisuje nową kolejność pytań (po przeciągnięciu na liście).
  Future<void> reorderQuestions(List<int> orderedIds) async {
    final data = await _read();
    final list = _mapList(data['quizQuestions']);
    final byId = {for (final m in list) _idOf(m): m};
    final result = <Map<String, dynamic>>[];
    for (final id in orderedIds) {
      final m = byId.remove(id);
      if (m != null) result.add(m);
    }
    result.addAll(byId.values); // dopisz ewentualne brakujące
    await _firestore.setAndSync({'quizQuestions': result}, SetOptions(merge: true));
  }

  Future<void> setActive(bool value) =>
      _firestore.setAndSync({'quizActive': value}, SetOptions(merge: true));

  /// Dodaje przykładowe pytania (tylko gdy lista jest pusta).
  Future<void> seedExamples() async {
    final data = await _read();
    final list = _mapList(data['quizQuestions']);
    if (list.isNotEmpty) return;
    var nextId = _nextId(data['nextQuizQuestionId'], list);
    for (final e in examples) {
      list.add({
        'id': nextId,
        'question': e.q,
        'answers': e.a,
        'correctIndex': e.correct,
      });
      nextId++;
    }
    await _firestore.setAndSync(
      {'quizQuestions': list, 'nextQuizQuestionId': nextId},
      SetOptions(merge: true),
    );
  }

  // ── WYNIKI (osobna kolekcja) ─────────────────────────────────────────

  Stream<List<QuizResult>> watchResults() =>
      LegacyScope.scoped(_db.collection(resultsCollection))
          .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(QuizResult.fromDoc).toList());

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
