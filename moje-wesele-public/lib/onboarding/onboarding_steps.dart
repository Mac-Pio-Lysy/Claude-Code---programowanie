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
    this.navigate = true,
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

  /// Czy przewodnik ma przełączyć widok na [section].
  ///
  /// `false` w wariancie GOŚCIA: opisujemy wtedy sekcje strefy gości, których
  /// w panelu organizatora nie ma (albo wyglądają zupełnie inaczej), więc
  /// skakanie po panelu tylko myliłoby oglądającego. Krok pokazuje sam dymek.
  final bool navigate;
}

/// Wariant przewodnika — dobierany do roli zalogowanego użytkownika.
enum OnbVariant {
  /// Para Młoda i współorganizator — pełny panel.
  owner,

  /// Planer weselny — pełny panel, ale opisy w kontekście obsługi klientów.
  planner,

  /// Gość — wyłącznie strefa gości (RSVP, galeria, muzyka, gry, pamiątki).
  guest,
}

/// Wariant przewodnika dla roli z członkostwa (`owner`/`planner`/
/// `collaborator`/`guest`). Współorganizator dostaje wariant właściciela —
/// widzi ten sam panel.
OnbVariant variantForRole(String? role) => switch (role) {
      'guest' => OnbVariant.guest,
      'planner' => OnbVariant.planner,
      _ => OnbVariant.owner,
    };

/// Klucz wariantu do zapisu stanu ukończenia (per użytkownik i per wariant).
String variantKey(OnbVariant v) => v.name;

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
  AppSection.games:
      'Ślubne gry — zabawy dla gości, m.in. Ślubne Bingo generowane '
          'z wydarzeń harmonogramu. Wkrótce kolejne gry.',
  AppSection.keepsakes:
      'Ślubne pamiątki — księga gości, rady dla Pary Młodej, kapsuła czasu '
          'i mapa gości. W przygotowaniu.',
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
        'Koszt sali — stawka za osobę przelicza się z liczbą gości '
        '(przypisanych, nieprzypisanych i obsługi).'),
    ('Wydatki', 'Dodawaj pozostałe wydatki i grupuj je w kategorie.'),
    ('Alkohol', 'Planuj rodzaje, ilości i koszty alkoholu.'),
    ('Napoje bezalkoholowe',
        'Woda, soki, napoje gazowane — ilości i koszty.'),
    ('Podróż poślubna',
        'Budżet miesiąca miodowego osobno od kosztów wesela. W „Podsumowaniu" '
        'znajdziesz też wszystkie płatności i terminy.'),
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
  ('Ustawienia · Widoczność dla gości',
      'Decydujesz, które sekcje widzą goście i od kiedy do kiedy. Np. RSVP '
          'włącz od razu, a galerię dopiero w dniu wesela.'),
  ('Ustawienia · Kod dołączenia dla gości',
      'Sześcioznakowy kod, którym gość dołącza do wesela na własnym koncie. '
          'Weryfikacja jest potrójna: kod, data ślubu i nazwisko.'),
  ('Ustawienia · Link i QR dla gości',
      'Link i kod QR do strefy gości — działa bez logowania i bez instalowania '
          'aplikacji. To go drukujesz na zaproszeniach albo kładziesz na stołach.'),
  ('Ustawienia · Interakcje gości',
      'Wszystko, co przysłali goście: RSVP, wpisy księgi, rady, zdjęcia, '
          'propozycje muzyki i wyniki gier. Tu też moderujesz — kasujesz '
          'nieodpowiednie wpisy jednym kliknięciem.'),
  ('Ustawienia · Osoby i dostęp',
      'Dodawaj współorganizatorów i planera, nadawaj datę ważności, blokuj '
          'i przywracaj dostęp. Tylko właściciel wesela może tu cokolwiek '
          'zmienić — to zabezpieczenie, nie ograniczenie.'),
  ('Ustawienia · Konfiguracja',
      'Nazwa imprezy, data, miejsca, podział kosztów i słowniki.'),
  ('Ustawienia · Logowanie',
      'Biometria, PIN/wzór i status zabezpieczeń urządzenia.'),
  ('Ustawienia · Programistyczne',
      'Eksport/import danych i kopie zapasowe.'),
];

