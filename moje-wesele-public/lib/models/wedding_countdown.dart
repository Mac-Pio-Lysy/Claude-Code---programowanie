import '../utils/warsaw_time.dart';

/// Odliczanie do wesela (#24) — czysta logika, bez widgetów.
///
/// Liczone w czasie warszawskim, zgodnie z resztą aplikacji: gość może
/// oglądać stronę z innej strefy czasowej, a „ile zostało do wesela" ma
/// znaczyć to samo dla wszystkich.
class WeddingCountdown {
  const WeddingCountdown({
    required this.days,
    required this.hours,
    required this.minutes,
    required this.hasStarted,
    required this.isPast,
  });

  /// Pełne dni do rozpoczęcia.
  final int days;

  /// Godziny ponad pełne dni (0-23).
  final int hours;

  /// Minuty ponad pełne godziny (0-59).
  final int minutes;

  /// Uroczystość już się zaczęła i wciąż trwa (do końca doby).
  ///
  /// ⚠️ To NIE jest „wypada dzisiaj" — na pięć godzin przed ślubem licznik ma
  /// dalej odliczać godziny, a nie ogłaszać, że już się zaczęło.
  final bool hasStarted;

  /// Termin już minął.
  final bool isPast;

  /// Czy zostało mniej niż doba — wtedy pokazujemy godziny i minuty.
  bool get isFinalDay => !isPast && !hasStarted && days == 0;

  /// Buduje odliczanie z zapisanych pól wesela.
  ///
  /// [date] w formacie „YYYY-MM-DD", [time] w „HH:mm" (domyślnie 16:00, jak
  /// w konfiguracji). Zwraca `null`, gdy data nie jest ustawiona lub ma inny
  /// format — wtedy licznika po prostu nie pokazujemy.
  ///
  /// [now] wyłącznie do testów; produkcyjnie bierzemy czas warszawski.
  static WeddingCountdown? from(String? date, {String? time, DateTime? now}) {
    final target = _parseTarget(date, time);
    if (target == null) return null;

    final current = now ?? warsawNow();
    final diff = target.difference(current);

    if (diff.isNegative) {
      // Wesele traktujemy jako trwające do końca doby — inaczej licznik
      // znikałby gościom w środku przyjęcia.
      final endOfDay =
          DateTime(target.year, target.month, target.day + 1);
      final duringParty = current.isBefore(endOfDay);
      return WeddingCountdown(
        days: 0,
        hours: 0,
        minutes: 0,
        hasStarted: duringParty,
        isPast: !duringParty,
      );
    }

    return WeddingCountdown(
      days: diff.inDays,
      hours: diff.inHours % 24,
      minutes: diff.inMinutes % 60,
      hasStarted: false,
      isPast: false,
    );
  }

  /// Data i godzina uroczystości albo `null`, gdy zapis jest nieczytelny.
  static DateTime? _parseTarget(String? date, String? time) {
    if (date == null || date.isEmpty) return null;
    final d = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(date);
    if (d == null) return null;

    var hour = 16, minute = 0; // domyślna godzina z konfiguracji
    final t = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(time?.trim() ?? '');
    if (t != null) {
      final h = int.parse(t.group(1)!);
      final m = int.parse(t.group(2)!);
      if (h >= 0 && h <= 23 && m >= 0 && m <= 59) {
        hour = h;
        minute = m;
      }
    }

    return DateTime(
      int.parse(d.group(1)!),
      int.parse(d.group(2)!),
      int.parse(d.group(3)!),
      hour,
      minute,
    );
  }

  /// Główna liczba na liczniku (dni albo godziny w ostatniej dobie).
  int get headlineValue => isFinalDay ? hours : days;

  /// Podpis pod główną liczbą, z poprawną odmianą.
  String get headlineLabel =>
      isFinalDay ? _plural(hours, 'godzina', 'godziny', 'godzin')
                 : _plural(days, 'dzień', 'dni', 'dni');

  /// Doprecyzowanie pod spodem — `null`, gdy nie ma czego dodać.
  String? get detail {
    if (isPast || hasStarted) return null;
    if (isFinalDay) {
      return '$minutes ${_plural(minutes, 'minuta', 'minuty', 'minut')}';
    }
    if (hours == 0) return null;
    return 'i $hours ${_plural(hours, 'godzina', 'godziny', 'godzin')}';
  }

  /// Polska odmiana po liczebniku (1 / 2-4 / 5+, z wyjątkiem 12-14).
  static String _plural(int n, String one, String few, String many) {
    if (n == 1) return one;
    final last = n % 10;
    final last2 = n % 100;
    if (last >= 2 && last <= 4 && (last2 < 12 || last2 > 14)) return few;
    return many;
  }
}
