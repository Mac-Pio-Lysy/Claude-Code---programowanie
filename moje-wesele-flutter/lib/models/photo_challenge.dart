import 'package:cloud_firestore/cloud_firestore.dart';

/// Wyzwanie fotograficzne (w `weddingPlanner/main`, tablica
/// `photoChallengeTasks`): `{id, text, points}`.
class PhotoChallengeTask {
  PhotoChallengeTask(this.raw);
  final Map<String, dynamic> raw;

  int? get id => (raw['id'] as num?)?.toInt();
  String get text => (raw['text'] as String?)?.trim() ?? '';
  int get points => (raw['points'] as num?)?.toInt() ?? 1;
}

/// Zdjęcie przesłane przez gościa (kolekcja `photoChallenges`):
/// `{name, challengeId, photoUrl, photoPublicId, timestamp}`.
class PhotoChallengeSubmission {
  PhotoChallengeSubmission({
    required this.id,
    required this.name,
    required this.challengeId,
    required this.photoUrl,
    required this.timestamp,
  });

  final String id;
  final String name;
  final int challengeId;
  final String photoUrl;
  final int timestamp;

  DateTime? get dateTime =>
      timestamp > 0 ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;

  factory PhotoChallengeSubmission.fromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return PhotoChallengeSubmission(
      id: doc.id,
      name: (d['name'] as String?)?.trim() ?? '',
      challengeId: (d['challengeId'] as num?)?.toInt() ?? -1,
      photoUrl: (d['photoUrl'] as String?)?.trim() ?? '',
      timestamp: _ts(d['timestamp']),
    );
  }

  static int _ts(dynamic v) {
    if (v is num) return v.toInt();
    if (v is Timestamp) return v.millisecondsSinceEpoch;
    return 0;
  }
}
