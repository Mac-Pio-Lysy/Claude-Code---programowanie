import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/wedding_data.dart';

/// Dostęp do współdzielonych danych wesela w Firestore.
///
/// WAŻNE: aplikacja Flutter korzysta z DOKŁADNIE tej samej lokalizacji co
/// aplikacja webowa (zrodlo-web/firebase-config.js):
///   kolekcja `weddingPlanner`, dokument `main`.
/// Dzięki temu obie aplikacje czytają i zapisują te same dane.
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Nazwa kolekcji — zgodna z `FS_COLLECTION` w aplikacji webowej.
  static const String collectionName = 'weddingPlanner';

  /// Identyfikator dokumentu — zgodny z `FS_DOC_ID` w aplikacji webowej.
  static const String docId = 'main';

  /// Referencja do współdzielonego dokumentu z danymi wesela.
  DocumentReference<Map<String, dynamic>> get mainDoc =>
      _db.collection(collectionName).doc(docId);

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
}
