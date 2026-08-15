import 'package:flutter/material.dart';

import '../l10n/app_text.dart';
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
// TREŚĆ POMOCY
//
// Gettery, nie stałe: teksty są tłumaczone, więc muszą powstawać po każdej
// zmianie języka na nowo. Podział na warianty ról ([OnbVariant]) zostaje
// bez zmian — właściciel, planer (panel + rozdział o pracy z klientami)
// i gość mają osobne zestawy kategorii.
// ═══════════════════════════════════════════════════════════════════════════

/// Panel organizatora — wspólny dla właściciela i planera.
List<HelpCategory> get _ownerHelp => [
  HelpCategory(
    title: AppText.t.help_start_title,
    icon: Icons.dashboard_outlined,
    topics: [
      HelpTopic(AppText.t.help_start_1Title, AppText.t.help_start_1Body),
      HelpTopic(AppText.t.help_start_2Title, AppText.t.help_start_2Body),
      HelpTopic(AppText.t.help_start_3Title, AppText.t.help_start_3Body),
    ],
  ),
  HelpCategory(
    title: AppText.t.help_guests_title,
    icon: Icons.people_outline,
    topics: [
      HelpTopic(AppText.t.help_guests_1Title, AppText.t.help_guests_1Body),
      HelpTopic(AppText.t.help_guests_2Title, AppText.t.help_guests_2Body),
      HelpTopic(AppText.t.help_guests_3Title, AppText.t.help_guests_3Body),
      HelpTopic(AppText.t.help_guests_4Title, AppText.t.help_guests_4Body),
    ],
  ),
  HelpCategory(
    title: AppText.t.help_budget_title,
    icon: Icons.savings_outlined,
    topics: [
      HelpTopic(AppText.t.help_budget_1Title, AppText.t.help_budget_1Body),
      HelpTopic(AppText.t.help_budget_2Title, AppText.t.help_budget_2Body),
      HelpTopic(AppText.t.help_budget_3Title, AppText.t.help_budget_3Body),
      HelpTopic(AppText.t.help_budget_4Title, AppText.t.help_budget_4Body),
      HelpTopic(AppText.t.help_budget_5Title, AppText.t.help_budget_5Body),
      HelpTopic(AppText.t.help_budget_6Title, AppText.t.help_budget_6Body),
      HelpTopic(AppText.t.help_budget_7Title, AppText.t.help_budget_7Body),
    ],
  ),
  HelpCategory(
    title: AppText.t.help_room_title,
    icon: Icons.table_restaurant_outlined,
    topics: [
      HelpTopic(AppText.t.help_room_1Title, AppText.t.help_room_1Body),
      HelpTopic(AppText.t.help_room_2Title, AppText.t.help_room_2Body),
      HelpTopic(AppText.t.help_room_3Title, AppText.t.help_room_3Body),
    ],
  ),
  HelpCategory(
    title: AppText.t.help_schedule_title,
    icon: Icons.event_outlined,
    topics: [
      HelpTopic(AppText.t.help_schedule_1Title, AppText.t.help_schedule_1Body),
      HelpTopic(AppText.t.help_schedule_2Title, AppText.t.help_schedule_2Body),
      HelpTopic(AppText.t.help_schedule_3Title, AppText.t.help_schedule_3Body),
      HelpTopic(AppText.t.help_schedule_4Title, AppText.t.help_schedule_4Body),
      HelpTopic(AppText.t.help_schedule_5Title, AppText.t.help_schedule_5Body),
    ],
  ),
  HelpCategory(
    title: AppText.t.help_vendors_title,
    icon: Icons.handshake_outlined,
    topics: [
      HelpTopic(AppText.t.help_vendors_1Title, AppText.t.help_vendors_1Body),
      HelpTopic(AppText.t.help_vendors_2Title, AppText.t.help_vendors_2Body),
      HelpTopic(AppText.t.help_vendors_3Title, AppText.t.help_vendors_3Body),
    ],
  ),
  HelpCategory(
    title: AppText.t.help_guestZone_title,
    icon: Icons.groups_outlined,
    topics: [
      HelpTopic(AppText.t.help_guestZone_1Title, AppText.t.help_guestZone_1Body),
      HelpTopic(AppText.t.help_guestZone_2Title, AppText.t.help_guestZone_2Body),
      HelpTopic(AppText.t.help_guestZone_3Title, AppText.t.help_guestZone_3Body),
      HelpTopic(AppText.t.help_guestZone_4Title, AppText.t.help_guestZone_4Body),
      HelpTopic(AppText.t.help_guestZone_5Title, AppText.t.help_guestZone_5Body),
    ],
  ),
  HelpCategory(
    title: AppText.t.help_media_title,
    icon: Icons.photo_library_outlined,
    topics: [
      HelpTopic(AppText.t.help_media_1Title, AppText.t.help_media_1Body),
      HelpTopic(AppText.t.help_media_2Title, AppText.t.help_media_2Body),
    ],
  ),
  HelpCategory(
    title: AppText.t.help_games_title,
    icon: Icons.casino_outlined,
    topics: [
      HelpTopic(AppText.t.help_games_1Title, AppText.t.help_games_1Body),
      HelpTopic(AppText.t.help_games_2Title, AppText.t.help_games_2Body),
      HelpTopic(AppText.t.help_games_3Title, AppText.t.help_games_3Body),
      HelpTopic(AppText.t.help_games_4Title, AppText.t.help_games_4Body),
    ],
  ),
  HelpCategory(
    title: AppText.t.help_roles_title,
    icon: Icons.admin_panel_settings_outlined,
    topics: [
      HelpTopic(AppText.t.help_roles_1Title, AppText.t.help_roles_1Body),
      HelpTopic(AppText.t.help_roles_2Title, AppText.t.help_roles_2Body),
      HelpTopic(AppText.t.help_roles_3Title, AppText.t.help_roles_3Body),
      HelpTopic(AppText.t.help_roles_4Title, AppText.t.help_roles_4Body),
      HelpTopic(AppText.t.help_roles_5Title, AppText.t.help_roles_5Body),
      HelpTopic(AppText.t.help_roles_6Title, AppText.t.help_roles_6Body),
      HelpTopic(AppText.t.help_roles_7Title, AppText.t.help_roles_7Body),
    ],
  ),
  HelpCategory(
    title: AppText.t.help_analytics_title,
    icon: Icons.insights_outlined,
    topics: [
      HelpTopic(AppText.t.help_analytics_1Title, AppText.t.help_analytics_1Body),
    ],
  ),
  HelpCategory(
    title: AppText.t.help_settings_title,
    icon: Icons.settings_outlined,
    topics: [
      HelpTopic(AppText.t.help_settings_1Title, AppText.t.help_settings_1Body),
      HelpTopic(AppText.t.help_settings_2Title, AppText.t.help_settings_2Body),
      HelpTopic(AppText.t.help_settings_3Title, AppText.t.help_settings_3Body),
      HelpTopic(AppText.t.help_settings_4Title, AppText.t.help_settings_4Body),
    ],
  ),
];

