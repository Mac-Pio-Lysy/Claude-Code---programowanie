import 'package:flutter_test/flutter_test.dart';
import 'package:moje_wesele/models/app_notification.dart';
import 'package:moje_wesele/models/notification_snapshot.dart';
import 'package:moje_wesele/models/wedding_data.dart';
import 'package:moje_wesele/navigation/app_sections.dart';
import 'package:moje_wesele/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Testy etapu 1a powiadomień: odcisk, wykrywanie zmian i stan przeczytania.
void main() {
  /// Wesele z trojgiem gości, jednym zadaniem i jednym punktem programu.
  Map<String, dynamic> base() => {
        'guests': [
          {'id': 1, 'firstName': 'Jan', 'lastName': 'Kowalski'},
          {'id': 2, 'firstName': 'Anna', 'lastName': 'Nowak'},
          {'id': 3, 'firstName': 'Piotr', 'lastName': 'Zieliński'},
        ],
        'tasks': [
          {'id': 1, 'name': 'Rezerwacja sali'},
        ],
        'scheduleEvents': [
          {'id': 1, 'hour': 16, 'minute': 0, 'name': 'Ceremonia'},
        ],
        'rsvpEntries': <dynamic>[],
      };

  WeddingData data(Map<String, dynamic> raw) => WeddingData.fromMap(raw);

  /// Skrót: policz różnicę między dwoma stanami wesela.
  List<AppNotification> diff(
      Map<String, dynamic> before, Map<String, dynamic> after) {
    final prev = NotificationSnapshot.of(data(before));
    return NotificationDetector.detect(
      previous: prev,
      data: data(after),
      now: DateTime(2027, 6, 1, 12),
    ).notifications;
  }

  group('pierwsze uruchomienie', () {
    test('pusty odcisk → ZERO powiadomień, mimo pełnych danych', () {
      // Sedno mechanizmu: wesele z gośćmi nie może zasypać dzwoneczka
      // powiadomieniami o wszystkim, co już istnieje.
      final result = NotificationDetector.detect(
        previous: NotificationSnapshot.empty,
        data: data(base()),
      );

      expect(result.notifications, isEmpty);
      // …ale odcisk musi zostać zapisany, inaczej przy drugim wejściu
      // wygenerowałyby się wszystkie naraz.
      expect(result.snapshot.isEmpty, isFalse);
      expect(result.snapshot.marks, contains('guest:1'));
    });

    test('brak danych → brak powiadomień i pusty odcisk', () {
      final result = NotificationDetector.detect(
        previous: NotificationSnapshot.empty,
        data: null,
      );
      expect(result.notifications, isEmpty);
      expect(result.snapshot.isEmpty, isTrue);
    });
  });

  group('wykrywanie zmian', () {
    test('nowy gość → DOKŁADNIE jedno powiadomienie', () {
      final after = base()
        ..['guests'] = [
          ...base()['guests'] as List,
          {'id': 4, 'firstName': 'Ewa', 'lastName': 'Wiśniewska'},
        ];

      final out = diff(base(), after);
      expect(out, hasLength(1));
      expect(out.single.kind, NotifKind.guestAdded);
      expect(out.single.text, 'Dodano gościa: Ewa Wiśniewska');
      expect(out.single.section, AppSection.guests);
    });

    test('nowe RSVP → jedno powiadomienie z imieniem gościa', () {
      final after = base()
        ..['rsvpEntries'] = [
          {'id': 10, 'guestId': 1, 'status': 'attending'},
        ];

      final out = diff(base(), after);
      expect(out, hasLength(1));
      expect(out.single.kind, NotifKind.rsvp);
      expect(out.single.text, 'Jan Kowalski potwierdził(a) obecność');
      expect(out.single.section, AppSection.rsvp);
    });

    test('zmiana decyzji RSVP → jedno nowe powiadomienie', () {
      final before = base()
        ..['rsvpEntries'] = [
          {'id': 10, 'guestId': 1, 'status': 'attending'},
        ];
      final after = base()
        ..['rsvpEntries'] = [
          {'id': 10, 'guestId': 1, 'status': 'not_attending'},
        ];

      final out = diff(before, after);
      expect(out, hasLength(1));
      expect(out.single.text, 'Jan Kowalski nie przyjdzie');
    });

    test('RSVP bez dopasowanego gościa używa wpisanej nazwy', () {
      final after = base()
        ..['rsvpEntries'] = [
          {'id': 11, 'rawName': 'Ciocia Basia', 'status': 'attending'},
        ];
      expect(diff(base(), after).single.text,
          'Ciocia Basia potwierdził(a) obecność');
    });

    test('nowe zadanie → jedno powiadomienie z nazwą', () {
      final after = base()
        ..['tasks'] = [
          ...base()['tasks'] as List,
          {'id': 2, 'name': 'Zamów tort'},
        ];

      final out = diff(base(), after);
      expect(out, hasLength(1));
      expect(out.single.kind, NotifKind.taskAdded);
      expect(out.single.text, 'Dodano zadanie: Zamów tort');
    });

    test('nowy punkt harmonogramu → jedno powiadomienie z godziną', () {
      final after = base()
        ..['scheduleEvents'] = [
          ...base()['scheduleEvents'] as List,
          {'id': 2, 'hour': 20, 'minute': 0, 'name': 'Pierwszy taniec'},
        ];

      final out = diff(base(), after);
      expect(out, hasLength(1));
      expect(out.single.kind, NotifKind.schedule);
      expect(out.single.text, 'Harmonogram: Pierwszy taniec o 20:00');
    });

    test('zmiana godziny punktu → jedno powiadomienie', () {
      final after = base()
        ..['scheduleEvents'] = [
          {'id': 1, 'hour': 17, 'minute': 30, 'name': 'Ceremonia'},
        ];

      final out = diff(base(), after);
      expect(out, hasLength(1));
      expect(out.single.text, 'Harmonogram: Ceremonia o 17:30');
    });

    test('brak zmian → zero powiadomień', () {
      expect(diff(base(), base()), isEmpty);
    });

    test('usunięcie elementu nie generuje powiadomienia', () {
      final after = base()
        ..['guests'] = [
          {'id': 1, 'firstName': 'Jan', 'lastName': 'Kowalski'},
        ];
      expect(diff(base(), after), isEmpty);
    });

    test('kilka zmian naraz → po jednym powiadomieniu na zmianę', () {
      final after = base()
        ..['guests'] = [
          ...base()['guests'] as List,
          {'id': 4, 'firstName': 'Ewa', 'lastName': 'Wiśniewska'},
        ]
        ..['tasks'] = [
          ...base()['tasks'] as List,
          {'id': 2, 'name': 'Zamów tort'},
        ]
        ..['rsvpEntries'] = [
          {'id': 10, 'guestId': 2, 'status': 'attending'},
        ];

      final out = diff(base(), after);
      expect(out, hasLength(3));
      expect(out.map((n) => n.kind).toSet(), {
        NotifKind.guestAdded,
        NotifKind.taskAdded,
        NotifKind.rsvp,
      });
    });

    test('gość bez imienia dostaje czytelną nazwę zastępczą', () {
      final after = base()
        ..['guests'] = [
          ...base()['guests'] as List,
          {'id': 4, 'firstName': '', 'lastName': ''},
        ];
      expect(diff(base(), after).single.text, 'Dodano gościa: Gość bez imienia');
    });

    test('identyfikatory są deterministyczne', () {
      final after = base()
        ..['guests'] = [
          ...base()['guests'] as List,
          {'id': 4, 'firstName': 'Ewa', 'lastName': 'W'},
        ];
      // Ta sama zmiana policzona dwa razy daje ten sam identyfikator —
      // na tym opiera się stan przeczytania.
      expect(diff(base(), after).single.id, diff(base(), after).single.id);
      expect(diff(base(), after).single.id, 'guest:4');
    });
  });

  group('grupowanie', () {
    test('grupy po rodzaju z poprawną odmianą liczebnika', () {
      final at = DateTime(2027);
      final items = [
        for (var i = 0; i < 3; i++)
          AppNotification(
              id: 'rsvp:$i', kind: NotifKind.rsvp, text: 't', at: at),
        AppNotification(
            id: 'task:1', kind: NotifKind.taskAdded, text: 't', at: at),
      ];

      final groups = NotifGroup.from(items);
      expect(groups, hasLength(2));
      expect(groups.first.kind, NotifKind.rsvp);
      expect(groups.first.label, 'Potwierdzenia');
      expect(groups.first.summary, '3 nowe');
      expect(groups.last.summary, '1 nowe');
    });

    test('odmiana dla 5 i 12', () {
      final at = DateTime(2027);
      List<AppNotification> many(int n) => [
            for (var i = 0; i < n; i++)
              AppNotification(
                  id: 'rsvp:$i', kind: NotifKind.rsvp, text: 't', at: at),
          ];
      expect(NotifGroup.from(many(5)).single.summary, '5 nowych');
      expect(NotifGroup.from(many(12)).single.summary, '12 nowych');
      expect(NotifGroup.from(many(22)).single.summary, '22 nowe');
    });

    test('puste wejście → brak grup', () {
      expect(NotifGroup.from(const []), isEmpty);
    });
  });

  group('skrzynka w pamięci', () {
    AppNotification n(String id) => AppNotification(
        id: id, kind: NotifKind.rsvp, text: id, at: DateTime(2027));

    test('nie dubluje tego samego powiadomienia', () {
      final inbox = NotificationInbox()
        ..add([n('a'), n('b')])
        ..add([n('b'), n('c')]);

      expect(inbox.all, hasLength(3));
      expect(inbox.unreadCount, 3);
    });

    test('przeczytane znika z licznika i nie wraca po odświeżeniu', () {
      final inbox = NotificationInbox()..add([n('a'), n('b')]);
      inbox.markRead('a');
      expect(inbox.unreadCount, 1);

      // Kolejne odświeżenie danych podaje to samo powiadomienie ponownie.
      inbox.add([n('a')]);
      expect(inbox.unreadCount, 1);
      expect(inbox.isRead('a'), isTrue);
    });

    test('oznaczenie wszystkich zeruje licznik', () {
      final inbox = NotificationInbox()..add([n('a'), n('b'), n('c')]);
      inbox.markAllRead();
      expect(inbox.unreadCount, 0);
      expect(inbox.unreadGroups, isEmpty);
    });

    test('lista nie rośnie w nieskończoność', () {
      final inbox = NotificationInbox(maxItems: 5);
      inbox.add([for (var i = 0; i < 20; i++) n('id$i')]);
      expect(inbox.all, hasLength(5));
    });
  });

  group('trwałość (SharedPreferences)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    NotificationService service() =>
        NotificationService(uid: 'u1', weddingId: 'w1');

    test('pierwsze odświeżenie milczy, drugie już wykrywa zmianę', () async {
      final s = service();

      // Pierwsze wejście — zapisuje odcisk po cichu.
      expect(await s.refresh(data(base())), isEmpty);

      final after = base()
        ..['guests'] = [
          ...base()['guests'] as List,
          {'id': 9, 'firstName': 'Ewa', 'lastName': 'W'},
        ];
      final out = await s.refresh(data(after));
      expect(out, hasLength(1));
      expect(out.single.id, 'guest:9');
    });

    test('to samo odświeżenie dwa razy nie powtarza powiadomienia', () async {
      final s = service();
      await s.refresh(data(base()));

      final after = base()
        ..['tasks'] = [
          ...base()['tasks'] as List,
          {'id': 5, 'name': 'Tort'},
        ];
      expect(await s.refresh(data(after)), hasLength(1));
      // Odcisk został zaktualizowany, więc drugi przebieg jest już cichy.
      expect(await s.refresh(data(after)), isEmpty);
    });

    test('przeczytane nie wraca nawet przy ponownym wykryciu', () async {
      final s = service();
      await s.refresh(data(base()));

      final after = base()
        ..['guests'] = [
          ...base()['guests'] as List,
          {'id': 9, 'firstName': 'Ewa', 'lastName': 'W'},
        ];
      final out = await s.refresh(data(after));
      await s.markRead(out.map((n) => n.id));

      // Symulacja ponownego wykrycia (np. po wyczyszczeniu odcisku).
      await s.saveSnapshot(NotificationSnapshot.of(data(base())));
      expect(await s.refresh(data(after)), isEmpty);
    });

    test('stan przeczytania jest przycinany', () async {
      final s = service();
      await s.markRead([
        for (var i = 0; i < NotificationService.maxReadIds + 50; i++) 'id$i'
      ]);
      expect((await s.loadReadIds()).length, NotificationService.maxReadIds);
    });

    test('reset czyści odcisk i przeczytane', () async {
      final s = service();
      await s.refresh(data(base()));
      await s.markRead(['x']);

      await s.reset();
      expect((await s.loadSnapshot()).isEmpty, isTrue);
      expect(await s.loadReadIds(), isEmpty);
    });

    test('osobne wesela mają osobne liczniki', () async {
      final w1 = NotificationService(uid: 'u1', weddingId: 'w1');
      final w2 = NotificationService(uid: 'u1', weddingId: 'w2');

      await w1.refresh(data(base()));
      // Drugie wesele nadal jest „pierwszym uruchomieniem".
      expect((await w2.loadSnapshot()).isEmpty, isTrue);
    });
  });
}
