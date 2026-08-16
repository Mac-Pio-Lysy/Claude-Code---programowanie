import '../models/invite_identity.dart';

/// Kim jest gość w bieżącej sesji strefy gości.
///
/// Globalny holder — ten sam wzorzec, co `AppText`, `CoupleLabels.current`
/// i `ActiveWedding`. Powód jest tu praktyczny: imię gościa musi trafić do
/// kilkunastu formularzy rozsianych po `guest_web_sections.dart`, a większość
/// z nich siedzi w prywatnych widgetach bez wspólnego przodka, przez który
/// dałoby się przekazać parametr.
///
/// Pusty w trybie wspólnego linku — wtedy gość podaje imię sam, jak dotąd.
class GuestSession {
  GuestSession._();

  /// Tożsamość z kodu paczki albo `null` przy wejściu wspólnym linkiem.
  static PackageIdentity? identity;

  /// Imię do wstępnego wypełnienia formularzy (puste = brak tożsamości).
  static String get displayName => identity?.displayName ?? '';

  /// Czy gość wszedł kodem indywidualnym.
  static bool get hasIdentity => (identity?.displayName ?? '').isNotEmpty;

  static void apply(PackageIdentity? value) => identity = value;

  static void clear() => identity = null;
}
