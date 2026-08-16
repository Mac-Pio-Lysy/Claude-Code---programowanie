import '../l10n/app_text.dart';

/// Ustalenie liczby dzieci na weselu — JEDNO miejsce dla kalkulacji sali,
/// napojów i UI budżetu.
///
/// Problem, który to rozwiązuje: `budgetData.childrenCount` było liczbą
/// wpisywaną ręcznie, niepowiązaną z listą gości. Para dodawała dzieci na
/// listę, a catering ich nie widział, dopóki nie poprawiła liczby drugi raz.
///
/// ⚠️ ZGODNOŚĆ WSTECZNA: brak pola `childrenCountMode` = tryb ręczny. Stare
/// wesela mają wpisaną liczbę, której NIE WOLNO podmienić na wyliczone zero
/// tylko dlatego, że nikt nie oznaczył jeszcze gości flagą `isChild`.
class ChildrenSettings {
  const ChildrenSettings({
    required this.enabled,
    required this.auto,
    required this.fromGuests,
    required this.manualCount,
  });

  /// Czy to wesele z dziećmi (`budgetData.withChildren`).
  final bool enabled;

  /// Tryb `auto` — liczba brana z listy gości zamiast z pola.
  final bool auto;

  /// Ilu gości ma flagę `isChild` (niezależnie od trybu — UI to pokazuje
  /// także w trybie ręcznym, żeby dało się porównać obie liczby).
  final int fromGuests;

  /// Liczba wpisana ręcznie (`budgetData.childrenCount`).
  final int manualCount;

  /// Klucz trybu w `budgetData`.
  static const String modeKey = 'childrenCountMode';
  static const String modeAuto = 'auto';
  static const String modeManual = 'manual';

  /// Liczba dzieci do wszystkich przeliczeń. Wesele bez dzieci → 0.
  int get count => !enabled ? 0 : (auto ? fromGuests : manualCount);

  /// Czy ręczna liczba rozjeżdża się z listą gości — UI ostrzega o tym
  /// w trybie ręcznym, bo to najczęstsze źródło błędnego cateringu.
  bool get manualMismatch =>
      enabled && !auto && fromGuests > 0 && fromGuests != manualCount;

  /// Odczyt z surowych danych wesela.
  ///
  /// [budgetData] to mapa `budgetData`, [guests] — lista gości (surowe mapy).
  factory ChildrenSettings.from(Map<dynamic, dynamic> budgetData,
      List<dynamic> guests) {
    final enabled = budgetData['withChildren'] == true;
    // Brak pola → tryb ręczny (patrz uwaga o zgodności wstecznej).
    final auto = budgetData[modeKey] == modeAuto;

    var fromGuests = 0;
    for (final g in guests) {
      if (g is Map && g['isChild'] == true) fromGuests++;
    }

    final rawManual = budgetData['childrenCount'];
    final manual = rawManual is num ? rawManual.round() : 0;

    return ChildrenSettings(
      enabled: enabled,
      auto: auto,
      fromGuests: fromGuests,
      manualCount: manual < 0 ? 0 : manual,
    );
  }

  /// Ustawienia dla wesela bez danych.
  static const ChildrenSettings empty = ChildrenSettings(
    enabled: false,
    auto: false,
    fromGuests: 0,
    manualCount: 0,
  );

  /// Pola `budgetData` dla nowo zakładanego wesela (#8).
  ///
  /// O trybie decyduje to, czy para podała liczbę z góry:
  ///  • podana → `manual`, bo lista gości jest jeszcze pusta i tryb „auto"
  ///    wyzerowałby wpisaną liczbę w kalkulacjach,
  ///  • niepodana → `auto`, czyli liczenie z listy gości w miarę jej
  ///    uzupełniania.
  static Map<String, dynamic> initialBudgetFields({
    required bool withChildren,
    required int childrenCount,
  }) {
    final count = withChildren && childrenCount > 0 ? childrenCount : 0;
    return {
      'withChildren': withChildren,
      if (count > 0) 'childrenCount': count,
      modeKey: count > 0 ? modeManual : modeAuto,
    };
  }

  /// Podpowiedź przy sadzaniu gościa. `null` = nie ma o czym mówić.
  ///
  /// MIĘKKA z założenia — nigdy nie blokuje przypisania. Przy stole dzieci
  /// zwykle siada opiekun, a dziecko bywa celowo sadzane przy rodzicach.
  /// Blokada byłaby tu błędem, nie zabezpieczeniem.
  ///
  /// [childTableExists] pilnuje, żeby nie proponować stołu dziecięcego
  /// weselu, które go nie ma.
  static String? seatingHint({
    required bool guestIsChild,
    required bool tableIsChildTable,
    required bool childTableExists,
  }) {
    if (tableIsChildTable && !guestIsChild) {
      return AppText.t.children_adultAtKidsTable;
    }
    if (guestIsChild && !tableIsChildTable && childTableExists) {
      return AppText.t.children_kidAtNormalTable;
    }
    return null;
  }

  /// Czy w planie jest choć jeden stół dla dzieci.
  static bool hasChildTable(List<dynamic> tables) =>
      tables.any((t) => t is Map && t['isChildTable'] == true);
}
