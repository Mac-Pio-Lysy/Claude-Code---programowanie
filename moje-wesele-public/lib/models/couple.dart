import '../l10n/app_text.dart';

/// Typ uroczystości — decyduje o etykietach pary w całej aplikacji.
///
/// Wartość zapisywana w `appConfig.coupleType`. Brak pola (stare wesela) =
/// [CoupleType.mixed], czyli dokładnie dotychczasowe zachowanie.
enum CoupleType {
  /// Kobieta i mężczyzna — „Panna Młoda" / „Pan Młody".
  mixed,

  /// Dwie kobiety — obie „Panny Młode".
  women,

  /// Dwóch mężczyzn — obaj „Panowie Młodzi".
  men,

  /// Neutralnie / inne — „Osoba 1" / „Osoba 2", kategoria „Para Młoda".
  neutral;

  String get label => switch (this) {
        CoupleType.mixed => AppText.t.coupleType_mixed,
        CoupleType.women => AppText.t.coupleType_women,
        CoupleType.men => AppText.t.coupleType_men,
        CoupleType.neutral => AppText.t.coupleType_neutral,
      };

  String get hint => switch (this) {
        CoupleType.mixed => AppText.t.coupleType_mixedHint,
        CoupleType.women => AppText.t.coupleType_womenHint,
        CoupleType.men => AppText.t.coupleType_menHint,
        CoupleType.neutral => AppText.t.coupleType_neutralHint,
      };

  /// Odczyt z zapisanej wartości; nieznana lub brak → [CoupleType.mixed].
  static CoupleType fromRaw(dynamic value) => CoupleType.values.firstWhere(
        (t) => t.name == value,
        orElse: () => CoupleType.mixed,
      );

  /// Płeć rekordu gościa (`'K'` / `'M'` / `'N'`) dla osoby 1 lub 2.
  ///
  /// Wyliczana z typu uroczystości, bo przy zakładaniu wesela nie pytamy o płeć
  /// osobno — to byłoby drugie pytanie o to samo. Wartość jak każda inna płeć
  /// gościa: użytkownik może ją później zmienić w formularzu.
  String genderFor(int index) => switch (this) {
        CoupleType.mixed => index == 1 ? 'K' : 'M',
        CoupleType.women => 'K',
        CoupleType.men => 'M',
        CoupleType.neutral => 'N',
      };
}

/// Etykiety Pary Młodej wyliczane z typu uroczystości i podanych imion.
///
/// JEDYNE miejsce, które produkuje teksty „Panna Młoda" / „Pan Młody" itd.
/// Widoki nie mają ich wpisywać na sztywno — inaczej para jednopłciowa albo
/// niebinarna zobaczy etykiety, które do niej nie pasują.
///
/// ⚠️ WARTOŚCI W BAZIE SIĘ NIE ZMIENIAJĄ. `invitedBy` nadal przechowuje
/// `'groom'` / `'bride'`, a kategoria gościa nadal `'Państwo Młodzi'`. Zmienia
/// się wyłącznie to, co widzi użytkownik — dzięki temu żadne istniejące wesele
/// nie wymaga migracji.
class CoupleLabels {
  const CoupleLabels({
    required this.type,
    this.firstName1 = '',
    this.firstName2 = '',
  });

  final CoupleType type;

  /// Imię osoby zapisanej jako `'bride'` (historycznie „Panna Młoda").
  final String firstName1;

  /// Imię osoby zapisanej jako `'groom'` (historycznie „Pan Młody").
  final String firstName2;

  /// Domyślne etykiety dla wesel bez konfiguracji.
  static const CoupleLabels fallback = CoupleLabels(type: CoupleType.mixed);

  /// Aktualnie obowiązujące etykiety — ustawiane przy wczytaniu wesela.
  ///
  /// Globalny holder w stylu `ActiveWedding` / `DisplayModeController`: pozwala
  /// sięgnąć po etykiety z dowolnego widoku bez przewlekania ich przez
  /// kilkanaście konstruktorów. Świadomy kompromis — spójny z tym, co w
  /// projekcie już jest.
  static CoupleLabels current = fallback;

