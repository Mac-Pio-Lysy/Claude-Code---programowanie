import 'guest.dart';

/// Pomocnicze opisy i agregaty dla Podsumowania gości
/// (odwzorowane z `_guestSummaryStats` / `_gs*` w zrodlo-web/script.js).
class GuestSummary {
  GuestSummary._();

  /// Status RSVP gościa na podstawie ostatniego wpisu.
  static String rsvpStatus(int? guestId, List<dynamic> entries) {
    String? status;
    for (final e in entries) {
      if (e is Map && (e['guestId'] as num?)?.toInt() == guestId) {
        status = e['status'] as String?;
      }
    }
    return status ?? '';
  }

  static String rsvpLabel(String status) => switch (status) {
        'attending' => 'Przyjdzie',
        'not_attending' => 'Nie przyjdzie',
        _ => 'Brak odpowiedzi',
      };

  /// Opis transportu: „Własny" / typ pojazdu / „—".
  static (bool has, bool own, String label) transport(
      Guest g, List<dynamic> vehicles) {
    if (g.raw['ownTransport'] == true) return (true, true, 'Własny');
    final vid = (g.raw['vehicleId'] as num?)?.toInt();
    for (final v in vehicles) {
      if (v is! Map) continue;
      final id = (v['id'] as num?)?.toInt();
      final ids = (v['guestIds'] is List)
          ? (v['guestIds'] as List)
              .map((e) => (e as num?)?.toInt())
              .whereType<int>()
          : const <int>[];
      if (id == vid || ids.contains(g.id)) {
        final type = (v['type'] as String?)?.trim();
        return (true, false, type?.isNotEmpty == true ? type! : 'Zorganizowany');
      }
    }
    return (false, false, '—');
  }

  /// Opis noclegu: nazwa hotelu / status / „—".
  static (bool needs, String label) accommodation(
      Guest g, List<dynamic> hotels) {
    if (g.raw['needsAccommodation'] != true) return (false, '—');
    final hid = (g.raw['hotelId'] as num?)?.toInt();
    if (hid != null) {
      for (final h in hotels) {
        if (h is Map && (h['id'] as num?)?.toInt() == hid) {
          final name = (h['name'] as String?)?.trim();
          if (name?.isNotEmpty == true) return (true, name!);
        }
      }
    }
    final st = g.raw['accommodationStatus'] as String?;
    return (true, switch (st) {
      'reserved' => 'Zarezerwowany',
      'pending' => 'Do zarezerwowania',
      'self' => 'Sam rezerwuje',
      _ => 'Potrzebuje',
    });
  }

  static String companion(Guest g) {
    if (!g.hasCompanion) return '—';
    return g.companionName.isNotEmpty ? g.companionName : '+1';
  }

  static String tableName(Guest g, List<dynamic> tables) {
    final tid = g.tableId;
    if (tid == null) return '—';
    for (final t in tables) {
      if (t is Map && (t['id'] as num?)?.toInt() == tid) {
        return (t['name'] as String?) ?? 'Stół';
      }
    }
    return '—';
  }

  /// Typ diety (jeśli inny niż standardowa) + alergie/nietolerancje.
  static String dietAllergies(Guest g) {
    final parts = <String>[];
    if (g.diet != 'standard') {
      parts.add(GuestOptions.dietLabel(g.diet, g.dietOther));
    }
    if (g.allergies.isNotEmpty) parts.add(g.allergies);
    return parts.isEmpty ? '—' : parts.join(' · ');
  }
}

/// Agregaty Podsumowania gości.
class GuestSummaryStats {
  GuestSummaryStats({
    required this.menu,
    required this.noMenu,
    required this.diet,
    required this.transOwn,
    required this.transOrg,
    required this.transNone,
    required this.accomNeeds,
    required this.accomAssigned,
    required this.attending,
    required this.notAttending,
    required this.noRsvp,
    required this.total,
  });

  final Map<String, int> menu;
  final int noMenu;

  /// Liczba gości wg typu diety (etykieta → liczba).
  final Map<String, int> diet;
  final int transOwn;
  final int transOrg;
  final int transNone;
  final int accomNeeds;
  final int accomAssigned;
  final int attending;
  final int notAttending;
  final int noRsvp;
  final int total;

  factory GuestSummaryStats.from(
    List<Guest> guests,
    List<dynamic> vehicles,
    List<dynamic> hotels,
    List<dynamic> rsvpEntries,
  ) {
    final menu = <String, int>{};
    final diet = <String, int>{};
    var noMenu = 0, transOwn = 0, transOrg = 0, transNone = 0;
    var accomNeeds = 0, accomAssigned = 0, att = 0, notAtt = 0, noRsvp = 0;

    for (final g in guests) {
      final m = g.menuChoice.trim();
      if (m.isNotEmpty) {
        menu[m] = (menu[m] ?? 0) + 1;
      } else {
        noMenu++;
      }

      final dietLabel = GuestOptions.dietLabel(g.diet, g.dietOther);
      diet[dietLabel] = (diet[dietLabel] ?? 0) + 1;

      final t = GuestSummary.transport(g, vehicles);
      if (t.$2) {
        transOwn++;
      } else if (t.$1) {
        transOrg++;
      } else {
        transNone++;
      }

      final a = GuestSummary.accommodation(g, hotels);
      if (a.$1) {
        accomNeeds++;
        if (g.raw['hotelId'] != null) accomAssigned++;
      }

      final st = GuestSummary.rsvpStatus(g.id, rsvpEntries);
      if (st == 'attending') {
        att++;
      } else if (st == 'not_attending') {
        notAtt++;
      } else {
        noRsvp++;
      }
    }

    return GuestSummaryStats(
      menu: menu,
      noMenu: noMenu,
      diet: diet,
      transOwn: transOwn,
      transOrg: transOrg,
      transNone: transNone,
      accomNeeds: accomNeeds,
      accomAssigned: accomAssigned,
      attending: att,
      notAttending: notAtt,
      noRsvp: noRsvp,
      total: guests.length,
    );
  }
}
