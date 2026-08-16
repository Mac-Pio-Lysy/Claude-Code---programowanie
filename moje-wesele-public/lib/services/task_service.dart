import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_service.dart';
import '../l10n/app_text.dart';

/// Wybór powiązania dla jednej sekcji (Dostawca / Transport / Nocleg / Muzyka).
/// `existingId` → powiąż z istniejącym elementem; `createNew` → utwórz nowy
/// (referencja, NIE kopia); oba puste → brak powiązania (odłącz).
class TaskLinkChoice {
  const TaskLinkChoice({this.existingId, this.createNew = false});
  final int? existingId;
  final bool createNew;

  static const none = TaskLinkChoice();
}

/// Dane zadania z formularza.
class TaskDraft {
  TaskDraft({
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.dueDate,
    required this.responsible,
    required this.assigneeName,
    required this.status,
    required this.priority,
    required this.goal,
    required this.goalAchieved,
    required this.isBudgetLinked,
    required this.estimatedCost,
    required this.budgetCategory,
    this.vendorLink = TaskLinkChoice.none,
    this.transportLink = TaskLinkChoice.none,
    this.accommodationLink = TaskLinkChoice.none,
    this.musicLink = TaskLinkChoice.none,
  });

  /// Powiązania przez referencję (ID). Budżet jest obsługiwany osobno
  /// (isBudgetLinked/estimatedCost/budgetCategory → wpis w budgetData.expenses).
  final TaskLinkChoice vendorLink;
  final TaskLinkChoice transportLink;
  final TaskLinkChoice accommodationLink;
  final TaskLinkChoice musicLink;

  final String name;
  final String startDate;
  final String endDate;
  final String dueDate;
  final String responsible;
  final String assigneeName;
  final String status;
  final String priority;

  /// Cel/zdarzenie powiązane z zadaniem (np. „Znalezienie DJa").
  final String goal;
  final bool goalAchieved;

  /// Powiązanie z budżetem — obsługiwane osobno przez
  /// [TaskService._syncBudgetLink] (referencja, bez duplikatów).
  final bool isBudgetLinked;
  final num estimatedCost;
  final String budgetCategory;

  Map<String, dynamic> toFields() => {
        'name': name,
        'startDate': startDate,
        'endDate': endDate,
        'dueDate': dueDate,
        'responsible': responsible,
        'assigneeName': assigneeName,
        'status': status,
        'priority': priority,
        'goal': goal,
        'goalAchieved': goalAchieved,
      };
}

