import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/wedding_data.dart';
import 'active_wedding.dart';
import 'wedding_service.dart';

/// Dostęp do danych KONKRETNEGO wesela w Firestore (model wielu wesel).
///
/// Dane każdego wesela żyją w osobnym dokumencie:
///   kolekcja `weddings`, dokument `{weddingId}`.
///
/// Wcześniej istniał jeden, stały dokument `weddingPlanner/main`. Teraz ścieżkę
/// wyznacza aktywne wesele: albo jawnie podane w konstruktorze ([weddingId]),
/// albo z globalnego [ActiveWedding.id] (ustawianego przy wyborze wesela).
/// Dzięki temu wszystkie serwisy sekcji (goście, budżet, plan sali…), które
/// korzystają z tego serwisu, automatycznie operują na aktywnym weselu.
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore, String? weddingId})
      : _db = firestore ?? FirebaseFirestore.instance,
        _explicitWeddingId = weddingId;

  final FirebaseFirestore _db;

  /// ID wesela podane jawnie w konstruktorze (ma pierwszeństwo przed globalnym).
  final String? _explicitWeddingId;

  /// Nazwa kolekcji wesel.
  static const String collectionName = 'weddings';

  /// Aktywne ID wesela — jawne z konstruktora lub z [ActiveWedding.id].
  String get weddingId {
    final id = _explicitWeddingId ?? ActiveWedding.id;
    assert(
      id != null && id.isNotEmpty,
      'Brak aktywnego weddingId — wybierz wesele (ActiveWedding.id) '
      'lub przekaż weddingId do FirestoreService.',
    );
    return (id != null && id.isNotEmpty) ? id : '__none__';
  }

  /// Referencja do dokumentu z danymi AKTYWNEGO wesela.
  DocumentReference<Map<String, dynamic>> get mainDoc =>
      _db.collection(collectionName).doc(weddingId);

  /// Strumień zmian dokumentu — odpowiednik `onSnapshot` w aplikacji webowej.
  Stream<Map<String, dynamic>?> watchData() =>
      mainDoc.snapshots().map((snap) => snap.data());

  /// Strumień typowanych danych wesela (nasłuch w czasie rzeczywistym).
  /// Zwraca `null`, gdy dokument jeszcze nie istnieje.
  Stream<WeddingData?> watchWeddingData() => mainDoc.snapshots().map((snap) {
        final data = snap.data();
        return data == null ? null : WeddingData.fromMap(data);
      });

  /// Jednorazowy odczyt danych wesela.
  Future<Map<String, dynamic>?> readData() async {
    final snap = await mainDoc.get();
    return snap.data();
  }

  /// Zapis danych (scala z istniejącymi — `set(..., merge: true)`).
  Future<void> saveData(Map<String, dynamic> data) =>
      mainDoc.set(data, SetOptions(merge: true));

  /// Zapis + odświeżenie PUBLICZNEGO mirrora dla gości (`guestSpaces/{token}`).
  ///
  /// Używany przez sekcje, których treść trafia na stronę gości: harmonogram
  /// i gry (pytania quizu, stwierdzenia prawda/fałsz, zdjęcia do zgadywania,
  /// wyzwania foto, pola bingo). Bez tego gość widziałby wersję z ostatniego
  /// zapisu konfiguracji, a nie bieżącą.
  ///
  /// Sygnatura celowo zgodna z `mainDoc.set(...)`, żeby podmiana w serwisach
  /// była mechaniczna. Synchronizacja mirrora jest best-effort — jej błąd
  /// (np. brak uprawnień) NIE przewraca zapisu danych wesela.
  Future<void> setAndSync(Map<String, dynamic> data, [SetOptions? options]) async {
    await mainDoc.set(data, options ?? SetOptions(merge: true));
    await WeddingService().syncGuestMirrorSafe(weddingId);
  }
}
