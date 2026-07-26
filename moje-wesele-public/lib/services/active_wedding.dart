/// Globalny wskaźnik AKTYWNEGO wesela (multi-wedding).
///
/// W modelu wielu wesel każde wesele ma własny dokument `weddings/{weddingId}`.
/// Ten holder trzyma ID wesela wybranego na ekranie „Twoje wesela"; dzięki temu
/// [FirestoreService] (a przez niego wszystkie serwisy sekcji) czyta i zapisuje
/// dane pod właściwym weselem BEZ przewlekania weddingId przez każdy konstruktor.
///
/// Ustawiane przy wyborze/utworzeniu wesela (patrz `auth_gate.dart`), czyszczone
/// przy powrocie do listy („Zmień wesele").
class ActiveWedding {
  ActiveWedding._();

  static String? _id;

  /// ID aktywnego wesela lub `null`, gdy żadne nie jest wybrane.
  static String? get id => _id;

  /// Ustawia aktywne wesele (`null` = brak wyboru → ekran „Twoje wesela").
  static set id(String? value) => _id = (value != null && value.isNotEmpty) ? value : null;

  /// Czy jakieś wesele jest aktywne.
  static bool get hasWedding => _id != null && _id!.isNotEmpty;

  /// Czyści wybór (powrót do listy wesel).
  static void clear() => _id = null;
}
