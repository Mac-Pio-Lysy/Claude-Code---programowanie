import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moje_wesele/models/currency.dart';
import 'package:moje_wesele/models/wedding_data.dart';
import 'package:moje_wesele/utils/app_format.dart';
import 'package:moje_wesele/utils/format.dart';

/// Testy warstwy formatowania (etap 2 lokalizacji): kwoty i daty zależne od
/// języka, symbol waluty zależny od wesela.
void main() {
  setUpAll(() async {
    // Nazwy miesięcy dla `intl` — w aplikacji robi to `main()`.
    await initializeDateFormatting();
  });

  setUp(() {
    AppFormat.configure(locale: 'pl', currency: Currency.pln);
  });

  group('kwoty', () {
    test('polski: spacja jako separator tysięcy, przecinek dziesiętny', () {
      // Zachowanie zgodne z dotychczasowym `formatPln` i wersją web.
      // `intl` używa NIEŁAMLIWEJ spacji (U+00A0) — wizualnie identycznej,
      // a `parsePln` obsługuje obie, więc round-trip działa.
      expect(AppFormat.amount(1234.5), '1 234,50');
      expect(AppFormat.amount(0), '0,00');
      expect(AppFormat.amount(999), '999,00');
    });

    test('polski: duże liczby grupowane co trzy cyfry', () {
      expect(AppFormat.amount(1234567.89), '1 234 567,89');
    });

    test('angielski: przecinek jako separator tysięcy, kropka dziesiętna', () {
      AppFormat.configure(locale: 'en');
      expect(AppFormat.amount(1234.5), '1,234.50');
    });

    test('zawsze dwa miejsca po przecinku', () {
      expect(AppFormat.amount(10), '10,00');
      expect(AppFormat.amount(10.1), '10,10');
    });

    test('kwoty ujemne zachowują znak', () {
      expect(AppFormat.amount(-1234.5), startsWith('-'));
    });

    test('symbol waluty stoi ZA kwotą', () {
      expect(AppFormat.money(1234.5), '1 234,50 zł');

      AppFormat.configure(currency: Currency.eur);
      expect(AppFormat.money(1234.5), '1 234,50 €');
    });

    test('symbol nie przeskakuje po zmianie języka', () {
      // Jedna konwencja w obu językach — inaczej ta sama liczba zmieniałaby
      // układ po przełączeniu interfejsu.
      AppFormat.configure(locale: 'en', currency: Currency.usd);
      expect(AppFormat.money(1234.5), '1,234.50 \$');
    });

    test('zmiana waluty NIE przelicza kwoty', () {
      const value = 15000;
      final pln = AppFormat.money(value);

      AppFormat.configure(currency: Currency.eur);
      final eur = AppFormat.money(value);

      // Ta sama liczba, inny symbol — żadnych kursów.
      expect(pln.replaceAll(' zł', ''), eur.replaceAll(' €', ''));
    });
  });

  group('zgodność starych wywołań', () {
    test('formatPln nadal zwraca kwotę bez symbolu', () {
      expect(formatPln(1234.5), '1 234,50');
    });

    test('formatPlnZl używa waluty wesela, nie zaszytego „zł"', () {
      AppFormat.configure(currency: Currency.eur);
      expect(formatPlnZl(100), '100,00 €');
    });
  });

  group('parsowanie kwot', () {
    test('odczytuje to, co sami wyświetlamy', () {
      expect(parsePln(AppFormat.money(1234.5)), 1234.5);
    });

    test('radzi sobie z symbolem innej waluty', () {
      // Para rozliczająca się w euro musi móc poprawić własną kwotę.
      AppFormat.configure(currency: Currency.eur);
      expect(parsePln(AppFormat.money(999.99)), 999.99);
      expect(parsePln('250,00 €'), 250);
    });

    test('akceptuje kropkę i przecinek', () {
      expect(parsePln('1234.50'), 1234.5);
      expect(parsePln('1234,50'), 1234.5);
    });

    test('puste wejście to zero, śmieci to null', () {
      expect(parsePln(''), 0);
      expect(parsePln('dużo'), isNull);
    });
  });

  group('daty', () {
    final date = DateTime(2027, 6, 12);

    test('polski: pełna data z nazwą miesiąca', () {
      expect(AppFormat.dateLong(date), '12 czerwca 2027');
    });

    test('angielski: pełna data w konwencji lokalnej', () {
      AppFormat.configure(locale: 'en');
      expect(AppFormat.dateLong(date), 'June 12, 2027');
    });

    test('data z zapisu ISO', () {
      expect(AppFormat.dateLongFromIso('2027-06-12'), '12 czerwca 2027');
      expect(AppFormat.dateLongFromIso('2027-06-12T10:00:00'),
          '12 czerwca 2027');
    });

    test('pusty lub nieczytelny zapis → null', () {
      expect(AppFormat.dateLongFromIso(null), isNull);
      expect(AppFormat.dateLongFromIso(''), isNull);
      expect(AppFormat.dateLongFromIso('kiedyś'), isNull);
    });

    test('parsowanie ISO zwraca właściwy dzień', () {
      final parsed = AppFormat.parseIso('2027-06-12');
      expect(parsed, DateTime(2027, 6, 12));
    });

    test('godzina w formacie 24-godzinnym', () {
      expect(AppFormat.time(DateTime(2027, 6, 12, 20, 5)), '20:05');
    });
  });

  group('waluta podąża za weselem', () {
    test('wczytanie wesela ustawia symbol', () {
      WeddingData.fromMap({
        'appConfig': {'currency': 'EUR'}
      });
      expect(AppFormat.currency, Currency.eur);
      expect(AppFormat.money(10), '10,00 €');
    });

    test('wesele bez pola wraca do PLN', () {
      AppFormat.configure(currency: Currency.eur);
      WeddingData.fromMap(const {});
      expect(AppFormat.currency, Currency.pln);
    });
  });
}
