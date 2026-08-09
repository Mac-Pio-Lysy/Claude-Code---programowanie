import '../navigation/app_sections.dart';
import 'wedding_data.dart';

/// Poziom kreatora „Poprowadź mnie za rękę".
enum SetupLevel {
  /// Minimum, żeby aplikacja miała sens: kto, kiedy, gdzie i kto przyjdzie.
  basic,

  /// Dopracowanie: pieniądze, menu, stoły, harmonogram, strefa gości.
  advanced;

  String get label => switch (this) {
        SetupLevel.basic => 'Konfiguracja podstawowa',
        SetupLevel.advanced => 'Konfiguracja zaawansowana',
      };

  String get intro => switch (this) {
        SetupLevel.basic =>
          'Minimum, żeby ruszyć: dane wesela i pierwsi goście.',
        SetupLevel.advanced =>
          'Dopracowanie: budżet, menu, stoły, harmonogram i strefa gości. '
              'To, co masz już uzupełnione, jest odhaczone.',
      };
}

/// Pojedyncze zadanie kreatora konfiguracji (#17).
///
/// ⚠️ Stan zadania NIE JEST ZAPISYWANY. Wynika z danych wesela — [done] czyta
/// je za każdym razem od nowa. Dzięki temu:
///  • postęp jest prawdziwy także wtedy, gdy ktoś uzupełnił dane ręcznie albo
///    w wersji web, z pominięciem kreatora,
///  • stare wesela od razu widzą realny stan, bez migracji,
///  • nie ma drugiego źródła prawdy, które mogłoby się rozjechać.
///
/// Ta sama zasada co przy automatycznym liczeniu dzieci z listy gości.
class SetupTask {
  const SetupTask({
    required this.id,
    required this.label,
    required this.hint,
    required this.level,
    required this.section,
    required this.done,
    this.subTab,
  });

  /// Stały identyfikator (do kluczy widgetów i ewentualnych testów).
  final String id;

  /// Nazwa zadania — czego dotyczy.
  final String label;

  /// Podpowiedź: CO konkretnie wpisać. To odróżnia kreator od przewodnika,
  /// który mówi tylko, gdzie dana rzecz się znajduje.
  final String hint;

  final SetupLevel level;

  /// Dokąd prowadzi przycisk „Przejdź".
  final AppSection section;

  /// Podzakładka docelowa (dla sekcji z zakładkami).
  final int? subTab;

  /// Czy zadanie jest wykonane — liczone z danych wesela.
  final bool Function(WeddingData data) done;
}

