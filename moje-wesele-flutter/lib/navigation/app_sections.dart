import 'package:flutter/material.dart';

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
  bingo,
  analytics,
  rsvp,
  settings,
}

/// Etykiety i ikony sekcji oraz podział na nawigację telefonu/tabletu.
extension AppSectionMeta on AppSection {
  String get label => switch (this) {
        AppSection.dashboard => 'Dashboard',
        AppSection.guests => 'Goście',
        AppSection.budget => 'Budżet',
        AppSection.room => 'Plan sali',
        AppSection.schedule => 'Harmonogram',
        AppSection.tasks => 'Zadania',
        AppSection.vendors => 'Dostawcy',
        AppSection.transport => 'Transport',
        AppSection.accommodation => 'Noclegi',
        AppSection.music => 'Muzyka',
        AppSection.gifts => 'Prezenty',
        AppSection.gallery => 'Galeria & QR',
        AppSection.bingo => 'Ślubne Bingo',
        AppSection.analytics => 'Analityka',
        AppSection.rsvp => 'Potwierdzenia',
        AppSection.settings => 'Ustawienia',
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
        AppSection.bingo => Icons.grid_on_outlined,
        AppSection.analytics => Icons.analytics_outlined,
        AppSection.rsvp => Icons.how_to_reg_outlined,
        AppSection.settings => Icons.settings_outlined,
      };
}

// Konfiguracja paska nawigacji (które 4 sekcje i kolejność) jest teraz
// dynamiczna — patrz NavConfigService. Dashboard jest przypięty osobno
// w lewym górnym rogu (AppBar).
