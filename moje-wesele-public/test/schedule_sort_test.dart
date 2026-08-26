// Weryfikuje, że wydarzenia po północy (np. zakończenie wesela 01:00)
// sortują się PO wieczornych, a nie na początku dnia.

import 'package:flutter_test/flutter_test.dart';
import 'package:moje_wesele/models/schedule_event.dart';

void main() {
  test('godziny po północy są późniejsze niż wieczorne', () {
    final przygotowania = ScheduleEvent({'hour': 10, 'minute': 0, 'name': 'Przygotowania'});
    final tort = ScheduleEvent({'hour': 22, 'minute': 0, 'name': 'Tort'});
    final ostatniTaniec = ScheduleEvent({'hour': 1, 'minute': 0, 'name': 'Ostatni taniec'});

    final list = [tort, ostatniTaniec, przygotowania]
      ..sort((a, b) => a.sortKey.compareTo(b.sortKey));

    expect(list.map((e) => e.name).toList(),
        ['Przygotowania', 'Tort', 'Ostatni taniec']);
    // 01:00 (po północy) ma większy sortKey niż 22:00.
    expect(ostatniTaniec.sortKey, greaterThan(tort.sortKey));
  });

  group('przedział czasu (hasRange/timeRangeLabel)', () {
    test('brak endHour/endMinute → wydarzenie punktowe, jak dotąd', () {
      final tort = ScheduleEvent({'hour': 21, 'minute': 0, 'name': 'Tort'});
      expect(tort.hasRange, isFalse);
      expect(tort.timeRangeLabel, '21:00');
    });

    test('przedział w tym samym dniu — budka do zdjęć 19:00–23:00', () {
      final budka = ScheduleEvent({
        'hour': 19,
        'minute': 0,
        'endHour': 23,
        'endMinute': 0,
        'name': 'Budka do zdjęć',
        'category': 'Atrakcja',
      });
      expect(budka.hasRange, isTrue);
      expect(budka.timeRangeLabel, '19:00–23:00');
      expect(budka.cat.name, 'Atrakcja');
    });

    test('przejście przez północ (barman 18:00–02:00) — bez blokady, dosłowna etykieta', () {
      final barman = ScheduleEvent({
        'hour': 18,
        'minute': 0,
        'endHour': 2,
        'endMinute': 0,
        'name': 'Barman',
        'category': 'Dostawca',
      });
      expect(barman.hasRange, isTrue);
      expect(barman.timeRangeLabel, '18:00–02:00');
    });

    test('sortowanie: wydarzenie z przedziałem sortuje po godzinie POCZĄTKU', () {
      final barman = ScheduleEvent({
        'hour': 18,
        'minute': 0,
        'endHour': 2,
        'endMinute': 0,
        'name': 'Barman',
      });
      final tort = ScheduleEvent({'hour': 21, 'minute': 0, 'name': 'Tort'});
      final list = [tort, barman]..sort((a, b) => a.sortKey.compareTo(b.sortKey));
      // Barman zaczyna o 18:00 — przed tortem (21:00), mimo że KOŃCZY się
      // dużo później (02:00, po północy). Sortowanie ignoruje koniec.
      expect(list.map((e) => e.name).toList(), ['Barman', 'Tort']);
    });

    test('endHour bez endMinute (dane niekompletne) → traktowane jak punktowe', () {
      final e = ScheduleEvent({'hour': 19, 'minute': 0, 'endHour': 23});
      expect(e.hasRange, isFalse);
      expect(e.timeRangeLabel, '19:00');
    });
  });
}