/// Dodatek WYŁĄCZNIE dla planera (dopinany do panelu).
HelpCategory get _plannerHelp => HelpCategory(
    title: AppText.t.help_planner_title,
    icon: Icons.work_outline,
    topics: [
      HelpTopic(AppText.t.help_planner_1Title, AppText.t.help_planner_1Body),
      HelpTopic(AppText.t.help_planner_2Title, AppText.t.help_planner_2Body),
      HelpTopic(AppText.t.help_planner_3Title, AppText.t.help_planner_3Body),
      HelpTopic(AppText.t.help_planner_4Title, AppText.t.help_planner_4Body),
      HelpTopic(AppText.t.help_planner_5Title, AppText.t.help_planner_5Body),
      HelpTopic(AppText.t.help_planner_6Title, AppText.t.help_planner_6Body),
    ],
  );

/// Strefa gościa — osobny zestaw, bez panelu organizatora.
List<HelpCategory> get _guestHelp => [
  HelpCategory(
    title: AppText.t.help_gStart_title,
    icon: Icons.celebration_outlined,
    topics: [
      HelpTopic(AppText.t.help_gStart_1Title, AppText.t.help_gStart_1Body),
      HelpTopic(AppText.t.help_gStart_2Title, AppText.t.help_gStart_2Body),
    ],
  ),
  HelpCategory(
    title: AppText.t.help_gRsvp_title,
    icon: Icons.how_to_reg_outlined,
    topics: [
      HelpTopic(AppText.t.help_gRsvp_1Title, AppText.t.help_gRsvp_1Body),
      HelpTopic(AppText.t.help_gRsvp_2Title, AppText.t.help_gRsvp_2Body),
      HelpTopic(AppText.t.help_gRsvp_3Title, AppText.t.help_gRsvp_3Body),
    ],
  ),
  HelpCategory(
    title: AppText.t.help_gPhotos_title,
    icon: Icons.photo_camera_outlined,
    topics: [
      HelpTopic(AppText.t.help_gPhotos_1Title, AppText.t.help_gPhotos_1Body),
      HelpTopic(AppText.t.help_gPhotos_2Title, AppText.t.help_gPhotos_2Body),
    ],
  ),
  HelpCategory(
    title: AppText.t.help_gMusic_title,
    icon: Icons.music_note_outlined,
    topics: [
      HelpTopic(AppText.t.help_gMusic_1Title, AppText.t.help_gMusic_1Body),
      HelpTopic(AppText.t.help_gMusic_2Title, AppText.t.help_gMusic_2Body),
    ],
  ),
  HelpCategory(
    title: AppText.t.help_gSchedule_title,
    icon: Icons.event_outlined,
    topics: [
      HelpTopic(AppText.t.help_gSchedule_1Title, AppText.t.help_gSchedule_1Body),
    ],
  ),
  HelpCategory(
    title: AppText.t.help_gGames_title,
    icon: Icons.casino_outlined,
    topics: [
      HelpTopic(AppText.t.help_gGames_1Title, AppText.t.help_gGames_1Body),
      HelpTopic(AppText.t.help_gGames_2Title, AppText.t.help_gGames_2Body),
      HelpTopic(AppText.t.help_gGames_3Title, AppText.t.help_gGames_3Body),
      HelpTopic(AppText.t.help_gGames_4Title, AppText.t.help_gGames_4Body),
    ],
  ),
  HelpCategory(
    title: AppText.t.help_gKeepsakes_title,
    icon: Icons.favorite_outline,
    topics: [
      HelpTopic(AppText.t.help_gKeepsakes_1Title, AppText.t.help_gKeepsakes_1Body),
      HelpTopic(AppText.t.help_gKeepsakes_2Title, AppText.t.help_gKeepsakes_2Body),
      HelpTopic(AppText.t.help_gKeepsakes_3Title, AppText.t.help_gKeepsakes_3Body),
    ],
  ),
  HelpCategory(
    title: AppText.t.help_gPrivacy_title,
    icon: Icons.lock_outline,
    topics: [
      HelpTopic(AppText.t.help_gPrivacy_1Title, AppText.t.help_gPrivacy_1Body),
      HelpTopic(AppText.t.help_gPrivacy_2Title, AppText.t.help_gPrivacy_2Body),
    ],
  ),
];
