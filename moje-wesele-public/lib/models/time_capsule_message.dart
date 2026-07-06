import 'package:cloud_firestore/cloud_firestore.dart';

/// Wiadomość w kapsule czasu (kolekcja `timeCapsule` w Firestore).
///
/// Zapisywana publicznie przez gości na stronie `kapsula.html`
/// `{name, message, photoUrl, photoPublicId, openDate, createdAt}`.
/// `openDate` (ms od epoki) = kiedy wiadomość ma zostać „otwarta".
class TimeCapsuleMessage {
  TimeCapsuleMessage({
    required this.id,
    required this.name,
    required this.message,
    required this.photoUrl,
    required this.openDate,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String message;
  final String photoUrl;
  final int openDate;
  final int createdAt;

  bool get hasPhoto => photoUrl.isNotEmpty;

  DateTime? get openDateTime =>
      openDate > 0 ? DateTime.fromMillisecondsSinceEpoch(openDate) : null;

  DateTime? get createdDateTime =>
      createdAt > 0 ? DateTime.fromMillisecondsSinceEpoch(createdAt) : null;

  /// Czy wiadomość jest wciąż zapieczętowana (data otwarcia w przyszłości).
  bool get isSealed =>
      openDate > 0 && openDate > DateTime.now().millisecondsSinceEpoch;

  factory TimeCapsuleMessage.fromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return TimeCapsuleMessage(
      id: doc.id,
      name: (d['name'] as String?)?.trim() ?? '',
      message: (d['message'] as String?)?.trim() ?? '',
      photoUrl: (d['photoUrl'] as String?)?.trim() ?? '',
      openDate: _ts(d['openDate']),
      createdAt: _ts(d['createdAt']),
    );
  }

  static int _ts(dynamic v) {
    if (v is num) return v.toInt();
    if (v is Timestamp) return v.millisecondsSinceEpoch;
    return 0;
  }
}
