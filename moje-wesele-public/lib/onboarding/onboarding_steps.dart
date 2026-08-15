import 'package:flutter/widgets.dart';

import '../l10n/app_text.dart';
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

/// Opisy sekcji — wariant WŁAŚCICIELA (i współorganizatora).
///
/// Getter, nie stała: teksty są tłumaczone i muszą powstawać na nowo po
/// każdej zmianie języka.
Map<AppSection, String> get _sectionDesc => {
      AppSection.dashboard: AppText.t.onb_desc_dashboard,
      AppSection.guests: AppText.t.onb_desc_guests,
      AppSection.budget: AppText.t.onb_desc_budget,
      AppSection.room: AppText.t.onb_desc_room,
      AppSection.schedule: AppText.t.onb_desc_schedule,
      AppSection.tasks: AppText.t.onb_desc_tasks,
      AppSection.vendors: AppText.t.onb_desc_vendors,
      AppSection.transport: AppText.t.onb_desc_transport,
      AppSection.accommodation: AppText.t.onb_desc_accommodation,
      AppSection.music: AppText.t.onb_desc_music,
      AppSection.gifts: AppText.t.onb_desc_gifts,
      AppSection.gallery: AppText.t.onb_desc_gallery,
      AppSection.games: AppText.t.onb_desc_games,
      AppSection.keepsakes: AppText.t.onb_desc_keepsakes,
      AppSection.analytics: AppText.t.onb_desc_analytics,
      AppSection.rsvp: AppText.t.onb_desc_rsvp,
      AppSection.settings: AppText.t.onb_desc_settings,
};

/// Podzakładki sekcji (etykieta, opis) — zgodne ze strukturą aplikacji.
Map<AppSection, List<(String, String)>> get _subTabs => {
      AppSection.guests: [
        (AppText.t.onb_sub_guests_1Title, AppText.t.onb_sub_guests_1Desc),
        (AppText.t.onb_sub_guests_2Title, AppText.t.onb_sub_guests_2Desc),
        (AppText.t.onb_sub_guests_3Title, AppText.t.onb_sub_guests_3Desc),
      ],
      AppSection.budget: [
        (AppText.t.onb_sub_budget_1Title, AppText.t.onb_sub_budget_1Desc),
        (AppText.t.onb_sub_budget_2Title, AppText.t.onb_sub_budget_2Desc),
        (AppText.t.onb_sub_budget_3Title, AppText.t.onb_sub_budget_3Desc),
        (AppText.t.onb_sub_budget_4Title, AppText.t.onb_sub_budget_4Desc),
        (AppText.t.onb_sub_budget_5Title, AppText.t.onb_sub_budget_5Desc),
        (AppText.t.onb_sub_budget_6Title, AppText.t.onb_sub_budget_6Desc),
      ],
      AppSection.schedule: [
        (AppText.t.onb_sub_schedule_1Title, AppText.t.onb_sub_schedule_1Desc),
        (AppText.t.onb_sub_schedule_2Title, AppText.t.onb_sub_schedule_2Desc),
      ],
      AppSection.gifts: [
        (AppText.t.onb_sub_gifts_1Title, AppText.t.onb_sub_gifts_1Desc),
        (AppText.t.onb_sub_gifts_2Title, AppText.t.onb_sub_gifts_2Desc),
        (AppText.t.onb_sub_gifts_3Title, AppText.t.onb_sub_gifts_3Desc),
      ],
};

/// Sekcje, które mają sterowalne podzakładki (DefaultTabController + TourTabSync).
const Set<AppSection> tabbedSections = {
  AppSection.guests,
  AppSection.budget,
  AppSection.schedule,
  AppSection.gifts,
};

/// Podsekcje Ustawień (krok pełnego trybu, bez przełączania zakładek).
List<(String, String)> get _settingsSubs => [
      (AppText.t.onb_set_1Title, AppText.t.onb_set_1Desc),
      (AppText.t.onb_set_2Title, AppText.t.onb_set_2Desc),
      (AppText.t.onb_set_3Title, AppText.t.onb_set_3Desc),
      (AppText.t.onb_set_4Title, AppText.t.onb_set_4Desc),
      (AppText.t.onb_set_5Title, AppText.t.onb_set_5Desc),
      (AppText.t.onb_set_6Title, AppText.t.onb_set_6Desc),
      (AppText.t.onb_set_7Title, AppText.t.onb_set_7Desc),
      (AppText.t.onb_set_8Title, AppText.t.onb_set_8Desc),
      (AppText.t.onb_set_9Title, AppText.t.onb_set_9Desc),
];

