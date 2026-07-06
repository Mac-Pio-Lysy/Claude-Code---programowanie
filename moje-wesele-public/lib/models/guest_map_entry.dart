import 'package:cloud_firestore/cloud_firestore.dart';

/// Wpis na mapie gości (kolekcja `guestMap` w Firestore).
///
/// Zapisywany publicznie przez gości na stronie `mapa.html`
/// `{name, city, greeting, lat, lng, timestamp}`. `lat`/`lng` mogą być puste,
/// gdy geokodowanie się nie powiodło (organizer może je uzupełnić ręcznie).
class GuestMapEntry {
  GuestMapEntry({
    required this.id,
    required this.name,
    required this.city,
    required this.greeting,
    required this.lat,
    required this.lng,
    required this.timestamp,
  });

  final String id;
  final String name;
  final String city;
  final String greeting;
  final double? lat;
  final double? lng;
  final int timestamp;

  bool get hasCoords => lat != null && lng != null;

  DateTime? get dateTime =>
      timestamp > 0 ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;

  factory GuestMapEntry.fromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return GuestMapEntry(
      id: doc.id,
      name: (d['name'] as String?)?.trim() ?? '',
      city: (d['city'] as String?)?.trim() ?? '',
      greeting: (d['greeting'] as String?)?.trim() ?? '',
      lat: (d['lat'] as num?)?.toDouble(),
      lng: (d['lng'] as num?)?.toDouble(),
      timestamp: _ts(d['timestamp']),
    );
  }

  static int _ts(dynamic v) {
    if (v is num) return v.toInt();
    if (v is Timestamp) return v.millisecondsSinceEpoch;
    return 0;
  }
}
