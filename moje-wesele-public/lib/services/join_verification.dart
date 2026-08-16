/// Weryfikacja nazwiska przy dołączaniu gościa do wesela kodem.
///
/// ⚠️ TO JEST ZABEZPIECZENIE, nie wygoda. Kod dołączenia bywa jawny — para
/// drukuje go na zaproszeniach i kładzie na stołach — więc to nazwisko
/// (obok daty ślubu) decyduje, czy ktoś przypadkowy wejdzie na cudze wesele.
///
/// POPRZEDNIA WERSJA BYŁA DZIURAWA: skleiła wszystkie pola w jeden ciąg
/// i robiła `hay.contains(needle)` z jedynym warunkiem „min. 2 znaki". Wobec
/// tego przechodził DOWOLNY fragment — „Kow" trafiał w „Kowalscy", a „ow"
/// w cokolwiek. Co gorsza, w porównaniu brała udział nazwa wydarzenia, więc
/// wpisanie domyślnego „Ceremonia Weselna" otwierało każde wesele, które tej
/// nazwy nie zmieniło.
///
/// TERAZ: dopasowanie CAŁYCH członów nazwiska, nigdy fragmentu.
library;

/// Wynik dopasowania — osobny typ, żeby dało się testować bez Firestore'a.
class JoinVerification {
  const JoinVerification._();

  /// Człony krótsze niż tyle znaków pomijamy. Odsiewa spójniki („i", „&")
  /// i inicjały, których nikt nie traktuje jak nazwiska.
  static const int minTokenLength = 2;

  /// Czy tekst podany przez gościa pasuje do nazwiska Państwa Młodych.
  ///
  /// [surnames] — dedykowane pole weryfikacji (zgłoszenie #23), najpewniejsze
  /// źródło. [displayNames] — pole „Osoby", zwykle imiona; zostaje, bo
  /// Ustawienia wprost zapowiadają, że przy pustym polu nazwisk gość poda
  /// właśnie je.
  ///
  /// Nazwa wydarzenia NIE bierze udziału w porównaniu — jest wspólna dla wielu
  /// wesel (domyślne „Ceremonia Weselna"), więc nie identyfikuje niczego.
  ///
  /// Przechodzi, gdy:
  ///  • cały wpis (po normalizacji) równa się całemu polu, albo
  ///  • każdy człon wpisu jest RÓWNY któremuś członowi pola.
  ///
  /// Dzięki drugiemu warunkowi para z dwoma nazwiskami („Kowalski Nowak")
  /// może podać gościom jedno z nich, a kolejność wpisania nie ma znaczenia.
  static bool surnameMatches({
    required String input,
    required String surnames,
    required String displayNames,
  }) {
    final needle = normalize(input);
    if (needle.isEmpty) return false;

    final expected = [surnames, displayNames]
        .map(normalize)
        .where((s) => s.isNotEmpty)
        .toList();
    if (expected.isEmpty) return false;

    // 1) Pełna zgodność z którymkolwiek polem — najprostszy przypadek.
    if (expected.contains(needle)) return true;

    // 2) Zgodność członów. Wpis musi w CAŁOŚCI składać się z członów, które
    //    występują w danych wesela — fragment nigdy nie jest członem.
    final needleTokens = tokens(needle);
    if (needleTokens.isEmpty) return false;

    final known = <String>{for (final e in expected) ...tokens(e)};
    if (known.isEmpty) return false;

    return needleTokens.every(known.contains);
  }

  /// Normalizacja: małe litery, bez polskich znaków diakrytycznych, bez
  /// wiodących/końcowych i podwójnych spacji.
  ///
  /// Świadomie tolerancyjna — „ KOWALSCY " i „kowalscy" to ta sama osoba.
  /// Nie usuwa natomiast liter ani nie skraca tekstu, więc nie da się przez
  /// nią przemycić fragmentu.
  static String normalize(String s) {
    var t = s.toLowerCase().trim();
    const map = {
      'ą': 'a',
      'ć': 'c',
      'ę': 'e',
      'ł': 'l',
      'ń': 'n',
      'ó': 'o',
      'ś': 's',
      'ż': 'z',
      'ź': 'z',
    };
    map.forEach((k, v) => t = t.replaceAll(k, v));
    return t.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Człony nazwiska: dzielimy po spacjach ORAZ po myślniku i ukośniku.
  ///
  /// Dzięki temu „Kowalska-Nowak" daje dwa człony i gość może podać dowolny
  /// z nich w całości. To nadal nie jest fragment — każdy człon to kompletny
  /// element nazwiska, a nie dowolny prefiks.
  static List<String> tokens(String normalized) => normalized
      .split(RegExp(r'[\s/,\-–—]+'))
      .map((t) => t.trim())
      .where((t) => t.length >= minTokenLength)
      .toList();
}
