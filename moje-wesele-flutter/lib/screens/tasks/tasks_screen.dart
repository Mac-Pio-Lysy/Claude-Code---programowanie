import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/task.dart';
import '../../models/wedding_data.dart';
import '../../services/firestore_service.dart';
import '../../services/task_service.dart';
import 'task_form_sheet.dart';

/// Sekcja „Zadania" — tablica Kanban (Do zrobienia / W trakcie / Zrobione).
class TasksScreen extends StatefulWidget {
  TasksScreen({
    super.key,
    required this.data,
    required FirestoreService firestore,
  }) : service = TaskService(firestore: firestore);

  final WeddingData? data;
  final TaskService service;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  static const double _tabletBreakpoint = 720;

  String _person = 'all';
  String _statusFilter = 'all';
  String _linkFilter = 'all'; // all | budget | vendor | gift | none
  String _sort = 'none';

  bool _matchesLink(Task t) {
    switch (_linkFilter) {
      case 'budget':
        return t.isBudgetLinked;
      case 'vendor':
        return t.vendorId != null;
      case 'gift':
        return t.giftId != null;
      case 'none':
        return !t.isBudgetLinked && t.vendorId == null && t.giftId == null;
      default:
        return true;
    }
  }

  List<Task> get _allTasks => [
        for (final e in widget.data?.tasks ?? const [])
          if (e is Map) Task(Map<String, dynamic>.from(e)),
      ];

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _add() async {
    final draft = await showModalBottomSheet<TaskDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TaskFormSheet(),
    );
    if (draft == null) return;
    await widget.service.addTask(draft);
    _toast('Dodano zadanie');
  }

  Future<void> _edit(Task task) async {
    final draft = await showModalBottomSheet<TaskDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskFormSheet(existing: task),
    );
    if (draft == null || task.id == null) return;
    await widget.service.updateTask(task.id!, draft);
    _toast('Zapisano zmiany');
  }

  Future<void> _delete(Task task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć zadanie?'),
        content: Text('Czy na pewno usunąć „${task.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Anuluj')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC0392B)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (ok != true || task.id == null) return;
    await widget.service.deleteTask(task.id!);
    _toast('Usunięto zadanie');
  }

  void _move(Task task, String status) {
    if (task.id != null) widget.service.updateStatus(task.id!, status);
  }

  List<Task> _filteredSorted() {
    var list = _allTasks.where((t) {
      if (_person != 'all' && t.responsible != _person) return false;
      if (!_matchesLink(t)) return false;
      return true;
    }).toList();

    switch (_sort) {
      case 'date':
        list.sort((a, b) => (a.dueDate.isEmpty ? '9999' : a.dueDate)
            .compareTo(b.dueDate.isEmpty ? '9999' : b.dueDate));
      case 'priority':
        int rank(String p) => switch (p) { 'high' => 0, 'med' => 1, _ => 2 };
        list.sort((a, b) => rank(a.priorityId).compareTo(rank(b.priorityId)));
      case 'status':
        final order = TaskStatus.columns.map((s) => s.id).toList();
        list.sort((a, b) =>
            order.indexOf(a.statusId).compareTo(order.indexOf(b.statusId)));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final all = _allTasks;
    final doneCount = all.where((t) => t.statusId == 'done').length;
    final pct = all.isEmpty ? 0 : (doneCount / all.length * 100).round();
    final filtered = _filteredSorted();
    final isTablet = MediaQuery.sizeOf(context).width >= _tabletBreakpoint;

    final visibleColumns = _statusFilter == 'all'
        ? TaskStatus.columns
        : TaskStatus.columns.where((s) => s.id == _statusFilter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Zadania',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text)),
              const SizedBox(height: 8),
              Text('$doneCount/${all.length} ukończonych ($pct%)',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textLight)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: all.isEmpty ? 0 : doneCount / all.length,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE5EBF5),
                  valueColor:
                      const AlwaysStoppedAnimation(Color(0xFF10B981)),
                ),
              ),
              const SizedBox(height: 12),
              _filters(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _board(filtered, visibleColumns, isTablet),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _add,
                icon: const Icon(Icons.add),
                label: const Text('Dodaj zadanie'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _board(
      List<Task> tasks, List<TaskStatus> columns, bool isTablet) {
    Widget columnFor(TaskStatus s) => _TaskColumn(
          status: s,
          tasks: tasks.where((t) => t.statusId == s.id).toList(),
          onAccept: (taskId) {
            final t = tasks.firstWhere((x) => x.id == taskId,
                orElse: () => Task({'id': taskId}));
            _move(t, s.id);
          },
          onEdit: _edit,
          onDelete: _delete,
          onMove: _move,
        );

    // Pojedyncza kolumna (filtr statusu) — pełna szerokość.
    if (columns.length == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: columnFor(columns.first),
      );
    }

    // Tablet: 3 kolumny obok siebie.
    if (isTablet) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final s in columns)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: columnFor(s),
                ),
              ),
          ],
        ),
      );
    }

    // Telefon: kolumny przewijane poziomo.
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        for (final s in columns)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SizedBox(width: 300, child: columnFor(s)),
          ),
      ],
    );
  }

  Widget _filters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _chipRow([
          _chip('Wszystkie statusy', _statusFilter == 'all',
              () => setState(() => _statusFilter = 'all')),
          for (final s in TaskStatus.columns)
            _chip(s.label, _statusFilter == s.id,
                () => setState(() => _statusFilter = s.id)),
        ]),
        const SizedBox(height: 8),
        _chipRow([
          _chip('Wszyscy', _person == 'all',
              () => setState(() => _person = 'all')),
          for (final p in TaskPerson.all)
            _chip(p.label, _person == p.id,
                () => setState(() => _person = p.id)),
        ]),
        const SizedBox(height: 8),
        _chipRow([
          _chip('Wszystkie powiązania', _linkFilter == 'all',
              () => setState(() => _linkFilter = 'all')),
          _chip('💰 Budżet', _linkFilter == 'budget',
              () => setState(() => _linkFilter = 'budget')),
          _chip('👨‍🍳 Dostawca', _linkFilter == 'vendor',
              () => setState(() => _linkFilter = 'vendor')),
          _chip('🎁 Prezent', _linkFilter == 'gift',
              () => setState(() => _linkFilter = 'gift')),
          _chip('Bez powiązania', _linkFilter == 'none',
              () => setState(() => _linkFilter = 'none')),
        ]),
        const SizedBox(height: 8),
        _chipRow([
          _chip('Bez sortowania', _sort == 'none',
              () => setState(() => _sort = 'none')),
          _chip('Wg terminu', _sort == 'date',
              () => setState(() => _sort = 'date')),
          _chip('Wg priorytetu', _sort == 'priority',
              () => setState(() => _sort = 'priority')),
          _chip('Wg statusu', _sort == 'status',
              () => setState(() => _sort = 'status')),
        ]),
      ],
    );
  }

  Widget _chipRow(List<Widget> chips) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final c in chips)
            Padding(padding: const EdgeInsets.only(right: 8), child: c),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: selected ? Colors.white : AppColors.textLight,
      ),
      selectedColor: AppColors.accent,
      backgroundColor: Colors.white,
      side: BorderSide(
          color: selected ? AppColors.accent : const Color(0xFFDCE4F2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

class _TaskColumn extends StatelessWidget {
  const _TaskColumn({
    required this.status,
    required this.tasks,
    required this.onAccept,
    required this.onEdit,
    required this.onDelete,
    required this.onMove,
  });

  final TaskStatus status;
  final List<Task> tasks;
  final ValueChanged<int> onAccept;
  final ValueChanged<Task> onEdit;
  final ValueChanged<Task> onDelete;
  final void Function(Task, String) onMove;

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (d) => onAccept(d.data),
      builder: (context, candidate, rejected) {
        final highlight = candidate.isNotEmpty;
        return Container(
          decoration: BoxDecoration(
            color: highlight ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: highlight ? AppColors.accent : const Color(0xFFE2EAF7),
                width: highlight ? 2 : 1),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Row(
                  children: [
                    Text('${status.icon} ',
                        style: const TextStyle(fontSize: 14)),
                    Expanded(
                      child: Text(status.label,
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: status.color)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: status.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${tasks.length}',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: status.color)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Text('Przeciągnij tutaj',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppColors.textLight)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        itemCount: tasks.length,
                        itemBuilder: (context, i) => _TaskCard(
                          task: tasks[i],
                          onEdit: () => onEdit(tasks[i]),
                          onDelete: () => onDelete(tasks[i]),
                          onMove: (s) => onMove(tasks[i], s),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onEdit,
    required this.onDelete,
    required this.onMove,
  });

  final Task task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<String> onMove;

  @override
  Widget build(BuildContext context) {
    final card = _card(context);
    if (task.id == null) return card;
    return LongPressDraggable<int>(
      data: task.id!,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 280, child: _card(context, dragging: true)),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: card),
      child: card,
    );
  }

  Widget _card(BuildContext context, {bool dragging = false}) {
    final t = task;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: t.isOverdue
                ? const Color(0xFFE9A8A8)
                : const Color(0xFFE2EAF7)),
        boxShadow: dragging
            ? [
                BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 12)
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.priority.icon, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  t.name.isEmpty ? '(bez nazwy)' : t.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    decoration: t.statusId == 'done'
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
              _menu(context),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _personBadge(t),
              if (t.dueDate.isNotEmpty)
                _badge(
                  '${t.isOverdue ? '⚠ ' : '📅 '}${t.dueDate}',
                  t.isOverdue
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFF1F5F9),
                  t.isOverdue
                      ? const Color(0xFFC0392B)
                      : AppColors.textLight,
                ),
              if (t.isBudgetLinked)
                _badge('💰 ${t.estimatedCost.toStringAsFixed(0)} zł',
                    const Color(0xFFF5F3FF), const Color(0xFF7C3AED)),
              if (t.vendorId != null)
                _badge('👨‍🍳 Dostawca', const Color(0xFFECFDF5),
                    const Color(0xFF059669)),
              if (t.giftId != null)
                _badge('🎁 Prezent', const Color(0xFFFDF2F8),
                    const Color(0xFFDB2777)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _menu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textLight),
      padding: EdgeInsets.zero,
      tooltip: 'Akcje',
      onSelected: (v) {
        if (v == 'edit') {
          onEdit();
        } else if (v == 'delete') {
          onDelete();
        } else if (v.startsWith('move:')) {
          onMove(v.substring(5));
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Text('✏ Edytuj')),
        for (final s in TaskStatus.columns)
          if (s.id != task.statusId)
            PopupMenuItem(value: 'move:${s.id}', child: Text('→ ${s.label}')),
        const PopupMenuItem(value: 'delete', child: Text('🗑 Usuń')),
      ],
    );
  }

  Widget _personBadge(Task t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: t.person.color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(t.assigneeLabel,
          style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: t.person.color)),
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}
