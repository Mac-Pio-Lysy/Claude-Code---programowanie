import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_service.dart';

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
  });

  final String name;
  final String startDate;
  final String endDate;
  final String dueDate;
  final String responsible;
  final String assigneeName;
  final String status;
  final String priority;

  Map<String, dynamic> toFields() => {
        'name': name,
        'startDate': startDate,
        'endDate': endDate,
        'dueDate': dueDate,
        'responsible': responsible,
        'assigneeName': assigneeName,
        'status': status,
        'priority': priority,
      };
}

/// Operacje na zadaniach (`tasks`) w `weddingPlanner/main`.
class TaskService {
  TaskService({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  final FirestoreService _firestore;

  Future<void> addTask(TaskDraft draft) async {
    final data = await _read();
    final list = _mapList(data['tasks']);
    final nextId = _nextId(data['nextTaskId'], list);
    list.add({
      'id': nextId,
      'linkType': '',
      'linkId': null,
      'vendorId': null,
      'giftId': null,
      'isBudgetLinked': false,
      'estimatedCost': 0,
      'budgetCategory': '',
      'budgetExpenseId': null,
      ...draft.toFields(),
    });
    await _firestore.mainDoc.set({
      'tasks': list,
      'nextTaskId': nextId + 1,
    }, SetOptions(merge: true));
  }

  Future<void> updateTask(int id, TaskDraft draft) async {
    final data = await _read();
    final list = _mapList(data['tasks']);
    final item = _find(list, id);
    if (item == null) return;
    item.addAll(draft.toFields());
    await _firestore.mainDoc.set({'tasks': list}, SetOptions(merge: true));
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

  Future<void> deleteTask(int id) async {
    final data = await _read();
    final list = _mapList(data['tasks'])..removeWhere((m) => _idOf(m) == id);
    await _firestore.mainDoc.set({'tasks': list}, SetOptions(merge: true));
  }

  // ── Pomocnicze ──
  Future<Map<String, dynamic>> _read() async =>
      await _firestore.readData() ?? <String, dynamic>{};

  List<Map<String, dynamic>> _mapList(dynamic value) => value is List
      ? value.map((e) => Map<String, dynamic>.from(e as Map)).toList()
      : <Map<String, dynamic>>[];

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
