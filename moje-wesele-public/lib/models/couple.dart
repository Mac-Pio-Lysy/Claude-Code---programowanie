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
        CoupleType.mixed => 'Kobieta i mężczyzna',
        CoupleType.women => 'Dwie kobiety',
        CoupleType.men => 'Dwóch mężczyzn',
        CoupleType.neutral => 'Niebinarne / inne',
      };

  String get hint => switch (this) {
        CoupleType.mixed => 'Panna Młoda i Pan Młody',
        CoupleType.women => 'Obie osoby jako Panny Młode',
        CoupleType.men => 'Obie osoby jako Panowie Młodzi',
        CoupleType.neutral => 'Neutralne etykiety: Osoba 1 i Osoba 2',
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
      return (v == 'Osoba 1' || v == 'Osoba 2') ? '' : v;
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

  String get _roleName => switch (type) {
        CoupleType.women => 'Panna Młoda',
        CoupleType.men => 'Pan Młody',
        CoupleType.neutral => 'Osoba',
        CoupleType.mixed => '',
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

  /// Skleja stały przedrostek z osobą, pilnując polskiej gramatyki.
  ///
  /// Przy parze mieszanej używamy dopełniacza („Auto rodziców Panny Młodej"),
  /// bo tak brzmi naturalnie. Imion nie odmieniamy, więc tam wchodzi nawias
  /// („Auto rodziców (Kasia)") — forma neutralna, poprawna niezależnie od
  /// imienia.
  String withPerson(String prefix, int index) => type == CoupleType.mixed
      ? '$prefix ${index == 1 ? 'Panny Młodej' : 'Pana Młodego'}'
      : '$prefix (${personPlain(index)})';

  String _person(String name, int index, {bool emoji = true}) {
    // Para mieszana zostaje przy dotychczasowych etykietach — role same się
    // rozróżniają, a każde istniejące wesele ma być widziane bez zmian.
    // Imion używamy tylko tam, gdzie bez nich nie da się odróżnić osób.
    if (type == CoupleType.mixed) {
      final base = index == 1 ? 'Panna Młoda' : 'Pan Młody';
      return emoji ? '${index == 1 ? '👰' : '🤵'} $base' : base;
    }
    if (type == CoupleType.neutral) {
      return name.isEmpty ? 'Osoba $index' : name;
    }
    // Para jednopłciowa: imię, gdy podane; numer jako wariant awaryjny.
    final base = name.isEmpty ? '$_roleName $index' : name;
    return emoji ? '$_emoji $base' : base;
  }

  /// Etykieta dla zapisanej wartości `invitedBy` (`'bride'` / `'groom'`).
  String invitedBy(String? value) => switch (value) {
        'bride' => person1,
        'groom' => person2,
        _ => '—',
      };

  /// Gotowy tekst filtra „kto zaprosił" (chip na liście gości).
  ///
  /// Polszczyzna wymaga tu dopełniacza („Od Panny Młodej"), a imion nie
  /// odmieniamy — dlatego przy imionach i numerowaniu używamy dwukropka
  /// („Od: 👰 Ania"). Cała fraza powstaje tutaj, żeby widok nie sklejał
  /// gramatyki z kawałków.
  String invitedByFilterLabel(String? value) {
    if (type == CoupleType.mixed) {
      return value == 'bride' ? 'Od Panny Młodej' : 'Od Pana Młodego';
    }
    return 'Od: ${invitedBy(value)}';
  }

  /// Etykieta świadka po stronie danej osoby.
  String witness(String? value) => switch (value) {
        'witness_bride' => _sameRole || type == CoupleType.neutral
            ? 'Świadek/Świadkowa (${_shortName(firstName1, 1)})'
            : 'Świadkowa',
        'witness_groom' => _sameRole || type == CoupleType.neutral
            ? 'Świadek/Świadkowa (${_shortName(firstName2, 2)})'
            : 'Świadek',
        _ => 'Brak roli',
      };

  String _shortName(String name, int index) =>
      name.isEmpty ? 'osoba $index' : name;

  /// Nazwa kategorii gościa dla Pary Młodej (etykieta, nie wartość w bazie).
  String get coupleCategoryLabel => switch (type) {
        CoupleType.mixed => 'Państwo Młodzi',
        CoupleType.women => 'Panny Młode',
        CoupleType.men => 'Panowie Młodzi',
        CoupleType.neutral => 'Para Młoda',
      };

  /// Wartość kategorii ZAPISYWANA w bazie — niezmienna, wspólna dla wszystkich
  /// typów uroczystości.
  static const String coupleCategoryValue = 'Państwo Młodzi';

  /// Ile osób może mieć kategorię Pary Młodej. Trzecia Panna Młoda to zawsze
  /// pomyłka przy wpisywaniu, nie zamierzony wpis (zgłoszenie #13).
  static const int maxCouple = 2;

  /// Składa „Ania i Piotr" z dwóch imion; puste pomija.
  static String joinNames(String a, String b) =>
      [a.trim(), b.trim()].where((s) => s.isNotEmpty).join(' i ');
}
