import 'package:cloud_firestore/cloud_firestore.dart';

/// Stwierdzenie do gry „Prawda czy Fałsz" (w `weddingPlanner/main`, tablica
/// `tfStatements`): `{id, text, isTrue, explanation}`.
class TFStatement {
  TFStatement(this.raw);
  final Map<String, dynamic> raw;

  int? get id => (raw['id'] as num?)?.toInt();
  String get text => (raw['text'] as String?)?.trim() ?? '';
  bool get isTrue => raw['isTrue'] == true;
  String get explanation => (raw['explanation'] as String?)?.trim() ?? '';
}

/// Wynik gościa (kolekcja `trueFalseResults`):
/// `{name, score, total, answers, timestamp}`.
/// `answers` mapuje id stwierdzenia (String) → wybór gościa (bool: prawda?).
class TFResult {
  TFResult({
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
  final Map<String, bool> answers;
  final int timestamp;

  DateTime? get dateTime =>
      timestamp > 0 ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;

  factory TFResult.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final ans = <String, bool>{};
    final raw = d['answers'];
    if (raw is Map) {
      raw.forEach((k, v) {
        if (v is bool) ans['$k'] = v;
      });
    }
    return TFResult(
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
