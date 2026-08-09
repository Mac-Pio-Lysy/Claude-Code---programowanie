import 'package:flutter/material.dart';

import '../onboarding/onboarding_steps.dart' show OnbVariant;

/// Pojedyncze hasło pomocy: co funkcja robi i jak z niej skorzystać.
class HelpTopic {
  const HelpTopic(this.title, this.body);

  final String title;
  final String body;

  /// Czy hasło pasuje do zapytania wyszukiwarki (tytuł lub treść).
  bool matches(String q) =>
      title.toLowerCase().contains(q) || body.toLowerCase().contains(q);
}

/// Kategoria haseł (rozwijana sekcja na ekranie pomocy).
class HelpCategory {
  const HelpCategory(
      {required this.title, required this.icon, required this.topics});

  final String title;
  final IconData icon;
  final List<HelpTopic> topics;
}

/// Buduje spis pomocy dla wskazanego wariantu roli.
///
/// Ten sam podział ról co przewodnik ([OnbVariant]): właściciel i
/// współorganizator widzą pełny panel, planer dodatkowo rozdział o pracy
/// z klientami, a gość wyłącznie swoją strefę.
List<HelpCategory> buildHelp(OnbVariant variant) => switch (variant) {
      OnbVariant.guest => _guestHelp,
      OnbVariant.planner => [..._ownerHelp, _plannerHelp],
      OnbVariant.owner => _ownerHelp,
    };

// ═══════════════════════════════════════════════════════════════════════════
// PANEL ORGANIZATORA
// ═══════════════════════════════════════════════════════════════════════════