// ── Wariant PLANERA: nadpisania opisów (kontekst „to oferujesz klientom") ──
// Tam, gdzie planer widzi to samo co Para Młoda, ale znaczenie jest inne:
// pracuje na weselu KLIENTA, często ma ich kilka naraz, a dostęp bywa czasowy.
const Map<AppSection, String> _plannerDesc = {
  AppSection.dashboard:
      'Pulpit wesela KLIENTA — licznik dni, postępy i statystyki. Każde wesele '
          'w Twoim koncie ma własny pulpit; przełączasz je w „Zmień wesele".',
  AppSection.guests:
      'Lista gości klienta wraz z potwierdzeniami i preferencjami. To dane '
          'osobowe Waszych klientów — traktuj je poufnie.',
  AppSection.budget:
      'Budżet wesela klienta. Tu najczęściej pokazujesz Parze, na co idą '
          'pieniądze i gdzie są oszczędności — podzakładki obok.',
  AppSection.room:
      'Plan sali do ustalenia z klientem i salą. Wydrukowany układ stołów to '
          'jeden z najczęściej zamawianych elementów Twojej usługi.',
  AppSection.schedule:
      'Harmonogram dnia — Twój najważniejszy dokument roboczy. To on trafia do '
          'obsługi, fotografa i zespołu muzycznego.',
  AppSection.tasks:
      'Zadania z przypisaniem osób. Możesz tu rozdzielić obowiązki między '
          'siebie, Parę i podwykonawców.',
  AppSection.vendors:
      'Baza usługodawców z umowami i ratami. Prowadząc kilka wesel, budujesz '
          'tu swoją prywatną bazę sprawdzonych kontaktów.',
  AppSection.analytics:
      'Wykresy i statystyki — gotowy materiał na podsumowanie postępów dla '
          'klienta.',
  AppSection.settings:
      'Konfiguracja wesela, dostęp osób i widoczność sekcji dla gości. '
          'Pamiętaj: właścicielem wesela pozostaje Para Młoda — to ona nadaje '
          'i odbiera dostępy. Przewodnik wznowisz z menu pod logo.',
};

// ── Wariant PLANERA: kroki, których nie ma w wariancie właściciela ────────
List<OnbStep> _plannerExtraSteps() => const [
      OnbStep(
        section: AppSection.dashboard,
        title: 'Wiele wesel na jednym koncie',
        desc:
            'Jako planer możesz prowadzić dowolnie wiele wesel. Przełączasz je '
            'w menu pod logo → „Zmień wesele". Dane każdego wesela są w pełni '
            'oddzielone — klient A nigdy nie zobaczy wesela klienta B.',
        basic: true,
      ),
      OnbStep(
        section: AppSection.dashboard,
        title: 'Twój dostęp może mieć datę ważności',
        desc:
            'Para Młoda nadaje planerowi dostęp, może ustawić mu datę ważności '
            'i w każdej chwili go zablokować lub przywrócić. Po wygaśnięciu '
            'wesele znika z Twojej listy — to normalne, nie awaria.',
        basic: true,
      ),
      OnbStep(
        section: AppSection.settings,
        title: 'Przekazanie wesela Parze Młodej',
        desc:
            'Konto Pary Młodej jest nadrzędne: tylko ona dodaje osoby i wystawia '
            'zaproszenia. Gdy kończysz współpracę, to Para przejmuje pełną '
            'kontrolę — nic nie trzeba przenosić ani eksportować.',
      ),
    ];

