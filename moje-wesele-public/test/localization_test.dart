import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moje_wesele/l10n/app_localizations.dart';
import 'package:moje_wesele/l10n/locale_controller.dart';
import 'package:moje_wesele/models/currency.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Testy etapu 1 lokalizacji: infrastruktura, wybór języka i waluta.
void main() {
  group('pliki tłumaczeń', () {
    test('obsługiwane są polski i angielski', () {
      final codes =
          AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet();
      expect(codes, containsAll(['pl', 'en']));
    });

    testWidgets('ten sam klucz daje inny tekst w pl i en', (tester) async {
      Future<AppLocalizations> load(Locale locale) async {
        late AppLocalizations t;
        await tester.pumpWidget(MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(builder: (context) {
            t = AppLocalizations.of(context);
            return const SizedBox();
          }),
        ));
        await tester.pumpAndSettle();
        return t;
      }

      final pl = await load(const Locale('pl'));
      expect(pl.common_add, 'Dodaj');
      expect(pl.settings_title, 'Ustawienia');

      final en = await load(const Locale('en'));
      expect(en.common_add, 'Add');
      expect(en.settings_title, 'Settings');
    });

    testWidgets('placeholder podstawia wartość', (tester) async {
      late AppLocalizations t;
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('pl'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) {
          t = AppLocalizations.of(context);
          return const SizedBox();
        }),
      ));
      await tester.pumpAndSettle();

      expect(t.common_saveErrorToast('brak sieci'), 'Błąd zapisu: brak sieci');
    });

    testWidgets('ICU plural odmienia po polsku', (tester) async {
      late AppLocalizations t;
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('pl'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) {
          t = AppLocalizations.of(context);
          return const SizedBox();
        }),
      ));
      await tester.pumpAndSettle();

      // To zastępuje ręczne funkcje odmiany rozsiane po kodzie.
      expect(t.common_guestCount(0), 'Brak gości');
      expect(t.common_guestCount(1), '1 gość');
      expect(t.common_guestCount(3), '3 gości');
      expect(t.common_guestCount(12), '12 gości');
    });
  });

  group('wybór języka', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      LocaleController.locale.value = null;
    });

    test('domyślnie „jak w systemie"', () {
      expect(LocaleController.locale.value, isNull);
    });

    test('nieznany język urządzenia → polski, nie angielski', () {
      // Kluczowa decyzja: produkt jest polski, więc fallback to polski.
      final resolved = LocaleController.resolve(
          const Locale('de'), AppLocalizations.supportedLocales);
      expect(resolved.languageCode, 'pl');
    });

    test('znany język urządzenia jest respektowany', () {
      final resolved = LocaleController.resolve(
          const Locale('en'), AppLocalizations.supportedLocales);
      expect(resolved.languageCode, 'en');
    });

    test('wybór użytkownika ma pierwszeństwo przed systemem', () {
      LocaleController.locale.value = const Locale('en');
      final resolved = LocaleController.resolve(
          const Locale('pl'), AppLocalizations.supportedLocales);
      expect(resolved.languageCode, 'en');
    });

    test('wybór zapisuje się i wczytuje per użytkownik', () async {
      await LocaleController.set('u1', const Locale('en'));
      LocaleController.locale.value = null;

      await LocaleController.load('u1');
      expect(LocaleController.locale.value?.languageCode, 'en');

      // Inny użytkownik ma własny wybór.
      await LocaleController.load('u2');
      expect(LocaleController.locale.value, isNull);
    });

    test('powrót do „jak w systemie" czyści zapis', () async {
      await LocaleController.set('u1', const Locale('en'));
      await LocaleController.set('u1', null);

      await LocaleController.load('u1');
      expect(LocaleController.locale.value, isNull);
    });
  });

  group('przebudowa po zmianie języka', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      LocaleController.locale.value = null;
    });

    testWidgets('zmiana kontrolera przebudowuje interfejs', (tester) async {
      // Start od jawnego polskiego: środowisko testowe zgłasza locale en_US,
      // więc bez tego `resolve` słusznie wybrałby angielski.
      LocaleController.locale.value = const Locale('pl');

      // Odwzorowanie korzenia z main.dart. Pilnuje pułapki ze zgłoszenia #20:
      // gdyby dziecko było `const`, tekst nie zmieniłby się mimo zapisu.
      await tester.pumpWidget(ListenableBuilder(
        listenable: LocaleController.locale,
        builder: (context, _) => MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: LocaleController.locale.value,
          localeResolutionCallback: LocaleController.resolve,
          home: Builder(
            builder: (context) =>
                Text(AppLocalizations.of(context).settings_title),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Ustawienia'), findsOneWidget);

      LocaleController.locale.value = const Locale('en');
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Ustawienia'), findsNothing);
    });
  });

  group('waluta', () {
    test('brak pola → PLN (istniejące wesela bez zmian)', () {
      expect(Currency.ofRaw(null), Currency.pln);
      expect(Currency.ofRaw(const {}), Currency.pln);
      expect(Currency.ofRaw({'appConfig': const {}}), Currency.pln);
    });

    test('zapisany kod czyta się wprost', () {
      expect(
        Currency.ofRaw({
          'appConfig': {'currency': 'EUR'}
        }),
        Currency.eur,
      );
    });

    test('nieznany kod → PLN, bez wyjątku', () {
      expect(Currency.fromRaw('BTC'), Currency.pln);
      expect(Currency.fromRaw(123), Currency.pln);
    });

    test('każda waluta ma kod, symbol i nazwę', () {
      for (final c in Currency.values) {
        expect(c.code.length, 3, reason: c.name);
        expect(c.symbol.trim(), isNotEmpty, reason: c.name);
        expect(c.label.trim(), isNotEmpty, reason: c.name);
      }
    });
  });
}
