import 'dart:math';

import 'wedding_data.dart';

/// Rodzaj napojów — wspólna logika dla Alkoholu i Napojów bezalkoholowych.
enum BeverageKind { alcohol, soft }

extension BeverageKindX on BeverageKind {
  String get itemsKey =>
      this == BeverageKind.alcohol ? 'alcoholItems' : 'softItems';
  String get idKey =>
      this == BeverageKind.alcohol ? 'nextAlcoholId' : 'nextSoftId';
  String get splitP1Key =>
      this == BeverageKind.alcohol ? 'alcoholSplitP1' : 'softSplitP1';
  String get splitP2Key =>
      this == BeverageKind.alcohol ? 'alcoholSplitP2' : 'softSplitP2';
  String get perVirtualKey => this == BeverageKind.alcohol
      ? 'alcoholPerPersonVirtual'
      : 'softPerPersonVirtual';

  String get title =>
      this == BeverageKind.alcohol ? 'Alkohol' : 'Napoje bezalkoholowe';

  /// Rodzaje (ALCOHOL_TYPES / SOFT_TYPES w zrodlo-web/script.js).
  List<String> get types => this == BeverageKind.alcohol
      ? const [
          'Wódka',
          'Wino',
          'Piwo',
          'Szampan',
          'Whisky',
          'Nalewka',
          'Gin',
          'Rum',
          'Inne',
        ]
      : const [
          'Woda',
          'Soki',
          'Napoje gazowane',
          'Kawa / Herbata',
          'Energetyki',
          'Inne',
        ];
}

/// Podsumowanie napojów (alkohol/soft) — odwzorowane z renderAlcohol/renderSoft.
class BeverageSummary {
  const BeverageSummary({
    required this.totalBottles,
    required this.totalCost,
    required this.personCount,
    required this.perBottles,
    required this.perCost,
    required this.perVirtual,
    required this.splitP1,
    required this.splitP2,
    required this.coupleNames,
  });

  final double totalBottles;
  final double totalCost;
  final double personCount;
  final double perBottles;
  final double perCost;
  final bool perVirtual;
  final double splitP1;
  final double splitP2;
  final List<String> coupleNames;

  factory BeverageSummary.from(WeddingData? data, BeverageKind kind) {
    final raw = data?.raw ?? const {};
    final bd = raw['budgetData'];
    final budget = bd is Map ? Map<String, dynamic>.from(bd) : <String, dynamic>{};

    final items = budget[kind.itemsKey];
    double totalBottles = 0, totalCost = 0;
    if (items is List) {
      for (final e in items) {
        if (e is Map) {
          final bottles = _d(e['bottles']);
          totalBottles += bottles;
          totalCost += bottles * _d(e['pricePerBottle']);
        }
      }
    }

    final guests = data?.guests ?? const [];
    final seated = guests.where((g) => g is Map && g['tableId'] != null).length;
    final venueMin = _d(budget['venueMinGuests']);
    final virtual = max(0.0, venueMin - seated);
    final perVirtual = budget[kind.perVirtualKey] == true;
    final personCount = guests.length + (perVirtual ? virtual : 0.0);

    final names = budget['coupleNames'];
    final coupleNames = (names is List && names.length >= 2)
        ? [names[0]?.toString() ?? 'Osoba 1', names[1]?.toString() ?? 'Osoba 2']
        : <String>['Osoba 1', 'Osoba 2'];

    return BeverageSummary(
      totalBottles: totalBottles,
      totalCost: totalCost,
      personCount: personCount,
      perBottles: personCount > 0 ? totalBottles / personCount : 0,
      perCost: personCount > 0 ? totalCost / personCount : 0,
      perVirtual: perVirtual,
      splitP1: _d(budget[kind.splitP1Key]),
      splitP2: _d(budget[kind.splitP2Key]),
      coupleNames: coupleNames,
    );
  }

  static double _d(dynamic v) => v is num ? v.toDouble() : 0.0;
}
