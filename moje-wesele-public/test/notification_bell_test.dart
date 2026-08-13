import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moje_wesele/models/app_notification.dart';
import 'package:moje_wesele/navigation/app_sections.dart';
import 'package:moje_wesele/services/notification_service.dart';
import 'package:moje_wesele/widgets/notification_bell.dart';

/// Testy UI powiadomień (etap 1b): licznik na dzwoneczku, grupy w centrum,
/// oznaczanie i przejście do sekcji.
void main() {
  AppNotification n(String id, NotifKind kind, String text) =>
      AppNotification(id: id, kind: kind, text: text, at: DateTime.now());

  NotificationInbox inboxWith(List<AppNotification> items) =>
      NotificationInbox()..add(items);

  Widget bellApp(NotificationInbox inbox, {VoidCallback? onOpen}) => MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              NotificationBell(inbox: inbox, onOpen: onOpen ?? () {}),
            ],
          ),
        ),
      );

  group('dzwoneczek', () {
    testWidgets('bez powiadomień nie pokazuje licznika', (tester) async {
      await tester.pumpWidget(bellApp(NotificationInbox()));

      expect(find.byIcon(Icons.notifications_none), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('pokazuje liczbę nieprzeczytanych', (tester) async {
      await tester.pumpWidget(bellApp(inboxWith([
        n('rsvp:1', NotifKind.rsvp, 'Jan potwierdził'),
        n('guest:2', NotifKind.guestAdded, 'Dodano gościa'),
        n('task:3', NotifKind.taskAdded, 'Dodano zadanie'),
      ])));

      expect(find.text('3'), findsOneWidget);
      expect(find.byIcon(Icons.notifications), findsOneWidget);
    });

    testWidgets('licznik pomija przeczytane', (tester) async {
      final inbox = inboxWith([
        n('rsvp:1', NotifKind.rsvp, 'a'),
        n('rsvp:2', NotifKind.rsvp, 'b'),
      ])
        ..markRead('rsvp:1');

      await tester.pumpWidget(bellApp(inbox));
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('duże liczby skracamy do 99+', (tester) async {
      await tester.pumpWidget(bellApp(inboxWith([
        for (var i = 0; i < 120; i++) n('rsvp:$i', NotifKind.rsvp, 'x'),
      ])));

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('kliknięcie wywołuje otwarcie centrum', (tester) async {
      var opened = false;
      await tester.pumpWidget(
        bellApp(NotificationInbox(), onOpen: () => opened = true),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(opened, isTrue);
    });
  });

  group('centrum powiadomień', () {
    /// Otwiera centrum i zwraca wynik przejścia.
    Future<NotifJump?> openCenter(
        WidgetTester tester, NotificationInbox inbox) async {
      NotifJump? result;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await NotificationCenter.open(context, inbox);
              },
              child: const Text('otwórz'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('otwórz'));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('pusta skrzynka pokazuje stan pusty', (tester) async {
      await openCenter(tester, NotificationInbox());

      expect(find.text('Brak nowych powiadomień'), findsOneWidget);
    });

    testWidgets('grupuje po sekcjach z licznikami', (tester) async {
      await openCenter(
        tester,
        inboxWith([
          n('rsvp:1', NotifKind.rsvp, 'Jan potwierdził obecność'),
          n('rsvp:2', NotifKind.rsvp, 'Anna potwierdziła obecność'),
          n('task:1', NotifKind.taskAdded, 'Dodano zadanie: tort'),
        ]),
      );

      expect(find.text('Potwierdzenia: 2 nowe'), findsOneWidget);
      expect(find.text('Zadania: 1 nowe'), findsOneWidget);
      // Wpisy są zwinięte, dopóki grupa nie zostanie rozwinięta.
      expect(find.text('Jan potwierdził obecność'), findsNothing);
    });

    testWidgets('rozwinięcie grupy pokazuje treść wpisów', (tester) async {
      await openCenter(
        tester,
        inboxWith([n('rsvp:1', NotifKind.rsvp, 'Jan potwierdził obecność')]),
      );

      await tester.tap(find.text('Potwierdzenia: 1 nowe'));
      await tester.pumpAndSettle();

      expect(find.text('Jan potwierdził obecność'), findsOneWidget);
      expect(find.text('przed chwilą'), findsOneWidget);
    });

    testWidgets('„Oznacz wszystkie" zeruje listę', (tester) async {
      final inbox = inboxWith([
        n('rsvp:1', NotifKind.rsvp, 'a'),
        n('task:1', NotifKind.taskAdded, 'b'),
      ]);
      await openCenter(tester, inbox);

      await tester.tap(find.text('Oznacz wszystkie'));
      await tester.pumpAndSettle();

      expect(inbox.unreadCount, 0);
      expect(find.text('Brak nowych powiadomień'), findsOneWidget);
    });

    testWidgets('pojedyncze oznaczenie usuwa wpis z listy', (tester) async {
      final inbox = inboxWith([
        n('rsvp:1', NotifKind.rsvp, 'Jan potwierdził'),
        n('rsvp:2', NotifKind.rsvp, 'Anna potwierdziła'),
      ]);
      await openCenter(tester, inbox);

      await tester.tap(find.text('Potwierdzenia: 2 nowe'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.check).first);
      await tester.pumpAndSettle();

      expect(inbox.unreadCount, 1);
      expect(find.text('Potwierdzenia: 1 nowe'), findsOneWidget);
    });

    testWidgets('kliknięcie wpisu zwraca przejście i oznacza jako przeczytane',
        (tester) async {
      final inbox =
          inboxWith([n('guest:5', NotifKind.guestAdded, 'Dodano gościa: Ewa')]);
      NotifJump? jump;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                jump = await NotificationCenter.open(context, inbox);
              },
              child: const Text('otwórz'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('otwórz'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Goście: 1 nowe'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dodano gościa: Ewa'));
      await tester.pumpAndSettle();

      expect(jump, isNotNull);
      expect(jump!.section, AppSection.guests);
      expect(jump!.subTab, 0); // podzakładka „Lista"
      expect(inbox.isRead('guest:5'), isTrue);
    });

    testWidgets('strzałka przy grupie prowadzi do sekcji', (tester) async {
      final inbox = inboxWith([
        n('sched:1', NotifKind.schedule, 'Harmonogram: Pierwszy taniec o 20:00'),
      ]);
      NotifJump? jump;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                jump = await NotificationCenter.open(context, inbox);
              },
              child: const Text('otwórz'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('otwórz'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();

      expect(jump!.section, AppSection.schedule);
      // Wejście przez grupę oznacza wszystkie jej wpisy jako przeczytane.
      expect(inbox.unreadCount, 0);
    });
  });
}
