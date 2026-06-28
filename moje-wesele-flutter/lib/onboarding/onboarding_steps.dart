import 'package:flutter/widgets.dart';

import '../navigation/app_sections.dart';

/// Pojedynczy krok przewodnika. `basic` → widoczny też w trybie „Podstawy".
/// `subTab` → indeks podzakładki do przełączenia (null = sekcja główna).
/// `planning` → krok prezentujący „Od czego zacząć?".
class OnbStep {
  const OnbStep({
    required this.section,
    required this.title,
    required this.desc,
    this.subTab,
    this.basic = false,
    this.planning = false,
    this.nav = false,
  });

  final AppSection section;
  final int? subTab;
  final String title;
  final String desc;
  final bool basic;
  final bool planning;

  /// Czy podświetlić przycisk nawigacji prowadzący do tej sekcji (spotlight).
  /// Dla podzakładek / podsekcji pokazujemy wyśrodkowany dymek (treść już
  /// widoczna pod nakładką).
  final bool nav;
}

/// Magistrala żądań przełączenia podzakładki w trakcie przewodnika.
/// Ekrany zakładkowe nasłuchują i animują swój [TabController]/DefaultTabController.
class OnboardingTabBus {
  OnboardingTabBus._();
  static final ValueNotifier<({AppSection section, int index})?> request =
      ValueNotifier(null);

  static void requestTab(AppSection section, int index) =>
      request.value = (section: section, index: index);

  static void clear() => request.value = null;
}

// ── Opisy sekcji (krótki tekst kroku) ─────────────────────────────────────
const Map<AppSection, String> _sectionDesc = {
  AppSection.dashboard:
      'Twój pulpit — licznik dni do ślubu, skróty i najważniejsze statystyki '
          'w jednym miejscu.',
  AppSection.guests:
      'Lista zaproszonych, ich dane, statusy potwierdzeń i preferencje — '
          'w podzakładkach.',
  AppSection.budget:
      'Kontroluj wszystkie koszty wesela w jednym miejscu — podzakładki obok.',
  AppSection.room:
      'Rozmieść stoły i elementy sali na interaktywnym planie. Włącz „Edytuj '
          'plan", aby przeciągać i zmieniać rozmiary.',
  AppSection.schedule:
      'Rozpisz przebieg dnia ślubu oraz checklistę — w podzakładkach.',
  AppSection.tasks:
      'Rozpisz zadania, przypisz osoby i powiąż je z budżetem, dostawcą lub '
          'prezentem.',
  AppSection.vendors:
      'Baza usługodawców — kontakty, umowy, raty płatności i powiązania '
          'z budżetem.',
  AppSection.transport:
      'Zorganizuj dojazd gości — trasy, pojazdy i przypisanie pasażerów.',
  AppSection.accommodation:
      'Zarządzaj noclegami dla gości — obiekty, pokoje i rezerwacje.',
  AppSection.music:
      'Twórz playlistę wesela i zbieraj propozycje utworów od gości (kod QR).',
  AppSection.gifts:
      'Ewidencja prezentów otrzymanych, upominków dla gości i listy życzeń — '
          'w podzakładkach.',
  AppSection.gallery:
      'Wspólna galeria zdjęć z wesela oraz kody QR do udostępniania gościom.',
  AppSection.bingo:
      'Ślubne Bingo — zabawa dla gości generowana z wydarzeń harmonogramu.',
  AppSection.analytics:
      'Wykresy i statystyki organizacji — postępy, koszty i frekwencja.',
  AppSection.rsvp:
      'Zarządzaj potwierdzeniami obecności (RSVP) i udostępniaj gościom '
          'formularz online.',
  AppSection.settings:
      'Tu znajdziesz konfigurację, dostęp, logowanie i narzędzia. Przewodnik '
          'wznowisz w każdej chwili z menu pod logo. To już wszystko — '
          'powodzenia!',
};

