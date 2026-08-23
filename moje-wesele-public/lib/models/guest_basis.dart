import 'dart:math';

import 'wedding_data.dart';

/// Jedyne miejsce liczące „efektywną liczbę gości" dla całego budżetu
/// (catering, obsługa, sala, napoje, prezenty dla gości).
///
/// `effective = MAX(zaproszeni, minimum sali, planowani)` — jedna liczba,
/// bez przełączników „licz nieprzypisanych"/„licz wirtualnych": te dwa
/// dotychczasowe mechanizmy dublowały ludzi już policzonych w „zaproszeni"
/// (nieprzypisani są PODZBIOREM zaproszonych) albo dokładały „wirtualnych"
/// do minimum sali w oderwaniu od realnej liczby zaproszonych, co zawyżało
/// koszt, gdy zaproszeni i tak już pokrywali minimum.
///
/// [assigned]/[unassigned] zostają WYŁĄCZNIE jako informacja („X gości bez
/// przypisanego stołu") — nie wpływają na [effective] ani na żaden koszt.
///
/// Sala/catering/obsługa używają [effective] bezwarunkowo. Napoje i prezenty
/// dla gości zachowują własny wybór „realni goście" vs „z dopłatą do
/// minimum sali" — to NIE jest ten sam błąd (minimum sali nie jest
/// podzbiorem zaproszonych, więc nie ma dublowania) — ale wariant „z dopłatą"
/// ma wołać [effective] stąd, zamiast liczyć to samo osobno.
class GuestBasis {
  const GuestBasis({
    required this.invited,
    required this.assigned,
    required this.unassigned,
    required this.venueMinGuests,
    required this.plannedGuests,
    required this.effective,
  });

  /// Wszyscy zaproszeni (lista Gości), niezależnie od przypisania do stołu.
  final int invited;

  /// Zaproszeni przypisani do stołu. Informacyjne.
  final int assigned;

  /// Zaproszeni BEZ przypisanego stołu. Informacyjne — zero wpływu na koszt.
  final int unassigned;

  /// Minimalna liczba osób wymagana przez salę (`budgetData.venueMinGuests`).
  final double venueMinGuests;

  /// Szacunek pary, zanim zna pełną listę gości (`budgetData.plannedGuests`).
  final double plannedGuests;

  /// `max(invited, venueMinGuests, plannedGuests)` — liczba do wszystkich
  /// przeliczeń per-osobę w budżecie.
  final double effective;

  /// O ile [effective] przewyższa realnie zaproszonych — czyli „dopłata"
  /// do minimum sali / do planu, gdy jeszcze nie ma tylu gości na liście.
  /// Wyłącznie informacyjne.
  double get paddingOverInvited => max(0.0, effective - invited);

  factory GuestBasis.from(WeddingData? data) {
    if (data == null) return empty;

    final raw = data.raw;
    final bd = raw['budgetData'];
    final budget = bd is Map ? bd : const <String, dynamic>{};
    final guests = data.guests;

    final invited = guests.length;
    final assigned =
        guests.where((g) => g is Map && g['tableId'] != null).length;
    final unassigned = invited - assigned;

    final venueMin = _d(budget['venueMinGuests']);
    final planned = _d(budget['plannedGuests']);

    final effective =
        [invited.toDouble(), venueMin, planned].reduce(max);

    return GuestBasis(
      invited: invited,
      assigned: assigned,
      unassigned: unassigned,
      venueMinGuests: venueMin,
      plannedGuests: planned,
      effective: effective,
    );
  }

  static const GuestBasis empty = GuestBasis(
    invited: 0,
    assigned: 0,
    unassigned: 0,
    venueMinGuests: 0,
    plannedGuests: 0,
    effective: 0,
  );

  static double _d(dynamic v) => v is num ? v.toDouble() : 0.0;
}
