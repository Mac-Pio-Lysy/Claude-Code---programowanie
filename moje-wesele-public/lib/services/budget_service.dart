import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/beverage.dart';
import '../models/children.dart';
import 'firestore_service.dart';
import '../l10n/app_text.dart';

/// Dane wydatku z formularza dodawania/edycji.
class ExpenseDraft {
  ExpenseDraft({
    required this.category,
    required this.customName,
    required this.planned,
    required this.estimatedAmount,
    required this.paid,
    required this.paymentDate,
    required this.note,
    required this.splitP1,
    required this.splitP2,
    this.origin = 'expenses',
    this.isVendor = false,
    this.vendorCompany = '',
    this.vendorContact = '',
    this.vendorPhone = '',
    this.vendorEmail = '',
    this.vendorCategory = 'Inne',
  });

  final String category;
  final String customName;
  final num planned;
  final num estimatedAmount;
  final num paid;
  final String paymentDate;
  final String note;
  final num splitP1;
  final num splitP2;

  /// Sekcja źródłowa rekordu ('expenses' | 'vendors'). Zachowywana przy edycji.
  final String origin;

  /// Czy wydatek jest też dostawcą/usługą (pokazuje się w sekcji Dostawcy
  /// jako TEN SAM rekord — przez referencję, nie kopię).
  final bool isVendor;
  final String vendorCompany;
  final String vendorContact;
  final String vendorPhone;
  final String vendorEmail;
  final String vendorCategory;
}

