import 'package:flutter/material.dart';

import '../l10n/app_text.dart';

/// Wszystkie sekcje aplikacji weselnej (odpowiednik zakładek `switchView`
/// w aplikacji webowej).
enum AppSection {
  dashboard,
  guests,
  budget,
  room,
  schedule,
  tasks,
  vendors,
  transport,
  accommodation,
  music,
  gifts,
  gallery,
  games,
  keepsakes,
  analytics,
  rsvp,
  rsvpAll,
  settings,
}

/// Etykiety i ikony sekcji oraz podział na nawigację telefonu/tabletu.
///
/// Etykieta jest TŁUMACZONA; w bazie (układ paska nawigacji) zapisuje się
/// `AppSection.name`, czyli angielski identyfikator — i on się nie zmienia.
extension AppSectionMeta on AppSection {
  String get label => switch (this) {
        AppSection.dashboard => AppText.t.section_dashboard,
        AppSection.guests => AppText.t.section_guests,
        AppSection.budget => AppText.t.section_budget,
        AppSection.room => AppText.t.section_room,
        AppSection.schedule => AppText.t.section_schedule,
        AppSection.tasks => AppText.t.section_tasks,
        AppSection.vendors => AppText.t.section_vendors,
        AppSection.transport => AppText.t.section_transport,
        AppSection.accommodation => AppText.t.section_accommodation,
        AppSection.music => AppText.t.section_music,
        AppSection.gifts => AppText.t.section_gifts,
        AppSection.gallery => AppText.t.section_gallery,
        AppSection.games => AppText.t.section_games,
        AppSection.keepsakes => AppText.t.section_keepsakes,
        AppSection.analytics => AppText.t.section_analytics,
        AppSection.rsvp => AppText.t.section_rsvp,
        AppSection.rsvpAll => AppText.t.section_rsvpAll,
        AppSection.settings => AppText.t.section_settings,
      };

  IconData get icon => switch (this) {
        AppSection.dashboard => Icons.dashboard_outlined,
        AppSection.guests => Icons.people_outline,
        AppSection.budget => Icons.account_balance_wallet_outlined,
        AppSection.room => Icons.table_restaurant_outlined,
        AppSection.schedule => Icons.event_outlined,
        AppSection.tasks => Icons.checklist_outlined,
        AppSection.vendors => Icons.store_outlined,
        AppSection.transport => Icons.directions_bus_outlined,
        AppSection.accommodation => Icons.hotel_outlined,
        AppSection.music => Icons.music_note_outlined,
        AppSection.gifts => Icons.card_giftcard_outlined,
        AppSection.gallery => Icons.photo_library_outlined,
        AppSection.games => Icons.casino_outlined,
        AppSection.keepsakes => Icons.favorite_outline,
        AppSection.analytics => Icons.analytics_outlined,
        AppSection.rsvp => Icons.how_to_reg_outlined,
        AppSection.rsvpAll => Icons.list_alt_outlined,
        AppSection.settings => Icons.settings_outlined,
      };
}

// Konfiguracja paska nawigacji (które 4 sekcje i kolejność) jest teraz
// dynamiczna — patrz NavConfigService. Dashboard jest przypięty osobno
// w lewym górnym rogu (AppBar).
