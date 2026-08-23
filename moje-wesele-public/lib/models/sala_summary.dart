import 'dart:math';

import 'children.dart';
import 'guest_basis.dart';
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

/// Tryb liczenia kosztu obsługi.
class StaffCalcMode {
  const StaffCalcMode._();

  /// Suma osób z listy obsługi (`staffTables`) × stawka — dotychczasowe
  /// zachowanie, domyślne dla starych wesel (brak pola = ten tryb).
  static const String headcount = 'headcount';

  /// Efektywna liczba gości × stawka — obsługa liczona jak catering.
  static const String perGuest = 'perGuest';

  /// Kwota wpisana wprost, bez żadnego mnożenia.
  static const String manual = 'manual';

  static const List<String> all = [headcount, perGuest, manual];

  /// Odczyt z surowych danych. Nieznana/brakująca wartość → [headcount]
  /// (zgodność wsteczna — stare wesela nie znają innych trybów).
  static String fromRaw(dynamic v) =>
      all.contains(v) ? v as String : headcount;
}

/// Obliczenia podzakładki „Sala" — catering, obsługa i dekoracje.
///
/// Liczba osób do WSZYSTKICH przeliczeń per-osobę (catering, dodatki menu,
/// obsługa w trybie „na gości") pochodzi z JEDNEGO miejsca: [GuestBasis]
/// (`effective = max(zaproszeni, minimum sali, planowani)`), bez osobnych
/// przełączników „licz nieprzypisanych"/„licz wirtualnych" — te dwa
/// dotychczasowe mechanizmy dublowały ludzi już policzonych w „zaproszeni"
/// (nieprzypisani są PODZBIOREM zaproszonych) albo dokładały „wirtualnych"
/// w oderwaniu od realnej liczby zaproszonych. [assignedCount]/
/// [unassignedCount]/[virtualGuests] zostają WYŁĄCZNIE jako informacja.
class SalaSummary {
  const SalaSummary({
    required this.pricePerPerson,
    required this.staffPricePerPerson,
    required this.staffRate,
    required this.staffCalcMode,
    required this.staffManualAmount,
    required this.venueMinGuests,
    required this.plannedGuests,
    required this.includeStaff,
    required this.guestCount,
    required this.assignedCount,
    required this.unassignedCount,
    required this.guestCost,
    required this.virtualGuests,
    required this.virtualCost,
    required this.staffPersonCount,
    required this.staffCostPersonCount,
    required this.staffCost,
    required this.staff,
    required this.effectiveGuestCount,
    required this.addonsPersonCount,
    required this.menuAddonsTotal,
    required this.honorDecoTotal,
    required this.regularDecoTotal,
    required this.regularTableCount,
    required this.cateringTotal,
    // ── Catering oddzielny ──
    required this.cateringSeparate,
    required this.cateringPricePerPerson,
    required this.cateringMenuAddonsTotal,
    required this.cateringSeparateTotal,
    // ── Wesele z dziećmi ──
    required this.withChildren,
    required this.childrenCount,
    required this.children,
    required this.childBilledCount,
    required this.childMenuSeparate,
    required this.childMenuPricePerPerson,
    required this.childMenuTotal,
  });

  final double pricePerPerson;

  /// Stawka obsługi (zapisana). W trybie [StaffCalcMode.headcount] pusta
  /// (0) oznacza „jak za gościa" — patrz [staffRate]. W pozostałych trybach
  /// bez fallbacku: pusta = 0, bez ukrytej magii.
  final double staffPricePerPerson;

  /// Efektywna stawka obsługi DLA TRYBU HEADCOUNT (staffPricePerPerson albo,
  /// gdy pusta, pricePerPerson — zgodność wsteczna ze starymi weselami).
  final double staffRate;

  /// Tryb liczenia kosztu obsługi — patrz [StaffCalcMode].
  final String staffCalcMode;

  /// Kwota wpisana wprost w trybie [StaffCalcMode.manual].
  final double staffManualAmount;

  final double venueMinGuests;

  /// Szacunek pary, zanim zna pełną listę gości (`budgetData.plannedGuests`).
  final double plannedGuests;

  final bool includeStaff;

  /// Wszyscy zaproszeni (przypisani + nieprzypisani).
  final int guestCount;

  /// Goście przypisani do stołów. WYŁĄCZNIE informacyjne.
  final int assignedCount;

  /// Goście bez przypisanego stołu. WYŁĄCZNIE informacyjne — zero wpływu
  /// na [effectiveGuestCount] ani na żaden koszt.
  final int unassignedCount;

  /// Koszt gości: `effectiveGuestCount * pricePerPerson` (z uwzględnieniem
  /// osobnego menu dziecięcego, jeśli włączone).
  final double guestCost;

  /// O ile [effectiveGuestCount] przewyższa realnie zaproszonych — czysto
  /// informacyjne, np. „5 osób to dopłata do minimum sali". NIE dolicza się
  /// osobno do [cateringTotal] (jest już wliczone w [guestCost], bo
  /// [effectiveGuestCount] jest tego bazą).
  final double virtualGuests;

  /// Koszt [virtualGuests] — czysto informacyjny (wycinek [guestCost]).
  final double virtualCost;

