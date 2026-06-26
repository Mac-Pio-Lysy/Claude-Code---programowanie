import 'dart:math';

import 'wedding_data.dart';

/// Obliczenia podzakładki „Sala" (catering) — odwzorowane z funkcji
/// `calcCatering*` / `getEffectiveGuestCount` w zrodlo-web/script.js.
class SalaSummary {
  const SalaSummary({
    required this.pricePerPerson,
    required this.venueMinGuests,
    required this.includeVirtual,
    required this.guestCount,
    required this.seated,
    required this.virtualGuests,
    required this.virtualCost,
    required this.cateringBase,
    required this.effectiveGuestCount,
    required this.menuAddonsTotal,
    required this.honorDecoTotal,
    required this.regularDecoTotal,
    required this.regularTableCount,
    required this.cateringTotal,
  });

  final double pricePerPerson;
  final double venueMinGuests;
  final bool includeVirtual;
  final int guestCount;
  final int seated;
  final double virtualGuests;
  final double virtualCost;
  final double cateringBase;
  final double effectiveGuestCount;
  final double menuAddonsTotal;
  final double honorDecoTotal;
  final double regularDecoTotal;
  final int regularTableCount;
  final double cateringTotal;

  double get tableDecoTotal => honorDecoTotal + regularDecoTotal;

  factory SalaSummary.from(WeddingData? data) {
    if (data == null) {
      return const SalaSummary(
        pricePerPerson: 0,
        venueMinGuests: 0,
        includeVirtual: false,
        guestCount: 0,
        seated: 0,
        virtualGuests: 0,
        virtualCost: 0,
        cateringBase: 0,
        effectiveGuestCount: 0,
        menuAddonsTotal: 0,
        honorDecoTotal: 0,
        regularDecoTotal: 0,
        regularTableCount: 0,
        cateringTotal: 0,
      );
    }

    final raw = data.raw;
    final bd = _asMap(raw['budgetData']);
    final guests = data.guests;
    final tables = data.tables;

    final pricePerPerson = _d(bd['pricePerPerson']);
    final guestCount = guests.length;
    final cateringBase = pricePerPerson * guestCount;

    final seated = guests.where((g) => g is Map && g['tableId'] != null).length;
    final venueMin = _d(bd['venueMinGuests']);
    final virtual = max(0.0, venueMin - seated);
    final virtualCost = virtual * pricePerPerson;

    final includeVirtual = bd['includeVirtualInCalc'] == true;
    final includeStaff = bd['includeStaffInCalc'] == true;
    final staffTables = raw['staffTables'];
    final staffPersonCount = _sum(staffTables, (t) => _d(t['persons']));
    final effectiveGuestCount = seated +
        (includeVirtual && virtual > 0 ? virtual : 0.0) +
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

    final cateringTotal = cateringBase +
        virtualCost +
        (includeStaff ? staffPersonCount * pricePerPerson : 0.0) +
        menuAddonsTotal +
        honorDeco +
        regularDeco;

    return SalaSummary(
      pricePerPerson: pricePerPerson,
      venueMinGuests: venueMin,
      includeVirtual: includeVirtual,
      guestCount: guestCount,
      seated: seated,
      virtualGuests: virtual,
      virtualCost: virtualCost,
      cateringBase: cateringBase,
      effectiveGuestCount: effectiveGuestCount,
      menuAddonsTotal: menuAddonsTotal,
      honorDecoTotal: honorDeco,
      regularDecoTotal: regularDeco,
      regularTableCount: regularTableCount,
      cateringTotal: cateringTotal,
    );
  }

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
