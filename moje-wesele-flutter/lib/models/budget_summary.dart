import 'dart:math';

import 'wedding_data.dart';

/// Podsumowanie budżetu — wierne odwzorowanie `renderBudgetOverview()`
/// z zrodlo-web/script.js (wraz ze wszystkimi funkcjami składowymi).
///
/// Agreguje koszty z wielu sekcji: catering/sala, wydatki, alkohol, napoje,
/// podróż poślubną oraz koszty zewnętrzne (dostawcy niepowiązani, hotele,
/// transport).
class BudgetSummary {
  const BudgetSummary({
    required this.budget,
    required this.totalConfirmed,
    required this.totalEffective,
    required this.totalPaid,
    required this.remaining,
    required this.diff,
    required this.catering,
    required this.expensesEstimated,
    required this.hasEstimates,
    required this.planForCalc,
  });

  /// Budżet całkowity (`budgetData.total`).
  final double budget;

  /// „Potwierdzone" — sumy potwierdzone (planowane).
  final double totalConfirmed;

  /// „Przewidywane" — z uwzględnieniem szacunków tam, gdzie brak potwierdzeń.
  final double totalEffective;

  /// „Opłacono".
  final double totalPaid;

  /// „Pozostało" = max(0, plan - opłacono).
  final double remaining;

  /// „Budżet-plan" = budżet − plan (dodatni = zapas, ujemny = przekroczenie).
  final double diff;

  /// Catering/sala (część potwierdzonych).
  final double catering;

  /// Suma szacunków z wydatków (do informacji).
  final double expensesEstimated;

  /// Czy występują szacunki (plan przewidywany > potwierdzony).
  final bool hasEstimates;

  /// Kwota planu użyta do obliczeń („Pozostało", procent opłacenia).
  final double planForCalc;

  /// Procent opłacenia względem planu (etykieta „X% opłacono").
  int get paidPercentLabel =>
      (totalPaid / max(planForCalc, 1) * 100).round().clamp(0, 999);

  // Podstawa skali paska postępu (jak `base` w wersji web).
  double get _base => [budget, totalEffective, 1.0].reduce(max);

  double get confirmedFraction => (totalConfirmed / _base).clamp(0, 1);
  double get effectiveFraction => (totalEffective / _base).clamp(0, 1);
  double get paidFraction => (totalPaid / _base).clamp(0, 1);
  double get planFraction => (planForCalc / _base).clamp(0, 1);

  factory BudgetSummary.from(WeddingData? data) {
    if (data == null) {
      return const BudgetSummary(
        budget: 0,
        totalConfirmed: 0,
        totalEffective: 0,
        totalPaid: 0,
        remaining: 0,
        diff: 0,
        catering: 0,
        expensesEstimated: 0,
        hasEstimates: false,
        planForCalc: 0,
      );
    }

    final raw = data.raw;
    final bd = _asMap(raw['budgetData']);
    final guests = data.guests;
    final tables = data.tables;

    final pricePerPerson = _d(bd['pricePerPerson']);
    final guestCount = guests.length;

    // ── Catering / sala ──
    final cateringBase = pricePerPerson * guestCount;
    final seated =
        guests.where((g) => g is Map && g['tableId'] != null).length;
    final venueMin = _d(bd['venueMinGuests']);
    final virtual = max(0.0, venueMin - seated);
    final virtualCost = virtual * pricePerPerson;

    final staffTables = raw['staffTables'];
    final staffPersonCount = _sum(staffTables, (t) => _d(t['persons']));
    final staffCostPersonCount = _sum(staffTables,
        (t) => t['includeInCost'] == true ? _d(t['persons']) : 0.0);
    final staffCost = staffCostPersonCount * pricePerPerson;

    final includeVirtual = bd['includeVirtualInCalc'] == true;
    final includeStaff = bd['includeStaffInCalc'] == true;
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
    final tableDecoTotal = honorDeco + regularDeco;

    final catering = cateringBase +
        virtualCost +
        staffCost +
        menuAddonsTotal +
        tableDecoTotal;

    // ── Napoje ──
    final alcoholTotal = _sum(bd['alcoholItems'],
        (i) => _d(i['bottles']) * _d(i['pricePerBottle']));
    final softTotal = _sum(
        bd['softItems'], (i) => _d(i['bottles']) * _d(i['pricePerBottle']));

    // ── Wydatki ──
    final expenses = bd['expenses'];
    final expPlanned =
        _sum(expenses, (e) => _d(e['planned'])) + alcoholTotal + softTotal;
    final expPaid = _sum(expenses, (e) => _d(e['paid']));
    final expEstimated = _sum(expenses, (e) => _d(e['estimatedAmount']));
    final expEffective = _sum(expenses, (e) {
          final planned = _d(e['planned']);
          return planned > 0 ? planned : _d(e['estimatedAmount']);
        }) +
        alcoholTotal +
        softTotal;

    // ── Podróż poślubna ──
    final honeymoon = _asMap(bd['honeymoon']);
    final hmConfirmed = _d(honeymoon['totalAmount']);
    final hmEstimated = _d(honeymoon['estimatedAmount']);
    final hmEffective = hmConfirmed > 0 ? hmConfirmed : hmEstimated;
    final honeymoonPaid = _sum(honeymoon['installments'],
        (i) => i['status'] == 'paid' ? _d(i['amount']) : 0.0);

    // ── Koszty zewnętrzne (dostawcy niepowiązani + hotele + transport) ──
    final vendors = raw['vendors'];
    final vendorsExternalTotal = _sum(
        vendors, (v) => v['isBudgetLinked'] != true ? _d(v['price']) : 0.0);
    final vendorsExternalPaid = _sum(vendors, (v) {
      if (v['isBudgetLinked'] == true) return 0.0;
      return _sum(v['installments'],
          (i) => i['status'] == 'paid' ? _d(i['amount']) : 0.0);
    });
    final hotelsTotal = _sum(raw['hotels'], (h) {
      final ppr = _d(h['personsPerRoom']);
      return _d(h['pricePerNight']) * (ppr <= 0 ? 1 : ppr);
    });
    final transportTotal = _sum(raw['vehicles'], (v) => _d(v['cost']));
    final externalTotal =
        vendorsExternalTotal + hotelsTotal + transportTotal;

    // ── Agregacja końcowa ──
    final totalConfirmed = catering + expPlanned + hmConfirmed + externalTotal;
    final totalEffective = catering + expEffective + hmEffective + externalTotal;
    final totalPaid = expPaid + honeymoonPaid + vendorsExternalPaid;
    final hasEstimates = totalEffective > totalConfirmed;
    final planForCalc = hasEstimates ? totalEffective : totalConfirmed;
    final remaining = max(0.0, planForCalc - totalPaid);
    final budget = _d(bd['total']);
    final diff = budget - planForCalc;

    return BudgetSummary(
      budget: budget,
      totalConfirmed: totalConfirmed,
      totalEffective: totalEffective,
      totalPaid: totalPaid,
      remaining: remaining,
      diff: diff,
      catering: catering,
      expensesEstimated: expEstimated,
      hasEstimates: hasEstimates,
      planForCalc: planForCalc,
    );
  }

  // ── Pomocnicze ──
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