  /// Łączna liczba osób obsługi z listy `staffTables`.
  final double staffPersonCount;

  /// Obsługa oznaczona „w kosztach" (`includeInCost`) — dotyczy trybu
  /// [StaffCalcMode.headcount].
  final double staffCostPersonCount;

  /// Koszt obsługi (gdy [includeStaff]) — wg [staffCalcMode].
  final double staffCost;

  /// Lista pozycji obsługi (do zarządzania w UI, tryb headcount).
  final List<StaffEntry> staff;

  /// „Efektywna liczba gości" — `max(zaproszeni, minimum sali, planowani)`.
  /// JEDYNA baza do kosztu gości, dodatków per-osobę (poza wyjątkiem niżej)
  /// i obsługi w trybie [StaffCalcMode.perGuest].
  final double effectiveGuestCount;

  /// Liczba osób do dodatków menu/cateringu oddzielnego: [effectiveGuestCount]
  /// plus obsługa (gdy wliczona I w trybie headcount — w pozostałych trybach
  /// nie ma osobno śledzonego headcountu obsługi do doliczenia).
  final double addonsPersonCount;

  final double menuAddonsTotal;
  final double honorDecoTotal;
  final double regularDecoTotal;
  final int regularTableCount;

  /// Łączny koszt sekcji „Sala" (sala + catering oddzielny, jeśli włączony).
  final double cateringTotal;

  // ── Catering oddzielny (osobna firma niż sala) ──
  final bool cateringSeparate;
  final double cateringPricePerPerson;
  final double cateringMenuAddonsTotal;

  /// Łączny koszt cateringu oddzielnego (baza per-osoba + dodatki).
  final double cateringSeparateTotal;

  // ── Wesele z dziećmi ──
  final bool withChildren;

  /// Liczba dzieci (do przeliczeń: wyłączane z alkoholu, opcjonalnie osobne menu).
  final int childrenCount;

  /// Ustawienia liczenia dzieci (tryb auto/ręczny + liczba z listy gości).
  /// UI Budżetu pokazuje na tej podstawie pole edytowalne albo podgląd.
  final ChildrenSettings children;

  /// Dzieci faktycznie liczone do sali (min z liczby dzieci i efektywnej
  /// liczby gości).
  final double childBilledCount;

  /// Czy dzieci mają OSOBNE menu (inna cena za dziecko).
  final bool childMenuSeparate;
  final double childMenuPricePerPerson;

  /// Koszt osobnego menu dziecięcego (0, gdy wyłączone).
  final double childMenuTotal;

  double get tableDecoTotal => honorDecoTotal + regularDecoTotal;