/// Operacje na budżecie (`budgetData`) w `weddingPlanner/main`.
///
/// Zapisy używają głębokiego scalania (`merge: true`) na zagnieżdżonych polach
/// `budgetData`, więc pozostałe pola pozostają nietknięte. Tablice (np.
/// `expenses`, `menuAddons`) są nadpisywane w całości — czytamy je, modyfikujemy
/// i zapisujemy z powrotem.
class BudgetService {
  BudgetService({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  final FirestoreService _firestore;

  // ── SALA / KONFIGURACJA ──────────────────────────────────────────────

  Future<void> setTotalBudget(num value) => _mergeBudget({'total': value});

  /// Rezerwa (bufor) — zapas ponad budżet główny, liczony osobno. Ta sama
  /// ścieżka zapisu co reszta budżetu; ten sam efekt co pole „Rezerwa" w
  /// Ustawieniach → „Ustawienia budżetu" (`ConfigService.saveBudgetSettings`).
  Future<void> setReserve(num value) => _mergeBudget({'reserve': value});

  Future<void> setPricePerPerson(num value) =>
      _mergeBudget({'pricePerPerson': value});

  Future<void> setVenueMinGuests(num value) =>
      _mergeBudget({'venueMinGuests': value});

  /// Szacunek pary, zanim zna pełną listę gości — jeden ze składników
  /// efektywnej liczby gości (`GuestBasis.effective`).
  Future<void> setPlannedGuests(num value) =>
      _mergeBudget({'plannedGuests': value});

  /// Czy doliczać obsługę (`staffTables` z „w kosztach") do kosztu sali.
  Future<void> setIncludeStaff(bool value) =>
      _mergeBudget({'includeStaffInCalc': value});

  /// Stawka za osobę dla obsługi (0 = w trybie headcount używana jest cena
  /// ogólna za osobę — zgodność wsteczna).
  Future<void> setStaffPricePerPerson(num value) =>
      _mergeBudget({'staffPricePerPerson': value});

  /// Tryb liczenia kosztu obsługi — patrz `StaffCalcMode`.
  Future<void> setStaffCalcMode(String mode) =>
      _mergeBudget({'staffCalcMode': mode});

  /// Kwota obsługi wpisana wprost (tryb `StaffCalcMode.manual`).
  Future<void> setStaffManualAmount(num value) =>
      _mergeBudget({'staffManualAmount': value});

  // ── CATERING ODDZIELNY (osobna firma niż sala) ───────────────────────

  Future<void> setCateringSeparate(bool value) =>
      _mergeBudget({'cateringSeparate': value});

  Future<void> setCateringPricePerPerson(num value) =>
      _mergeBudget({'cateringPricePerPerson': value});

  // ── WESELE Z DZIEĆMI ─────────────────────────────────────────────────

  Future<void> setWithChildren(bool value) =>
      _mergeBudget({'withChildren': value});

  Future<void> setChildrenCount(num value) =>
      _mergeBudget({'childrenCount': value});

  /// Przełącza liczenie dzieci: `auto` (z listy gości) ↔ `manual` (z pola).
  ///
  /// Przy przejściu na tryb ręczny zapisujemy aktualnie wyliczoną liczbę jako
  /// punkt startowy — inaczej pole pokazałoby starą, nieaktualną wartość.
  Future<void> setChildrenCountAuto(bool auto, {int? currentCount}) =>
      _mergeBudget({
        ChildrenSettings.modeKey:
            auto ? ChildrenSettings.modeAuto : ChildrenSettings.modeManual,
        if (!auto && currentCount != null) 'childrenCount': currentCount,
      });

  Future<void> setChildMenuSeparate(bool value) =>
      _mergeBudget({'childMenuSeparate': value});

  Future<void> setChildMenuPricePerPerson(num value) =>
      _mergeBudget({'childMenuPricePerPerson': value});

  // ── OBSŁUGA (kelnerzy, fotograf, DJ…) — `staffTables` (top-level) ─────
  // Współdzielone z planem sali; pozycja nadawana automatycznie (jak w web).

  Future<void> addStaffTable(String name, num persons) async {
    final data = await _read();
    final list = _mapList(data['staffTables']);
    final nextId = _nextId(data['nextStaffTableId'], list);
    final idx = list.length;
    list.add({
      'id': nextId,
      'name': name.trim().isEmpty ? AppText.t.budget_staff : name.trim(),
      'persons': persons,
      'includeInCost': false,
      'posX': 50 + (idx % 6) * 150,
      'posY': 600 + (idx ~/ 6) * 110,
    });
    await _firestore.mainDoc.set(
      {'staffTables': list, 'nextStaffTableId': nextId + 1},
      SetOptions(merge: true),
    );
  }

  Future<void> updateStaffTable(int id,
      {String? name, num? persons, bool? includeInCost}) async {
    final data = await _read();
    final list = _mapList(data['staffTables']);
    final item = _find(list, id);
    if (item == null) return;
    if (name != null) item['name'] = name;
    if (persons != null) item['persons'] = persons;
    if (includeInCost != null) item['includeInCost'] = includeInCost;
    await _firestore.mainDoc.set({'staffTables': list}, SetOptions(merge: true));
  }

  Future<void> deleteStaffTable(int id) async {
    final data = await _read();
    final list = _mapList(data['staffTables'])
      ..removeWhere((m) => _idOf(m) == id);
    await _firestore.mainDoc.set({'staffTables': list}, SetOptions(merge: true));
  }

  // ── DODATKI DO MENU (per osoba) ──────────────────────────────────────

  Future<void> addMenuAddon() async {
    final data = await _read();
    final list = _mapList(_budget(data)['menuAddons']);
    final nextId = _nextId(data['nextMenuAddonId'], list);
    list.add({'id': nextId, 'name': '', 'pricePerPerson': 0});
    await _firestore.mainDoc.set({
      'budgetData': {'menuAddons': list},
      'nextMenuAddonId': nextId + 1,
    }, SetOptions(merge: true));
  }

  Future<void> updateMenuAddon(int id, {String? name, num? pricePerPerson}) async {
    final data = await _read();
    final list = _mapList(_budget(data)['menuAddons']);
    final item = _find(list, id);
    if (item == null) return;
    if (name != null) item['name'] = name;
    if (pricePerPerson != null) item['pricePerPerson'] = pricePerPerson;
    await _mergeBudget({'menuAddons': list});
  }

  Future<void> deleteMenuAddon(int id) async {
    final data = await _read();
    final list = _mapList(_budget(data)['menuAddons'])
      ..removeWhere((m) => _idOf(m) == id);
    await _mergeBudget({'menuAddons': list});
  }

  // ── DODATKI DO MENU CATERINGU (per osoba, gdy catering oddzielny) ─────

  Future<void> addCateringMenuAddon() async {
    final data = await _read();
    final list = _mapList(_budget(data)['cateringMenuAddons']);
    final nextId = _nextId(data['nextCateringAddonId'], list);
    list.add({'id': nextId, 'name': '', 'pricePerPerson': 0});
    await _firestore.mainDoc.set({
      'budgetData': {'cateringMenuAddons': list},
      'nextCateringAddonId': nextId + 1,
    }, SetOptions(merge: true));
  }

  Future<void> updateCateringMenuAddon(int id,
      {String? name, num? pricePerPerson}) async {
    final data = await _read();
    final list = _mapList(_budget(data)['cateringMenuAddons']);
    final item = _find(list, id);
    if (item == null) return;
    if (name != null) item['name'] = name;
    if (pricePerPerson != null) item['pricePerPerson'] = pricePerPerson;
    await _mergeBudget({'cateringMenuAddons': list});
  }

  Future<void> deleteCateringMenuAddon(int id) async {
    final data = await _read();
    final list = _mapList(_budget(data)['cateringMenuAddons'])
      ..removeWhere((m) => _idOf(m) == id);
    await _mergeBudget({'cateringMenuAddons': list});
  }

  // ── DEKORACJE STOŁÓW (honorowy / zwykłe) ─────────────────────────────

  Future<void> addTableDeco(String type) async {
    final data = await _read();
    final deco = _tableDeco(data);
    final honor = _mapList(deco['honorAddons']);
    final regular = _mapList(deco['regularAddons']);
    final nextId = _nextId(data['nextTableDecoId'], [...honor, ...regular]);
    if (type == 'honor') {
      honor.add({'id': nextId, 'name': '', 'price': 0});
    } else {
      regular.add({'id': nextId, 'name': '', 'pricePerTable': 0});
    }
    await _firestore.mainDoc.set({
      'budgetData': {
        'tableDeco': {'honorAddons': honor, 'regularAddons': regular},
      },
      'nextTableDecoId': nextId + 1,
    }, SetOptions(merge: true));
  }

  Future<void> updateTableDeco(String type, int id,
      {String? name, num? value}) async {
    final data = await _read();
    final deco = _tableDeco(data);
    final honor = _mapList(deco['honorAddons']);
    final regular = _mapList(deco['regularAddons']);
    final list = type == 'honor' ? honor : regular;
    final item = _find(list, id);
    if (item == null) return;
    if (name != null) item['name'] = name;
    if (value != null) item[type == 'honor' ? 'price' : 'pricePerTable'] = value;
    await _mergeBudget({
      'tableDeco': {'honorAddons': honor, 'regularAddons': regular},
    });
  }

  Future<void> deleteTableDeco(String type, int id) async {
    final data = await _read();
    final deco = _tableDeco(data);
    final honor = _mapList(deco['honorAddons']);
    final regular = _mapList(deco['regularAddons']);
    (type == 'honor' ? honor : regular).removeWhere((m) => _idOf(m) == id);
    await _mergeBudget({
      'tableDeco': {'honorAddons': honor, 'regularAddons': regular},
    });
  }

  // ── WYDATKI ──────────────────────────────────────────────────────────

  Future<void> addExpense(ExpenseDraft draft) async {
    final data = await _read();
    final list = _mapList(_budget(data)['expenses']);
    final order = _intList(data['expenseOrder']);
    final nextId = _nextId(data['nextExpenseId'], list);
    final item = <String, dynamic>{
      'id': nextId,
      'category': draft.category,
      'customName': draft.customName,
      'planned': draft.planned,
      'estimatedAmount': draft.estimatedAmount,
      'paid': draft.paid,
      'paymentDate': draft.paymentDate,
      'note': draft.note,
      'splitP1': draft.splitP1,
      'splitP2': draft.splitP2,
      'sidePanel': false,
      'origin': draft.origin.isEmpty ? 'expenses' : draft.origin,
      'vendorId': null,
    };
    list.add(item);
    order.add(nextId);

    final payload = <String, dynamic>{
      'nextExpenseId': nextId + 1,
      'expenseOrder': order,
    };
    // Powiązanie z dostawcą (jeśli „To jest dostawca/usługa") — referencja.
    _syncExpenseVendor(data, item, draft, payload);
    payload['budgetData'] = {'expenses': list};

    await _firestore.mainDoc.set(payload, SetOptions(merge: true));
  }

  Future<void> updateExpense(int id, ExpenseDraft draft) async {
    final data = await _read();
    final list = _mapList(_budget(data)['expenses']);
    final item = _find(list, id);
    if (item == null) return;
    item['category'] = draft.category;
    item['customName'] = draft.category == 'Inne' ? draft.customName : '';
    item['planned'] = draft.planned;
    item['estimatedAmount'] = draft.estimatedAmount;
    item['paid'] = draft.paid;
    item['paymentDate'] = draft.paymentDate;
    item['note'] = draft.note;
    item['splitP1'] = draft.splitP1;
    item['splitP2'] = draft.splitP2;
    // Zachowaj/ustaw źródło rekordu (nie nadpisuj pochodzenia z Dostawców).
    item['origin'] = draft.origin.isEmpty ? (item['origin'] ?? 'expenses') : draft.origin;

    final payload = <String, dynamic>{};
    _syncExpenseVendor(data, item, draft, payload);
    payload['budgetData'] = {'expenses': list};

    await _firestore.mainDoc.set(payload, SetOptions(merge: true));
  }

  /// Synchronizuje powiązanego dostawcę z wydatkiem (referencja, nie kopia).
  /// Mutuje [expense] (ustawia `vendorId`) i dopisuje `vendors`/`nextVendorId`
  /// do [payload]. Kwota pozostaje w wydatku — dostawca jest tylko „widokiem"
  /// z danymi kontaktowymi (`isBudgetLinked=true`, `price=0`), więc kwota się
  /// NIE dubluje (dostawcy powiązani są wykluczani z sum „zewnętrznych").
  void _syncExpenseVendor(Map<String, dynamic> data, Map<String, dynamic> expense,
      ExpenseDraft draft, Map<String, dynamic> payload) {
    final vendors = _mapList(data['vendors']);
    final expId = _idOf(expense);
    Map<String, dynamic>? vendor;
    final vid = (expense['vendorId'] as num?)?.toInt();
    if (vid != null) vendor = _find(vendors, vid);
    vendor ??= () {
      for (final v in vendors) {
        if ((v['budgetExpenseId'] as num?)?.toInt() == expId) return v;
      }
      return null;
    }();

    if (!draft.isVendor) {
      // Odłączenie — NIE kasujemy dostawcy (zachowujemy kontakt/raty), tylko
      // czyścimy powiązanie i zerujemy cenę, by uniknąć podwójnego liczenia.
      if (vendor != null) {
        vendor['isBudgetLinked'] = false;
        vendor['budgetExpenseId'] = null;
        vendor['contractAmount'] = 0;
        vendor['price'] = 0;
      }
      expense['vendorId'] = null;
      payload['vendors'] = vendors;
      return;
    }

    final amount = _effectiveOf(expense);
    if (vendor != null) {
      vendor['companyName'] = draft.vendorCompany;
      vendor['contactName'] = draft.vendorContact;
      vendor['phone'] = draft.vendorPhone;
      vendor['email'] = draft.vendorEmail;
      vendor['category'] =
          draft.vendorCategory.isEmpty ? 'Inne' : draft.vendorCategory;
      vendor['isBudgetLinked'] = true;
      vendor['budgetExpenseId'] = expId;
      vendor['contractAmount'] = amount;
      vendor['price'] = 0;
      expense['vendorId'] = vendor['id'];
    } else {
      final nextVendorId = _nextId(data['nextVendorId'], vendors);
      vendors.add({
        'id': nextVendorId,
        'category': draft.vendorCategory.isEmpty ? 'Inne' : draft.vendorCategory,
        'customCategory': '',
        'companyName': draft.vendorCompany,
        'contactName': draft.vendorContact,
        'phone': draft.vendorPhone,
        'email': draft.vendorEmail,
        'price': 0,
        'paymentStatus': 'contacted',
        'notes': '',
        'mapUrl': '',
        'isBudgetLinked': true,
        'contractAmount': amount,
        'budgetCategory': (expense['category'] as String?) ?? '',
        'budgetExpenseId': expId,
        'installments': <dynamic>[],
      });
      expense['vendorId'] = nextVendorId;
      payload['nextVendorId'] = nextVendorId + 1;
    }
    payload['vendors'] = vendors;
  }

  double _effectiveOf(Map<String, dynamic> e) {
    final planned = (e['planned'] as num?)?.toDouble() ?? 0;
    final est = (e['estimatedAmount'] as num?)?.toDouble() ?? 0;
    return planned > 0 ? planned : est;
  }

  /// Szybka pozycja — dodaje gotowy wydatek dla danej kategorii (kwota do
  /// uzupełnienia). [known] = czy nazwa jest jedną ze skonfigurowanych kategorii.
  Future<void> addExpenseForCategory(String name, {bool known = true}) =>
      addExpense(ExpenseDraft(
        category: known ? name : 'Inne',
        customName: known ? '' : name,
        planned: 0,
        estimatedAmount: 0,
        paid: 0,
        paymentDate: '',
        note: '',
        splitP1: 0,
        splitP2: 0,
      ));

  Future<void> deleteExpense(int id) async {
    final data = await _read();
    final list = _mapList(_budget(data)['expenses'])
      ..removeWhere((m) => _idOf(m) == id);
    final order = _intList(data['expenseOrder'])..removeWhere((e) => e == id);

    final payload = <String, dynamic>{
      'budgetData': {'expenses': list},
      'expenseOrder': order,
    };

    // Spójność: odłącz zadania i dostawców powiązanych z wydatkiem.
    if (data['tasks'] is List) {
      final tasks = _mapList(data['tasks']);
      for (final t in tasks) {
        if ((t['budgetExpenseId'] as num?)?.toInt() == id) {
          t['budgetExpenseId'] = null;
          t['isBudgetLinked'] = false;
          t['estimatedCost'] = 0;
          t['budgetCategory'] = '';
        }
      }
      payload['tasks'] = tasks;
    }
    if (data['vendors'] is List) {
      final vendors = _mapList(data['vendors']);
      for (final v in vendors) {
        if ((v['budgetExpenseId'] as num?)?.toInt() == id) {
          v['budgetExpenseId'] = null;
          v['isBudgetLinked'] = false;
          v['contractAmount'] = 0;
          v['budgetCategory'] = '';
        }
      }
      payload['vendors'] = vendors;
    }

    await _firestore.mainDoc.set(payload, SetOptions(merge: true));
  }

  // ── NAPOJE (alkohol / bezalkoholowe) ─────────────────────────────────

  Future<void> addBeverage(BeverageKind kind) async {
    final data = await _read();
    final bd = _budget(data);
    final list = _mapList(bd[kind.itemsKey]);
    final nextId = _nextId(bd[kind.idKey], list);
    list.add({
      'id': nextId,
      'type': kind.types.first,
      'name': '',
      'bottles': 0,
      'pricePerBottle': 0,
    });
    await _mergeBudget({kind.itemsKey: list, kind.idKey: nextId + 1});
  }

  Future<void> updateBeverage(BeverageKind kind, int id,
      {String? type, String? name, num? bottles, num? pricePerBottle}) async {
    final data = await _read();
    final list = _mapList(_budget(data)[kind.itemsKey]);
    final item = _find(list, id);
    if (item == null) return;
    if (type != null) item['type'] = type;
    if (name != null) item['name'] = name;
    if (bottles != null) item['bottles'] = bottles;
    if (pricePerBottle != null) item['pricePerBottle'] = pricePerBottle;
    await _mergeBudget({kind.itemsKey: list});
  }

  Future<void> deleteBeverage(BeverageKind kind, int id) async {
    final data = await _read();
    final list = _mapList(_budget(data)[kind.itemsKey])
      ..removeWhere((m) => _idOf(m) == id);
    await _mergeBudget({kind.itemsKey: list});
  }

  Future<void> setBeverageSplit(BeverageKind kind, {num? p1, num? p2}) =>
      _mergeBudget({
        kind.splitP1Key: ?p1,
        kind.splitP2Key: ?p2,
      });

  Future<void> setBeveragePerPersonVirtual(BeverageKind kind, bool value) =>
      _mergeBudget({kind.perVirtualKey: value});

  /// Ukrywa/przywraca boczny panel napojów. Ukryty panel NIE jest liczony
  /// w budżecie, ale pozycje pozostają zapisane (nie kasujemy danych).
  Future<void> setBeveragePanelHidden(BeverageKind kind, bool hidden) =>
      _mergeBudget({kind.panelHiddenKey: hidden});

  // ── PODRÓŻ POŚLUBNA ──────────────────────────────────────────────────

  Future<void> updateHoneymoon({
    String? name,
    String? link,
    num? totalAmount,
    num? estimatedAmount,
  }) =>
      _mergeBudget({
        'honeymoon': {
          'name': ?name,
          'link': ?link,
          'totalAmount': ?totalAmount,
          'estimatedAmount': ?estimatedAmount,
        },
      });

  Future<void> addHoneymoonInstallment() async {
    final data = await _read();
    final hm = _honeymoon(data);
    final list = _mapList(hm['installments']);
    final nextId = _nextId(data['nextHoneymoonInstId'], list);
    list.add({
      'id': nextId,
      'amount': 0,
      'dueDate': '',
      'paidBy': 'both',
      'status': 'pending',
    });
    await _firestore.mainDoc.set({
      'budgetData': {
        'honeymoon': {'installments': list},
      },
      'nextHoneymoonInstId': nextId + 1,
    }, SetOptions(merge: true));
  }

  Future<void> updateHoneymoonInstallment(int id,
      {num? amount, String? dueDate, String? paidBy, String? status}) async {
    final data = await _read();
    final list = _mapList(_honeymoon(data)['installments']);
    final item = _find(list, id);
    if (item == null) return;
    if (amount != null) item['amount'] = amount;
    if (dueDate != null) item['dueDate'] = dueDate;
    if (paidBy != null) item['paidBy'] = paidBy;
    if (status != null) item['status'] = status;
    await _mergeBudget({
      'honeymoon': {'installments': list},
    });
  }

  Future<void> deleteHoneymoonInstallment(int id) async {
    final data = await _read();
    final list = _mapList(_honeymoon(data)['installments'])
      ..removeWhere((m) => _idOf(m) == id);
    await _mergeBudget({
      'honeymoon': {'installments': list},
    });
  }

  // ── PODRÓŻ POŚLUBNA — warianty/propozycje ────────────────────────────
  // Do budżetu wchodzi tylko wybrany wariant (lub najdroższy, gdy włączone
  // „wlicz droższą wersję"). Wybór zapisujemy też do `totalAmount`/`name`/
  // `link`, by reszta aplikacji (podsumowanie, płatności) działała bez zmian.

  Future<void> addHoneymoonOption() async {
    final data = await _read();
    final hm = _honeymoon(data);
    final list = _mapList(hm['options']);
    final nextId = _nextId(data['nextHoneymoonOptId'], list);
    // Pierwszy wariant dziedziczy dotychczasową kwotę/nazwę/link (bez utraty).
    final seedFirst = list.isEmpty;
    list.add({
      'id': nextId,
      'name': seedFirst ? (hm['name'] ?? '') : '',
      'link': seedFirst ? (hm['link'] ?? '') : '',
      'amount': seedFirst ? (hm['totalAmount'] ?? 0) : 0,
    });
    hm['options'] = list;
    hm['selectedOptionId'] ??= nextId;
    _applyHoneymoonSelection(hm);
    await _firestore.mainDoc.set({
      'budgetData': {'honeymoon': hm},
      'nextHoneymoonOptId': nextId + 1,
    }, SetOptions(merge: true));
  }

  Future<void> updateHoneymoonOption(int id,
      {String? name, String? link, num? amount}) async {
    final data = await _read();
    final hm = _honeymoon(data);
    final list = _mapList(hm['options']);
    final item = _find(list, id);
    if (item == null) return;
    if (name != null) item['name'] = name;
    if (link != null) item['link'] = link;
    if (amount != null) item['amount'] = amount;
    hm['options'] = list;
    _applyHoneymoonSelection(hm);
    await _mergeBudget({'honeymoon': hm});
  }

  Future<void> deleteHoneymoonOption(int id) async {
    final data = await _read();
    final hm = _honeymoon(data);
    final list = _mapList(hm['options'])..removeWhere((m) => _idOf(m) == id);
    hm['options'] = list;
    if ((hm['selectedOptionId'] as num?)?.toInt() == id) {
      hm['selectedOptionId'] = list.isNotEmpty ? _idOf(list.first) : null;
    }
    _applyHoneymoonSelection(hm);
    await _mergeBudget({'honeymoon': hm});
  }

  Future<void> selectHoneymoonOption(int id) async {
    final data = await _read();
    final hm = _honeymoon(data);
    hm['selectedOptionId'] = id;
    _applyHoneymoonSelection(hm);
    await _mergeBudget({'honeymoon': hm});
  }

  /// Czy kwota podróży wlicza się do sum budżetu — patrz
  /// `HoneymoonSummary.includeInBudget` / `BudgetSummary.honeymoonTotal`.
  Future<void> setHoneymoonIncludeInBudget(bool value) =>
      _mergeBudget({
        'honeymoon': {'includeInBudget': value},
      });

  Future<void> setHoneymoonUseHigher(bool value) async {
    final data = await _read();
    final hm = _honeymoon(data);
    hm['useHigher'] = value;
    _applyHoneymoonSelection(hm);
    await _mergeBudget({'honeymoon': hm});
  }

  /// Ustawia `totalAmount`/`name`/`link` na podstawie wybranego wariantu
  /// (lub najdroższego, gdy `useHigher`). Bez wariantów nie zmienia nic.
  void _applyHoneymoonSelection(Map<String, dynamic> hm) {
    final opts = _mapList(hm['options']);
    if (opts.isEmpty) return;
    Map<String, dynamic>? chosen;
    if (hm['useHigher'] == true) {
      for (final o in opts) {
        final a = (o['amount'] as num?)?.toDouble() ?? 0;
        final best = (chosen?['amount'] as num?)?.toDouble() ?? -1;
        if (chosen == null || a > best) chosen = o;
      }
    } else {
      final sel = (hm['selectedOptionId'] as num?)?.toInt();
      chosen = (sel != null ? _find(opts, sel) : null) ?? opts.first;
    }
    if (chosen != null) {
      hm['totalAmount'] = chosen['amount'] ?? 0;
      hm['name'] = chosen['name'] ?? '';
      hm['link'] = chosen['link'] ?? '';
    }
  }

  // ── Pomocnicze ──────────────────────────────────────────────────────

  Future<void> _mergeBudget(Map<String, dynamic> fields) =>
      _firestore.mainDoc.set({'budgetData': fields}, SetOptions(merge: true));

  Future<Map<String, dynamic>> _read() async =>
      await _firestore.readData() ?? <String, dynamic>{};

  Map<String, dynamic> _budget(Map<String, dynamic> data) =>
      data['budgetData'] is Map
          ? Map<String, dynamic>.from(data['budgetData'] as Map)
          : <String, dynamic>{};

  Map<String, dynamic> _tableDeco(Map<String, dynamic> data) {
    final deco = _budget(data)['tableDeco'];
    return deco is Map ? Map<String, dynamic>.from(deco) : <String, dynamic>{};
  }

  Map<String, dynamic> _honeymoon(Map<String, dynamic> data) {
    final hm = _budget(data)['honeymoon'];
    return hm is Map ? Map<String, dynamic>.from(hm) : <String, dynamic>{};
  }

  List<Map<String, dynamic>> _mapList(dynamic value) => value is List
      ? value.map((e) => Map<String, dynamic>.from(e as Map)).toList()
      : <Map<String, dynamic>>[];

  List<int> _intList(dynamic value) => value is List
      ? value.map((e) => (e as num?)?.toInt()).whereType<int>().toList()
      : <int>[];

  int _nextId(dynamic stored, List<Map<String, dynamic>> list) {
    final s = (stored as num?)?.toInt() ?? 1;
    var maxId = 0;
    for (final m in list) {
      final i = _idOf(m) ?? 0;
      if (i > maxId) maxId = i;
    }
    return max(s, maxId + 1);
  }

  Map<String, dynamic>? _find(List<Map<String, dynamic>> list, int id) {
    for (final m in list) {
      if (_idOf(m) == id) return m;
    }
    return null;
  }

  int? _idOf(Map<String, dynamic> m) => (m['id'] as num?)?.toInt();
}
