import 'dart:math';

import 'wedding_data.dart';

/// Pozycja obsługi (kelnerzy, fotograf, DJ…) — `staffTables` (współdzielone
/// z planem sali). `{id, name, persons, includeInCost, posX, posY}`.
class StaffEntry {
  StaffEntry(this.raw);
  final Map<String, dynamic> raw;

  int get id => (raw['id'] as num?)?.toInt() ?? 0;
  String get name => (raw['name'] as String?)?.trim() ?? '';
  int get persons => (raw['persons'] as num?)?.toInt() ?? 0;
  bool get includeInCost => raw['includeInCost'] == true;
}

/// Obliczenia podzakładki „Sala" — odwzorowane z funkcji `calcCatering*` /
/// `getEffectiveGuestCount` w zrodlo-web/script.js, rozszerzone o trzy osobno
/// liczone grupy: goście przypisani, goście nieprzypisani (opcjonalnie) oraz
/// obsługa (własna stawka).
class SalaSummary {
  const SalaSummary({
    required this.pricePerPerson,
    required this.staffPricePerPerson,
    required this.staffRate,
    required this.venueMinGuests,
    required this.includeVirtual,
    required this.includeUnassigned,
    required this.includeStaff,
    required this.guestCount,
    required this.assignedCount,
    required this.unassignedCount,
    required this.guestBilledCount,
    required this.guestCost,
    required this.virtualGuests,
    required this.virtualCost,
    required this.staffPersonCount,
    required this.staffCostPersonCount,
    required this.staffCost,
    required this.staff,
    required this.effectiveGuestCount,
    required this.menuAddonsTotal,
    required this.honorDecoTotal,
    required this.regularDecoTotal,
    required this.regularTableCount,
    required this.cateringTotal,
  });

  final double pricePerPerson;

  /// Stawka obsługi (zapisana, 0 = brak — wtedy używana jest [pricePerPerson]).
  final double staffPricePerPerson;

  /// Efektywna stawka obsługi (staffPricePerPerson albo pricePerPerson).
  final double staffRate;

  final double venueMinGuests;
  final bool includeVirtual;
  final bool includeUnassigned;
  final bool includeStaff;

  /// Wszyscy goście (przypisani + nieprzypisani).
  final int guestCount;

  /// Goście przypisani do stołów.
  final int assignedCount;

  /// Goście bez przypisanego stołu.
  final int unassignedCount;

  /// Liczba gości wliczana do kosztu (przypisani + nieprzypisani gdy włączone).
  final double guestBilledCount;
  final double guestCost;

  final double virtualGuests;
  final double virtualCost;

  /// Łączna liczba osób obsługi.
  final double staffPersonCount;

  /// Obsługa oznaczona „w kosztach" (`includeInCost`).
  final double staffCostPersonCount;

  /// Koszt obsługi (gdy [includeStaff]).
  final double staffCost;

  /// Lista pozycji obsługi (do zarządzania w UI).
  final List<StaffEntry> staff;

  /// Liczba osób do przeliczeń per-osoba (dodatki do menu).
  final double effectiveGuestCount;

  final double menuAddonsTotal;
  final double honorDecoTotal;
  final double regularDecoTotal;
  final int regularTableCount;
  final double cateringTotal;

  double get tableDecoTotal => honorDecoTotal + regularDecoTotal;

