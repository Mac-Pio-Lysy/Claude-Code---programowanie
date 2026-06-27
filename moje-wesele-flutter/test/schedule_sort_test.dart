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
}
