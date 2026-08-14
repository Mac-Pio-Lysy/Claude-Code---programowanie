/// Waluta budżetu — WYŁĄCZNIE etykieta symbolu przy kwotach.
///
/// ⚠️ NIE PRZELICZA KURSÓW. Zmiana waluty nie rusza żadnej zapisanej liczby:
/// 15 000 pozostaje 15 000, zmienia się tylko to, co stoi obok. Para, która
/// prowadzi budżet w euro, wpisuje kwoty w euro — aplikacja nie udaje, że zna
/// kursy, bo fałszywe przeliczenie byłoby gorsze niż jego brak.
///
/// Waluta to ustawienie WESELA (`appConfig.currency`), a nie języka: para
/// płaci sali w złotówkach niezależnie od tego, w jakim języku gość ogląda
/// stronę.
enum Currency {
  pln('PLN', 'zł', 'Złoty polski'),
  eur('EUR', '€', 'Euro'),
  usd('USD', '\$', 'Dolar amerykański'),
  gbp('GBP', '£', 'Funt brytyjski'),
  czk('CZK', 'Kč', 'Korona czeska'),
  chf('CHF', 'CHF', 'Frank szwajcarski');

  const Currency(this.code, this.symbol, this.label);

  /// Kod ISO zapisywany w danych (`PLN`, `EUR`…).
  final String code;

  /// Symbol pokazywany przy kwocie.
  final String symbol;

  /// Nazwa na liście wyboru.
  final String label;

  /// Domyślna waluta — produkt startuje w Polsce.
  static const Currency fallback = Currency.pln;

  /// Odczyt z zapisanej wartości. Brak pola albo nieznany kod → [fallback],
  /// więc istniejące wesela (bez tego pola) działają bez zmian.
  static Currency fromRaw(dynamic value) {
    for (final c in Currency.values) {
      if (c.code == value) return c;
    }
    return fallback;
  }

  /// Waluta zapisana w dokumencie wesela (`appConfig.currency`).
  static Currency ofRaw(Map<String, dynamic>? raw) {
    final cfg = raw?['appConfig'];
    return fromRaw(cfg is Map ? cfg['currency'] : null);
  }
}