// ── Wariant GOŚCIA ────────────────────────────────────────────────────────
// Gość nie ma panelu organizatora ani szyny nawigacji, więc kroki są
// wyśrodkowanymi dymkami (`nav: false`, `navigate: false`). Ten sam zestaw
// służy podglądowi „Zobacz przewodnik gościa" dla właściciela i planera.
List<OnbStep> _buildGuestSteps() => const [
      OnbStep(
        section: AppSection.rsvp,
        title: 'Witaj w strefie gości',
        desc:
            'To Twoje miejsce na weselu Pary Młodej. Znajdziesz tu wszystko, '
            'czego potrzebujesz jako gość — bez zakładania konta i bez '
            'instalowania czegokolwiek.',
        basic: true,
        nav: false,
        navigate: false,
      ),
      OnbStep(
        section: AppSection.rsvp,
        title: 'Potwierdzenie obecności (RSVP)',
        desc:
            'Daj znać, czy będziesz i z iloma osobami. Podaj dietę lub alergie, '
            'jeśli je masz. Wystarczy jedno potwierdzenie — gdy plany się '
            'zmienią, wróć tutaj i popraw odpowiedź.',
        basic: true,
        nav: false,
        navigate: false,
      ),
      OnbStep(
        section: AppSection.schedule,
        title: 'Harmonogram dnia',
        desc:
            'Godzina po godzinie: ceremonia, przyjęcie, tort, pierwszy taniec. '
            'Zobaczysz też licznik dni do wesela.',
        basic: true,
        nav: false,
        navigate: false,
      ),
      OnbStep(
        section: AppSection.gallery,
        title: 'Galeria — dodaj swoje zdjęcia',
        desc:
            'Wrzuć zdjęcia prosto z telefonu i oglądaj te dodane przez innych '
            'gości. Para Młoda dostaje w ten sposób ujęcia, których nie ma '
            'żaden fotograf.',
        basic: true,
        nav: false,
        navigate: false,
      ),
      OnbStep(
        section: AppSection.music,
        title: 'Muzyka — zaproponuj utwór',
        desc:
            'Wyszukaj piosenkę i wyślij propozycję do Pary Młodej. Propozycje '
            'trafiają tylko do nich — nie ma publicznej listy ani głosowania.',
        basic: true,
        nav: false,
        navigate: false,
      ),
      OnbStep(
        section: AppSection.games,
        title: 'Ślubne gry',
        desc:
            'Quiz o Parze Młodej, Prawda/Fałsz, Zgadnij zdjęcie, foto-wyzwania '
            'i Ślubne Bingo. Wyniki widzi tylko Para Młoda — nie ma publicznego '
            'rankingu, więc graj dla zabawy.',
        basic: true,
        nav: false,
        navigate: false,
      ),
      OnbStep(
        section: AppSection.games,
        title: 'Gry — jak to działa',
        desc:
            'Quiz, Prawda/Fałsz i Zgadnij zdjęcie liczą wynik od razu na Twoim '
            'telefonie. Możesz podejść ponownie — nowy wynik zastąpi poprzedni. '
            'W foto-wyzwaniach wysyłasz po jednym zdjęciu do każdego zadania.',
        nav: false,
        navigate: false,
      ),
      OnbStep(
        section: AppSection.keepsakes,
        title: 'Ślubne pamiątki',
        desc:
            'Zostaw ślad po sobie: wpis w księdze gości, rada dla Pary Młodej, '
            'wiadomość do kapsuły czasu i pinezka na mapie gości.',
        basic: true,
        nav: false,
        navigate: false,
      ),
      OnbStep(
        section: AppSection.keepsakes,
        title: 'Księga gości i rady',
        desc:
            'Wpisów możesz zostawić kilka — życzenia, wspomnienie, dobra rada. '
            'Widzą je inni goście, więc to trochę jak wspólna kronika.',
        nav: false,
        navigate: false,
      ),
      OnbStep(
        section: AppSection.keepsakes,
        title: 'Kapsuła czasu i mapa gości',
        desc:
            'Kapsuła to prywatna wiadomość — przeczyta ją wyłącznie Para Młoda. '
            'Na mapie zaznaczasz, skąd przyjeżdżasz; jedna pinezka na gościa, '
            'można ją poprawić.',
        nav: false,
        navigate: false,
      ),
      OnbStep(
        section: AppSection.rsvp,
        title: 'To wszystko!',
        desc:
            'Sekcje pojawiają się i znikają zgodnie z tym, co udostępniła Para '
            'Młoda — jeśli czegoś nie widzisz, być może będzie dostępne bliżej '
            'wesela. Bawcie się dobrze!',
        basic: true,
        nav: false,
        navigate: false,
      ),
    ];

/// Buduje pełną, uporządkowaną listę kroków przewodnika.
///
/// Iteruje po [AppSection.values], więc NOWE sekcje dodane w przyszłości
/// automatycznie trafią do przewodnika (z etykietą i ogólnym opisem, gdy brak
/// dedykowanego tekstu). Po Dashboardzie pokazujemy „Od czego zacząć?",
/// po Galerii krok o kodach QR, a Ustawienia (z podsekcjami) są na końcu.
List<OnbStep> buildOnboardingSteps({OnbVariant variant = OnbVariant.owner}) {
  // Gość ma zupełnie inną aplikację — własny, krótki zestaw kroków.
  if (variant == OnbVariant.guest) return _buildGuestSteps();

  final planner = variant == OnbVariant.planner;

  // Planer widzi te same sekcje, ale opis stawia je w kontekście obsługi
  // klienta. Gdy nie ma nadpisania — używamy opisu wspólnego.
  String descFor(AppSection s) =>
      (planner ? _plannerDesc[s] : null) ??
      _sectionDesc[s] ??
      'Sekcja „${s.label}" w aplikacji.';

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

  // Planer: kontekst „wiele wesel / dostęp czasowy" od razu po pulpicie.
  if (planner) {
    steps.addAll(_plannerExtraSteps()
        .where((s) => s.section == AppSection.dashboard));
  }

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

  // Planer: domknięcie tematu przekazania wesela Parze Młodej.
  if (planner) {
    steps.addAll(
        _plannerExtraSteps().where((s) => s.section == AppSection.settings));
  }

  return steps;
}