  /// Buduje etykiety z surowego dokumentu wesela (`data.raw`).
  factory CoupleLabels.fromRaw(Map<String, dynamic> raw) {
    final cfg = raw['appConfig'];
    final type =
        CoupleType.fromRaw(cfg is Map ? cfg['coupleType'] : null);

    // Imiona: najpierw z budżetu (`coupleNames`, używane w podziale kosztów),
    // bo to jedyne miejsce trzymające je ROZDZIELNIE.
    final bd = raw['budgetData'];
    final names = (bd is Map && bd['coupleNames'] is List)
        ? bd['coupleNames'] as List
        : const [];
    String at(int i) {
      final v = (i < names.length ? names[i]?.toString() : null)?.trim() ?? '';
      // „Osoba 1" / „Osoba 2" to wartości zastępcze, nie prawdziwe imiona.
      return isPlaceholderName(v) ? '' : v;
    }

    return CoupleLabels(
      type: type,
      firstName1: at(0),
      firstName2: at(1),
    );
  }

  /// Ustawia globalne etykiety (wołane przy wczytaniu danych wesela).
  static void apply(Map<String, dynamic>? raw) {
    current = raw == null ? fallback : CoupleLabels.fromRaw(raw);
  }

  bool get _sameRole => type == CoupleType.women || type == CoupleType.men;

  /// Numerowana etykieta zastępcza, gdy imię nie zostało podane
  /// („Panna Młoda 1"). Cała fraza z tłumaczeń — liczebnik bywa w innych
  /// językach po drugiej stronie.
  String _numbered(int index) => switch (type) {
        CoupleType.women => AppText.t.couple_brideNumbered(index),
        CoupleType.men => AppText.t.couple_groomNumbered(index),
        _ => AppText.t.couple_personNumbered(index),
      };

  String get _emoji => switch (type) {
        CoupleType.women => '👰',
        CoupleType.men => '🤵',
        CoupleType.mixed => '',
        CoupleType.neutral => '',
      };

  /// Etykieta osoby zapisanej jako `'bride'`.
  String get person1 => _person(firstName1, 1);

  /// Etykieta osoby zapisanej jako `'groom'`.
  String get person2 => _person(firstName2, 2);

  /// Ikona pary jako całości (np. moment „Wejście Pary Młodej").
  String get coupleEmoji => switch (type) {
        CoupleType.men => '🤵',
        CoupleType.neutral => '💍',
        CoupleType.mixed || CoupleType.women => '👰',
      };

  /// Etykieta osoby BEZ emoji — do miejsc, gdzie ikonka przeszkadza
  /// (podpowiedzi nazw, treści quizu).
  String personPlain(int index) =>
      _person(index == 1 ? firstName1 : firstName2, index, emoji: false);

  /// Czy fraza z osobą wymaga wariantu „z imieniem" zamiast roli.
  ///
  /// Zastąpiło `withPerson(prefix, index)`, które sklejało przedrostek z rolą
  /// w dopełniaczu („Auto rodziców Panny Młodej"). Takiej konstrukcji nie da
  /// się przenieść na inne języki — każde miejsce ma teraz własny, pełny klucz
  /// i tylko wybiera wariant przez ten getter.
  bool get usesNames => type != CoupleType.mixed;

  String _person(String name, int index, {bool emoji = true}) {
    // Para mieszana zostaje przy dotychczasowych etykietach — role same się
    // rozróżniają, a każde istniejące wesele ma być widziane bez zmian.
    // Imion używamy tylko tam, gdzie bez nich nie da się odróżnić osób.
    if (type == CoupleType.mixed) {
      if (emoji) {
        return index == 1
            ? AppText.t.couple_brideEmoji
            : AppText.t.couple_groomEmoji;
      }
      return index == 1 ? AppText.t.couple_bride : AppText.t.couple_groom;
    }
    if (type == CoupleType.neutral) {
      return name.isEmpty ? AppText.t.couple_personNumbered(index) : name;
    }
    // Para jednopłciowa: imię, gdy podane; numer jako wariant awaryjny.
    final base = name.isEmpty ? _numbered(index) : name;
    return emoji ? AppText.t.couple_withEmoji(_emoji, base) : base;
  }

