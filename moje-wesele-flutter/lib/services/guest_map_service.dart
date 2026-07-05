import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/guest_map_entry.dart';

/// Dostęp do mapy gości — osobna kolekcja `guestMap` w Firestore
/// (publiczny zapis ze strony `mapa.html`, jak `guestbook`).
///
/// NIE rusza dokumentu `weddingPlanner/main`. Usuwanie/edycja/ręczne dodanie
/// dla zalogowanych organizatorów (reguły Firestore).
class GuestMapService {
  GuestMapService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String collectionName = 'guestMap';

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(collectionName);

  Stream<List<GuestMapEntry>> watchEntries() => _col
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(GuestMapEntry.fromDoc).toList());

  /// Ręczne dodanie wpisu przez organizatora (gdy ktoś nie wpisał się sam).
  Future<void> addEntry({
    required String name,
    required String city,
    String greeting = '',
    double? lat,
    double? lng,
  }) =>
      _col.add({
        'name': name.trim(),
        'city': city.trim(),
        'greeting': greeting.trim(),
        'lat': lat,
        'lng': lng,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

  Future<void> updateEntry(String id,
      {String? name, String? city, String? greeting, double? lat, double? lng}) {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name.trim();
    if (city != null) data['city'] = city.trim();
    if (greeting != null) data['greeting'] = greeting.trim();
    if (lat != null) data['lat'] = lat;
    if (lng != null) data['lng'] = lng;
    return _col.doc(id).set(data, SetOptions(merge: true));
  }

  Future<void> deleteEntry(String id) => _col.doc(id).delete();
}
