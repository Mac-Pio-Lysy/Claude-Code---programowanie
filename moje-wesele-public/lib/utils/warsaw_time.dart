/// Czas w strefie Europe/Warsaw bez dodatkowych zależności.
///
/// Widoczność sekcji dla gości działa z dokładnością do DNIA, więc kluczowe
/// jest poprawne „dzisiaj" w Polsce (a nie w strefie urządzenia/serwera).
/// Polska używa CET (UTC+1) zimą i CEST (UTC+2) latem. Przełączenie następuje
/// wg reguł UE: ostatnia niedziela marca 01:00 UTC → ostatnia niedziela
/// października 01:00 UTC.
library;

/// Bieżąca data i godzina w strefie Europe/Warsaw.
DateTime warsawNow() {
  final utc = DateTime.now().toUtc();
  final offset = _isPolandDst(utc) ? 2 : 1;
  return utc.add(Duration(hours: offset));
}

/// Dzisiejsza data (bez godziny) w strefie Europe/Warsaw.
DateTime warsawToday() {
  final n = warsawNow();
  return DateTime(n.year, n.month, n.day);
}

/// Czy w danym momencie UTC w Polsce obowiązuje czas letni (CEST, UTC+2).
bool _isPolandDst(DateTime utc) {
  final year = utc.year;
  // Moment przejścia: 01:00 UTC ostatniej niedzieli marca / października.
  final dstStart = _lastSundayOfMonth(year, 3).add(const Duration(hours: 1));
  final dstEnd = _lastSundayOfMonth(year, 10).add(const Duration(hours: 1));
  return !utc.isBefore(dstStart) && utc.isBefore(dstEnd);
}

/// Ostatnia niedziela danego miesiąca (00:00 UTC).
DateTime _lastSundayOfMonth(int year, int month) {
  // Dzień 0 kolejnego miesiąca = ostatni dzień bieżącego miesiąca.
  var day = DateTime.utc(year, month + 1, 0);
  while (day.weekday != DateTime.sunday) {
    day = day.subtract(const Duration(days: 1));
  }
  return DateTime.utc(day.year, day.month, day.day);
}
