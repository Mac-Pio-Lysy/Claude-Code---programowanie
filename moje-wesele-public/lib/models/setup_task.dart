import '../l10n/app_text.dart';
import '../navigation/app_sections.dart';
import 'wedding_data.dart';

/// Poziom kreatora „Poprowadź mnie za rękę".
enum SetupLevel {
  /// Minimum, żeby aplikacja miała sens: kto, kiedy, gdzie i kto przyjdzie.
  basic,

  /// Dopracowanie: pieniądze, menu, stoły, harmonogram, strefa gości.
  advanced;

  String get label => switch (this) {
        SetupLevel.basic => AppText.t.setupLevel_basic,
        SetupLevel.advanced => AppText.t.setupLevel_advanced,
      };

  String get intro => switch (this) {
        SetupLevel.basic => AppText.t.setupLevel_basicIntro,
        SetupLevel.advanced => AppText.t.setupLevel_advancedIntro,
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
        label: AppText.t.setupTask_eventNameLabel,
        hint: AppText.t.setupTask_eventNameHint,
        level: SetupLevel.basic,
        section: AppSection.settings,
        done: (d) => _cfgText(d, 'eventName').isNotEmpty,
      ),
      SetupTask(
        id: 'weddingDate',
        label: AppText.t.setupTask_weddingDateLabel,
        hint: AppText.t.setupTask_weddingDateHint,
        level: SetupLevel.basic,
        section: AppSection.settings,
        done: (d) => d.weddingDate != null,
      ),
      SetupTask(
        id: 'coupleType',
        label: AppText.t.setupTask_coupleTypeLabel,
        hint: AppText.t.setupTask_coupleTypeHint,
        level: SetupLevel.basic,
        section: AppSection.settings,
        done: (d) => _cfg(d)['coupleType'] != null,
      ),
      SetupTask(
        id: 'coupleNames',
        label: AppText.t.setupTask_coupleNamesLabel,
        hint: AppText.t.setupTask_coupleNamesHint,
        level: SetupLevel.basic,
        section: AppSection.settings,
        done: _hasCoupleNames,
      ),
      SetupTask(
        id: 'ceremonyPlace',
        label: AppText.t.setupTask_ceremonyPlaceLabel,
        hint: AppText.t.setupTask_ceremonyPlaceHint,
        level: SetupLevel.basic,
        section: AppSection.settings,
        done: (d) => _cfgText(d, 'ceremonyPlace').isNotEmpty,
      ),
      SetupTask(
        id: 'receptionPlace',
        label: AppText.t.setupTask_receptionPlaceLabel,
        hint: AppText.t.setupTask_receptionPlaceHint,
        level: SetupLevel.basic,
        section: AppSection.settings,
        done: (d) => _cfgText(d, 'receptionPlace').isNotEmpty,
      ),
      SetupTask(
        id: 'verificationSurnames',
        label: AppText.t.setupTask_verificationSurnamesLabel,
        hint: AppText.t.setupTask_verificationSurnamesHint,
        level: SetupLevel.basic,
        section: AppSection.settings,
        done: (d) => _cfgText(d, 'verificationSurnames').isNotEmpty,
      ),
      SetupTask(
        id: 'guests',
        label: AppText.t.setupTask_guestsLabel,
        hint: AppText.t.setupTask_guestsHint,
        level: SetupLevel.basic,
        section: AppSection.guests,
        subTab: 0,
        done: (d) => d.guests.isNotEmpty,
      ),

      // ── ZAAWANSOWANA ──────────────────────────────────────────────────────
      SetupTask(
        id: 'budgetTotal',
        label: AppText.t.setupTask_budgetTotalLabel,
        hint: AppText.t.setupTask_budgetTotalHint,
        level: SetupLevel.advanced,
        section: AppSection.budget,
        subTab: 0,
        done: (d) => d.budgetTotal > 0,
      ),
      SetupTask(
        id: 'pricePerPerson',
        label: AppText.t.setupTask_pricePerPersonLabel,
        hint: AppText.t.setupTask_pricePerPersonHint,
        level: SetupLevel.advanced,
        section: AppSection.budget,
        subTab: 1,
        done: (d) => _num(_budget(d)['pricePerPerson']) > 0,
      ),
      SetupTask(
        id: 'withChildren',
        label: AppText.t.setupTask_withChildrenLabel,
        hint: AppText.t.setupTask_withChildrenHint,
        level: SetupLevel.advanced,
        section: AppSection.budget,
        subTab: 1,
        // Sam zapis decyzji wystarczy — „nie ma dzieci" to też odpowiedź.
        done: (d) => _budget(d).containsKey('withChildren'),
      ),
      SetupTask(
        id: 'menuOptions',
        label: AppText.t.setupTask_menuOptionsLabel,
        hint: AppText.t.setupTask_menuOptionsHint,
        level: SetupLevel.advanced,
        section: AppSection.settings,
        done: (d) => _list(_cfg(d)['menuOptions']).isNotEmpty,
      ),
      SetupTask(
        id: 'expenseCategories',
        label: AppText.t.setupTask_expenseCategoriesLabel,
        hint: AppText.t.setupTask_expenseCategoriesHint,
        level: SetupLevel.advanced,
        section: AppSection.settings,
        done: (d) => _list(_cfg(d)['expenseCategories']).isNotEmpty,
      ),
      SetupTask(
        id: 'witnesses',
        label: AppText.t.setupTask_witnessesLabel,
        hint: AppText.t.setupTask_witnessesHint,
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
        label: AppText.t.setupTask_tablesLabel,
        hint: AppText.t.setupTask_tablesHint,
        level: SetupLevel.advanced,
        section: AppSection.room,
        done: (d) => d.tables.isNotEmpty,
      ),
      SetupTask(
        id: 'seating',
        label: AppText.t.setupTask_seatingLabel,
        hint: AppText.t.setupTask_seatingHint,
        level: SetupLevel.advanced,
        section: AppSection.room,
        done: (d) => _anyGuest(d, (g) => g['tableId'] != null),
      ),
      SetupTask(
        id: 'schedule',
        label: AppText.t.setupTask_scheduleLabel,
        hint: AppText.t.setupTask_scheduleHint,
        level: SetupLevel.advanced,
        section: AppSection.schedule,
        subTab: 0,
        done: (d) => d.scheduleEvents.isNotEmpty,
      ),
      SetupTask(
        id: 'guestVisibility',
        label: AppText.t.setupTask_guestVisibilityLabel,
        hint: AppText.t.setupTask_guestVisibilityHint,
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
