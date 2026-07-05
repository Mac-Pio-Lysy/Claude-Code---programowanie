import 'package:cloud_firestore/cloud_firestore.dart';

/// Kategoria rady (klucz zapisywany w Firestore + etykieta i emoji).
class AdviceCategory {
  const AdviceCategory(this.key, this.label, this.emoji);
  final String key;
  final String label;
  final String emoji;

  static const love = AdviceCategory('love', 'Miłość', '❤️');
  static const daily = AdviceCategory('daily', 'Codzienność', '🏡');
  static const humor = AdviceCategory('humor', 'Humor', '😄');
  static const wisdom = AdviceCategory('wisdom', 'Mądrość życiowa', '🦉');
  static const other = AdviceCategory('other', 'Inne', '💬');

  static const all = [love, daily, humor, wisdom, other];

  static AdviceCategory byKey(String? key) =>
      all.firstWhere((c) => c.key == key, orElse: () => other);
}

/// Rada / złota myśl dla Pary Młodej (kolekcja `advices` w Firestore).
///
/// Zapisywana publicznie przez gości na stronie `rady.html`
/// `{name, message, category, timestamp}`.
class Advice {
  Advice({
    required this.id,
    required this.name,
    required this.message,
    required this.categoryKey,
    required this.timestamp,
  });

  final String id;
  final String name;
  final String message;
  final String categoryKey;
  final int timestamp;

  AdviceCategory get category => AdviceCategory.byKey(categoryKey);

  DateTime? get dateTime =>
      timestamp > 0 ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;

  factory Advice.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return Advice(
      id: doc.id,
      name: (d['name'] as String?)?.trim() ?? '',
      message: (d['message'] as String?)?.trim() ?? '',
      categoryKey: (d['category'] as String?)?.trim() ?? 'other',
      timestamp: _ts(d['timestamp']),
    );
  }

  static int _ts(dynamic v) {
    if (v is num) return v.toInt();
    if (v is Timestamp) return v.millisecondsSinceEpoch;
    return 0;
  }
}
