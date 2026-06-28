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

  static String galeria(String base) => '$base/galeria.html';
  static String harmonogram(String base) => '$base/harmonogram.html';
  static String rsvp(String base) => '$base/rsvp.html';
  static String muzyka(String base) => '$base/muzyka.html';
  static String bingo(String base) => '$base/bingo.html';
}