const List<HelpCategory> _ownerHelp = [
  HelpCategory(
    title: 'Start',
    icon: Icons.dashboard_outlined,
    topics: [
      HelpTopic(
        'Pulpit',
        'Licznik dni do ślubu, skróty do sekcji i najważniejsze statystyki. '
            'Układ kafelków ustawiasz sam — możesz ukryć te, których nie '
            'używasz.',
      ),
      HelpTopic(
        'Od czego zacząć?',
        'Sugerowana kolejność planowania wesela. Odhaczaj ukończone kroki, '
            'a pasek pokaże postęp. Otworzysz ją z Ustawień w dowolnym momencie '
            '— lista jest wspólna dla wszystkich organizatorów wesela.',
      ),
      HelpTopic(
        'Przewodnik a Pomoc',
        'Przewodnik prowadzi po aplikacji krok po kroku i podświetla elementy '
            'na ekranie. Pomoc (ten ekran) to encyklopedia funkcji do czytania '
            'wtedy, gdy szukasz konkretnej odpowiedzi.',
      ),
    ],
  ),
  HelpCategory(
    title: 'Goście',
    icon: Icons.people_outline,
    topics: [
      HelpTopic(
        'Lista gości',
        'Dodawaj zaproszonych i zarządzaj ich danymi. Każdy gość może mieć '
            'osobę towarzyszącą — dodaj ją przy wpisie, a nie jako osobnego '
            'gościa, dzięki czemu liczby w podsumowaniu się zgadzają.',
      ),
      HelpTopic(
        'Kartoteka',
        'Szczegóły przydatne przy organizacji: dieta, alergie, wiek, potrzeba '
            'noclegu i transportu, uwagi. Te dane napędzają też kalkulacje '
            'w Budżecie i przypisania w Noclegach.',
      ),
      HelpTopic(
        'Podsumowanie gości',
        'Zbiorcze liczby: zaproszeni, potwierdzeni, dzieci, diety. Sprawdź je '
            'przed rozmową z salą — to na ich podstawie ustala się catering.',
      ),
      HelpTopic(
        'Potwierdzenia obecności (RSVP)',
        'Masz dwa źródła: wpisy, które sam dodasz w panelu, oraz potwierdzenia '
            'przysłane przez gości ze strefy gości. Te drugie znajdziesz '
            'w Ustawieniach → Interakcje gości → RSVP. Każdy gość może wysłać '
            'jedno potwierdzenie i sam je poprawić, jeśli plany się zmienią.',
      ),
    ],
  ),
  HelpCategory(
    title: 'Budżet',
    icon: Icons.savings_outlined,
    topics: [
      HelpTopic(
        'Jedno źródło danych — najważniejsza zasada',
        'Pozycja dodana w Dostawcach, Prezentach czy Podróży poślubnej pojawia '
            'się w Budżecie automatycznie, z etykietą „dodano w…". Edytuj ją '
            'tam, gdzie powstała — dzięki temu nic nie liczy się podwójnie '
            'i nie musisz pilnować dwóch list.',
      ),
      HelpTopic(
        'Podsumowanie budżetu',
        'Limit kontra wydatki, ile zostało do rozdysponowania oraz zestawienie '
            'wszystkich płatności i terminów w jednym miejscu.',
      ),
      HelpTopic(
        'Sala i catering',
        'Stawkę podajesz za osobę, a aplikacja przelicza koszt z liczby gości. '
            'Możesz osobno wliczyć obsługę (fotograf, zespół), dzieci po innej '
            'stawce i gości jeszcze nieprzypisanych do stołów. Ustaw też '
            'minimum gwarantowane przez salę, jeśli umowa je przewiduje.',
      ),
      HelpTopic(
        'Wydatki',
        'Pozostałe koszty pogrupowane w kategorie. Kategorie edytujesz '
            'w Ustawieniach → Konfiguracja.',
      ),
      HelpTopic(
        'Alkohol i napoje',
        'Rodzaje, ilości i ceny — osobno alkohol, osobno napoje bezalkoholowe. '
            'Przydaje się przy ustalaniu, co bierzecie własne, a co z sali.',
      ),
      HelpTopic(
        'Podróż poślubna',
        'Liczona osobno od kosztów wesela, żeby nie zaburzała budżetu przyjęcia '
            '— ale jej płatności widać w Podsumowaniu razem z pozostałymi.',
      ),
      HelpTopic(
        'Raty i terminy płatności',
        'Przy dostawcy lub wydatku rozpisz raty z datami. Nadchodzące terminy '
            'zobaczysz w Podsumowaniu budżetu i na pulpicie.',
      ),
    ],
  ),
  HelpCategory(
    title: 'Plan sali',
    icon: Icons.table_restaurant_outlined,
    topics: [
      HelpTopic(
        'Układanie sali',
        'Włącz „Edytuj plan", aby przeciągać stoły i elementy oraz zmieniać ich '
            'rozmiar. Poza trybem edycji plan służy do przeglądania '
            'i przypisywania gości — trudniej wtedy coś przypadkiem przesunąć.',
      ),
      HelpTopic(
        'Przypisywanie gości do stołów',
        'Przeciągnij gościa na miejsce przy stole. Goście nieprzypisani są '
            'widoczni osobno — pamiętaj o nich, bo mogą wliczać się do kosztu '
            'cateringu, zależnie od ustawień w Budżecie.',
      ),
      HelpTopic(
        'Stoły obsługi',
        'Stoliki dla fotografa, zespołu czy obsługi oznacz osobno — mają własną '
            'stawkę cateringową i nie mieszają się z listą gości.',
      ),
    ],
  ),
  HelpCategory(
    title: 'Harmonogram i zadania',
    icon: Icons.event_outlined,
    topics: [
      HelpTopic(
        'Plan dnia',
        'Punkty programu z godzinami, kategorią i miejscem. To najważniejszy '
            'dokument dnia ślubu — przyda się fotografowi, zespołowi i obsłudze '
            'sali.',
      ),
      HelpTopic(
        'Punkt prywatny',
        'Punkt oznaczony jako prywatny NIE trafia do strefy gości. Używaj go do '
            'spraw organizacyjnych: „przyjazd florystki", „rozliczenie z salą".',
      ),
      HelpTopic(
        'Link do miejsca dla gości',
        'Przy punkcie możesz podać link do mapy i osobno zdecydować, czy '
            'pokazać go gościom. Bez zaznaczenia tej opcji link zostaje tylko '
            'dla Was.',
      ),
      HelpTopic(
        'Checklista',
        'Lista rzeczy do odhaczenia przed weselem i w jego trakcie — osobna od '
            'Zadań, bo służy do szybkiego „zrobione / niezrobione".',
      ),
      HelpTopic(
        'Zadania i powiązania',
        'Zadaniu możesz przypisać osobę odpowiedzialną i powiązać je z '
            'wydatkiem, dostawcą lub prezentem. Dzięki temu z jednego miejsca '
            'widzisz, co zostało do zrobienia i ile to kosztuje.',
      ),
    ],
  ),
  HelpCategory(
    title: 'Dostawcy, transport, noclegi',
    icon: Icons.handshake_outlined,
    topics: [
      HelpTopic(
        'Dostawcy',
        'Kontakty, kwoty umów, statusy płatności i raty. Kwota dostawcy trafia '
            'do Budżetu automatycznie — nie dodawaj jej drugi raz jako wydatku.',
      ),
      HelpTopic(
        'Transport',
        'Trasy, pojazdy i przypisanie pasażerów. Informacja „potrzebuje '
            'transportu" pochodzi z kartoteki gościa.',
      ),
      HelpTopic(
        'Noclegi',
        'Obiekty, pokoje i rezerwacje dla gości. Podobnie jak transport — '
            'korzysta z oznaczeń w kartotece.',
      ),
    ],
  ),
  HelpCategory(
    title: 'Strefa gości',
    icon: Icons.groups_outlined,
    topics: [
      HelpTopic(
        'Link i kod QR dla gości',
        'Ustawienia → „Link i QR dla gości". Gość otwiera stronę bez logowania '
            'i bez instalowania aplikacji. Ten kod drukujesz na zaproszeniach '
            'albo kładziesz na stołach.',
      ),
      HelpTopic(
        'Kod dołączenia (konto gościa)',
        'Sześcioznakowy kod dla gościa, który chce mieć wesele na własnym '
            'koncie. Weryfikacja jest potrójna: kod, data ślubu i nazwisko — '
            'sam kod nie wystarczy, bo bywa jawny na stołach.',
      ),
      HelpTopic(
        'Widoczność sekcji dla gości',
        'Decydujesz, które sekcje widzą goście i w jakim okresie (daty OD/DO). '
            'Wybierasz też, co się dzieje poza zakresem: komunikat „dostępne '
            'od…" albo całkowite ukrycie kafelka. Typowo: RSVP włącz od razu, '
            'galerię dopiero w dniu wesela.',
      ),
      HelpTopic(
        'Interakcje gości i moderacja',
        'Ustawienia → „Interakcje gości". W jednym miejscu zbierają się '
            'potwierdzenia, wpisy księgi, rady, zdjęcia, propozycje muzyki '
            'i wyniki gier. Każdy wpis możesz usunąć jednym kliknięciem.',
      ),
      HelpTopic(
        'Czego gość nie widzi',
        'Budżet, pełna lista gości, dostawcy, plan sali i zadania są dla gościa '
            'niedostępne — i nie chodzi o ukrycie w interfejsie, tylko '
            'o techniczny brak dostępu do tych danych.',
      ),
    ],
  ),
  HelpCategory(
    title: 'Zdjęcia i muzyka',
    icon: Icons.photo_library_outlined,
    topics: [
      HelpTopic(
        'Galeria',
        'Wspólny album: goście wrzucają zdjęcia ze swoich telefonów, Wy widzicie '
            'wszystko w panelu i możecie usuwać niechciane wpisy.',
      ),
      HelpTopic(
        'Muzyka i propozycje gości',
        'Budujesz playlistę wesela, a goście przysyłają propozycje utworów. '
            'Propozycje widzicie tylko Wy — nie ma publicznej listy ani '
            'głosowania. Każdą oznaczysz jako „Zagramy" lub „Odrzucona".',
      ),
    ],
  ),
  HelpCategory(
    title: 'Gry i pamiątki',
    icon: Icons.casino_outlined,
    topics: [
      HelpTopic(
        'Quiz, Prawda/Fałsz, Zgadnij zdjęcie',
        'Dodaj pytania i włącz grę przełącznikiem „aktywna". Gość gra na swoim '
            'telefonie, a wynik trafia do Was. Publicznego rankingu nie ma — '
            'nikt nie porównuje się z innymi.',
      ),
      HelpTopic(
        'Foto-wyzwania',
        'Lista zadań fotograficznych z punktami. Gość wysyła po jednym zdjęciu '
            'do każdego wyzwania; kolejne zastępuje poprzednie.',
      ),
      HelpTopic(
        'Ślubne Bingo',
        'Pola bingo możesz wpisać ręcznie lub wygenerować z punktów '
            'harmonogramu. Plansze drukujesz do PDF, a goście mogą też grać '
            'na telefonie.',
      ),
      HelpTopic(
        'Pamiątki',
        'Księga gości, rady dla Pary Młodej, kapsuła czasu i mapa gości. '
            'Kapsuła jest prywatna — czytacie ją tylko Wy.',
      ),
    ],
  ),
  HelpCategory(
    title: 'Role i dostęp',
    icon: Icons.admin_panel_settings_outlined,
    topics: [
      HelpTopic(
        'Właściciel ma władzę nadrzędną',
        'Konto Pary Młodej jest najważniejsze. Tylko właściciel dodaje osoby, '
            'wystawia zaproszenia i może każdemu odebrać dostęp — także '
            'planerowi.',
      ),
      HelpTopic(
        'Współorganizator',
        'Świadek, mama, przyjaciółka — pełny panel bez daty ważności. Nie może '
            'jednak dodawać kolejnych osób; to zostaje przy właścicielu.',
      ),
      HelpTopic(
        'Planer i data ważności',
        'Planerowi możesz nadać dostęp z datą wygaśnięcia. Po tej dacie wesele '
            'znika z jego listy. Dostęp da się w każdej chwili zablokować '
            'i przywrócić — wielokrotnie.',
      ),
      HelpTopic(
        'Jak dodać planera lub współorganizatora — krok po kroku',
        'Ustawienia → „Osoby i dostęp" → „Dodaj osobę". Wybierz rolę '
            '(Współorganizator albo Planer), a przy planerze ustaw datę '
            'ważności dostępu. Potem masz dwie drogi: podać adres e-mail osoby '
            '(musi już mieć konto w aplikacji) albo wygenerować kod '
            'zaproszenia i przekazać go dowolnym kanałem. Zaproszenie dodaje '
            'osobę tylko do TEGO wesela — przy kilku weselach każde wymaga '
            'osobnego zaproszenia.',
      ),
      HelpTopic(
        'Jak działa kod zaproszenia',
        'Kod jest jednorazowy i przypisany do konkretnego wesela oraz roli. '
            'Osoba, która go dostanie, zakłada konto (albo loguje się na '
            'istniejące), a następnie na liście wesel wybiera „Mam kod '
            'zaproszenia (współorganizator / planer)" i wpisuje go. Po '
            'wykorzystaniu kod przestaje działać — dla kolejnej osoby '
            'wygeneruj nowy. To inna ścieżka niż kod dla gości, którym goście '
            'dołączają do strefy gościa.',
      ),
      HelpTopic(
        'Data ważności dostępu planera',
        'Datę ustawiasz przy zapraszaniu i zmieniasz później na liście osób. '
            'Po jej upływie wesele znika z listy planera i traci on dostęp do '
            'danych — bez usuwania czegokolwiek u Ciebie. Datę można '
            'przesunąć, a dostęp zablokować i przywrócić wielokrotnie. '
            'Współorganizator daty ważności nie ma.',
      ),
      HelpTopic(
        'Odbieranie dostępu',
        'Na liście „Osoby i dostęp" przy każdej osobie znajdziesz blokadę '
            'i usunięcie. Blokada zostawia osobę na liście (można ją '
            'odblokować), usunięcie kasuje członkostwo — powrót wymaga nowego '
            'zaproszenia. Właściciela nie da się usunąć.',
      ),
    ],
  ),
  HelpCategory(
    title: 'Analityka',
    icon: Icons.insights_outlined,
    topics: [
      HelpTopic(
        'Wykresy i statystyki',
        'Postępy organizacji, struktura kosztów i frekwencja. Dobre miejsce, by '
            'sprawdzić, czy budżet nie rozjeżdża się z planem.',
      ),
    ],
  ),
  HelpCategory(
    title: 'Ustawienia i dane',
    icon: Icons.settings_outlined,
    topics: [
      HelpTopic(
        'Konfiguracja wesela',
        'Nazwa, data, godzina, miejsca ceremonii i przyjęcia, podział kosztów '
            'oraz słowniki (menu, kategorie wydatków). Po zmianie daty lub '
            'nazwisk zapisz konfigurację — odświeża to dane dołączania gości.',
      ),
      HelpTopic(
        'Synchronizacja',
        'Dane zapisują się w chmurze i są wspólne dla wszystkich organizatorów '
            'wesela. Kartę statusu znajdziesz na górze Ustawień.',
      ),
      HelpTopic(
        'Kopie zapasowe i eksport',
        'Możesz utworzyć kopię zapasową oraz wyeksportować wszystkie dane do '
            'pliku JSON. Import nadpisuje dane wesela — używaj ostrożnie.',
      ),
      HelpTopic(
        'Blokada aplikacji',
        'PIN, wzór lub biometria zabezpieczają dostęp na tym urządzeniu. '
            'Ustawienie jest lokalne — nie przenosi się na inne telefony.',
      ),
    ],
  ),
];

