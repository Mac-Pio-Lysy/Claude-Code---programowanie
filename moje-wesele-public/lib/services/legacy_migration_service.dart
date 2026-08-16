import 'package:cloud_firestore/cloud_firestore.dart';

import 'legacy_scope.dart';
import '../l10n/app_text.dart';

/// Wynik migracji jednej kolekcji legacy.
class LegacyMigrationResult {
  const LegacyMigrationResult({
    required this.collection,
    required this.stamped,
    required this.skipped,
    this.error,
  });

  /// Nazwa kolekcji.
  final String collection;

  /// Ile dokumentów dostało `weddingId`.
  final int stamped;

  /// Ile pominięto (miały już `weddingId` — cudze albo własne).
  final int skipped;

  /// Komunikat błędu, gdy kolekcji nie udało się przetworzyć.
  final String? error;

  bool get ok => error == null;
}

/// JEDNORAZOWA migracja kolekcji legacy do modelu wielu wesel.
///
/// Kolekcje `gallery`, `guestbook`, `advices`, `guestMap`, `timeCapsule`,
/// `musicProposals`, `photoChallenges`, `quizResults`, `photoGuessResults` i
/// `trueFalseResults` leżą w korzeniu bazy i powstały, gdy istniało jedno
/// wesele. Nowe reguły (audyt 5b, naprawa #4) wymagają w każdym dokumencie pola
/// `weddingId` i wpuszczają wyłącznie organizatora tego wesela — dokumenty bez
/// tego pola stają się niedostępne dla wszystkich.
///
/// ⚠️ KOLEJNOŚĆ MA ZNACZENIE: migrację trzeba uruchomić na STARYCH regułach
/// (`firestore.rules.OPEN-BACKUP` lub obecnie wdrożonych), zanim wdrożysz nowe.
/// Po wdrożeniu nowych reguł zapis dokumentu bez `weddingId` jest zabroniony,
/// więc migracja już nie przejdzie.
///
/// Migracja jest idempotentna: dokumenty, które mają już `weddingId`, są
/// pomijane — także wtedy, gdy należą do innego wesela.
class LegacyMigrationService {
  LegacyMigrationService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Kolekcje objęte migracją (zgodne z listą `match` w `firestore.rules`).
  static const List<String> collections = [
    'gallery',
    'guestbook',
    'advices',
    'guestMap',
    'timeCapsule',
    'musicProposals',
    'photoChallenges',
    'quizResults',
    'photoGuessResults',
    'trueFalseResults',
  ];

  /// Limit operacji w jednym batchu Firestore.
  static const int _batchLimit = 400;

  /// Przypisuje wszystkie „bezpańskie" dokumenty (bez `weddingId`) do wesela
  /// [weddingId]; domyślnie do aktywnego. Zwraca podsumowanie per kolekcja.
  Future<List<LegacyMigrationResult>> run({String? weddingId}) async {
    final target = weddingId ?? LegacyScope.weddingId;
    if (target.isEmpty || target == LegacyScope.noWedding) {
      throw StateError(AppText.t.err_noActiveWedding);
    }
    final results = <LegacyMigrationResult>[];
    for (final name in collections) {
      results.add(await _migrateCollection(name, target));
    }
    return results;
  }

  /// Podgląd BEZ zapisu — ile dokumentów czeka na migrację w każdej kolekcji.
  Future<List<LegacyMigrationResult>> dryRun() async {
    final results = <LegacyMigrationResult>[];
    for (final name in collections) {
      try {
        final snap = await _db.collection(name).get();
        final pending =
            snap.docs.where((d) => !_hasWeddingId(d.data())).length;
        results.add(LegacyMigrationResult(
          collection: name,
          stamped: pending,
          skipped: snap.docs.length - pending,
        ));
      } catch (e) {
        results.add(LegacyMigrationResult(
          collection: name,
          stamped: 0,
          skipped: 0,
          error: '$e',
        ));
      }
    }
    return results;
  }

  Future<LegacyMigrationResult> _migrateCollection(
      String name, String weddingId) async {
    try {
      final snap = await _db.collection(name).get();
      final pending =
          snap.docs.where((d) => !_hasWeddingId(d.data())).toList();
      var written = 0;
      for (var i = 0; i < pending.length; i += _batchLimit) {
        final chunk = pending.skip(i).take(_batchLimit);
        final batch = _db.batch();
        for (final doc in chunk) {
          batch.set(doc.reference, {'weddingId': weddingId},
              SetOptions(merge: true));
        }
        await batch.commit();
        written += chunk.length;
      }
      return LegacyMigrationResult(
        collection: name,
        stamped: written,
        skipped: snap.docs.length - pending.length,
      );
    } catch (e) {
      return LegacyMigrationResult(
        collection: name,
        stamped: 0,
        skipped: 0,
        error: '$e',
      );
    }
  }

  bool _hasWeddingId(Map<String, dynamic> data) {
    final v = data['weddingId'];
    return v is String && v.trim().isNotEmpty;
  }
}
