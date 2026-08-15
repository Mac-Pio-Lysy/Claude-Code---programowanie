import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../layout/responsive.dart';
import '../../models/task.dart';
import '../../models/vendor.dart'
    show kVendorBudgetCategories, vendorBudgetCategoryLabel;
import '../../models/wedding_data.dart';
import '../../navigation/app_sections.dart';
import '../../services/firestore_service.dart';
import '../../services/task_service.dart';
import '../../utils/format.dart';
import '../../widgets/filter_toggle_button.dart';
import 'task_form_sheet.dart';
import '../../l10n/app_text.dart';
import '../../utils/app_format.dart';

/// Sekcja „Zadania" — tablica Kanban (Do zrobienia / W trakcie / Zrobione).
class TasksScreen extends StatefulWidget {
  TasksScreen({
    super.key,
    required this.data,
    required FirestoreService firestore,
    this.onOpenSection,
  }) : service = TaskService(firestore: firestore);

  final WeddingData? data;
  final TaskService service;

  /// Nawigacja do powiązanej sekcji (z karty zadania).
  final void Function(AppSection)? onOpenSection;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {

  String _person = 'all';
  String _statusFilter = 'all';
  String _linkFilter = 'all'; // all | budget | vendor | gift | none
  String _sort = 'none';
  bool _filtersVisible = false;

  bool _matchesLink(Task t) {
    switch (_linkFilter) {
      case 'budget':
        return t.isBudgetLinked;
      case 'vendor':
        return t.vendorId != null;
      case 'transport':
        return t.transportId != null;
      case 'accommodation':
        return t.accommodationId != null;
      case 'music':
        return t.musicId != null;
      case 'gift':
        return t.giftId != null;
      case 'none':
        return !t.hasAnyLink;
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
      constraints: const BoxConstraints(maxWidth: kSheetMaxWidth),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskFormSheet(data: widget.data),
    );
    if (draft == null) return;
    await widget.service.addTask(draft);
    _toast(AppText.t.tasks_addedToast);
  }

  Future<void> _edit(Task task) async {
    final draft = await showModalBottomSheet<TaskDraft>(
      context: context,
      constraints: const BoxConstraints(maxWidth: kSheetMaxWidth),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskFormSheet(existing: task, data: widget.data),
    );
    if (draft == null || task.id == null) return;
    await widget.service.updateTask(task.id!, draft);
    _toast(AppText.t.common_savedToast);
  }

  Future<void> _delete(Task task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppText.t.tasks_deleteTitle),
        content: Text(AppText.t.tasks_deleteBody(task.name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppText.t.common_cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC0392B)),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppText.t.common_delete),
          ),
        ],
      ),
    );
    if (ok != true || task.id == null) return;
    await widget.service.deleteTask(task.id!);
    _toast(AppText.t.tasks_deletedToast);
  }

  void _move(Task task, String status) {
    if (task.id != null) widget.service.updateStatus(task.id!, status);
  }

  /// Przełącza „cel osiągnięty" bezpośrednio z widoku zadań. Przy zaznaczeniu
  /// (i braku istniejącego powiązania budżetowego) pyta, czy utworzyć wpis
  /// w budżecie — jeśli tak, tworzy referencję (bez duplikatów, SSOT).
  Future<void> _toggleGoalAchieved(Task task) async {
    if (task.id == null) return;
    final next = !task.goalAchieved;
    await widget.service.setGoalAchieved(task.id!, next);

    if (!next || task.isBudgetLinked) return;
    if (!mounted) return;

    final createBudget = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(AppText.t.tasks_goalReached),
        content: Text(AppText.t.tasks_goalReachedBody(task.goal)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppText.t.tasks_notNow),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            child: Text(AppText.t.tasks_goalCreateYes),
          ),
        ],
      ),
    );
    if (createBudget != true || !mounted) return;

    final details = await _askBudgetDetails(task);
    if (details == null || task.id == null) return;
    await widget.service.linkToBudget(task.id!,
        estimatedCost: details.cost, budgetCategory: details.category);
    _toast(AppText.t.tasks_budgetItemCreated);
  }

  /// Mały dialog z kosztem i kategorią dla nowej pozycji budżetowej.
  Future<({num cost, String category})?> _askBudgetDetails(Task task) {
    final costController = TextEditingController();
    var category = 'Sala';
    return showDialog<({num cost, String category})>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(AppText.t.tasks_newBudgetItem),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppText.t.tasks_estimatedCost(AppFormat.currency.symbol),
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: costController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                    isDense: true,
                    hintText: '0',
                    suffixText: AppFormat.currency.symbol),
              ),
              const SizedBox(height: 14),
              Text(AppText.t.tasks_budgetCategory,
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: category,
                isExpanded: true,
                decoration: const InputDecoration(isDense: true),
                items: [
                  for (final c in kVendorBudgetCategories)
                    DropdownMenuItem(
                        value: c,
                        child: Text(vendorBudgetCategoryLabel(c))),
                ],
                onChanged: (v) => setState(() => category = v ?? 'Sala'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppText.t.common_cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop((
                cost: parsePln(costController.text) ?? 0,
                category: category,
              )),
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              child: Text(AppText.t.tasks_create),
            ),
          ],
        ),
      ),
    );
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
    final isTablet = isTabletLayout(context);

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
              Row(
                children: [
                  Expanded(
                    child: Text(AppText.t.tasks_title,
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text)),
                  ),
                  FilterToggleButton(
                    expanded: _filtersVisible,
                    onTap: () =>
                        setState(() => _filtersVisible = !_filtersVisible),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(AppText.t.tasks_progress(doneCount, all.length, pct),
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
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.topCenter,
                curve: Curves.easeInOut,
                child: _filtersVisible
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _filters(),
                      )
                    : const SizedBox(width: double.infinity),
              ),
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
                label: Text(AppText.t.tasks_addButton),
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
          onToggleGoal: _toggleGoalAchieved,
          data: widget.data,
          onOpenSection: widget.onOpenSection,
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
          _chip(AppText.t.tasks_allLinks, _linkFilter == 'all',
              () => setState(() => _linkFilter = 'all')),
          _chip(AppText.t.tasks_linkBudget, _linkFilter == 'budget',
              () => setState(() => _linkFilter = 'budget')),
          _chip(AppText.t.tasks_linkVendor, _linkFilter == 'vendor',
              () => setState(() => _linkFilter = 'vendor')),
          _chip('🚗 Transport', _linkFilter == 'transport',
              () => setState(() => _linkFilter = 'transport')),
          _chip('🏨 Nocleg', _linkFilter == 'accommodation',
              () => setState(() => _linkFilter = 'accommodation')),
          _chip('🎵 Muzyka', _linkFilter == 'music',
              () => setState(() => _linkFilter = 'music')),
          _chip('🎁 Prezent', _linkFilter == 'gift',
              () => setState(() => _linkFilter = 'gift')),
          _chip(AppText.t.tasks_noLink, _linkFilter == 'none',
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
    required this.onToggleGoal,
    required this.data,
    required this.onOpenSection,
  });

  final TaskStatus status;
  final List<Task> tasks;
  final ValueChanged<int> onAccept;
  final ValueChanged<Task> onEdit;
  final ValueChanged<Task> onDelete;
  final void Function(Task, String) onMove;
  final ValueChanged<Task> onToggleGoal;
  final WeddingData? data;
  final void Function(AppSection)? onOpenSection;

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
                        child: Text(AppText.t.tasks_dragHere,
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
                          onToggleGoal: () => onToggleGoal(tasks[i]),
                          data: data,
                          onOpenSection: onOpenSection,
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
    required this.onToggleGoal,
    required this.data,
    required this.onOpenSection,
  });

  final Task task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<String> onMove;
  final VoidCallback onToggleGoal;
  final WeddingData? data;
  final void Function(AppSection)? onOpenSection;

  /// Nazwa powiązanego elementu (po ID) z danej kolekcji — dla etykiety
  /// „Powiązane z: [nazwa]". Zwraca null, gdy element nie istnieje.
  String? _linkName(String key, int? id, String Function(Map) nameOf) {
    if (id == null) return null;
    final list = data?.raw[key];
    if (list is! List) return null;
    for (final e in list) {
      if (e is Map && (e['id'] as num?)?.toInt() == id) {
        final n = nameOf(e).trim();
        return n.isEmpty ? null : n;
      }
    }
    return null;
  }

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
              if (t.goal.isNotEmpty) _goalBadge(t),
              if (t.dueDate.isNotEmpty)
                _badge(
                  '${t.isOverdue ? '⚠ ' : '📅 '}'
                  '${AppFormat.dateShortFromIso(t.dueDate) ?? t.dueDate}',
                  t.isOverdue
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFF1F5F9),
                  t.isOverdue
                      ? const Color(0xFFC0392B)
                      : AppColors.textLight,
                ),
              if (t.isBudgetLinked)
                _linkBadge(
                    AppText.t.tasks_costWithCurrency(
                        t.estimatedCost.toStringAsFixed(0), AppFormat.currency.symbol),
                    const Color(0xFFF5F3FF), const Color(0xFF7C3AED),
                    AppSection.budget),
              if (t.vendorId != null)
                _linkBadge(
                    _withName(
                        AppText.t.tasks_linkVendor,
                        _linkName('vendors', t.vendorId, (m) {
                          final c = (m['companyName'] as String?)?.trim();
                          return (c == null || c.isEmpty)
                              ? ((m['category'] as String?) ?? '')
                              : c;
                        })),
                    const Color(0xFFECFDF5),
                    const Color(0xFF059669),
                    AppSection.vendors),
              if (t.transportId != null)
                _linkBadge(
                    _withName(
                        '🚗 Transport',
                        _linkName('vehicles', t.transportId, (m) {
                          final d = (m['description'] as String?)?.trim();
                          return (d == null || d.isEmpty)
                              ? ((m['type'] as String?) ?? '')
                              : d;
                        })),
                    const Color(0xFFEFF6FF),
                    const Color(0xFF1D4ED8),
                    AppSection.transport),
              if (t.accommodationId != null)
                _linkBadge(
                    _withName(
                        '🏨 Nocleg',
                        _linkName('hotels', t.accommodationId,
                            (m) => (m['name'] as String?) ?? '')),
                    const Color(0xFFF0FDFA),
                    const Color(0xFF0D9488),
                    AppSection.accommodation),
              if (t.musicId != null)
                _linkBadge(
                    _withName(
                        '🎵 Muzyka',
                        _linkName('songs', t.musicId,
                            (m) => (m['title'] as String?) ?? '')),
                    const Color(0xFFFFF7ED),
                    const Color(0xFFB45309),
                    AppSection.music),
              if (t.giftId != null)
                _linkBadge('🎁 Prezent', const Color(0xFFFDF2F8),
                    const Color(0xFFDB2777), AppSection.gifts),
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
        PopupMenuItem(
            value: 'edit', child: Text(AppText.t.tasks_editAction)),
        for (final s in TaskStatus.columns)
          if (s.id != task.statusId)
            PopupMenuItem(value: 'move:${s.id}', child: Text('→ ${s.label}')),
        PopupMenuItem(
            value: 'delete', child: Text(AppText.t.tasks_deleteAction)),
      ],
    );
  }

  /// Odznaka celu/zdarzenia — tappable, przełącza „cel osiągnięty" i (przy
  /// pierwszym zaznaczeniu) pyta o utworzenie powiązanej pozycji budżetowej.
  Widget _goalBadge(Task t) {
    final achieved = t.goalAchieved;
    return GestureDetector(
      onTap: onToggleGoal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: achieved ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              achieved ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 13,
              color:
                  achieved ? const Color(0xFF059669) : AppColors.textLight,
            ),
            const SizedBox(width: 4),
            Text('🎯 ${t.goal}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: achieved
                      ? const Color(0xFF059669)
                      : AppColors.textLight,
                  decoration: achieved ? TextDecoration.lineThrough : null,
                )),
          ],
        ),
      ),
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

  /// „Powiązane z: [nazwa]" — dokleja nazwę elementu do etykiety, jeśli znana.
  String _withName(String base, String? name) =>
      (name == null || name.isEmpty) ? base : '$base: $name';

  /// Odznaka powiązania — klikalna (nawigacja do sekcji), gdy dostępne.
  Widget _linkBadge(String text, Color bg, Color fg, AppSection? section) {
    final badge = _badge(text, bg, fg);
    if (section == null || onOpenSection == null) return badge;
    return GestureDetector(
      onTap: () => onOpenSection!(section),
      child: badge,
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