  factory SalaSummary.from(WeddingData? data) {
    if (data == null) return _empty;

    final raw = data.raw;
    final bd = _asMap(raw['budgetData']);
    final tables = data.tables;

    final basis = GuestBasis.from(data);
    final effectiveGuestCount = basis.effective;

    final pricePerPerson = _d(bd['pricePerPerson']);
    final staffPricePerPerson = _d(bd['staffPricePerPerson']);
    // Fallback „jak za gościa" — WYŁĄCZNIE dla trybu headcount, dla
    // zgodności wstecznej ze starymi weselami, które na nim polegały.
    final staffRate = staffPricePerPerson > 0 ? staffPricePerPerson : pricePerPerson;
    final staffCalcMode = StaffCalcMode.fromRaw(bd['staffCalcMode']);
    final staffManualAmount = _d(bd['staffManualAmount']);

    final includeStaff = bd['includeStaffInCalc'] == true;

    // ── Wesele z dziećmi ──
    final children = ChildrenSettings.from(bd, data.guests);
    final withChildren = children.enabled;
    final childrenCount = children.count;
    final childMenuSeparate = withChildren && bd['childMenuSeparate'] == true;
    final childMenuPPP = _d(bd['childMenuPricePerPerson']);
    // Dzieci faktycznie liczone (nie więcej niż efektywna liczba gości).
    final childBilled = min(childrenCount.toDouble(), effectiveGuestCount);

    // Koszt gości: gdy dzieci mają osobne menu, liczymy je po cenie dziecięcej,
    // a dorosłych po cenie za osobę. W przeciwnym razie wszyscy po cenie sali.
    final adultBilled = effectiveGuestCount - childBilled;
    final childMenuTotal =
        childMenuSeparate ? childBilled * childMenuPPP : 0.0;
    final guestCost = childMenuSeparate
        ? adultBilled * pricePerPerson + childMenuTotal
        : effectiveGuestCount * pricePerPerson;

    // „Dopłata" do minimum/planu ponad realnie zaproszonych — WYŁĄCZNIE
    // informacyjna, już wliczona w guestCost (bo effectiveGuestCount jest
    // jego bazą), więc NIE dolicza się osobno do cateringTotal.
    final virtualGuests = basis.paddingOverInvited;
    final virtualCost = virtualGuests * pricePerPerson;

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

    final staffCost = !includeStaff
        ? 0.0
        : switch (staffCalcMode) {
            StaffCalcMode.perGuest => effectiveGuestCount * staffPricePerPerson,
            StaffCalcMode.manual => staffManualAmount,
            _ => staffCostPersonCount * staffRate,
          };

    // Liczba osób do dodatków per-osoba: efektywna liczba gości + obsługa,
    // ale headcount obsługi doliczamy TYLKO w trybie headcount — w trybie
    // „na gości"/ręcznym nie ma osobno śledzonej liczby osób obsługi do
    // doliczenia (koszt obsługi już nie pochodzi z tej listy).
    final addonsPersonCount = effectiveGuestCount +
        (includeStaff && staffCalcMode == StaffCalcMode.headcount
            ? staffPersonCount
            : 0.0);

    final menuAddonsTotal =
        _sum(bd['menuAddons'], (a) => _d(a['pricePerPerson'])) *
            addonsPersonCount;

    final regularTableCount =
        tables.where((t) => t is Map && t['isHonorTable'] != true).length;
    final tableDeco = _asMap(bd['tableDeco']);
    final honorDeco = _sum(tableDeco['honorAddons'], (a) => _d(a['price']));
    final regularDeco =
        _sum(tableDeco['regularAddons'], (a) => _d(a['pricePerTable'])) *
            regularTableCount;

    // ── Catering oddzielny (osobna firma niż sala) — te same przeliczenia
    // per-osoba co sala (baza = liczba osób do przeliczeń + dodatki). ──
    final cateringSeparate = bd['cateringSeparate'] == true;
    final cateringPPP = _d(bd['cateringPricePerPerson']);
    final cateringAddonsPerPerson =
        _sum(bd['cateringMenuAddons'], (a) => _d(a['pricePerPerson']));
    final cateringMenuAddonsTotal =
        cateringSeparate ? cateringAddonsPerPerson * addonsPersonCount : 0.0;
    final cateringSeparateTotal = cateringSeparate
        ? addonsPersonCount * cateringPPP + cateringMenuAddonsTotal
        : 0.0;

    // ⚠️ BEZ osobnego `+ virtualCost` — dopłata do minimum/planu jest już
    // wliczona w `guestCost` (patrz [virtualCost]), doliczenie jej tu
    // ponownie dublowałoby te same osoby.
    final cateringTotal = guestCost +
        staffCost +
        menuAddonsTotal +
        honorDeco +
        regularDeco +
        cateringSeparateTotal;

    return SalaSummary(
      pricePerPerson: pricePerPerson,
      staffPricePerPerson: staffPricePerPerson,
      staffRate: staffRate,
      staffCalcMode: staffCalcMode,
      staffManualAmount: staffManualAmount,
      venueMinGuests: basis.venueMinGuests,
      plannedGuests: basis.plannedGuests,
      includeStaff: includeStaff,
      guestCount: basis.invited,
      assignedCount: basis.assigned,
      unassignedCount: basis.unassigned,
      guestCost: guestCost,
      virtualGuests: virtualGuests,
      virtualCost: virtualCost,
      staffPersonCount: staffPersonCount,
      staffCostPersonCount: staffCostPersonCount,
      staffCost: staffCost,
      staff: staffList,
      effectiveGuestCount: effectiveGuestCount,
      addonsPersonCount: addonsPersonCount,
      menuAddonsTotal: menuAddonsTotal,
      honorDecoTotal: honorDeco,
      regularDecoTotal: regularDeco,
      regularTableCount: regularTableCount,
      cateringTotal: cateringTotal,
      cateringSeparate: cateringSeparate,
      cateringPricePerPerson: cateringPPP,
      cateringMenuAddonsTotal: cateringMenuAddonsTotal,
      cateringSeparateTotal: cateringSeparateTotal,
      withChildren: withChildren,
      childrenCount: childrenCount,
      children: children,
      childBilledCount: childBilled,
      childMenuSeparate: childMenuSeparate,
      childMenuPricePerPerson: childMenuPPP,
      childMenuTotal: childMenuTotal,
    );
  }

  static const _empty = SalaSummary(
    pricePerPerson: 0,
    staffPricePerPerson: 0,
    staffRate: 0,
    staffCalcMode: StaffCalcMode.headcount,
    staffManualAmount: 0,
    venueMinGuests: 0,
    plannedGuests: 0,
    includeStaff: false,
    guestCount: 0,
    assignedCount: 0,
    unassignedCount: 0,
    guestCost: 0,
    virtualGuests: 0,
    virtualCost: 0,
    staffPersonCount: 0,
    staffCostPersonCount: 0,
    staffCost: 0,
    staff: [],
    effectiveGuestCount: 0,
    addonsPersonCount: 0,
    menuAddonsTotal: 0,
    honorDecoTotal: 0,
    regularDecoTotal: 0,
    regularTableCount: 0,
    cateringTotal: 0,
    cateringSeparate: false,
    cateringPricePerPerson: 0,
    cateringMenuAddonsTotal: 0,
    cateringSeparateTotal: 0,
    withChildren: false,
    childrenCount: 0,
    children: ChildrenSettings.empty,
    childBilledCount: 0,
    childMenuSeparate: false,
    childMenuPricePerPerson: 0,
    childMenuTotal: 0,
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
