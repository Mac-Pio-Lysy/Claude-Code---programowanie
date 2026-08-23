import 'dart:math';

import 'children.dart';
import 'guest_basis.dart';
import 'wedding_data.dart';
import '../l10n/app_text.dart';

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

  /// Flaga ukrycia bocznego panelu (ukryty = niewliczany do budżetu).
  String get panelHiddenKey =>
      this == BeverageKind.alcohol ? 'alcoholPanelHidden' : 'softPanelHidden';

  String get title =>
      this == BeverageKind.alcohol
          ? AppText.t.beverage_alcohol
          : AppText.t.beverage_soft;

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
    required this.panelHidden,
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

  /// Czy panel jest ukryty (wykluczony z budżetu, dane zachowane).
  final bool panelHidden;

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
    final perVirtual = budget[kind.perVirtualKey] == true;

    // „Realni goście" vs „z dopłatą do minimum sali/planu" — LEGALNY wybór
    // (nie to samo co dawny błąd „nieprzypisanych" w Sali: minimum sali nie
    // jest podzbiorem zaproszonych, więc nie ma tu dublowania). Wariant
    // „z dopłatą" woła WSPÓLNĄ efektywną liczbę gości z [GuestBasis] —
    // zero własnej arytmetyki.
    final rawBase = perVirtual
        ? GuestBasis.from(data).effective
        : guests.length.toDouble();

    // Wesele z dziećmi: dzieci są WYŁĄCZONE z przeliczeń alkoholu
    // (alkohol nie dla dzieci). Napojów bezalkoholowych to nie dotyczy.
    //
    // Liczba pochodzi z [ChildrenSettings] — w trybie „auto" z listy gości,
    // w ręcznym z pola w Budżecie. Sama logika przeliczeń bez zmian.
    final childrenCount = ChildrenSettings.from(budget, guests).count;
    final personCount = kind == BeverageKind.alcohol
        ? max(0.0, rawBase - childrenCount)
        : rawBase;

    final names = budget['coupleNames'];
    // Etykiety zastępcze do POKAZANIA (nie do zapisu) — stąd tłumaczenie.
    final fallback = [
      AppText.t.couple_personNumbered(1),
      AppText.t.couple_personNumbered(2),
    ];
    final coupleNames = (names is List && names.length >= 2)
        ? [
            names[0]?.toString() ?? fallback[0],
            names[1]?.toString() ?? fallback[1],
          ]
        : fallback;

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
      panelHidden: budget[kind.panelHiddenKey] == true,
    );
  }

  static double _d(dynamic v) => v is num ? v.toDouble() : 0.0;
}
