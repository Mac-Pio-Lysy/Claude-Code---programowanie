/// Kod dostępu do wesela — długość, alfabet, zapis i odczyt.
///
/// Wspólne dla OBU rodzajów kodów, bo jedno i drugie otwiera dostęp do
/// wesela i nie ma powodu, żeby różniły się siłą:
///  • kod gościa (`weddingCodes/{KOD}`) — jeden z trzech czynników przy
///    dołączaniu, drukowany na zaproszeniach,
///  • kod zaproszenia roli (`roleInvites/{KOD}`) — jednorazowy, nadaje PEŁNY
///    panel współorganizatorowi albo planerowi.
///
/// Kod jest IDENTYFIKATOREM dokumentu, więc porównanie jest z natury dokładne.
/// Tutaj mieszka wszystko, co dotyczy jego postaci: z jakich znaków się składa,
/// jak go pokazać człowiekowi i jak sprowadzić wpisany tekst do postaci
/// porównywalnej.
class JoinCode {
  const JoinCode._();

  /// Alfabet kodu — BEZ znaków mylących przy przepisywaniu z kartki:
  /// nie ma `0`/`O`, `1`/`I`/`L`. Zostaje 31 znaków, same wielkie litery
  /// i cyfry 2–9, więc nie trzeba tłumaczyć gościowi, „czy to zero, czy o”.
  static const String alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  /// Długość NOWO generowanych kodów — gościa i zaproszenia roli.
  ///
  /// 12 znaków z 31-znakowego alfabetu to ok. 7,9·10¹⁷ kombinacji (wcześniej
  /// 6 znaków ≈ 8,9·10⁸). Zgadywanie kodu przestaje być realną drogą — nawet
  /// przy milionie prób na sekundę mowa o dziesiątkach tysięcy lat.
  static const int length = 12;

  /// Długość kodów wydanych PRZED zmianą.
  ///
  /// ⚠️ Stare kody ZOSTAJĄ WAŻNE — obu rodzajów. Kod jest identyfikatorem
  /// dokumentu, więc wyszukanie działa niezależnie od długości: nic nie
  /// migrujemy, nie unieważniamy wydrukowanych zaproszeń ani kodów ról,
  /// które ktoś już dostał, a jeszcze nie odebrał.
  static const int legacyLength = 6;

  /// Co ile znaków dzielimy kod przy pokazywaniu.
  static const int groupSize = 4;

  /// Separator grup w postaci do czytania.
  static const String groupSeparator = '-';

  /// Sprowadza wpisany tekst do postaci porównywalnej z zapisanym kodem.
  ///
  /// Wielkie litery i WYRZUCENIE wszystkiego spoza alfabetu: gość przepisujący
  /// kod z zaproszenia zobaczy `ABCD-EFGH-JKMN` i tak go wpisze — spacje,
  /// myślniki czy kropki nie mogą go blokować. Nie jest to poluzowanie
  /// weryfikacji: usuwamy wyłącznie znaki, których w kodzie i tak nigdy nie ma.
  static String normalize(String raw) {
    final upper = raw.toUpperCase();
    final buffer = StringBuffer();
    for (final ch in upper.split('')) {
      if (alphabet.contains(ch)) buffer.write(ch);
    }
    return buffer.toString();
  }

  /// Postać do pokazania i wydruku: `ABCD-EFGH-JKMN`.
  ///
  /// Krótkie kody (stare, 6-znakowe) też grupujemy — `ABC4-K7`. Nie zmienia to
  /// wartości, bo [normalize] i tak zdejmie separatory.
  static String format(String code) {
    final norm = normalize(code);
    if (norm.isEmpty) return '';
    final parts = <String>[];
    for (var i = 0; i < norm.length; i += groupSize) {
      parts.add(norm.substring(
          i, i + groupSize > norm.length ? norm.length : i + groupSize));
    }
    return parts.join(groupSeparator);
  }

  /// Czy tekst może być kodem dołączenia (bez sprawdzania, czy istnieje).
  ///
  /// Akceptuje obie długości — nowe kody i te wydane wcześniej.
  static bool looksValid(String raw) {
    final norm = normalize(raw);
    return norm.length == length || norm.length == legacyLength;
  }
}
