import 'package:flutter/material.dart';

import 'couple.dart';

/// Status zadania (kolumny Kanban).
class TaskStatus {
  const TaskStatus(this.id, this.label, this.color, this.icon);
  final String id;
  final String label;
  final Color color;
  final String icon;

  static const todo = TaskStatus('todo', 'Do zrobienia', Color(0xFFEF4444), '📋');
  static const inProgress =
      TaskStatus('inprogress', 'W trakcie', Color(0xFFF59E0B), '⏳');
  static const done = TaskStatus('done', 'Zrobione', Color(0xFF10B981), '✅');
  static const cancelled =
      TaskStatus('cancelled', 'Anulowane', Color(0xFF94A3B8), '🚫');

  /// Kolumny tablicy Kanban (KANBAN_COLS w wersji web).
  static const List<TaskStatus> columns = [todo, inProgress, done, cancelled];

  static TaskStatus byId(String? id) =>
      columns.firstWhere((s) => s.id == id, orElse: () => todo);
}

/// Osoba odpowiedzialna (organizatorzy).
class TaskPerson {
  const TaskPerson(this.id, this.color);
  final String id;
  final Color color;

  /// Etykieta wyliczana z typu uroczystości. Identyfikatory `'groom'`/`'bride'`
  /// zostają w bazie bez zmian — patrz [CoupleLabels].
  String get label => switch (id) {
        'bride' => CoupleLabels.current.person1,
        'groom' => CoupleLabels.current.person2,
        _ => 'Oboje',
      };

  static const groom = TaskPerson('groom', Color(0xFF3B82F6));
  static const bride = TaskPerson('bride', Color(0xFFEC4899));
  static const both = TaskPerson('both', Color(0xFF6B7280));

  static const List<TaskPerson> all = [groom, bride, both];

  static TaskPerson byId(String? id) =>
      all.firstWhere((p) => p.id == id, orElse: () => both);
}

/// Priorytet zadania.
class TaskPriority {
  const TaskPriority(this.id, this.label, this.color, this.icon);
  final String id;
  final String label;
  final Color color;
  final String icon;

  static const low = TaskPriority('low', 'Niski', Color(0xFF10B981), '🟢');
  static const med = TaskPriority('med', 'Średni', Color(0xFFF59E0B), '🟡');
  static const high = TaskPriority('high', 'Wysoki', Color(0xFFEF4444), '🔴');

  static const List<TaskPriority> all = [low, med, high];

  static TaskPriority byId(String? id) =>
      all.firstWhere((p) => p.id == id, orElse: () => med);
}

/// Prekonfigurowane cele/zdarzenia do szybkiego powiązania z zadaniem
/// (np. „Znalezienie DJa" → po zaznaczeniu jako osiągnięty można od razu
/// utworzyć powiązaną pozycję budżetową).
class TaskGoalPreset {
  TaskGoalPreset._();

  static const List<String> all = [
    'Znalezienie DJa',
    'Znalezienie orkiestry/zespołu',
    'Rezerwacja sali',
    'Znalezienie fotografa',
    'Znalezienie kamerzysty',
    'Wybór sukni ślubnej',
    'Wybór garnituru',
    'Zamówienie tortu',
    'Zamówienie kwiatów/dekoracji',
    'Rezerwacja hotelu dla gości',
    'Wybór obrączek',
    'Zaproszenia ślubne',
  ];
}

/// Zadanie — nakładka na surową mapę (zachowuje wszystkie pola z wersji web).
class Task {
  Task(this.raw);
  final Map<String, dynamic> raw;

  int? get id => (raw['id'] as num?)?.toInt();
  String get name => (raw['name'] as String?) ?? '';
  String get startDate => (raw['startDate'] as String?) ?? '';
  String get endDate => (raw['endDate'] as String?) ?? '';
  String get dueDate => (raw['dueDate'] as String?) ?? '';
  String get responsible => (raw['responsible'] as String?) ?? 'both';
  String get statusId => (raw['status'] as String?) ?? 'todo';
  String get priorityId => (raw['priority'] as String?) ?? 'med';
  String get assigneeName => (raw['assigneeName'] as String?) ?? '';

  int? get vendorId => (raw['vendorId'] as num?)?.toInt();
  int? get giftId => (raw['giftId'] as num?)?.toInt();
  bool get isBudgetLinked => raw['isBudgetLinked'] == true;
  double get estimatedCost => (raw['estimatedCost'] as num?)?.toDouble() ?? 0;
  String get budgetCategory => (raw['budgetCategory'] as String?) ?? '';
  int? get budgetExpenseId => (raw['budgetExpenseId'] as num?)?.toInt();

  /// Powiązania przez REFERENCJĘ (ID), bez duplikatów danych — zgodnie z
  /// integracją budżetu. Każde opcjonalne, wiele naraz (po jednym na sekcję).
  int? get transportId => (raw['transportId'] as num?)?.toInt();
  int? get accommodationId => (raw['accommodationId'] as num?)?.toInt();
  int? get musicId => (raw['musicId'] as num?)?.toInt();

  /// Czy zadanie ma jakiekolwiek powiązanie.
  bool get hasAnyLink =>
      isBudgetLinked ||
      vendorId != null ||
      giftId != null ||
      transportId != null ||
      accommodationId != null ||
      musicId != null;

  /// Cel/zdarzenie powiązane z zadaniem (np. „Znalezienie DJa"), opcjonalne.
  String get goal => (raw['goal'] as String?) ?? '';

  /// Czy cel został osiągnięty/zrealizowany (np. „DJ znaleziony").
  bool get goalAchieved => raw['goalAchieved'] == true;

  TaskStatus get status => TaskStatus.byId(statusId);
  TaskPerson get person => TaskPerson.byId(responsible);
  TaskPriority get priority => TaskPriority.byId(priorityId);

  /// Wyświetlana osoba: własna (assigneeName) lub etykieta organizatora.
  String get assigneeLabel =>
      assigneeName.isNotEmpty ? assigneeName : person.label;

  bool get isOverdue {
    if (dueDate.isEmpty || statusId == 'done' || statusId == 'cancelled') {
      return false;
    }
    final d = DateTime.tryParse(dueDate);
    if (d == null) return false;
    final now = DateTime.now();
    return d.isBefore(DateTime(now.year, now.month, now.day));
  }
}
