import 'package:cloud_firestore/cloud_firestore.dart';

/// Pytanie quizu o Parze Młodej (w `weddingPlanner/main`, tablica
/// `quizQuestions`): `{id, question, answers: [..], correctIndex}`.
class QuizQuestion {
  QuizQuestion(this.raw);
  final Map<String, dynamic> raw;

  int? get id => (raw['id'] as num?)?.toInt();
  String get question => (raw['question'] as String?)?.trim() ?? '';

  List<String> get answers {
    final v = raw['answers'];
    return v is List ? v.map((e) => e?.toString() ?? '').toList() : <String>[];
  }

  int get correctIndex => (raw['correctIndex'] as num?)?.toInt() ?? 0;
}

/// Wynik gościa (kolekcja `quizResults`): `{name, score, total, answers, timestamp}`.
/// `answers` mapuje id pytania → wybrany indeks odpowiedzi (do statystyk).
class QuizResult {
  QuizResult({
    required this.id,
    required this.name,
    required this.score,
    required this.total,
    required this.answers,
    required this.timestamp,
  });

  final String id;
  final String name;
  final int score;
  final int total;

  /// id pytania (String) → wybrany indeks odpowiedzi.
  final Map<String, int> answers;

  /// Czas dodania (ms od epoki). 0 = nieznany.
  final int timestamp;

  DateTime? get dateTime =>
      timestamp > 0 ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;

  factory QuizResult.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final ans = <String, int>{};
    final raw = d['answers'];
    if (raw is Map) {
      raw.forEach((k, v) {
        final i = (v as num?)?.toInt();
        if (i != null) ans['$k'] = i;
      });
    }
    return QuizResult(
      id: doc.id,
      name: (d['name'] as String?)?.trim() ?? '',
      score: (d['score'] as num?)?.toInt() ?? 0,
      total: (d['total'] as num?)?.toInt() ?? 0,
      answers: ans,
      timestamp: _ts(d['timestamp']),
    );
  }

  static int _ts(dynamic v) {
    if (v is num) return v.toInt();
    if (v is Timestamp) return v.millisecondsSinceEpoch;
    return 0;
  }
}
