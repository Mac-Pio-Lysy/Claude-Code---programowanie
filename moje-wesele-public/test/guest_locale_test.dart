import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moje_wesele/l10n/app_localizations.dart';
import 'package:moje_wesele/l10n/language_picker.dart';
import 'package:moje_wesele/l10n/locale_controller.dart';
import 'package:moje_wesele/models/guest_visibility.dart';
import 'package:moje_wesele/l10n/app_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Etap 6: język w STREFIE GOŚCIA.
///
/// Gość wchodzi z linku/QR — nie ma konta ani ekranu Ustawień, więc jego wybór
/// zapisuje się pod wspólnym kluczem `locale_guest`, a nie pod `uid`.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LocaleController.locale.value = null;
  });

  group('zapis wyboru gościa', () {
    test('wybór trafia pod klucz bez uid', () async {
      await LocaleController.setGuest(const Locale('en'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('locale_guest'), 'en');
    });

    test('wybór gościa nie miesza się z wyborem zalogowanego', () async {
      await LocaleController.set('u1', const Locale('pl'));
      await LocaleController.setGuest(const Locale('en'));

      await LocaleController.load('u1');
      expect(LocaleController.locale.value?.languageCode, 'pl');

      await LocaleController.loadGuest();
      expect(LocaleController.locale.value?.languageCode, 'en');
    });

    test('bez zapisu obowiązuje język przeglądarki, fallback polski', () async {
      await LocaleController.loadGuest();
      // null = „jak w przeglądarce"; dopiero `resolve` decyduje o wyniku.
      expect(LocaleController.locale.value, isNull);

      expect(
        LocaleController.resolve(
                const Locale('en'), AppLocalizations.supportedLocales)
            .languageCode,
        'en',
      );
      // Język, którego nie mamy → polski, nie angielski.
      expect(
        LocaleController.resolve(
                const Locale('fr'), AppLocalizations.supportedLocales)
            .languageCode,
        'pl',
      );
    });

    test('powrót do „jak w przeglądarce" czyści zapis', () async {
      await LocaleController.setGuest(const Locale('en'));
      await LocaleController.setGuest(null);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('locale_guest'), isNull);
    });
  });

  group('globus w nagłówku', () {
    testWidgets('menu pokazuje oba języki i pozycję „jak w systemie"',
        (tester) async {
      LocaleController.locale.value = const Locale('pl');
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('pl'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: GuestLanguageButton()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();

      expect(find.text('Jak w systemie'), findsOneWidget);
      expect(find.text('Polski'), findsOneWidget);
      expect(find.text('Angielski'), findsOneWidget);
    });

    testWidgets('wybór z menu zapisuje język gościa', (tester) async {
      LocaleController.locale.value = const Locale('pl');
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('pl'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: GuestLanguageButton()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Angielski'));
      await tester.pumpAndSettle();

      expect(LocaleController.locale.value?.languageCode, 'en');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('locale_guest'), 'en');
    });
  });

  group('sekcje gościa', () {
    testWidgets('klucz w bazie zostaje, tłumaczy się tylko etykieta',
        (tester) async {
      Future<void> withLocale(Locale locale) async {
        await tester.pumpWidget(MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(builder: (context) {
            AppText.apply(AppLocalizations.of(context));
            return const SizedBox();
          }),
        ));
        await tester.pumpAndSettle();
      }

      final gallery = kGuestSections.firstWhere((s) => s.key == 'gallery');

      await withLocale(const Locale('pl'));
      expect(gallery.label, 'Galeria');

      await withLocale(const Locale('en'));
      expect(gallery.label, 'Gallery');

      // Najważniejsze: klucz zapisywany w `guestVisibility.sections`
      // nie zmienia się razem z językiem.
      expect(gallery.key, 'gallery');
      for (final s in kGuestSections) {
        expect(RegExp(r'^[a-zA-Z]+$').hasMatch(s.key), isTrue, reason: s.key);
      }
    });
  });
}
