import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/beverage.dart';
import 'firestore_service.dart';

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

  Future<void> setPricePerPerson(num value) =>
      _mergeBudget({'pricePerPerson': value});

  Future<void> setVenueMinGuests(num value) =>
      _mergeBudget({'venueMinGuests': value});

  Future<void> setIncludeVirtual(bool value) =>
      _mergeBudget({'includeVirtualInCalc': value});

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
    list.add({
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
    });
    order.add(nextId);
    await _firestore.mainDoc.set({
      'budgetData': {'expenses': list},
      'nextExpenseId': nextId + 1,
      'expenseOrder': order,
    }, SetOptions(merge: true));
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
    await _mergeBudget({'expenses': list});
  }

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