  factory SalaSummary.from(WeddingData? data) {
    if (data == null) return _empty;

    final raw = data.raw;
    final bd = _asMap(raw['budgetData']);
    final guests = data.guests;
    final tables = data.tables;

    final pricePerPerson = _d(bd['pricePerPerson']);
    final staffPricePerPerson = _d(bd['staffPricePerPerson']);
    final staffRate = staffPricePerPerson > 0 ? staffPricePerPerson : pricePerPerson;

    final guestCount = guests.length;
    final assigned =
        guests.where((g) => g is Map && g['tableId'] != null).length;
    final unassigned = guestCount - assigned;

    final venueMin = _d(bd['venueMinGuests']);
    final virtual = max(0.0, venueMin - assigned);

    // Domyślnie liczymy nieprzypisanych (zgodnie z dotychczasową bazą cateringu
    // = wszyscy goście). Można wyłączyć.
    final includeUnassigned = bd['includeUnassignedInCalc'] != false;
    final includeVirtual = bd['includeVirtualInCalc'] == true;
    final includeStaff = bd['includeStaffInCalc'] == true;

    final guestBilledCount =
        assigned + (includeUnassigned ? unassigned : 0);
    final guestCost = guestBilledCount * pricePerPerson;
    final virtualCost = (includeVirtual ? virtual : 0.0) * pricePerPerson;

    final staffList = (raw['staffTables'] is List)
        ? (raw['staffTables'] as List)
            .whereType<Map>()
            .map((e) => StaffEntry(Map<String, dynamic>.from(e)))
            .toList()
        : <StaffEntry>[];
    final staffPersonCount =
        staffList.fold<double>(0, (s, t) => s + t.persons);
    final staffCostPersonCount = staffList.fold<double>(
        0, (s, t) => s + (t.includeInCost ? t.persons : 0));
    final staffCost = (includeStaff ? staffCostPersonCount : 0.0) * staffRate;

    // Liczba osób do dodatków per-osoba: wliczeni goście + wirtualni + obsługa.
    final effectiveGuestCount = guestBilledCount +
        (includeVirtual ? virtual : 0.0) +
        (includeStaff ? staffPersonCount : 0.0);

    final menuAddonsTotal =
        _sum(bd['menuAddons'], (a) => _d(a['pricePerPerson'])) *
            effectiveGuestCount;

    final regularTableCount =
        tables.where((t) => t is Map && t['isHonorTable'] != true).length;
    final tableDeco = _asMap(bd['tableDeco']);
    final honorDeco = _sum(tableDeco['honorAddons'], (a) => _d(a['price']));
    final regularDeco =
        _sum(tableDeco['regularAddons'], (a) => _d(a['pricePerTable'])) *
            regularTableCount;

    final cateringTotal = guestCost +
        virtualCost +
        staffCost +
        menuAddonsTotal +
        honorDeco +
        regularDeco;

    return SalaSummary(
      pricePerPerson: pricePerPerson,
      staffPricePerPerson: staffPricePerPerson,
      staffRate: staffRate,
      venueMinGuests: venueMin,
      includeVirtual: includeVirtual,
      includeUnassigned: includeUnassigned,
      includeStaff: includeStaff,
      guestCount: guestCount,
      assignedCount: assigned,
      unassignedCount: unassigned,
      guestBilledCount: guestBilledCount.toDouble(),
      guestCost: guestCost,
      virtualGuests: virtual,
      virtualCost: virtualCost,
      staffPersonCount: staffPersonCount,
      staffCostPersonCount: staffCostPersonCount,
      staffCost: staffCost,
      staff: staffList,
      effectiveGuestCount: effectiveGuestCount,
      menuAddonsTotal: menuAddonsTotal,
      honorDecoTotal: honorDeco,
      regularDecoTotal: regularDeco,
      regularTableCount: regularTableCount,
      cateringTotal: cateringTotal,
    );
  }

  static const _empty = SalaSummary(
    pricePerPerson: 0,
    staffPricePerPerson: 0,
    staffRate: 0,
    venueMinGuests: 0,
    includeVirtual: false,
    includeUnassigned: true,
    includeStaff: false,
    guestCount: 0,
    assignedCount: 0,
    unassignedCount: 0,
    guestBilledCount: 0,
    guestCost: 0,
    virtualGuests: 0,
    virtualCost: 0,
    staffPersonCount: 0,
    staffCostPersonCount: 0,
    staffCost: 0,
    staff: [],
    effectiveGuestCount: 0,
    menuAddonsTotal: 0,
    honorDecoTotal: 0,
    regularDecoTotal: 0,
    regularTableCount: 0,
    cateringTotal: 0,
  );

  static double _d(dynamic v) => v is num ? v.toDouble() : 0.0;

  static Map<String, dynamic> _asMap(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  static double _sum(dynamic list, double Function(Map) f) {
    if (list is! List) return 0;
    var s = 0.0;
    for (final e in list) {
      if (e is Map) s += f(e);
    }
    return s;
  }
}
