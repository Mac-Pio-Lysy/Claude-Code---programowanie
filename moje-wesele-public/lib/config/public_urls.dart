/// Adresy publicznych stron dla gości (galeria, harmonogram, RSVP, muzyka).
///
/// Strony publiczne pozostają w wersji webowej. Domena pochodzi z
/// `appConfig.publicBaseUrl` (edytowalna w panelu), a domyślnie wskazuje
/// na hosting Firebase projektu.
class PublicPages {
  PublicPages._();

  static const String defaultBaseUrl = 'https://ceremonia-patrycji-i-piotra.pl';

  static String baseUrl(Map<String, dynamic>? raw) {
    final cfg = raw?['appConfig'];
    final u = (cfg is Map) ? cfg['publicBaseUrl'] as String? : null;
    var base = (u != null && u.trim().isNotEmpty) ? u.trim() : defaultBaseUrl;
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    return base;
  }

  /// Wejście do strefy gości kodem paczki (indywidualne zaproszenia, etap 6).
  ///
  /// ⚠️ Inaczej niż pozostałe adresy w tym pliku: te NIE prowadzą do
  /// statycznych stron `*.html`, tylko do korzenia samej aplikacji Flutter
  /// web — `main.dart` czyta stamtąd parametr `?i=` i sam decyduje, co
  /// pokazać (patrz `_detectParam` w `main.dart`). Ta sama domena co reszta
  /// (`appConfig.publicBaseUrl`), inna ścieżka.
  static String inviteEntry(String base, String code) => '$base/?i=$code';

  static String galeria(String base) => '$base/galeria.html';
  static String harmonogram(String base) => '$base/harmonogram.html';
  static String rsvp(String base) => '$base/rsvp.html';
  static String muzyka(String base) => '$base/muzyka.html';
  static String bingo(String base) => '$base/bingo.html';
  static String ksiega(String base) => '$base/ksiega.html';
  static String quiz(String base) => '$base/quiz.html';
  static String rady(String base) => '$base/rady.html';
  static String prawdaFalsz(String base) => '$base/prawdafalsz.html';
  static String zgadnijZdjecie(String base) => '$base/zgadnijzdjecie.html';
  static String kapsula(String base) => '$base/kapsula.html';
  static String mapa(String base) => '$base/mapa.html';
  static String fotoWyzwania(String base) => '$base/fotowyzwania.html';
}
