import 'dart:math';

import 'guest_basis.dart';
import 'sala_summary.dart';
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
    required this.reserve,
    required this.totalConfirmed,
    required this.totalEffective,
    required this.totalPaid,
    required this.remaining,
    required this.diff,
    required this.catering,
    required this.expensesEstimated,
    required this.hasEstimates,
    required this.planForCalc,
    required this.alcoholTotal,
    required this.softTotal,
    required this.expensesOnly,
    required this.honeymoonTotal,
    required this.honeymoonIncludedInBudget,
    required this.externalTotal,
    required this.giftsForGuestsTotal,
  });

  /// Budżet PLANOWANY (`budgetData.total`) — kwota założona na start.
  final double budget;

  /// Rezerwa (`budgetData.reserve`) — opcjonalny bufor na nieprzewidziane,
  /// doliczany do planowanego jako bezpiecznik.
  final double reserve;

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

  /// Suma alkoholu (do rozbicia w Podsumowaniu; już wliczona w [catering]? Nie —
  /// wliczona w wydatki, patrz [expensesOnly]).
  final double alcoholTotal;

  /// Suma napojów bezalkoholowych.
  final double softTotal;

  /// Wydatki „czyste" (bez alkoholu/napojów — te mają własne wiersze, by
  /// uniknąć podwójnego liczenia przy osobnym rozbiciu w Podsumowaniu).
  final double expensesOnly;

  /// Kwota podróży poślubnej — zawsze rzeczywista wartość (do wyświetlenia
  /// w Podsumowaniu), NIEZALEŻNIE od [honeymoonIncludedInBudget]. Do sum
  /// końcowych ([totalEffective] itd.) wchodzi tylko, gdy włączone.
  final double honeymoonTotal;

  /// Czy podróż poślubna jest wliczana do budżetu (przełącznik w zakładce
  /// „Podróż poślubna", domyślnie włączony — zgodność wsteczna).
  final bool honeymoonIncludedInBudget;

  /// Koszty zewnętrzne (dostawcy niepowiązani + hotele + transport).
  final double externalTotal;

  /// Suma upominków „Dla gości" (sekcja Prezenty).
  final double giftsForGuestsTotal;

  /// Procent opłacenia względem planu (etykieta „X% opłacono").
  int get paidPercentLabel =>
      (totalPaid / max(planForCalc, 1) * 100).round().clamp(0, 999);

  /// Budżet planowany powiększony o rezerwę (bezpiecznik).
  double get plannedWithReserve => budget + reserve;

  /// Budżet RZECZYWISTY — faktyczne (bieżące) koszty wszystkich pozycji.
  /// Alias na [planForCalc] dla czytelności w podsumowaniach.
  double get actualCost => planForCalc;

  /// Ile rezerwy zostało wykorzystane: część kosztów przekraczająca budżet
  /// planowany, ograniczona do wysokości rezerwy.
  double get reserveUsed => (planForCalc - budget).clamp(0.0, reserve);

  /// Kwota przekraczająca budżet planowany + rezerwę (0, jeśli mieścimy się).
  double get overPlannedWithReserve => max(0.0, planForCalc - plannedWithReserve);

  // Podstawa skali paska postępu — uwzględnia rezerwę (bezpiecznik).
  double get _base => [plannedWithReserve, totalEffective, 1.0].reduce(max);

  double get confirmedFraction => (totalConfirmed / _base).clamp(0, 1);
  double get effectiveFraction => (totalEffective / _base).clamp(0, 1);
  double get paidFraction => (totalPaid / _base).clamp(0, 1);
  double get planFraction => (planForCalc / _base).clamp(0, 1);

  factory BudgetSummary.from(WeddingData? data) {
    if (data == null) {
      return const BudgetSummary(
        budget: 0,
        reserve: 0,
        totalConfirmed: 0,
        totalEffective: 0,
        totalPaid: 0,
        remaining: 0,
        diff: 0,
        catering: 0,
        expensesEstimated: 0,
        hasEstimates: false,
        planForCalc: 0,
        alcoholTotal: 0,
        softTotal: 0,
        expensesOnly: 0,
        honeymoonTotal: 0,
        honeymoonIncludedInBudget: true,
        externalTotal: 0,
        giftsForGuestsTotal: 0,
      );
    }

    final raw = data.raw;
    final bd = _asMap(raw['budgetData']);

    final guestBasis = GuestBasis.from(data);
    final guestCount = guestBasis.invited;

    // ── Sala (catering) — liczone tym samym modelem co podzakładka „Sala"
    // (goście przypisani/nieprzypisani + obsługa), bez duplikacji logiki. ──
    final catering = SalaSummary.from(data).cateringTotal;

    // ── Napoje (ukryte panele wykluczone z budżetu, dane zachowane) ──
    final alcoholTotal = bd['alcoholPanelHidden'] == true
        ? 0.0
        : _sum(bd['alcoholItems'],
            (i) => _d(i['bottles']) * _d(i['pricePerBottle']));
    final softTotal = bd['softPanelHidden'] == true
        ? 0.0
        : _sum(bd['softItems'],
            (i) => _d(i['bottles']) * _d(i['pricePerBottle']));

    // ── Wydatki ──
    final expenses = bd['expenses'];
    final expPlanned =
        _sum(expenses, (e) => _d(e['planned'])) + alcoholTotal + softTotal;
    final expPaid = _sum(expenses, (e) => _d(e['paid']));
    final expEstimated = _sum(expenses, (e) => _d(e['estimatedAmount']));
    final expEffectiveOnly = _sum(expenses, (e) {
      final planned = _d(e['planned']);
      return planned > 0 ? planned : _d(e['estimatedAmount']);
    });
    final expEffective = expEffectiveOnly + alcoholTotal + softTotal;

    // ── Podróż poślubna ──
    // `includeInBudget` (domyślnie true — zgodność wsteczna) decyduje, czy
    // kwota wchodzi do sum końcowych. [honeymoonTotal] eksponowany niżej
    // pokazuje ZAWSZE rzeczywistą kwotę (do wyświetlenia), niezależnie od
    // przełącznika.
    final honeymoon = _asMap(bd['honeymoon']);
    final hmIncludeInBudget = honeymoon['includeInBudget'] != false;
    final hmConfirmedRaw = _d(honeymoon['totalAmount']);
    final hmEstimated = _d(honeymoon['estimatedAmount']);
    final hmEffectiveRaw = hmConfirmedRaw > 0 ? hmConfirmedRaw : hmEstimated;
    final honeymoonPaidRaw = _sum(honeymoon['installments'],
        (i) => i['status'] == 'paid' ? _d(i['amount']) : 0.0);
    final hmConfirmed = hmIncludeInBudget ? hmConfirmedRaw : 0.0;
    final hmEffective = hmIncludeInBudget ? hmEffectiveRaw : 0.0;
    final honeymoonPaid = hmIncludeInBudget ? honeymoonPaidRaw : 0.0;

    // ── Upominki „Dla gości" (sekcja Prezenty) ──
    // Liczone wg podstawy przeliczania: stała ilość (qty) albo na gości
    // rzeczywistych / rzeczywistych+wirtualnych (jak w sekcji Prezenty).
    final giftBasisRaw = raw['giftForGuestsBasis'];
    final giftBasis = (giftBasisRaw == 'real' || giftBasisRaw == 'realvirtual')
        ? giftBasisRaw as String
        : '';
    final giftPersonCount = giftBasis == 'real'
        ? guestCount.toDouble()
        : giftBasis == 'realvirtual'
            ? guestBasis.effective
            : 0.0;
    final giftsForGuestsTotal = _sum(raw['giftsForGuests'], (g) {
      final qty = giftBasis.isNotEmpty ? giftPersonCount : _d(g['qty']);
      return qty * _d(g['cost']);
    });

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
    final totalConfirmed =
        catering + expPlanned + hmConfirmed + externalTotal + giftsForGuestsTotal;
    final totalEffective =
        catering + expEffective + hmEffective + externalTotal + giftsForGuestsTotal;
    final totalPaid = expPaid + honeymoonPaid + vendorsExternalPaid;
    final hasEstimates = totalEffective > totalConfirmed;
    final planForCalc = hasEstimates ? totalEffective : totalConfirmed;
    final remaining = max(0.0, planForCalc - totalPaid);
    final budget = _d(bd['total']);
    final reserve = max(0.0, _d(bd['reserve']));
    final diff = budget - planForCalc;

    return BudgetSummary(
      budget: budget,
      reserve: reserve,
      totalConfirmed: totalConfirmed,
      totalEffective: totalEffective,
      totalPaid: totalPaid,
      remaining: remaining,
      diff: diff,
      catering: catering,
      expensesEstimated: expEstimated,
      hasEstimates: hasEstimates,
      planForCalc: planForCalc,
      alcoholTotal: alcoholTotal,
      softTotal: softTotal,
      expensesOnly: expEffectiveOnly,
      honeymoonTotal: hmEffectiveRaw,
      honeymoonIncludedInBudget: hmIncludeInBudget,
      externalTotal: externalTotal,
      giftsForGuestsTotal: giftsForGuestsTotal,
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