// ═══════════════════════════════════════════════════════════════════════════
// DODATEK DLA PLANERA
// ═══════════════════════════════════════════════════════════════════════════

const HelpCategory _plannerHelp = HelpCategory(
  title: 'Praca z klientami',
  icon: Icons.work_outline,
  topics: [
    HelpTopic(
      'Wiele wesel na jednym koncie',
      'Możesz prowadzić dowolnie wiele wesel. Przełączasz je w menu pod logo → '
          '„Zmień wesele". Dane każdego wesela są w pełni oddzielone — klient A '
          'nigdy nie zobaczy wesela klienta B.',
    ),
    HelpTopic(
      'Twój dostęp bywa czasowy',
      'Para Młoda może nadać Ci dostęp z datą ważności oraz zablokować go '
          'i przywrócić. Gdy wesele zniknie z Twojej listy, to najczęściej '
          'wygasła data, a nie awaria — poproś klienta o przedłużenie.',
    ),
    HelpTopic(
      'Czego planer nie może',
      'Dodawanie osób i wystawianie zaproszeń jest zarezerwowane dla '
          'właściciela wesela. To celowe: klient ma zawsze kontrolę nad tym, kto '
          'ma dostęp do jego danych.',
    ),
    HelpTopic(
      'Przekazanie wesela Parze',
      'Nie ma osobnego „przekazania" — wesele od początku należy do Pary '
          'Młodej. Gdy kończycie współpracę, po prostu tracisz dostęp, a '
          'wszystkie dane zostają u klienta. Nic nie trzeba eksportować.',
    ),
    HelpTopic(
      'Dane osobowe klientów',
      'Lista gości zawiera dane osobowe: nazwiska, telefony, adresy e-mail, '
          'informacje o dietach. Traktuj je poufnie i nie przenoś między '
          'weselami.',
    ),
    HelpTopic(
      'Co pokazać klientowi',
      'Najczęściej sprawdzają się: Podsumowanie budżetu (na co idą pieniądze), '
          'plan sali (wydruk) i harmonogram dnia. Analityka daje gotowy materiał '
          'na podsumowanie postępów.',
    ),
  ],
);