/// Pełna lista zadań kreatora — najpierw podstawowe, potem zaawansowane.
List<SetupTask> buildSetupTasks() => [
      // ── PODSTAWOWA ────────────────────────────────────────────────────────
      SetupTask(
        id: 'eventName',
        label: 'Nazwa wesela',
        hint: 'Np. „Wesele Ani i Piotra" — pokazuje się w nagłówku aplikacji '
            'i na stronie dla gości.',
        level: SetupLevel.basic,
        section: AppSection.settings,
        done: (d) => _cfgText(d, 'eventName').isNotEmpty,
      ),
      SetupTask(
        id: 'weddingDate',
        label: 'Data i godzina ślubu',
        hint: 'Od daty liczy się odliczanie na pulpicie i weryfikacja gości '
            'przy dołączaniu kodem.',
        level: SetupLevel.basic,
        section: AppSection.settings,
        done: (d) => d.weddingDate != null,
      ),
      SetupTask(
        id: 'coupleType',
        label: 'Typ uroczystości',
        hint: 'Decyduje o etykietach w całej aplikacji — „Panna Młoda / Pan '
            'Młody", dwie Panny Młode, dwóch Panów Młodych albo neutralnie.',
        level: SetupLevel.basic,
        section: AppSection.settings,
        done: (d) => _cfg(d)['coupleType'] != null,
      ),
      SetupTask(
        id: 'coupleNames',
        label: 'Imiona Pary Młodej',
        hint: 'Wpisz oba imiona — używa ich podział kosztów, etykiety i lista '
            'gości.',
        level: SetupLevel.basic,
        section: AppSection.settings,
        done: _hasCoupleNames,
      ),
      SetupTask(
        id: 'ceremonyPlace',
        label: 'Miejsce ceremonii',
        hint: 'Kościół albo USC — adres zobaczą goście w harmonogramie.',
        level: SetupLevel.basic,
        section: AppSection.settings,
        done: (d) => _cfgText(d, 'ceremonyPlace').isNotEmpty,
      ),
      SetupTask(
        id: 'receptionPlace',
        label: 'Miejsce przyjęcia',
        hint: 'Nazwa i adres sali — też trafia do harmonogramu gości.',
        level: SetupLevel.basic,
        section: AppSection.settings,
        done: (d) => _cfgText(d, 'receptionPlace').isNotEmpty,
      ),
      SetupTask(
        id: 'verificationSurnames',
        label: 'Nazwisko do weryfikacji gości',
        hint: 'Nazwisko (albo oba nazwiska), które gość poda przy dołączaniu '
            'kodem. Nigdzie się nie wyświetla — służy tylko sprawdzeniu.',
        level: SetupLevel.basic,
        section: AppSection.settings,
        done: (d) => _cfgText(d, 'verificationSurnames').isNotEmpty,
      ),
      SetupTask(
        id: 'guests',
        label: 'Pierwsi goście',
        hint: 'Dodaj choć kilka osób — od listy gości zależą catering, stoły '
            'i statystyki.',
        level: SetupLevel.basic,
        section: AppSection.guests,
        subTab: 0,
        done: (d) => d.guests.isNotEmpty,
      ),

      // ── ZAAWANSOWANA ──────────────────────────────────────────────────────
      SetupTask(
        id: 'budgetTotal',
        label: 'Budżet planowany',
        hint: 'Kwota, w której chcecie się zmieścić. Bez niej nie ma z czym '
            'porównywać wydatków.',
        level: SetupLevel.advanced,
        section: AppSection.budget,
        subTab: 0,
        done: (d) => d.budgetTotal > 0,
      ),
      SetupTask(
        id: 'pricePerPerson',
        label: 'Cena za osobę (sala)',
        hint: 'Stawka od talerza — mnoży się przez liczbę gości i daje koszt '
            'cateringu.',
        level: SetupLevel.advanced,
        section: AppSection.budget,
        subTab: 1,
        done: (d) => _num(_budget(d)['pricePerPerson']) > 0,
      ),
      SetupTask(
        id: 'withChildren',
        label: 'Decyzja o dzieciach',
        hint: 'Ustal, czy na weselu będą dzieci. Jeśli tak, dojdzie menu '
            'dziecięce, stół dla dzieci i wyłączenie ich z przeliczeń alkoholu.',
        level: SetupLevel.advanced,
        section: AppSection.budget,
        subTab: 1,
        // Sam zapis decyzji wystarczy — „nie ma dzieci" to też odpowiedź.
        done: (d) => _budget(d).containsKey('withChildren'),
      ),
      SetupTask(
        id: 'menuOptions',
        label: 'Słownik menu',
        hint: 'Warianty dania do wyboru przy gościach (mięsne, rybne, wege, '
            'dla dziecka).',
        level: SetupLevel.advanced,
        section: AppSection.settings,
        done: (d) => _list(_cfg(d)['menuOptions']).isNotEmpty,
      ),
      SetupTask(
        id: 'expenseCategories',
        label: 'Kategorie wydatków',
        hint: 'Własne kategorie kosztów — po nich grupują się wydatki '
            'i wykresy w Analityce.',
        level: SetupLevel.advanced,
        section: AppSection.settings,
        done: (d) => _list(_cfg(d)['expenseCategories']).isNotEmpty,
      ),
      SetupTask(
        id: 'witnesses',
        label: 'Świadkowie',
        hint: 'Oznacz świadków na liście gości — pojawią się w podsumowaniu '
            'i na planie sali.',
        level: SetupLevel.advanced,
        section: AppSection.guests,
        subTab: 0,
        done: (d) => _anyGuest(d, (g) {
          final w = g['witness'];
          return w is String && w.isNotEmpty;
        }),
      ),
      SetupTask(
        id: 'tables',
        label: 'Stoły',
        hint: 'Dodaj stoły z liczbą miejsc — bez nich nie da się rozsadzić '
            'gości.',
        level: SetupLevel.advanced,
        section: AppSection.room,
        done: (d) => d.tables.isNotEmpty,
      ),
      SetupTask(
        id: 'seating',
        label: 'Rozsadzenie gości',
        hint: 'Przypisz gości do stołów — choćby część. Resztę dokończysz '
            'bliżej wesela.',
        level: SetupLevel.advanced,
        section: AppSection.room,
        done: (d) => _anyGuest(d, (g) => g['tableId'] != null),
      ),
      SetupTask(
        id: 'schedule',
        label: 'Harmonogram dnia',
        hint: 'Punkty programu z godzinami. Ten sam harmonogram widzą goście '
            'w swojej strefie.',
        level: SetupLevel.advanced,
        section: AppSection.schedule,
        subTab: 0,
        done: (d) => d.scheduleEvents.isNotEmpty,
      ),
      SetupTask(
        id: 'guestVisibility',
        label: 'Widoczność sekcji dla gości',
        hint: 'Zdecyduj, co i od kiedy widzą goście — np. RSVP od razu, '
            'a galerię dopiero w dniu wesela.',
        level: SetupLevel.advanced,
        section: AppSection.settings,
        done: (d) => d.raw['guestVisibility'] is Map,
      ),
    ];

