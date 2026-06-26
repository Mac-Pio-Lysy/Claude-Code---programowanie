import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_service.dart';

/// Dane dostawcy z formularza.
class VendorDraft {
  VendorDraft({
    required this.category,
    required this.customCategory,
    required this.companyName,
    required this.contactName,
    required this.phone,
    required this.email,
    required this.price,
    required this.paymentStatus,
    required this.mapUrl,
    required this.notes,
    required this.isBudgetLinked,
    required this.contractAmount,
    required this.budgetCategory,
  });

  final String category;
  final String customCategory;
  final String companyName;
  final String contactName;
  final String phone;
  final String email;
  final num price;
  final String paymentStatus;
  final String mapUrl;
  final String notes;
  final bool isBudgetLinked;
  final num contractAmount;
  final String budgetCategory;
}

/// Operacje na dostawcach (`vendors`) w `weddingPlanner/main`.
///
/// Powiązanie z budżetem to REFERENCJA, nie kopia: dostawca trzyma
/// `budgetExpenseId` wskazujący wpis w `budgetData.expenses`. Włączenie
/// powiązania tworzy wpis (lub aktualizuje istniejący), a nie duplikuje go.
class VendorService {
  VendorService({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  final FirestoreService _firestore;

  Future<void> addVendor(VendorDraft draft) async {
    final data = await _read();
    final vendors = _mapList(data['vendors']);
    final nextVendorId = _nextId(data['nextVendorId'], vendors);

    final vendor = <String, dynamic>{
      'id': nextVendorId,
      'category': draft.category,
      'customCategory': draft.customCategory,
      'companyName': draft.companyName,
      'contactName': draft.contactName,
      'phone': draft.phone,
      'email': draft.email,
      'price': draft.price,
      'paymentStatus': draft.paymentStatus,
      'notes': draft.notes,
      'mapUrl': draft.mapUrl,
      'isBudgetLinked': false,
      'contractAmount': 0,
      'budgetCategory': '',
      'budgetExpenseId': null,
      'installments': <dynamic>[],
    };

    final payload = <String, dynamic>{'nextVendorId': nextVendorId + 1};
    _syncBudgetLink(data, vendor, draft, payload);

    vendors.add(vendor);
    payload['vendors'] = vendors;
    await _firestore.mainDoc.set(payload, SetOptions(merge: true));
  }

  Future<void> updateVendor(int id, VendorDraft draft) async {
    final data = await _read();
    final vendors = _mapList(data['vendors']);
    final vendor = _find(vendors, id);
    if (vendor == null) return;

    vendor['category'] = draft.category;
    vendor['customCategory'] = draft.customCategory;
    vendor['companyName'] = draft.companyName;
    vendor['contactName'] = draft.contactName;
    vendor['phone'] = draft.phone;
    vendor['email'] = draft.email;
    vendor['price'] = draft.price;
    vendor['paymentStatus'] = draft.paymentStatus;
    vendor['notes'] = draft.notes;
    vendor['mapUrl'] = draft.mapUrl;

    final payload = <String, dynamic>{};
    _syncBudgetLink(data, vendor, draft, payload);

    payload['vendors'] = vendors;
    await _firestore.mainDoc.set(payload, SetOptions(merge: true));
  }

  /// Szybka zmiana pojedynczego pola (np. kategoria/status na karcie).
  Future<void> setField(int id, String field, dynamic value) async {
    final data = await _read();
    final vendors = _mapList(data['vendors']);
    final vendor = _find(vendors, id);
    if (vendor == null) return;
    vendor[field] = value;
    await _firestore.mainDoc.set({'vendors': vendors}, SetOptions(merge: true));
  }

  Future<void> deleteVendor(int id, {bool deleteLinkedExpense = false}) async {
    final data = await _read();
    final vendors = _mapList(data['vendors']);
    final vendor = _find(vendors, id);
    if (vendor == null) return;

    final payload = <String, dynamic>{};

    final expId = (vendor['budgetExpenseId'] as num?)?.toInt();
    if (deleteLinkedExpense && vendor['isBudgetLinked'] == true && expId != null) {
      final expenses = _mapList(_budget(data)['expenses'])
        ..removeWhere((e) => _idOf(e) == expId);
      final order = _intList(data['expenseOrder'])..removeWhere((e) => e == expId);
      payload['budgetData'] = {'expenses': expenses};
      payload['expenseOrder'] = order;
    }

    vendors.removeWhere((v) => _idOf(v) == id);
    payload['vendors'] = vendors;

    // Spójność: wyczyść powiązanie w zadaniach.
    if (data['tasks'] is List) {
      final tasks = _mapList(data['tasks']);
      for (final t in tasks) {
        if ((t['vendorId'] as num?)?.toInt() == id) t['vendorId'] = null;
      }
      payload['tasks'] = tasks;
    }

    await _firestore.mainDoc.set(payload, SetOptions(merge: true));
  }

  // ── RATY ─────────────────────────────────────────────────────────────

  Future<void> addInstallment(int vendorId) async {
    final data = await _read();
    final vendors = _mapList(data['vendors']);
    final vendor = _find(vendors, vendorId);
    if (vendor == null) return;
    final insts = _mapList(vendor['installments']);
    final nextId = _nextInstId(insts);
    final label = insts.isEmpty ? 'Zadatek' : '${insts.length}. rata';
    insts.add(
        {'id': nextId, 'label': label, 'amount': 0, 'dueDate': '', 'status': 'due'});
    vendor['installments'] = insts;
    await _firestore.mainDoc.set({'vendors': vendors}, SetOptions(merge: true));
  }

  Future<void> updateInstallment(int vendorId, int instId,
      {String? label, num? amount, String? dueDate, String? status}) async {
    final data = await _read();
    final vendors = _mapList(data['vendors']);
    final vendor = _find(vendors, vendorId);
    if (vendor == null) return;
    final insts = _mapList(vendor['installments']);
    final inst = _find(insts, instId);
    if (inst == null) return;
    if (label != null) inst['label'] = label;
    if (amount != null) inst['amount'] = amount;
    if (dueDate != null) inst['dueDate'] = dueDate;
    if (status != null) inst['status'] = status;
    vendor['installments'] = insts;
    await _firestore.mainDoc.set({'vendors': vendors}, SetOptions(merge: true));
  }

  Future<void> deleteInstallment(int vendorId, int instId) async {
    final data = await _read();
    final vendors = _mapList(data['vendors']);
    final vendor = _find(vendors, vendorId);
    if (vendor == null) return;
    final insts = _mapList(vendor['installments'])
      ..removeWhere((i) => _idOf(i) == instId);
    vendor['installments'] = insts;
    await _firestore.mainDoc.set({'vendors': vendors}, SetOptions(merge: true));
  }

  // ── Powiązanie z budżetem ────────────────────────────────────────────

  /// Synchronizuje powiązany wpis budżetowy (mutuje [vendor] i dopisuje
  /// zmiany do [payload]). Odwzorowuje logikę zapisu dostawcy w wersji web.
  void _syncBudgetLink(Map<String, dynamic> data, Map<String, dynamic> vendor,
      VendorDraft draft, Map<String, dynamic> payload) {
    if (!draft.isBudgetLinked) {
      // Odłączenie — wpis w budżecie pozostaje, czyścimy tylko referencję.
      vendor['isBudgetLinked'] = false;
      vendor['contractAmount'] = 0;
      vendor['budgetCategory'] = '';
      vendor['budgetExpenseId'] = null;
      return;
    }

    vendor['isBudgetLinked'] = true;
    vendor['contractAmount'] = draft.contractAmount;
    vendor['budgetCategory'] =
        draft.budgetCategory.isEmpty ? 'Inne' : draft.budgetCategory;

    final label = _vendorLabel(vendor);
    final expenses = _mapList(_budget(data)['expenses']);
    final order = _intList(data['expenseOrder']);
    final expId = (vendor['budgetExpenseId'] as num?)?.toInt();
    final existing = expId != null ? _find(expenses, expId) : null;

    if (existing != null) {
      // Edytuj TEN SAM wpis — bez duplikatu.
      existing['category'] = vendor['budgetCategory'];
      existing['customName'] = label;
      existing['estimatedAmount'] = draft.contractAmount;
      existing['vendorId'] = vendor['id'];
    } else {
      final newId = _nextId(data['nextExpenseId'], expenses);
      expenses.add({
        'id': newId,
        'category': vendor['budgetCategory'],
        'customName': label,
        'planned': 0,
        'estimatedAmount': draft.contractAmount,
        'paid': 0,
        'paymentDate': '',
        'note': 'Dostawca: $label',
        'splitP1': 0,
        'splitP2': 0,
        'sidePanel': false,
        'vendorId': vendor['id'],
      });
      order.add(newId);
      vendor['budgetExpenseId'] = newId;
      payload['nextExpenseId'] = newId + 1;
    }

    payload['budgetData'] = {'expenses': expenses};
    payload['expenseOrder'] = order;
  }

  String _vendorLabel(Map<String, dynamic> v) {
    final company = (v['companyName'] as String?)?.trim() ?? '';
    if (company.isNotEmpty) return company;
    final contact = (v['contactName'] as String?)?.trim() ?? '';
    if (contact.isNotEmpty) return contact;
    final cat = (v['category'] as String?) ?? '';
    if (cat == 'Inne') {
      final custom = (v['customCategory'] as String?)?.trim() ?? '';
      if (custom.isNotEmpty) return custom;
    } else if (cat.isNotEmpty) {
      return cat;
    }
    return 'Dostawca';
  }

  // ── Pomocnicze ──
  Future<Map<String, dynamic>> _read() async =>
      await _firestore.readData() ?? <String, dynamic>{};

  Map<String, dynamic> _budget(Map<String, dynamic> data) =>
      data['budgetData'] is Map
          ? Map<String, dynamic>.from(data['budgetData'] as Map)
          : <String, dynamic>{};

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

  int _nextInstId(List<Map<String, dynamic>> insts) {
    var n = 1;
    for (final i in insts) {
      final id = _idOf(i) ?? 0;
      if (id + 1 > n) n = id + 1;
    }
    return n;
  }

  Map<String, dynamic>? _find(List<Map<String, dynamic>> list, int id) {
    for (final m in list) {
      if (_idOf(m) == id) return m;
    }
    return null;
  }

  int? _idOf(Map<String, dynamic> m) => (m['id'] as num?)?.toInt();
}
