import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_service.dart';

/// Zapis konfiguracji „Koła fortuny" w `weddingPlanner/main` → `wheelConfig`
/// (per event, jak reszta danych planera). Głębokie scalanie nie rusza
/// pozostałych pól. NIE modyfikuje listy gości — usuwanie z puli przy
/// losowaniu jest tylko stanem sesji (w pamięci ekranu).
class WheelService {
  WheelService({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  final FirestoreService _firestore;

  Future<void> setActiveMode(String modeId) => _firestore.mainDoc
      .set({'wheelConfig': {'activeMode': modeId}}, SetOptions(merge: true));

  Future<void> setRemoveOnPick(bool value) => _firestore.mainDoc
      .set({'wheelConfig': {'removeOnPick': value}}, SetOptions(merge: true));

  /// Zapisuje własne pola dla danego zestawu (`couple`/`oczepiny`/`custom`).
  Future<void> setItems(String setKey, List<String> items) =>
      _firestore.mainDoc.set(
        {'wheelConfig': {'sets': {setKey: items}}},
        SetOptions(merge: true),
      );
}
