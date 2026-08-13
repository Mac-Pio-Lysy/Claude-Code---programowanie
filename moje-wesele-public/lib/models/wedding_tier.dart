import 'wedding_data.dart';

/// Poziom konta wesela — przygotowanie pod przyszłą monetyzację.
///
/// Wartość zapisywana w dokumencie `weddings/{id}` w polu `tier`. Zakładamy ją
/// TERAZ, zanim pojawią się użytkownicy, żeby później nie migrować danych.
///
/// ⚠️ Brak pola = [WeddingTier.free]. Wesela założone przed wprowadzeniem tego
/// pola czytają się poprawnie i działają bez zmian.
enum WeddingTier {
  /// Konto darmowe — obecnie WSZYSCY.
  free,

  /// Konto płatne. Na razie nikt go nie ma; rozpoznawanie zakupu (Google Play
  /// Billing) dojdzie razem z uruchomieniem monetyzacji.
  premium;

  String get key => name;

  /// Odczyt z zapisanej wartości. Nieznana wartość albo brak pola → [free].
  ///
  /// Celowo zachowawczo: gdyby w danych pojawiło się coś nieoczekiwanego,
  /// wesele ma działać jak darmowe, a nie wywalać się przy odczycie.
  static WeddingTier fromRaw(dynamic value) {
    for (final t in WeddingTier.values) {
      if (t.key == value) return t;
    }
    return WeddingTier.free;
  }
}

/// JEDYNE miejsce w aplikacji, które odpowiada na pytanie „czy to wesele jest
/// premium".
///
/// ═══════════════════════════════════════════════════════════════════════════
/// ZASADA GRANDFATHERINGU — obowiązuje bezwzględnie przy uruchamianiu premium
/// ═══════════════════════════════════════════════════════════════════════════
/// 1. Premium DODAJE funkcje. Nigdy nie odbiera tego, co użytkownik już ma.
/// 2. Kto zaczął jako darmowy, zachowuje pełny dostęp do wszystkiego, z czego
///    korzystał — lista gości, budżet, plan sali, harmonogram, gry, pamiątki
///    i strefa gości zostają darmowe na zawsze.
/// 3. Nowe ograniczenie wolno wprowadzić WYŁĄCZNIE dla funkcji, która jeszcze
///    nie istnieje. Zabranie działającej funkcji istniejącym parom to złamanie
///    umowy — para planuje wesele miesiącami i nie może w połowie stracić
///    dostępu do swoich danych.
/// 4. Gdy pojawi się wątpliwość „czy to wolno zamknąć za premium" — odpowiedź
///    brzmi „nie", jeśli funkcja działała wcześniej za darmo.
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Reszta aplikacji NIE sprawdza pola `tier` bezpośrednio — pyta tutaj. Dzięki
/// temu włączenie monetyzacji to zmiana w jednym pliku, a nie polowanie na
/// rozsiane po kodzie warunki.
class PremiumAccess {
  const PremiumAccess._();

  /// Główny wyłącznik monetyzacji.
  ///
  /// `false` = etap przygotowania: flaga istnieje w danych, ale NIC nie
  /// ogranicza i nikt nie jest premium. Przełączenie na `true` uruchamia
  /// odczyt realnego poziomu konta — dopiero wtedy, i dopiero po podłączeniu
  /// płatności, [isPremium] zacznie zwracać `true`.
  static const bool monetizationEnabled = false;

  /// Czy wesele ma poziom premium.
  ///
  /// Dopóki [monetizationEnabled] jest wyłączone, zwraca ZAWSZE `false` —
  /// niezależnie od tego, co jest zapisane w danych. To celowe: nikt nie może
  /// „stać się premium" przez ręczną edycję dokumentu, zanim monetyzacja
  /// wystartuje.
  static bool isPremium(WeddingData? data) {
    if (!monetizationEnabled) return false;
    return tierOf(data) == WeddingTier.premium;
  }

  /// Zapisany poziom konta — do diagnostyki i przyszłego ekranu planu.
  ///
  /// ⚠️ NIE używać do decyzji o dostępie do funkcji. Od tego jest [isPremium],
  /// które respektuje [monetizationEnabled].
  static WeddingTier tierOf(WeddingData? data) =>
      WeddingTier.fromRaw(data?.raw['tier']);

  /// Poziom odczytany wprost z surowego dokumentu wesela.
  ///
  /// Wariant dla miejsc, które mają mapę, a nie [WeddingData] (np. lista wesel
  /// użytkownika).
  static WeddingTier tierOfRaw(Map<String, dynamic>? raw) =>
      WeddingTier.fromRaw(raw?['tier']);

  /// Pola poziomu konta dla nowo zakładanego wesela.
  ///
  /// Każde nowe wesele startuje jako darmowe. Zapisujemy pole jawnie, żeby
  /// dokument miał komplet struktury od pierwszego dnia.
  static Map<String, dynamic> initialFields() => {
        'tier': WeddingTier.free.key,
      };
}
