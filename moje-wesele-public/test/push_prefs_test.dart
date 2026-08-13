import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moje_wesele/models/push_topic.dart';
import 'package:moje_wesele/screens/settings/notification_settings_screen.dart';
import 'package:moje_wesele/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Testy etapu 1c: preferencje przyszłych powiadomień push.
void main() {
  group('model preferencji', () {
    test('brak zapisu → wszystkie tematy włączone', () {
      final prefs = PushPrefs.fromKeys(null);
      expect(prefs.onCount, PushTopic.values.length);
      for (final t in PushTopic.values) {
        expect(prefs.isOn(t), isTrue, reason: t.name);
      }
    });

    test('pusty zapis to świadome wyłączenie wszystkiego', () {
      // Różnica względem braku zapisu: użytkownik wyłączył każdy przełącznik.
      final prefs = PushPrefs.fromKeys(const []);
      expect(prefs.allDisabled, isTrue);
      expect(prefs.onCount, 0);
    });

    test('wyłączenie i włączenie pojedynczego tematu', () {
      final off = PushPrefs.allOn.withTopic(PushTopic.rsvp, false);
      expect(off.isOn(PushTopic.rsvp), isFalse);
      expect(off.isOn(PushTopic.tasks), isTrue);

      final on = off.withTopic(PushTopic.rsvp, true);
      expect(on.isOn(PushTopic.rsvp), isTrue);
    });

    test('zapis i odczyt kluczy jest stabilny', () {
      final prefs = PushPrefs({PushTopic.rsvp, PushTopic.deadlines});
      final restored = PushPrefs.fromKeys(prefs.toKeys());

      expect(restored.enabled, prefs.enabled);
    });

    test('nieznany klucz jest pomijany, reszta zostaje', () {
      // Zabezpieczenie na wypadek usunięcia tematu w przyszłej wersji.
      final prefs = PushPrefs.fromKeys(['rsvp', 'cosCzegoNieMa']);
      expect(prefs.enabled, {PushTopic.rsvp});
    });

    test('każdy temat ma etykietę i opis', () {
      for (final t in PushTopic.values) {
        expect(t.label.trim(), isNotEmpty, reason: t.name);
        expect(t.description.trim(), isNotEmpty, reason: t.name);
      }
    });
  });

  group('trwałość', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('pierwszy odczyt zwraca komplet włączonych', () async {
      final s = PushPrefsService(uid: 'u1');
      expect((await s.load()).onCount, PushTopic.values.length);
    });

    test('wyłączenie tematu przeżywa ponowny odczyt', () async {
      final s = PushPrefsService(uid: 'u1');
      await s.toggle(PushTopic.tasks, false);

      final reloaded = await PushPrefsService(uid: 'u1').load();
      expect(reloaded.isOn(PushTopic.tasks), isFalse);
      expect(reloaded.isOn(PushTopic.rsvp), isTrue);
    });

    test('wyłączenie wszystkiego zapisuje się jako pusty zestaw', () async {
      final s = PushPrefsService(uid: 'u1');
      for (final t in PushTopic.values) {
        await s.toggle(t, false);
      }
      expect((await s.load()).allDisabled, isTrue);
    });

    test('preferencje są osobne dla różnych użytkowników', () async {
      await PushPrefsService(uid: 'u1').toggle(PushTopic.rsvp, false);

      final other = await PushPrefsService(uid: 'u2').load();
      expect(other.isOn(PushTopic.rsvp), isTrue);
    });
  });

  group('ekran ustawień', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    /// Wysoki ekran, żeby ListView zbudował wszystkie przełączniki naraz —
    /// inaczej lazy rendering pomija te poniżej krawędzi.
    Future<void> openScreen(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(
        home: NotificationSettingsScreen(uid: 'u1'),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('pokazuje baner „wkrótce" i informację o dzwoneczku',
        (tester) async {
      await openScreen(tester);

      expect(find.text('Powiadomienia na telefon — wkrótce'), findsOneWidget);
      expect(find.text('Dzwoneczek w aplikacji działa zawsze'), findsOneWidget);
    });

    testWidgets('wyświetla przełącznik dla każdego tematu', (tester) async {
      await openScreen(tester);

      expect(find.byType(SwitchListTile), findsNWidgets(PushTopic.values.length));
      for (final t in PushTopic.values) {
        expect(find.text(t.label), findsOneWidget, reason: t.name);
      }
    });

    testWidgets('przełączenie zapisuje wybór', (tester) async {
      await openScreen(tester);

      // Pierwszy przełącznik na liście to RSVP.
      await tester.tap(find.byType(SwitchListTile).first);
      await tester.pumpAndSettle();

      final saved = await PushPrefsService(uid: 'u1').load();
      expect(saved.isOn(PushTopic.rsvp), isFalse);
    });

    testWidgets('po wyłączeniu wszystkiego pojawia się wyjaśnienie',
        (tester) async {
      await openScreen(tester);

      for (var i = 0; i < PushTopic.values.length; i++) {
        await tester.tap(find.byType(SwitchListTile).at(i));
        await tester.pumpAndSettle();
      }

      expect(find.textContaining('Dzwoneczek w aplikacji nadal będzie'),
          findsOneWidget);
    });

    testWidgets('zapisany wybór jest widoczny po ponownym wejściu',
        (tester) async {
      await PushPrefsService(uid: 'u1').toggle(PushTopic.rsvp, false);
      await openScreen(tester);

      final first = tester.widget<SwitchListTile>(
          find.byType(SwitchListTile).first);
      expect(first.value, isFalse);
    });
  });
}