// ── Pomocnicze odczyty (odporne na braki i inne typy w danych) ────────────

Map<dynamic, dynamic> _cfg(WeddingData d) {
  final cfg = d.raw['appConfig'];
  return cfg is Map ? cfg : const {};
}

Map<dynamic, dynamic> _budget(WeddingData d) {
  final bd = d.raw['budgetData'];
  return bd is Map ? bd : const {};
}

String _cfgText(WeddingData d, String key) =>
    (_cfg(d)[key] as String?)?.trim() ?? '';

List<dynamic> _list(dynamic v) => v is List ? v : const [];

double _num(dynamic v) => v is num ? v.toDouble() : 0;

/// Czy imiona Pary Młodej są uzupełnione — wartości zastępcze się nie liczą.
bool _hasCoupleNames(WeddingData d) {
  final names = _list(_budget(d)['coupleNames']);
  var filled = 0;
  for (var i = 0; i < names.length && i < 2; i++) {
    final v = names[i]?.toString().trim() ?? '';
    if (v.isNotEmpty && v != 'Osoba 1' && v != 'Osoba 2') filled++;
  }
  return filled >= 2;
}

bool _anyGuest(WeddingData d, bool Function(Map<dynamic, dynamic> g) test) {
  for (final g in d.guests) {
    if (g is Map && test(g)) return true;
  }
  return false;
}

/// Postęp kreatora dla wybranego poziomu.
class SetupProgress {
  const SetupProgress({required this.done, required this.total});

  final int done;
  final int total;

  int get left => total - done;
  double get ratio => total == 0 ? 0 : done / total;
  bool get complete => total > 0 && done == total;
}

/// Liczy postęp dla listy zadań.
SetupProgress setupProgress(List<SetupTask> tasks, WeddingData? data) {
  if (data == null) return SetupProgress(done: 0, total: tasks.length);
  var done = 0;
  for (final t in tasks) {
    if (t.done(data)) done++;
  }
  return SetupProgress(done: done, total: tasks.length);
}