  /// Etykieta dla zapisanej wartości `invitedBy` (`'bride'` / `'groom'`).
  String invitedBy(String? value) => switch (value) {
        'bride' => person1,
        'groom' => person2,
        _ => AppText.t.common_none,
      };

  /// Gotowy tekst filtra „kto zaprosił" (chip na liście gości).
  ///
  /// Polszczyzna wymaga tu dopełniacza („Od Panny Młodej"), a imion nie
  /// odmieniamy — dlatego przy imionach i numerowaniu używamy dwukropka
  /// („Od: 👰 Ania"). Cała fraza powstaje tutaj, żeby widok nie sklejał
  /// gramatyki z kawałków.
  String invitedByFilterLabel(String? value) {
    if (type == CoupleType.mixed) {
      return value == 'bride'
          ? AppText.t.couple_fromBride
          : AppText.t.couple_fromGroom;
    }
    return AppText.t.couple_fromNamed(invitedBy(value));
  }

  /// Etykieta świadka po stronie danej osoby.
  String witness(String? value) => switch (value) {
        'witness_bride' => _sameRole || type == CoupleType.neutral
            ? AppText.t.couple_witnessNamed(_shortName(firstName1, 1))
            : AppText.t.couple_witnessBride,
        'witness_groom' => _sameRole || type == CoupleType.neutral
            ? AppText.t.couple_witnessNamed(_shortName(firstName2, 2))
            : AppText.t.couple_witnessGroom,
        _ => AppText.t.couple_witnessNone,
      };

  String _shortName(String name, int index) =>
      name.isEmpty ? AppText.t.couple_personShort(index) : name;

  /// Nazwa kategorii gościa dla Pary Młodej (etykieta, nie wartość w bazie).
  String get coupleCategoryLabel => switch (type) {
        CoupleType.mixed => AppText.t.couple_categoryMixed,
        CoupleType.women => AppText.t.couple_categoryWomen,
        CoupleType.men => AppText.t.couple_categoryMen,
        CoupleType.neutral => AppText.t.couple_categoryNeutral,
      };

  /// Wartość kategorii ZAPISYWANA w bazie — niezmienna, wspólna dla wszystkich
  /// typów uroczystości.
  static const String coupleCategoryValue = 'Państwo Młodzi';

  /// Ile osób może mieć kategorię Pary Młodej. Trzecia Panna Młoda to zawsze
  /// pomyłka przy wpisywaniu, nie zamierzony wpis (zgłoszenie #13).
  static const int maxCouple = 2;

  /// Składa „Ania i Piotr" z dwóch imion; puste pomija.
  static String joinNames(String a, String b) {
    final names = [a.trim(), b.trim()].where((s) => s.isNotEmpty).toList();
    if (names.isEmpty) return '';
    if (names.length == 1) return names.first;
    return AppText.t.couple_joinNames(names[0], names[1]);
  }

  /// Wartości ZASTĘPCZE imion zapisywane w `budgetData.coupleNames`, gdy para
  /// jeszcze ich nie podała.
  ///
  /// ⚠️ POLSKIE I NIEZMIENNE — te napisy porównujemy z tym, co JUŻ LEŻY
  /// W BAZIE, żeby odróżnić „imię niepodane" od prawdziwego imienia.
  /// Przetłumaczenie ich zerwałoby wykrywanie u wszystkich istniejących wesel.
  /// Angielska lista jest dopisana obok, bo wesele założone po angielsku
  /// zapisze tam swoje wartości zastępcze — sprawdzamy więc oba warianty.
  static const List<String> placeholderNames = [
    'Osoba 1',
    'Osoba 2',
    'Person 1',
    'Person 2',
  ];

  /// Czy podana wartość to wartość zastępcza, a nie prawdziwe imię.
  static bool isPlaceholderName(String value) =>
      placeholderNames.contains(value.trim());
}
