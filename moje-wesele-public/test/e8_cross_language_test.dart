import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moje_wesele/l10n/app_localizations.dart';
import 'package:moje_wesele/l10n/app_text.dart';
import 'package:moje_wesele/models/couple.dart';
import 'package:moje_wesele/models/song.dart';
import 'package:moje_wesele/models/task.dart';
import 'package:moje_wesele/models/vendor.dart';

/// Etap 8: przypadki, w których tekst ZAPISANY w bazie spotyka się
/// z etykietą z tłumaczeń.
///
/// To najgroźniejsza klasa błędów tej migracji: kod porównuje albo dopasowuje
/// napis, a napis zmienia się razem z językiem.
void main() {
  Future<void> useLocale(WidgetTester tester, Locale locale) async {
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

  group('ikona kluczowego momentu', () {
    testWidgets('trafia niezależnie od języka, w jakim zapisano moment',
        (tester) async {
      // Wesele polskie ma w bazie „Tort", angielskie „Cake" — obie nazwy
      // muszą dostać 🎂, bez względu na język interfejsu.
      for (final locale in AppLocalizations.supportedLocales) {
        await useLocale(tester, locale);
        expect(specialMomentIcon('Tort'), '🎂', reason: locale.languageCode);
        expect(specialMomentIcon('Cake'), '🎂', reason: locale.languageCode);
        expect(specialMomentIcon('Pierwszy taniec'), '💃');
        expect(specialMomentIcon('First dance'), '💃');
      }
    });

    testWidgets('własna etykieta pary dostaje gwiazdkę', (tester) async {
      await useLocale(tester, const Locale('pl'));
      expect(specialMomentIcon('Poprawiny'), '⭐');
      expect(specialMomentIcon(''), '⭐');
    });

    testWidgets('wejście Pary Młodej podąża za typem uroczystości',
        (tester) async {
      await useLocale(tester, const Locale('pl'));
      CoupleLabels.current = const CoupleLabels(type: CoupleType.men);
      expect(specialMomentIcon('Wejście Pary Młodej'), '🤵');
      expect(specialMomentIcon("The couple's entrance"), '🤵');
      CoupleLabels.current = CoupleLabels.fallback;
    });
  });

  group('wartości zastępcze imion', () {
    test('rozpoznawane w obu językach, bo w bazie leży jedna z nich', () {
      expect(CoupleLabels.isPlaceholderName('Osoba 1'), isTrue);
      expect(CoupleLabels.isPlaceholderName('Person 2'), isTrue);
      expect(CoupleLabels.isPlaceholderName('  Osoba 2  '), isTrue);
      expect(CoupleLabels.isPlaceholderName('Ania'), isFalse);
    });

    test('do ZAPISU zawsze polska wartość — jedno źródło prawdy', () {
      // Gdyby zapis zależał od języka, wesele założone po angielsku miałoby
      // inne wartości zastępcze i detektory przestałyby je odróżniać.
      expect(CoupleLabels.placeholderNames.first, 'Osoba 1');
      expect(CoupleLabels.placeholderNames[1], 'Osoba 2');
    });
  });

  group('identyfikatory w bazie nie zależą od języka', () {
    testWidgets('statusy zadań i dostawców', (tester) async {
      await useLocale(tester, const Locale('pl'));
      final plTask = [for (final s in TaskStatus.columns) s.id];
      final plVendor = [for (final s in VendorStatus.all) s.value];
      final plTaskLabels = [for (final s in TaskStatus.columns) s.label];

      await useLocale(tester, const Locale('en'));
      expect([for (final s in TaskStatus.columns) s.id], plTask);
      expect([for (final s in VendorStatus.all) s.value], plVendor);
      // …a etykiety JEDNAK się zmieniają.
      expect([for (final s in TaskStatus.columns) s.label],
          isNot(plTaskLabels));
    });

    testWidgets('kategoria Pary Młodej: wartość stała, etykieta tłumaczona',
        (tester) async {
      await useLocale(tester, const Locale('pl'));
      expect(CoupleLabels.coupleCategoryValue, 'Państwo Młodzi');
      expect(CoupleLabels.fallback.coupleCategoryLabel, 'Państwo Młodzi');

      await useLocale(tester, const Locale('en'));
      expect(CoupleLabels.coupleCategoryValue, 'Państwo Młodzi');
      expect(CoupleLabels.fallback.coupleCategoryLabel, 'The Couple');
    });
  });
}
