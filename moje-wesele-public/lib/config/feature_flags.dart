/// Przełączniki funkcji tymczasowo wyłączonych z widoku, BEZ usuwania kodu
/// ani danych — łatwo odwracalne (zmiana `false` → `true`).
///
/// Ukrycie dotyczy WYŁĄCZNIE nawigacji/UI. Dane utworzone wcześniej (np.
/// dostawca/pojazd/hotel/piosenka/wydatek powiązany z zadaniem) zostają
/// nietknięte i w pełni funkcjonalne — to tylko wejście do sekcji znika
/// z menu, nie sama sekcja ani jej dane.
class FeatureFlags {
  const FeatureFlags._();

  /// Sekcja „Zadania" w nawigacji (pasek, „Więcej", szyna tabletu, kreator,
  /// katalog widgetów dashboardu). Wróci w aktualizacji.
  static const bool showTasksSection = false;

  /// Sekcja „Dostawcy" w nawigacji — jak wyżej.
  static const bool showVendorsSection = false;

  /// Linki/QR do przeglądowych stron dla gości (`PublicLinkCard`, główny
  /// link w Ustawieniach). NIE dotyczy kodów indywidualnych (`?i=KOD`) —
  /// to osobny mechanizm wejścia, nie strona do przeglądania, i zostaje
  /// aktywny niezależnie od tej flagi.
  static const bool showWebsiteLinks = false;
}
