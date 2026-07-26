import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/guest_visibility.dart';
import 'firestore_service.dart';

/// Zapis/odczyt ustawień widoczności sekcji dla gości (`guestVisibility`
/// w dokumencie aktywnego wesela `weddings/{id}`).
class GuestVisibilityService {
  GuestVisibilityService({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  final FirestoreService _firestore;

  /// Jednorazowy odczyt ustawień (domyślne, gdy jeszcze nie zapisano).
  Future<GuestVisibility> read() async {
    final data = await _firestore.readData() ?? const <String, dynamic>{};
    return GuestVisibility.fromRaw(data);
  }

  /// Zapis całego bloku `guestVisibility` (scalanie z resztą dokumentu).
  Future<void> save(GuestVisibility visibility) => _firestore.mainDoc.set(
        {'guestVisibility': visibility.toMap()},
        SetOptions(merge: true),
      );
}
