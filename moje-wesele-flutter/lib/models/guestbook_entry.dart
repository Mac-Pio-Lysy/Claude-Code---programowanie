import 'package:cloud_firestore/cloud_firestore.dart';

/// Wpis w księdze gości (kolekcja `guestbook` w Firestore).
///
/// Zapisywany publicznie przez gości na stronie `ksiega.html`
/// `{name, message, photoUrl, photoPublicId, timestamp}`.
class GuestbookEntry {
  GuestbookEntry({
    required this.id,
    required this.name,
    required this.message,
    required this.photoUrl,
    required this.timestamp,
  });

  final String id;
  final String name;
  final String message;
  final String photoUrl;

  /// Czas dodania (ms od epoki). 0 = brak / nieznany.
  final int timestamp;

  bool get hasPhoto => photoUrl.isNotEmpty;

  DateTime? get dateTime =>
      timestamp > 0 ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;

  factory GuestbookEntry.fromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return GuestbookEntry(
      id: doc.id,
      name: (d['name'] as String?)?.trim() ?? '',
      message: (d['message'] as String?)?.trim() ?? '',
      photoUrl: (d['photoUrl'] as String?)?.trim() ?? '',
      timestamp: _ts(d['timestamp']),
    );
  }

  /// Obsługuje zarówno liczbę (Date.now() ze strony web), jak i Timestamp.
  static int _ts(dynamic v) {
    if (v is num) return v.toInt();
    if (v is Timestamp) return v.millisecondsSinceEpoch;
    return 0;
  }
}