// ═══════════════════════════════════════════════════════════════════════════
// STREFA GOŚCIA
// ═══════════════════════════════════════════════════════════════════════════

const List<HelpCategory> _guestHelp = [
  HelpCategory(
    title: 'Na start',
    icon: Icons.celebration_outlined,
    topics: [
      HelpTopic(
        'Czym jest ta strona',
        'To strefa gości przygotowana przez Parę Młodą. Nie musisz zakładać '
            'konta ani niczego instalować — wystarczy link lub kod QR '
            'z zaproszenia.',
      ),
      HelpTopic(
        'Nie widzę jakiejś sekcji',
        'Para Młoda sama decyduje, co i kiedy udostępnia. Część sekcji '
            'pojawia się dopiero bliżej wesela, a niektóre znikają po nim. '
            'Zajrzyj później.',
      ),
    ],
  ),
  HelpCategory(
    title: 'Potwierdzenie obecności',
    icon: Icons.how_to_reg_outlined,
    topics: [
      HelpTopic(
        'Jak potwierdzić obecność',
        'Wejdź w RSVP, wpisz imię i nazwisko, zaznacz, czy będziesz, i wyślij. '
            'Jeśli przyjeżdżasz z kimś, podaj liczbę osób towarzyszących — '
            'nie wypełniaj formularza drugi raz za tę osobę.',
      ),
      HelpTopic(
        'Zmiana odpowiedzi',
        'Wystarczy jedno potwierdzenie. Gdy plany się zmienią, wróć do RSVP — '
            'formularz wypełni się Twoją poprzednią odpowiedzią, a po zapisaniu '
            'zastąpi ją nowa.',
      ),
      HelpTopic(
        'Dieta i alergie',
        'Wpisz je w formularzu potwierdzenia. Ta informacja trafia prosto do '
            'Pary Młodej i pomaga ustalić menu z salą.',
      ),
    ],
  ),
  HelpCategory(
    title: 'Zdjęcia',
    icon: Icons.photo_camera_outlined,
    topics: [
      HelpTopic(
        'Dodawanie zdjęć',
        'W Galerii podaj imię, wybierz zdjęcie z telefonu lub zrób je od razu '
            'aparatem. Możesz dorzucić podpis. Zdjęć możesz dodać dowolnie '
            'wiele.',
      ),
      HelpTopic(
        'Kto widzi moje zdjęcia',
        'Galeria jest wspólna — widzą ją wszyscy goście z linkiem oraz Para '
            'Młoda. Para może usunąć każde zdjęcie.',
      ),
    ],
  ),
  HelpCategory(
    title: 'Muzyka',
    icon: Icons.music_note_outlined,
    topics: [
      HelpTopic(
        'Propozycja utworu',
        'Wyszukaj piosenkę albo wpisz tytuł i wykonawcę ręcznie, a potem wyślij '
            'propozycję. Jeśli wyszukiwarka nie działa (bywa tak w przeglądarce), '
            'skorzystaj z pól ręcznych — efekt jest taki sam.',
      ),
      HelpTopic(
        'Kto widzi propozycje',
        'Tylko Para Młoda. Nie ma publicznej listy ani głosowania, więc nikt nie '
            'podejrzy, co zaproponowali inni.',
      ),
    ],
  ),
  HelpCategory(
    title: 'Harmonogram',
    icon: Icons.event_outlined,
    topics: [
      HelpTopic(
        'Plan dnia',
        'Godzina po godzinie: ceremonia, przyjęcie, tort, pierwszy taniec. '
            'U góry zobaczysz licznik dni do wesela.',
      ),
    ],
  ),
  HelpCategory(
    title: 'Gry',
    icon: Icons.casino_outlined,
    topics: [
      HelpTopic(
        'Quiz, Prawda/Fałsz, Zgadnij zdjęcie',
        'Odpowiedz na wszystkie pytania i wyślij wynik. Możesz podejść ponownie '
            '— nowy wynik zastąpi poprzedni, więc nic nie tracisz.',
      ),
      HelpTopic(
        'Foto-wyzwania',
        'Lista zadań fotograficznych. Do każdego wyzwania wysyłasz jedno '
            'zdjęcie; kolejne zastąpi poprzednie. Zdjęcia widzą wszyscy goście.',
      ),
      HelpTopic(
        'Ślubne Bingo',
        'Skreślaj pola, gdy zobaczysz je na weselu. Skreślenia zostają na Twoim '
            'telefonie — wyślij zgłoszenie dopiero, gdy uzbierasz komplet.',
      ),
      HelpTopic(
        'Kto widzi wyniki',
        'Wyłącznie Para Młoda. Nie ma publicznego rankingu, więc graj dla '
            'zabawy, a nie dla rywalizacji.',
      ),
    ],
  ),
  HelpCategory(
    title: 'Pamiątki',
    icon: Icons.favorite_outline,
    topics: [
      HelpTopic(
        'Księga gości i rady',
        'Zostaw życzenia albo dobrą radę dla Pary Młodej. Wpisów możesz dodać '
            'kilka, a widzą je też inni goście — to trochę wspólna kronika.',
      ),
      HelpTopic(
        'Kapsuła czasu',
        'Prywatna wiadomość do Pary Młodej. Nie zobaczy jej żaden inny gość.',
      ),
      HelpTopic(
        'Mapa gości',
        'Zaznacz, skąd przyjeżdżasz. Jedna pinezka na gościa — możesz ją '
            'poprawić, wracając do sekcji.',
      ),
    ],
  ),
  HelpCategory(
    title: 'Prywatność',
    icon: Icons.lock_outline,
    topics: [
      HelpTopic(
        'Co widzi Para Młoda',
        'Twoje potwierdzenie obecności, wpisy, zdjęcia, propozycje muzyczne '
            'i wyniki gier — zawsze z imieniem, które podasz.',
      ),
      HelpTopic(
        'Czego nie widzą inni goście',
        'Twojego potwierdzenia obecności, wiadomości do kapsuły czasu, '
            'propozycji muzycznych ani wyników gier. Publiczne są tylko: księga '
            'gości, rady, mapa, galeria i zdjęcia z foto-wyzwań.',
      ),
    ],
  ),
];