// ── Podzakładki sekcji (etykieta, opis) — zgodne ze strukturą aplikacji ───
const Map<AppSection, List<(String, String)>> _subTabs = {
  AppSection.guests: [
    ('Lista', 'Lista zaproszonych — dodawaj gości i zarządzaj ich danymi.'),
    ('Kartoteka',
        'Szczegółowa kartoteka: status potwierdzenia, dieta, wiek i uwagi.'),
    ('Podsumowanie',
        'Zbiorcze statystyki: liczba gości, potwierdzenia, dzieci i diety.'),
  ],
  AppSection.budget: [
    ('Podsumowanie',
        'Budżet całkowity kontra wydatki — ile już rozdysponowano.'),
    ('Sala',
        'Koszt sali i cateringu — stawka za osobę przelicza się z liczbą gości.'),
    ('Wydatki', 'Dodawaj pozostałe wydatki i grupuj je w kategorie.'),
    ('Alkohol', 'Planuj rodzaje, ilości i koszty alkoholu.'),
    ('Napoje bezalkoholowe',
        'Woda, soki, napoje gazowane — ilości i koszty.'),
    ('Podróż poślubna',
        'Budżet miesiąca miodowego osobno od kosztów wesela.'),
    ('Płatności',
        'Harmonogram wpłat i zaliczek — terminy i to, co już zapłacone.'),
  ],
  AppSection.schedule: [
    ('Plan dnia',
        'Punkty programu z godzinami — od ceremonii po ostatni taniec.'),
    ('Checklista',
        'Lista rzeczy do odhaczenia przed weselem i w jego trakcie.'),
  ],
  AppSection.gifts: [
    ('Otrzymane',
        'Zapisuj, co i od kogo dostaliście — przyda się przy podziękowaniach.'),
    ('Dla gości', 'Planuj podziękowania i upominki dla gości.'),
    ('Propozycje',
        'Wasza lista życzeń — podpowiedzcie gościom, co sprawi Wam radość.'),
  ],
};

/// Sekcje, które mają sterowalne podzakładki (DefaultTabController + TourTabSync).
const Set<AppSection> tabbedSections = {
  AppSection.guests,
  AppSection.budget,
  AppSection.schedule,
  AppSection.gifts,
};

// ── Podsekcje Ustawień (krok pełnego trybu, bez przełączania zakładek) ────
const List<(String, String)> _settingsSubs = [
  ('Ustawienia · Status synchronizacji',
      'Sprawdź, czy dane są zsynchronizowane z chmurą (Firestore).'),
  ('Ustawienia · Konfiguracja',
      'Nazwa imprezy, data, miejsca, podział kosztów i słowniki.'),
  ('Ustawienia · Dostęp',
      'Lista autoryzowanych adresów e-mail z dostępem do aplikacji.'),
  ('Ustawienia · Logowanie',
      'Biometria, PIN/wzór i status zabezpieczeń urządzenia.'),
  ('Ustawienia · Programistyczne',
      'Eksport/import danych i kopie zapasowe.'),
];

/// Buduje pełną, uporządkowaną listę kroków przewodnika.
///
/// Iteruje po [AppSection.values], więc NOWE sekcje dodane w przyszłości
/// automatycznie trafią do przewodnika (z etykietą i ogólnym opisem, gdy brak
/// dedykowanego tekstu). Po Dashboardzie pokazujemy „Od czego zacząć?",
/// po Galerii krok o kodach QR, a Ustawienia (z podsekcjami) są na końcu.
List<OnbStep> buildOnboardingSteps() {
  String descFor(AppSection s) =>
      _sectionDesc[s] ?? 'Sekcja „${s.label}" w aplikacji.';

  final steps = <OnbStep>[
    OnbStep(
        section: AppSection.dashboard,
        title: 'Dashboard',
        desc: descFor(AppSection.dashboard),
        basic: true,
        nav: true),
    const OnbStep(
      section: AppSection.dashboard,
      planning: true,
      title: 'Od czego zacząć?',
      desc:
          'Sugerowana kolejność planowania wesela. Odhaczaj ukończone kroki, '
          'a pasek pokaże postęp. Otworzysz ją w każdej chwili z Ustawień.',
      basic: true,
    ),
  ];

  for (final s in AppSection.values) {
    if (s == AppSection.dashboard || s == AppSection.settings) continue;
    steps.add(OnbStep(
        section: s, title: s.label, desc: descFor(s), basic: true, nav: true));
    final subs = _subTabs[s];
    if (subs != null) {
      for (var i = 0; i < subs.length; i++) {
        steps.add(OnbStep(
          section: s,
          subTab: i,
          title: '${s.label} › ${subs[i].$1}',
          desc: subs[i].$2,
        ));
      }
    }
    if (s == AppSection.gallery) {
      steps.add(const OnbStep(
        section: AppSection.gallery,
        title: 'Kody QR dla gości',
        desc:
            'Udostępnij gościom kody QR prowadzące do galerii, muzyki, '
            'harmonogramu i potwierdzeń.',
      ));
    }
  }

  steps.add(OnbStep(
      section: AppSection.settings,
      title: 'Ustawienia',
      desc: descFor(AppSection.settings),
      basic: true,
      nav: true));
  for (final sub in _settingsSubs) {
    steps.add(OnbStep(
        section: AppSection.settings, title: sub.$1, desc: sub.$2));
  }

  return steps;
}
