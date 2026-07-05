import 'package:cloud_firestore/cloud_firestore.dart';

/// Pytanie ze zdjęciem do gry „Zgadnij zdjęcie" (w `weddingPlanner/main`,
/// tablica `photoQuestions`):
/// `{id, photoUrl, photoPublicId, question, answers:[..], correctIndex}`.
class PhotoQuestion {
  PhotoQuestion(this.raw);
  final Map<String, dynamic> raw;

  int? get id => (raw['id'] as num?)?.toInt();
  String get photoUrl => (raw['photoUrl'] as String?)?.trim() ?? '';
  String get photoPublicId => (raw['photoPublicId'] as String?)?.trim() ?? '';
  String get question => (raw['question'] as String?)?.trim() ?? '';

  List<String> get answers {
    final v = raw['answers'];
    return v is List ? v.map((e) => e?.toString() ?? '').toList() : <String>[];
  }

  int get correctIndex => (raw['correctIndex'] as num?)?.toInt() ?? 0;
}

/// Wynik gościa (kolekcja `photoGuessResults`):
/// `{name, score, total, answers, timestamp}`.
/// `answers` mapuje id pytania (String) → wybrany indeks odpowiedzi.
class PhotoGuessResult {
  PhotoGuessResult({
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
  final Map<String, int> answers;
  final int timestamp;

  DateTime? get dateTime =>
      timestamp > 0 ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;

  factory PhotoGuessResult.fromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final ans = <String, int>{};
    final raw = d['answers'];
    if (raw is Map) {
      raw.forEach((k, v) {
        final i = (v as num?)?.toInt();
        if (i != null) ans['$k'] = i;
      });
    }
    return PhotoGuessResult(
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
