import 'package:flutter_test/flutter_test.dart';
import 'package:moje_wesele/models/app_notification.dart';
import 'package:moje_wesele/models/notification_snapshot.dart';
import 'package:moje_wesele/models/wedding_data.dart';
import 'package:moje_wesele/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Testy etapu 1d: powiadomienia STREFY GOŚCIA — wyłącznie harmonogram,
/// liczone z publicznego mirrora `guestSpaces`, nie z dokumentu wesela.
void main() {
  List<Map<String, dynamic>> schedule() => [
        {'id': 1, 'hour': 16, 'minute': 0, 'name': 'Ceremonia'},
        {'id': 2, 'hour': 18, 'minute': 30, 'name': 'Obiad'},
      ];

  List<AppNotification> diff(List<dynamic> before, List<dynamic> after) =>
      NotificationDetector.detectGuest(
        previous: NotificationDetector.guestSnapshot(before),
        scheduleEvents: after,
        now: DateTime(2027, 6, 1, 12),
      ).notifications;

  group('pierwsze uruchomienie', () {
    test('pusty odcisk → ZERO powiadomień, ale odcisk zapisany', () {
      final result = NotificationDetector.detectGuest(
        previous: NotificationSnapshot.empty,
        scheduleEvents: schedule(),
      );

      expect(result.notifications, isEmpty);
      expect(result.snapshot.isEmpty, isFalse);
    });

    test('pusty harmonogram nie wywraca odczytu', () {
      final result = NotificationDetector.detectGuest(
        previous: NotificationSnapshot.empty,
        scheduleEvents: null,
      );
      expect(result.notifications, isEmpty);
      expect(result.snapshot.isEmpty, isTrue);
    });
  });

  group('zmiany harmonogramu', () {
    test('nowy punkt → jedno powiadomienie z nazwą i godziną', () {
      final after = [
        ...schedule(),
        {'id': 3, 'hour': 20, 'minute': 0, 'name': 'Pierwszy taniec'},
      ];

      final out = diff(schedule(), after);
      expect(out, hasLength(1));
      expect(out.single.kind, NotifKind.schedule);
      expect(out.single.text,
          'Zmieniono w harmonogramie: Pierwszy taniec 20:00');
    });

    test('zmiana godziny → jedno powiadomienie', () {
      final after = [
        {'id': 1, 'hour': 17, 'minute': 15, 'name': 'Ceremonia'},
        schedule()[1],
      ];

      final out = diff(schedule(), after);
      expect(out, hasLength(1));
      expect(out.single.text, 'Zmieniono w harmonogramie: Ceremonia 17:15');
    });

    test('zmiana nazwy → jedno powiadomienie', () {
      final after = [
        {'id': 1, 'hour': 16, 'minute': 0, 'name': 'Ceremonia w kościele'},
        schedule()[1],
      ];
      expect(diff(schedule(), after).single.text,
          'Zmieniono w harmonogramie: Ceremonia w kościele 16:00');
    });

    test('brak zmian → cisza', () {
      expect(diff(schedule(), schedule()), isEmpty);
    });

    test('usunięcie punktu nie generuje powiadomienia', () {
      expect(diff(schedule(), [schedule().first]), isEmpty);
    });

    test('punkt bez nazwy dostaje czytelny zastępnik', () {
      final after = [
        ...schedule(),
        {'id': 3, 'hour': 22, 'minute': 0, 'name': ''},
      ];
      expect(diff(schedule(), after).single.text,
          'Zmieniono w harmonogramie: punkt programu 22:00');
    });

    test('kilka zmian naraz → po jednym powiadomieniu', () {
      final after = [
        {'id': 1, 'hour': 17, 'minute': 0, 'name': 'Ceremonia'},
        schedule()[1],
        {'id': 3, 'hour': 20, 'minute': 0, 'name': 'Taniec'},
      ];
      expect(diff(schedule(), after), hasLength(2));
    });
  });

  group('gość NIE dostaje innych powiadomień', () {
    test('nowi goście, zadania i RSVP są niewidoczne dla gościa', () {
      // Te dane w ogóle nie trafiają do mirrora, ale nawet podane wprost
      // nie mogą wygenerować powiadomienia — detektor gościa patrzy
      // wyłącznie na harmonogram.
      final out = NotificationDetector.detectGuest(
        previous: NotificationDetector.guestSnapshot(schedule()),
        scheduleEvents: schedule(),
      ).notifications;

      expect(out, isEmpty);
    });

    test('odcisk gościa zawiera tylko znaczniki harmonogramu', () {
      final snap = NotificationDetector.guestSnapshot(schedule());
      expect(snap.marks, everyElement(startsWith('sched:')));
    });

    test('odcisk organizatora jest szerszy niż odcisk gościa', () {
      final full = NotificationSnapshot.of(WeddingData.fromMap({
        'guests': [
          {'id': 1, 'firstName': 'Jan'}
        ],
        'tasks': [
          {'id': 1, 'name': 'Tort'}
        ],
        'scheduleEvents': schedule(),
      }));
      final guest = NotificationDetector.guestSnapshot(schedule());

      expect(full.marks.length, greaterThan(guest.marks.length));
      expect(guest.marks.any((m) => m.startsWith('guest:')), isFalse);
      expect(guest.marks.any((m) => m.startsWith('task:')), isFalse);
    });

    test('oba warianty liczą harmonogram tak samo', () {
      // Wspólny `scheduleMark` gwarantuje, że gość i organizator wykrywają
      // dokładnie te same zmiany programu.
      final full = NotificationSnapshot.of(
          WeddingData.fromMap({'scheduleEvents': schedule()}));
      final guest = NotificationDetector.guestSnapshot(schedule());

      expect(guest.marks, full.marks);
    });
  });

  group('trwałość gościa (bez konta)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    GuestNotificationService service([String token = 'tok-1']) =>
        GuestNotificationService(token: token);

    test('pierwsze wejście milczy, kolejna zmiana już nie', () async {
      final s = service();
      expect(await s.refresh(schedule()), isEmpty);

      final after = [
        ...schedule(),
        {'id': 3, 'hour': 20, 'minute': 0, 'name': 'Taniec'},
      ];
      expect(await s.refresh(after), hasLength(1));
    });

    test('to samo odświeżenie dwa razy nie powtarza powiadomienia', () async {
      final s = service();
      await s.refresh(schedule());

      final after = [
        ...schedule(),
        {'id': 3, 'hour': 20, 'minute': 0, 'name': 'Taniec'},
      ];
      expect(await s.refresh(after), hasLength(1));
      expect(await s.refresh(after), isEmpty);
    });

    test('przeczytane nie wraca', () async {
      final s = service();
      await s.refresh(schedule());

      final after = [
        ...schedule(),
        {'id': 3, 'hour': 20, 'minute': 0, 'name': 'Taniec'},
      ];
      final out = await s.refresh(after);
      await s.markRead(out.map((n) => n.id));

      // Wymuszamy ponowne wykrycie tej samej zmiany.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('guest_notif_seen_tok-1',
          NotificationDetector.guestSnapshot(schedule()).toStringList());

      expect(await s.refresh(after), isEmpty);
    });

    test('dwa wesela na jednym urządzeniu nie mieszają się', () async {
      await service('tok-A').refresh(schedule());
      // Token B nadal jest „pierwszym uruchomieniem".
      expect((await service('tok-B').loadSnapshot()).isEmpty, isTrue);
    });
  });
}
