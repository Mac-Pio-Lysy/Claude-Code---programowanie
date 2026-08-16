import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_text.dart';

/// Tożsamość gościa strefy publicznej — anonimowe konto Firebase zakładane
/// w tle, całkowicie niewidoczne dla gościa (żadnego ekranu logowania).
///
/// Po co: dopiero mając `uid` reguły mogą wymusić „jeden RSVP na gościa"
/// (identyfikator dokumentu = `uid`). Bez tożsamości każdy wpis jest niczyj
/// i nie da się ograniczyć ich liczby ani pozwolić gościowi poprawić własnego.
///
/// ⚠️ NAJWAŻNIEJSZY WARUNEK: logujemy anonimowo WYŁĄCZNIE wtedy, gdy nikt nie
/// jest zalogowany. Aplikacja gościa i panel organizatora dzielą jedną
/// instancję [FirebaseAuth] i jedno miejsce zapisu sesji w przeglądarce —
/// bezwarunkowe `signInAnonymously()` wylogowałoby organizatora z konta Google
/// w chwili, gdy otworzy link gościa w tej samej przeglądarce.
///
/// Ograniczenie, o którym trzeba pamiętać: to tożsamość PRZEGLĄDARKI, nie
/// osoby. Wyczyszczenie danych, tryb prywatny albo drugie urządzenie dają nowy
/// `uid`. To spowalniacz dla powtarzanych wysyłek, nie zabezpieczenie kryptograficzne.
class GuestIdentity {
  GuestIdentity._();

  static FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Identyfikator bieżącej tożsamości — anonimowej albo zalogowanego
  /// użytkownika (organizator podglądający stronę gościa). `null`, gdy jeszcze
  /// nie ustalona lub logowanie się nie powiodło.
  static String? get uid => _auth.currentUser?.uid;

  /// Czy tożsamość jest gotowa (można zapisywać wpisy powiązane z gościem).
  static bool get isReady => uid != null;

  /// Czy bieżąca tożsamość jest anonimowa (a nie kontem organizatora).
  static bool get isAnonymous => _auth.currentUser?.isAnonymous ?? false;

  /// Zapewnia tożsamość i zwraca `uid`.
  ///
  /// Gdy ktoś jest już zalogowany — zwraca jego `uid` bez żadnego logowania.
  /// W przeciwnym razie zakłada konto anonimowe. Rzuca [FirebaseAuthException]
  /// — wołający pokazuje komunikat, bo cicha odmowa w dniu wesela jest gorsza
  /// niż widoczny błąd.
  static Future<String> ensure() async {
    final existing = _auth.currentUser;
    if (existing != null) return existing.uid;

    final cred = await _auth.signInAnonymously();
    final user = cred.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'null-user',
        message: AppText.t.guestId_noUser,
      );
    }
    return user.uid;
  }

  /// Zamienia kod błędu Firebase na komunikat dla gościa.
  ///
  /// `operation-not-allowed` oznacza, że w konsoli Firebase nie włączono
  /// dostawcy „Anonymous" — to błąd konfiguracji projektu, nie gościa.
  static String messageFor(Object error) {
    final code = error is FirebaseAuthException ? error.code : '';
    return switch (code) {
      'operation-not-allowed' =>
        AppText.t.guestId_notConfigured,
      'network-request-failed' =>
        AppText.t.guestId_offline,
      _ => AppText.t.guestId_generic,
    };
  }
}
