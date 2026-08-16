import '../l10n/app_text.dart';

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
  pln('PLN', 'zł'),
  eur('EUR', '€'),
  usd('USD', '\$'),
  gbp('GBP', '£'),
  czk('CZK', 'Kč'),
  chf('CHF', 'CHF');

  const Currency(this.code, this.symbol);

  /// Kod ISO zapisywany w danych (`PLN`, `EUR`…).
  final String code;

  /// Symbol pokazywany przy kwocie.
  final String symbol;

  /// Nazwa na liście wyboru — TŁUMACZONA, więc getter, a nie pole enuma
  /// (parametr konstruktora musiałby być stałą kompilacji).
  String get label => switch (this) {
        Currency.pln => AppText.t.currency_pln,
        Currency.eur => AppText.t.currency_eur,
        Currency.usd => AppText.t.currency_usd,
        Currency.gbp => AppText.t.currency_gbp,
        Currency.czk => AppText.t.currency_czk,
        Currency.chf => AppText.t.currency_chf,
      };

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
