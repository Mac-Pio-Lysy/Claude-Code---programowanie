import 'package:cloud_firestore/cloud_firestore.dart';

import 'active_wedding.dart';

/// Zawężenie LEGACY kolekcji globalnych (`gallery`, `guestbook`, `advices`,
/// `guestMap`, `timeCapsule`, `photoChallenges`, `*Results`) do AKTYWNEGO wesela.
///
/// Te kolekcje powstały przed modelem wielu wesel i leżą w korzeniu bazy, bez
/// żadnego powiązania z weselem — jeden wspólny worek dla wszystkich. Reguły
/// bezpieczeństwa (audyt 5b, naprawa #4) wymagają teraz pola `weddingId` w
/// każdym dokumencie i wpuszczają wyłącznie organizatora tego wesela.
///
/// WAŻNE: reguły Firestore NIE filtrują wyników — zapytanie bez `where` na
/// `weddingId` zostanie odrzucone w całości (permission-denied), a nie obcięte.
/// Dlatego każde zapytanie do tych kolekcji musi przejść przez [scoped].
///
/// Nowe treści gości NIE trafiają już tutaj — idą do `guestSpaces/{token}/…`.
/// Ten plik obsługuje dane historyczne i ręczne wpisy organizatora.
class LegacyScope {
  LegacyScope._();

  /// Wartość używana, gdy nie ma aktywnego wesela — celowo nie pasuje do
  /// żadnego dokumentu (zapytanie zwróci pustkę zamiast czytać cudze dane).
  static const String noWedding = '__none__';

  /// ID wesela, którym stemplowane i filtrowane są wpisy legacy.
  static String get weddingId => ActiveWedding.id ?? noWedding;

  /// Zapytanie do kolekcji zawężone do aktywnego wesela.
  static Query<Map<String, dynamic>> scoped(
          CollectionReference<Map<String, dynamic>> col) =>
      col.where('weddingId', isEqualTo: weddingId);

  /// Dokłada `weddingId` do zapisywanych danych (wymagane przez reguły).
  static Map<String, dynamic> stamp(Map<String, dynamic> data) =>
      {...data, 'weddingId': weddingId};
}