/// Wariant PLANERA — nadpisania opisów (kontekst „to oferujesz klientom").
/// Tam, gdzie planer widzi to samo co Para Młoda, ale znaczenie jest inne:
/// pracuje na weselu KLIENTA, często ma ich kilka naraz, a dostęp bywa
/// czasowy.
Map<AppSection, String> get _plannerDesc => {
      AppSection.dashboard: AppText.t.onb_plannerDesc_dashboard,
      AppSection.guests: AppText.t.onb_plannerDesc_guests,
      AppSection.budget: AppText.t.onb_plannerDesc_budget,
      AppSection.room: AppText.t.onb_plannerDesc_room,
      AppSection.schedule: AppText.t.onb_plannerDesc_schedule,
      AppSection.tasks: AppText.t.onb_plannerDesc_tasks,
      AppSection.vendors: AppText.t.onb_plannerDesc_vendors,
      AppSection.analytics: AppText.t.onb_plannerDesc_analytics,
      AppSection.settings: AppText.t.onb_plannerDesc_settings,
};

// ── Wariant PLANERA: kroki, których nie ma w wariancie właściciela ────────
List<OnbStep> _plannerExtraSteps() => [
      OnbStep(
        section: AppSection.dashboard,
        title: AppText.t.onb_planner_1Title,
        desc: AppText.t.onb_planner_1Desc,
        basic: true,
      ),
      OnbStep(
        section: AppSection.dashboard,
        title: AppText.t.onb_planner_2Title,
        desc: AppText.t.onb_planner_2Desc,
        basic: true,
      ),
      OnbStep(
        section: AppSection.settings,
        title: AppText.t.onb_planner_3Title,
        desc: AppText.t.onb_planner_3Desc,
      ),
    ];

// ── Wariant GOŚCIA ────────────────────────────────────────────────────────
// Gość nie ma panelu organizatora ani szyny nawigacji, więc kroki są
// wyśrodkowanymi dymkami (`nav: false`, `navigate: false`). Ten sam zestaw
// służy podglądowi „Zobacz przewodnik gościa" dla właściciela i planera.
List<OnbStep> _buildGuestSteps() => [
      OnbStep(
        section: AppSection.rsvp,
        title: AppText.t.onb_guest_1Title,
        desc: AppText.t.onb_guest_1Desc,
        basic: true,
        nav: false,
        navigate: false,
      ),
      OnbStep(
        section: AppSection.rsvp,
        title: AppText.t.onb_guest_2Title,
        desc: AppText.t.onb_guest_2Desc,
        basic: true,
        nav: false,
        navigate: false,
      ),
      OnbStep(
        section: AppSection.schedule,
        title: AppText.t.onb_guest_3Title,
        desc: AppText.t.onb_guest_3Desc,
        basic: true,
        nav: false,
        navigate: false,
      ),
      OnbStep(
        section: AppSection.gallery,
        title: AppText.t.onb_guest_4Title,
        desc: AppText.t.onb_guest_4Desc,
        basic: true,
        nav: false,
        navigate: false,
      ),
      OnbStep(
        section: AppSection.music,
        title: AppText.t.onb_guest_5Title,
        desc: AppText.t.onb_guest_5Desc,
        basic: true,
        nav: false,
        navigate: false,
      ),
      OnbStep(
        section: AppSection.games,
        title: AppText.t.onb_guest_6Title,
        desc: AppText.t.onb_guest_6Desc,
        basic: true,
        nav: false,
        navigate: false,
      ),
      OnbStep(
        section: AppSection.games,
        title: AppText.t.onb_guest_7Title,
        desc: AppText.t.onb_guest_7Desc,
        nav: false,
        navigate: false,
      ),
      OnbStep(
        section: AppSection.keepsakes,
        title: AppText.t.onb_guest_8Title,
        desc: AppText.t.onb_guest_8Desc,
        basic: true,
        nav: false,
        navigate: false,
      ),
      OnbStep(
        section: AppSection.keepsakes,
        title: AppText.t.onb_guest_9Title,
        desc: AppText.t.onb_guest_9Desc,
        nav: false,
        navigate: false,
      ),
      OnbStep(
        section: AppSection.keepsakes,
        title: AppText.t.onb_guest_10Title,
        desc: AppText.t.onb_guest_10Desc,
        nav: false,
        navigate: false,
      ),
      OnbStep(
        section: AppSection.rsvp,
        title: AppText.t.onb_guest_11Title,
        desc: AppText.t.onb_guest_11Desc,
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
      AppText.t.onb_desc_fallback(s.label);

  final steps = <OnbStep>[
    OnbStep(
        section: AppSection.dashboard,
        title: AppSection.dashboard.label,
        desc: descFor(AppSection.dashboard),
        basic: true,
        nav: true),
    OnbStep(
      section: AppSection.dashboard,
      planning: true,
      title: AppText.t.onb_planningTitle,
      desc: AppText.t.onb_planningDesc,
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
          title: AppText.t.onb_subTitle(s.label, subs[i].$1),
          desc: subs[i].$2,
        ));
      }
    }
    if (s == AppSection.gallery) {
      steps.add(OnbStep(
        section: AppSection.gallery,
        title: AppText.t.onb_qrTitle,
        desc: AppText.t.onb_qrDesc,
      ));
    }
  }

  steps.add(OnbStep(
      section: AppSection.settings,
      title: AppSection.settings.label,
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
