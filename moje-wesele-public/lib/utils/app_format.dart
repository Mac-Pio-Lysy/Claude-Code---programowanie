import 'package:intl/intl.dart';

import '../models/currency.dart';

/// Formatowanie kwot i dat zależne od języka i waluty wesela.
///
/// Globalny holder — jak `CoupleLabels.current` i `DisplayModeController`.
/// Powód jest ten sam: formatowanie wywołuje się w setkach miejsc, także
/// poza drzewem widgetów (modele, podsumowania, PDF), więc przewlekanie
/// `BuildContext` przez wszystkie sygnatury byłoby gorsze niż jeden punkt
/// konfiguracji ustawiany przy starcie i przy zmianie języka.
class AppFormat {
  AppFormat._();

  /// Język używany do separatorów i nazw miesięcy. Ustawiany z
  /// `LocaleController` przy starcie i po każdej zmianie języka.
  static String locale = 'pl';

  /// Waluta wesela — wyłącznie SYMBOL przy kwocie, bez przeliczania kursów.
  static Currency currency = Currency.fallback;

  /// Ustawia oba parametry naraz (wołane po wczytaniu wesela i przy zmianie
  /// języka).
  static void configure({String? locale, Currency? currency}) {
    if (locale != null) AppFormat.locale = locale;
    if (currency != null) AppFormat.currency = currency;
  }

  // ── Kwoty ────────────────────────────────────────────────────────────────

  /// Kwota bez symbolu waluty: `1 234,50` (pl) / `1,234.50` (en).
  ///
  /// Zawsze dwa miejsca po przecinku — kwoty w budżecie mają być porównywalne
  /// wzrokowo w kolumnie.
  static String amount(num value) =>
      NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: 2)
          .format(value);

  /// Kwota z symbolem waluty: `1 234,50 zł`, `1 234,50 €`.
  ///
  /// Symbol stoi ZA kwotą niezależnie od języka. To konwencja polska i
  /// większości europejskich; trzymamy jedną, żeby ta sama liczba nie
  /// przeskakiwała na drugą stronę po przełączeniu interfejsu na angielski.
  static String money(num value) => '${amount(value)} ${currency.symbol}';

  /// Kwota zaokrąglona do pełnych jednostek — do wykresów i skrótów.
  static String moneyRounded(num value) =>
      '${NumberFormat.decimalPattern(locale).format(value.round())} '
      '${currency.symbol}';

  // ── Daty ─────────────────────────────────────────────────────────────────

  /// Data pełna: `12 czerwca 2027` / `June 12, 2027`.
  ///
  /// Zastępuje ręczne tablice nazw miesięcy — te działały wyłącznie po polsku.
  static String dateLong(DateTime date) =>
      DateFormat.yMMMMd(locale).format(date);

  /// Data skrócona: `12.06.2027` / `6/12/2027`.
  static String dateShort(DateTime date) => DateFormat.yMd(locale).format(date);

  /// Dzień i miesiąc: `12 czerwca`.
  static String dayMonth(DateTime date) => DateFormat.MMMMd(locale).format(date);

  /// Godzina: `20:00`.
  static String time(DateTime date) => DateFormat.Hm(locale).format(date);

  /// Data z formatu zapisu `YYYY-MM-DD` na tekst dla użytkownika.
  ///
  /// Zwraca `null`, gdy zapis jest pusty albo nieczytelny — wywołujący sam
  /// decyduje, co pokazać zamiast daty.
  static String? dateLongFromIso(String? iso) {
    final parsed = parseIso(iso);
    return parsed == null ? null : dateLong(parsed);
  }

  /// Data skrócona z zapisu `YYYY-MM-DD`; `null`, gdy zapis nieczytelny.
  static String? dateShortFromIso(String? iso) {
    final parsed = parseIso(iso);
    return parsed == null ? null : dateShort(parsed);
  }

  /// Parsuje `YYYY-MM-DD` (ewentualnie z częścią czasową) na [DateTime].
  static DateTime? parseIso(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(iso);
    if (m == null) return null;
    return DateTime(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
    );
  }
}