/// Operacje na zadaniach (`tasks`) w `weddingPlanner/main`.
///
/// Powiązanie z budżetem to REFERENCJA, nie kopia: zadanie trzyma
/// `budgetExpenseId` wskazujący wpis w `budgetData.expenses` (jak przy
/// dostawcach w `VendorService`) — włączenie powiązania tworzy wpis (lub
/// aktualizuje istniejący), a nie duplikuje go.
class TaskService {
  TaskService({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  final FirestoreService _firestore;

  Future<void> addTask(TaskDraft draft) async {
    final data = await _read();
    final list = _mapList(data['tasks']);
    final nextId = _nextId(data['nextTaskId'], list);
    final task = <String, dynamic>{
      'id': nextId,
      'linkType': '',
      'linkId': null,
      'vendorId': null,
      'giftId': null,
      'isBudgetLinked': false,
      'estimatedCost': 0,
      'budgetCategory': '',
      'budgetExpenseId': null,
      'transportId': null,
      'accommodationId': null,
      'musicId': null,
      ...draft.toFields(),
    };

    final payload = <String, dynamic>{'nextTaskId': nextId + 1};
    _syncBudgetLink(
      data: data,
      task: task,
      isBudgetLinked: draft.isBudgetLinked,
      estimatedCost: draft.estimatedCost,
      budgetCategory: draft.budgetCategory,
      payload: payload,
    );
    _syncRefLinks(data, task, draft, payload);

    list.add(task);
    payload['tasks'] = list;
    await _firestore.mainDoc.set(payload, SetOptions(merge: true));
  }

  Future<void> updateTask(int id, TaskDraft draft) async {
    final data = await _read();
    final list = _mapList(data['tasks']);
    final item = _find(list, id);
    if (item == null) return;
    item.addAll(draft.toFields());

    final payload = <String, dynamic>{};
    _syncBudgetLink(
      data: data,
      task: item,
      isBudgetLinked: draft.isBudgetLinked,
      estimatedCost: draft.estimatedCost,
      budgetCategory: draft.budgetCategory,
      payload: payload,
    );
    _syncRefLinks(data, item, draft, payload);

    payload['tasks'] = list;
    await _firestore.mainDoc.set(payload, SetOptions(merge: true));
  }

  /// Zmiana statusu (przeciągnięcie na inną kolumnę Kanban).
  Future<void> updateStatus(int id, String status) async {
    final data = await _read();
    final list = _mapList(data['tasks']);
    final item = _find(list, id);
    if (item == null || item['status'] == status) return;
    item['status'] = status;
    await _firestore.mainDoc.set({'tasks': list}, SetOptions(merge: true));
  }

  /// Szybkie oznaczenie „cel osiągnięty" bezpośrednio z widoku zadań
  /// (bez otwierania formularza edycji).
  Future<void> setGoalAchieved(int id, bool achieved) async {
    final data = await _read();
    final list = _mapList(data['tasks']);
    final item = _find(list, id);
    if (item == null) return;
    item['goalAchieved'] = achieved;
    await _firestore.mainDoc.set({'tasks': list}, SetOptions(merge: true));
  }

  /// Tworzy/aktualizuje powiązany wpis budżetowy dla zadania — wywoływane po
  /// potwierdzeniu „Czy utworzyć z tego pozycję w budżecie?" bezpośrednio
  /// z widoku zadań.
  Future<void> linkToBudget(
    int id, {
    required num estimatedCost,
    required String budgetCategory,
  }) async {
    final data = await _read();
    final list = _mapList(data['tasks']);
    final item = _find(list, id);
    if (item == null) return;

    final payload = <String, dynamic>{};
    _syncBudgetLink(
      data: data,
      task: item,
      isBudgetLinked: true,
      estimatedCost: estimatedCost,
      budgetCategory: budgetCategory,
      payload: payload,
    );

    payload['tasks'] = list;
    await _firestore.mainDoc.set(payload, SetOptions(merge: true));
  }

  Future<void> deleteTask(int id) async {
    final data = await _read();
    final list = _mapList(data['tasks'])..removeWhere((m) => _idOf(m) == id);
    await _firestore.mainDoc.set({'tasks': list}, SetOptions(merge: true));
  }

  // ── Powiązanie z budżetem ────────────────────────────────────────────

  /// Synchronizuje powiązany wpis budżetowy (mutuje [task] i dopisuje
  /// zmiany do [payload]). Odwzorowuje logikę `VendorService._syncBudgetLink`.
  void _syncBudgetLink({
    required Map<String, dynamic> data,
    required Map<String, dynamic> task,
    required bool isBudgetLinked,
    required num estimatedCost,
    required String budgetCategory,
    required Map<String, dynamic> payload,
  }) {
    if (!isBudgetLinked) {
      // Odłączenie — wpis w budżecie pozostaje, czyścimy tylko referencję.
      task['isBudgetLinked'] = false;
      task['estimatedCost'] = 0;
      task['budgetCategory'] = '';
      task['budgetExpenseId'] = null;
      return;
    }

    task['isBudgetLinked'] = true;
    task['estimatedCost'] = estimatedCost;
    task['budgetCategory'] = budgetCategory.isEmpty ? 'Inne' : budgetCategory;

    final name = (task['name'] as String?) ?? '';
    final expenses = _mapList(_budget(data)['expenses']);
    final order = _intList(data['expenseOrder']);
    final expId = (task['budgetExpenseId'] as num?)?.toInt();
    final existing = expId != null ? _find(expenses, expId) : null;

    if (existing != null) {
      // Edytuj TEN SAM wpis — bez duplikatu.
      existing['category'] = task['budgetCategory'];
      existing['customName'] = name;
      existing['estimatedAmount'] = estimatedCost;
      existing['origin'] = 'tasks';
    } else {
      final newId = _nextId(data['nextExpenseId'], expenses);
      expenses.add({
        'id': newId,
        'category': task['budgetCategory'],
        'customName': name,
        'planned': 0,
        'estimatedAmount': estimatedCost,
        'paid': 0,
        'paymentDate': '',
        'note': AppText.t.taskSvc_fromTask(name),
        'splitP1': 0,
        'splitP2': 0,
        'sidePanel': false,
        'origin': 'tasks',
      });
      order.add(newId);
      task['budgetExpenseId'] = newId;
      payload['nextExpenseId'] = newId + 1;
    }

    payload['budgetData'] = {'expenses': expenses};
    payload['expenseOrder'] = order;
  }

  // ── Powiązania przez referencję (Dostawca / Transport / Nocleg / Muzyka) ──

  /// Synchronizuje wszystkie powiązania referencyjne zadania. Każde ustawia
  /// tylko ID na zadaniu (bez kopiowania danych) lub tworzy nowy element,
  /// którego rekord (SSOT) trafia do właściwej kolekcji.
  void _syncRefLinks(
    Map<String, dynamic> data,
    Map<String, dynamic> task,
    TaskDraft draft,
    Map<String, dynamic> payload,
  ) {
    final name = (task['name'] as String?) ?? '';
    _syncRefLink(data, task, draft.vendorLink, payload,
        idField: 'vendorId',
        listKey: 'vendors',
        nextKey: 'nextVendorId',
        create: () => _newVendor(name));
    _syncRefLink(data, task, draft.transportLink, payload,
        idField: 'transportId',
        listKey: 'vehicles',
        nextKey: 'nextVehicleId',
        create: () => _newVehicle(name));
    _syncRefLink(data, task, draft.accommodationLink, payload,
        idField: 'accommodationId',
        listKey: 'hotels',
        nextKey: 'nextHotelId',
        create: () => _newHotel(name));
    _syncRefLink(data, task, draft.musicLink, payload,
        idField: 'musicId',
        listKey: 'songs',
        nextKey: 'nextSongId',
        create: () => _newSong(name));
  }

  /// Pojedyncze powiązanie: utwórz nowy element / powiąż z istniejącym / odłącz.
  /// [create] zwraca rekord BEZ pola `id` (nadawane tutaj).
  void _syncRefLink(
    Map<String, dynamic> data,
    Map<String, dynamic> task,
    TaskLinkChoice choice,
    Map<String, dynamic> payload, {
    required String idField,
    required String listKey,
    required String nextKey,
    required Map<String, dynamic> Function() create,
  }) {
    if (choice.createNew) {
      final list = _mapList(payload[listKey] ?? data[listKey]);
      final newId = _nextId(payload[nextKey] ?? data[nextKey], list);
      list.add({'id': newId, ...create()});
      task[idField] = newId;
      payload[listKey] = list;
      payload[nextKey] = newId + 1;
    } else {
      // Powiązanie z istniejącym (ID) lub odłączenie (null). Dane elementu
      // pozostają nietknięte — trzymamy wyłącznie referencję.
      task[idField] = choice.existingId;
    }
  }

  Map<String, dynamic> _newVendor(String name) => {
        'category': 'Inne',
        'customCategory': '',
        'companyName': name.isEmpty ? 'Dostawca' : name,
        'contactName': '',
        'phone': '',
        'email': '',
        'price': 0,
        'paymentStatus': 'contacted',
        'notes': name.isEmpty ? '' : AppText.t.taskSvc_fromTask(name),
        'mapUrl': '',
        'isBudgetLinked': false,
        'contractAmount': 0,
        'budgetCategory': '',
        'budgetExpenseId': null,
        'installments': <dynamic>[],
      };

  Map<String, dynamic> _newVehicle(String name) => {
        'guestIds': <dynamic>[],
        'type': 'Autokar',
        'description': name.isEmpty ? 'Transport' : name,
        'driver': '',
        'seats': 0,
        'route': '',
        'departureTime': '',
        'cost': 0,
      };

  Map<String, dynamic> _newHotel(String name) => {
        'name': name.isEmpty ? 'Nocleg' : name,
        'address': '',
        'phone': '',
        'pricePerNight': 0,
        'personsPerRoom': 1,
        'bookingLink': '',
        'notes': name.isEmpty ? '' : AppText.t.taskSvc_fromTask(name),
        'inComplex': false,
      };

  Map<String, dynamic> _newSong(String name) => {
        'title': name.isEmpty ? AppText.t.taskSvc_song : name,
        'artist': '',
        'cover': '',
        'preview': '',
        'moment': 'Inne',
        'genre': '',
        'status': 'proposal',
        'fromGuest': false,
        'guestName': '',
        'unmatched': true,
        'specialMoment': '',
      };

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

  Map<String, dynamic>? _find(List<Map<String, dynamic>> list, int id) {
    for (final m in list) {
      if (_idOf(m) == id) return m;
    }
    return null;
  }

  int? _idOf(Map<String, dynamic> m) => (m['id'] as num?)?.toInt();
}
