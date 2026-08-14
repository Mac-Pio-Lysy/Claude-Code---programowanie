import '../models/currency.dart';
import 'app_format.dart';

/// Kwota bez symbolu waluty: `1 234,50` (pl) / `1,234.50` (en).
///
/// Nazwa została ze względu na ~70 wywołań w całej aplikacji — pod spodem
/// deleguje do [AppFormat], więc separatory idą za językiem interfejsu.
/// Przy migracji kolejnych ekranów wywołania zastępujemy `AppFormat.amount`.
String formatPln(num value) => AppFormat.amount(value);

/// Kwota z symbolem waluty wesela: `1 234,50 zł`, `1 234,50 €`.
///
/// ⚠️ Symbol bierze się z ustawienia wesela — waluta to ETYKIETA, kwoty nie
/// są przeliczane po żadnym kursie.
String formatPlnZl(num value) => AppFormat.money(value);

/// Parsuje kwotę wpisaną przez użytkownika. Zwraca `null`, gdy nie da się
/// odczytać liczby.
///
/// Akceptuje to, co sami wyświetlamy, oraz to, co użytkownik może wkleić:
///  • obie spacje — zwykłą i niełamliwą (tej używa `intl` w polskim),
///  • przecinek albo kropkę jako separator dziesiętny,
///  • symbol DOWOLNEJ obsługiwanej waluty, nie tylko „zł" — inaczej para
///    rozliczająca się w euro nie mogłaby poprawić własnej kwoty.
num? parsePln(String input) {
  var cleaned = input.replaceAll(' ', '').replaceAll(' ', '');
  for (final c in Currency.values) {
    cleaned = cleaned.replaceAll(c.symbol, '').replaceAll(c.code, '');
  }
  cleaned = cleaned.replaceAll(',', '.').trim();
  if (cleaned.isEmpty) return 0;
  return num.tryParse(cleaned);
}
