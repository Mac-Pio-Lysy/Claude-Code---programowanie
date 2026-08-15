import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moje_wesele/help/help_content.dart';
import 'package:moje_wesele/l10n/app_localizations.dart';
import 'package:moje_wesele/l10n/app_text.dart';
import 'package:moje_wesele/models/setup_task.dart';
import 'package:moje_wesele/navigation/app_sections.dart';
import 'package:moje_wesele/onboarding/onboarding_steps.dart';

/// Etap 7: pomoc i przewodnik po przeniesieniu do tłumaczeń.
///
/// Najważniejsze, czego pilnują te testy: podział na WARIANTY RÓL przetrwał
/// migrację i działa tak samo w obu językach.
void main() {
  /// Ustawia język dla [AppText] (pomoc i przewodnik są poza drzewem widgetów).
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

  group('pomoc — warianty ról', () {
    testWidgets('gość ma własny spis, bez rozdziałów panelu', (tester) async {
      await useLocale(tester, const Locale('pl'));

      final guest = buildHelp(OnbVariant.guest);
      final owner = buildHelp(OnbVariant.owner);

      expect(guest, isNotEmpty);
      expect(owner.length, greaterThan(guest.length));
      // Gość nie może zobaczyć rozdziału o rolach i dostępie.
      expect(guest.map((c) => c.title), isNot(contains('Role i dostęp')));
      expect(owner.map((c) => c.title), contains('Role i dostęp'));
    });

    testWidgets('planer dostaje panel + rozdział o pracy z klientami',
        (tester) async {
      await useLocale(tester, const Locale('pl'));

      final owner = buildHelp(OnbVariant.owner);
      final planner = buildHelp(OnbVariant.planner);

      expect(planner.length, owner.length + 1);
      expect(planner.last.title, 'Praca z klientami');
      expect(owner.map((c) => c.title), isNot(contains('Praca z klientami')));
    });

    testWidgets('ta sama struktura po angielsku, inne teksty', (tester) async {
      await useLocale(tester, const Locale('pl'));
      final pl = buildHelp(OnbVariant.owner);
      final plTitles = [for (final c in pl) c.title];
      final plCounts = [for (final c in pl) c.topics.length];

      await useLocale(tester, const Locale('en'));
      final en = buildHelp(OnbVariant.owner);

      expect([for (final c in en) c.topics.length], plCounts);
      expect([for (final c in en) c.title], isNot(plTitles));
      expect(en.first.title, 'Getting started');
      expect(plTitles.first, 'Start');
    });

    testWidgets('żadne hasło nie jest puste w obu językach', (tester) async {
      for (final locale in AppLocalizations.supportedLocales) {
        await useLocale(tester, locale);
        for (final variant in OnbVariant.values) {
          for (final c in buildHelp(variant)) {
            expect(c.title.trim(), isNotEmpty, reason: locale.languageCode);
            for (final t in c.topics) {
              expect(t.title.trim(), isNotEmpty,
                  reason: '${locale.languageCode} ${c.title}');
              expect(t.body.trim(), isNotEmpty,
                  reason: '${locale.languageCode} ${t.title}');
            }
          }
        }
      }
    });
  });

  group('przewodnik — warianty ról', () {
    testWidgets('gość ma krótki zestaw dymków bez skakania po panelu',
        (tester) async {
      await useLocale(tester, const Locale('pl'));

      final guest = buildOnboardingSteps(variant: OnbVariant.guest);
      expect(guest, isNotEmpty);
      // Gość nie ma panelu organizatora — przewodnik go nie przełącza.
      for (final s in guest) {
        expect(s.navigate, isFalse, reason: s.title);
        expect(s.nav, isFalse, reason: s.title);
      }
    });

    testWidgets('planer ma więcej kroków niż właściciel', (tester) async {
      await useLocale(tester, const Locale('pl'));

      final owner = buildOnboardingSteps(variant: OnbVariant.owner);
      final planner = buildOnboardingSteps(variant: OnbVariant.planner);
      expect(planner.length, owner.length + 3);
    });

    testWidgets('planer widzi opisy w kontekście klienta', (tester) async {
      await useLocale(tester, const Locale('pl'));

      String descOf(List<OnbStep> steps, AppSection s) =>
          steps.firstWhere((x) => x.section == s && x.nav).desc;

      final owner = buildOnboardingSteps(variant: OnbVariant.owner);
      final planner = buildOnboardingSteps(variant: OnbVariant.planner);
      // Nadpisanie działa tam, gdzie jest zdefiniowane…
      expect(descOf(planner, AppSection.guests),
          isNot(descOf(owner, AppSection.guests)));
      // …a gdzie go nie ma, wraca opis wspólny.
      expect(descOf(planner, AppSection.music),
          descOf(owner, AppSection.music));
    });

    testWidgets('liczba kroków jest taka sama w obu językach', (tester) async {
      await useLocale(tester, const Locale('pl'));
      final counts = {
        for (final v in OnbVariant.values)
          v: buildOnboardingSteps(variant: v).length
      };

      await useLocale(tester, const Locale('en'));
      for (final v in OnbVariant.values) {
        expect(buildOnboardingSteps(variant: v).length, counts[v],
            reason: v.name);
        for (final s in buildOnboardingSteps(variant: v)) {
          expect(s.title.trim(), isNotEmpty, reason: v.name);
          expect(s.desc.trim(), isNotEmpty, reason: s.title);
        }
      }
    });
  });

  group('kreator konfiguracji', () {
    testWidgets('każde zadanie ma nazwę i podpowiedź w obu językach',
        (tester) async {
      for (final locale in AppLocalizations.supportedLocales) {
        await useLocale(tester, locale);
        final tasks = buildSetupTasks();
        expect(tasks, isNotEmpty);
        for (final t in tasks) {
          expect(t.label.trim(), isNotEmpty, reason: '${t.id} $locale');
          expect(t.hint.trim(), isNotEmpty, reason: '${t.id} $locale');
        }
      }
    });

    testWidgets('identyfikatory zadań NIE zależą od języka', (tester) async {
      await useLocale(tester, const Locale('pl'));
      final pl = [for (final t in buildSetupTasks()) t.id];
      await useLocale(tester, const Locale('en'));
      final en = [for (final t in buildSetupTasks()) t.id];
      expect(en, pl);
    });
  });

  group('etykiety sekcji', () {
    testWidgets('tłumaczy się etykieta, nie identyfikator', (tester) async {
      await useLocale(tester, const Locale('pl'));
      expect(AppSection.room.label, 'Plan sali');

      await useLocale(tester, const Locale('en'));
      expect(AppSection.room.label, 'Seating plan');

      // `name` trafia do zapisanego układu paska nawigacji — musi być stałe.
      expect(AppSection.room.name, 'room');
    });
  });
}
