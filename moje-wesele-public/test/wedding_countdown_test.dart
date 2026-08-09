import 'package:flutter_test/flutter_test.dart';
import 'package:moje_wesele/models/wedding_countdown.dart';

/// Testy licznika do wesela (#24) — czysta logika, z wstrzykniętym „teraz".
void main() {
  WeddingCountdown? at(String now, {String date = '2027-06-12', String? time}) =>
      WeddingCountdown.from(date, time: time, now: DateTime.parse(now));

  group('brak lub zły format daty', () {
    test('null i pusty ciąg → brak licznika', () {
      expect(WeddingCountdown.from(null), isNull);
      expect(WeddingCountdown.from(''), isNull);
    });

    test('nieczytelna data → brak licznika (zamiast wywalenia się)', () {
      expect(WeddingCountdown.from('kiedyś latem'), isNull);
      expect(WeddingCountdown.from('12.06.2027'), isNull);
    });
  });

  group('odliczanie', () {
    test('pełne dni do wesela', () {
      // 10 dni przed, o tej samej godzinie co ślub.
      final c = at('2027-06-02T16:00:00', time: '16:00')!;
      expect(c.days, 10);
      expect(c.hours, 0);
      expect(c.hasStarted, isFalse);
      expect(c.isPast, isFalse);
      expect(c.headlineValue, 10);
      expect(c.headlineLabel, 'dni');
    });

    test('dni z godzinami — reszta trafia do doprecyzowania', () {
      final c = at('2027-06-10T10:00:00', time: '16:00')!;
      expect(c.days, 2);
      expect(c.hours, 6);
      expect(c.detail, 'i 6 godzin');
    });

    test('jeden dzień odmienia się poprawnie', () {
      final c = at('2027-06-11T16:00:00', time: '16:00')!;
      expect(c.days, 1);
      expect(c.headlineLabel, 'dzień');
    });

    test('brak godziny w danych → domyślnie 16:00', () {
      final withDefault = at('2027-06-12T10:00:00')!;
      final explicit = at('2027-06-12T10:00:00', time: '16:00')!;
      expect(withDefault.hours, explicit.hours);
      expect(withDefault.hours, 6);
    });

    test('nieczytelna godzina nie psuje licznika', () {
      final c = at('2027-06-12T10:00:00', time: 'popołudniu')!;
      expect(c.hours, 6); // wraca do 16:00
    });
  });

  group('ostatnia doba', () {
    test('poniżej doby licznik przechodzi na godziny', () {
      final c = at('2027-06-12T10:30:00', time: '16:00')!;
      expect(c.isFinalDay, isTrue);
      expect(c.days, 0);
      expect(c.headlineValue, 5);
      expect(c.headlineLabel, 'godzin');
      expect(c.detail, '30 minut');
    });

    test('odmiana godzin: 2 godziny', () {
      final c = at('2027-06-12T14:00:00', time: '16:00')!;
      expect(c.headlineValue, 2);
      expect(c.headlineLabel, 'godziny');
    });

    test('odmiana minut: 1 minuta', () {
      final c = at('2027-06-12T15:59:00', time: '16:00')!;
      expect(c.detail, '1 minuta');
    });
  });

  group('dzień wesela i po nim', () {
    test('po rozpoczęciu, ale tego samego dnia → „to już dziś"', () {
      final c = at('2027-06-12T20:00:00', time: '16:00')!;
      expect(c.hasStarted, isTrue);
      expect(c.isPast, isFalse);
    });

    test('licznik nie znika w środku przyjęcia (po północy dnia ślubu)', () {
      final c = at('2027-06-12T23:59:00', time: '16:00')!;
      expect(c.isPast, isFalse);
    });

    test('następnego dnia licznik jest przeszłością (widget go ukrywa)', () {
      final c = at('2027-06-13T00:01:00', time: '16:00')!;
      expect(c.isPast, isTrue);
      expect(c.hasStarted, isFalse);
    });

    test('dawne wesele też jest przeszłością', () {
      final c = at('2030-01-01T12:00:00', time: '16:00')!;
      expect(c.isPast, isTrue);
    });
  });

  group('odmiana liczebników', () {
    test('22 dni, ale 22 godziny', () {
      expect(at('2027-05-21T16:00:00', time: '16:00')!.headlineLabel, 'dni');
      final h = at('2027-06-11T18:00:00', time: '16:00')!;
      expect(h.days, 0);
      expect(h.headlineValue, 22);
      expect(h.headlineLabel, 'godziny');
    });

    test('12-14 godzin to forma „godzin", nie „godziny"', () {
      final c = at('2027-06-12T03:00:00', time: '16:00')!;
      expect(c.headlineValue, 13);
      expect(c.headlineLabel, 'godzin');
    });

    test('pełne godziny bez reszty nie dokładają doprecyzowania', () {
      final c = at('2027-06-10T16:00:00', time: '16:00')!;
      expect(c.days, 2);
      expect(c.hours, 0);
      expect(c.detail, isNull);
    });
  });
}
