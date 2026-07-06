import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/task.dart';
import '../../models/vendor.dart' show kVendorBudgetCategories;
import '../../services/task_service.dart';
import '../../utils/format.dart';

/// Sentinel wartości dropdowna celu, gdy użytkownik chce wpisać własny tekst.
const _kCustomGoal = '__custom__';

/// Modalny formularz dodawania / edycji zadania.
///
/// Podstawowy widok pokazuje tylko najważniejsze pola (nazwa, cel/zdarzenie,
/// status); reszta jest rozwijana przyciskiem „Pokaż więcej opcji", aby nie
/// przytłaczać formularza przy dodawaniu.
class TaskFormSheet extends StatefulWidget {
  const TaskFormSheet({super.key, this.existing});

  final Task? existing;

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _assignee;
  late final TextEditingController _customGoal;
  late final TextEditingController _estimatedCost;

  String _startDate = '';
  String _endDate = '';
  String _dueDate = '';
  String _responsible = 'both';
  String _status = 'todo';
  String _priority = 'med';
  String _goalSelection = '';
  bool _goalAchieved = false;
  bool _isBudgetLinked = false;
  String _budgetCategory = 'Sala';
  bool _showMore = false;

  bool get _isEdit => widget.existing != null;
  bool get _hasGoal =>
      _goalSelection.isNotEmpty && _goalSelection != _kCustomGoal ||
      (_goalSelection == _kCustomGoal && _customGoal.text.trim().isNotEmpty);

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _name = TextEditingController(text: t?.name ?? '');
    _assignee = TextEditingController(text: t?.assigneeName ?? '');
    _startDate = t?.startDate ?? '';
    _endDate = t?.endDate ?? '';
    _dueDate = t?.dueDate ?? '';
    _responsible = t?.responsible ?? 'both';
    if (!TaskPerson.all.any((p) => p.id == _responsible)) _responsible = 'both';
    _status = t?.statusId ?? 'todo';
    if (!TaskStatus.columns.any((s) => s.id == _status)) _status = 'todo';
    _priority = t?.priorityId ?? 'med';
    if (!TaskPriority.all.any((p) => p.id == _priority)) _priority = 'med';

    final goal = t?.goal ?? '';
    _customGoal = TextEditingController();
    if (goal.isEmpty) {
      _goalSelection = '';
    } else if (TaskGoalPreset.all.contains(goal)) {
      _goalSelection = goal;
    } else {
      _goalSelection = _kCustomGoal;
      _customGoal.text = goal;
    }
    _goalAchieved = t?.goalAchieved ?? false;

    _isBudgetLinked = t?.isBudgetLinked ?? false;
    _estimatedCost = TextEditingController(text: _amt(t?.estimatedCost));
    _budgetCategory =
        t?.budgetCategory.isNotEmpty == true ? t!.budgetCategory : 'Sala';
    if (!kVendorBudgetCategories.contains(_budgetCategory)) {
      _budgetCategory = 'Sala';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _assignee.dispose();
    _customGoal.dispose();
    _estimatedCost.dispose();
    super.dispose();
  }

  String _amt(double? v) {
    if (v == null || v == 0) return '';
    return v == v.roundToDouble()
        ? v.toInt().toString()
        : v.toString().replaceAll('.', ',');
  }

  Future<void> _pickDate(String current, ValueChanged<String> onPicked) async {
    final initial = DateTime.tryParse(current) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onPicked(
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final goal = _goalSelection == _kCustomGoal
        ? _customGoal.text.trim()
        : _goalSelection;
    Navigator.of(context).pop(
      TaskDraft(
        name: _name.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        dueDate: _dueDate,
        responsible: _responsible,
        assigneeName: _assignee.text.trim(),
        status: _status,
        priority: _priority,
        goal: goal,
        goalAchieved: goal.isEmpty ? false : _goalAchieved,
        isBudgetLinked: _isBudgetLinked,
        estimatedCost: parsePln(_estimatedCost.text) ?? 0,
        budgetCategory: _budgetCategory,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7DEEC),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _isEdit ? 'Edytuj zadanie' : 'Dodaj zadanie',
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text),
                    ),
                  ),
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      controller: scrollController,
                      padding: EdgeInsets.fromLTRB(
                          20, 8, 20, 20 + MediaQuery.paddingOf(context).bottom),
                      children: [
                        _field(
                          'Nazwa *',
                          TextFormField(
                            controller: _name,
                            decoration: _dec(hint: 'np. Zarezerwować salę'),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Podaj nazwę zadania'
                                : null,
                          ),
                        ),
                        _field(
                          'Cel / zdarzenie (opcjonalnie)',
                          DropdownButtonFormField<String>(
                            initialValue: _goalSelection,
                            isExpanded: true,
                            decoration: _dec(),
                            items: [
                              const DropdownMenuItem(
                                  value: '', child: Text('— brak —')),
                              for (final g in TaskGoalPreset.all)
                                DropdownMenuItem(value: g, child: Text(g)),
                              const DropdownMenuItem(
                                  value: _kCustomGoal,
                                  child: Text('➕ Inny cel (wpisz własny)')),
                            ],
                            onChanged: (v) =>
                                setState(() => _goalSelection = v ?? ''),
                          ),
                        ),
                        if (_goalSelection == _kCustomGoal)
                          _field(
                            'Nazwa celu',
                            TextField(
                              controller: _customGoal,
                              decoration:
                                  _dec(hint: 'np. Znalezienie fotografa'),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        if (_hasGoal)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              activeThumbColor: AppColors.accent,
                              title: Text('🎯 Cel osiągnięty',
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                'np. „DJ znaleziony" — zaznacz, gdy cel jest już zrealizowany.',
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: AppColors.textLight),
                              ),
                              value: _goalAchieved,
                              onChanged: (v) =>
                                  setState(() => _goalAchieved = v),
                            ),
                          ),
                        _field(
                          'Status',
                          DropdownButtonFormField<String>(
                            initialValue: _status,
                            isExpanded: true,
                            decoration: _dec(),
                            items: [
                              for (final s in TaskStatus.columns)
                                DropdownMenuItem(
                                    value: s.id,
                                    child: Text('${s.icon} ${s.label}')),
                            ],
                            onChanged: (v) =>
                                setState(() => _status = v ?? 'todo'),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () =>
                                setState(() => _showMore = !_showMore),
                            icon: Icon(
                                _showMore
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 18),
                            label: Text(_showMore
                                ? 'Ukryj dodatkowe opcje'
                                : 'Pokaż więcej opcji'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.accent,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          alignment: Alignment.topCenter,
                          child: _showMore ? _moreOptions() : const SizedBox(width: double.infinity),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textLight,
                                  side: const BorderSide(
                                      color: Color(0xFFD7DEEC)),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Anuluj'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(_isEdit ? 'Zapisz' : 'Dodaj'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _moreOptions() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _field(
            'Priorytet',
            DropdownButtonFormField<String>(
              initialValue: _priority,
              isExpanded: true,
              decoration: _dec(),
              items: [
                for (final p in TaskPriority.all)
                  DropdownMenuItem(
                      value: p.id, child: Text('${p.icon} ${p.label}')),
              ],
              onChanged: (v) => setState(() => _priority = v ?? 'med'),
            ),
          ),
          _field(
            'Osoba odpowiedzialna',
            DropdownButtonFormField<String>(
              initialValue: _responsible,
              isExpanded: true,
              decoration: _dec(),
              items: [
                for (final p in TaskPerson.all)
                  DropdownMenuItem(value: p.id, child: Text(p.label)),
              ],
              onChanged: (v) => setState(() => _responsible = v ?? 'both'),
            ),
          ),
          _field(
            'Własna osoba (opcjonalnie)',
            TextField(
              controller: _assignee,
              decoration: _dec(hint: 'Imię — nadpisuje powyższy wybór'),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _field(
                  'Data rozpoczęcia',
                  _dateField(_startDate,
                      () => _pickDate(
                          _startDate, (d) => setState(() => _startDate = d)),
                      () => setState(() => _startDate = '')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  'Data zakończenia',
                  _dateField(_endDate,
                      () => _pickDate(
                          _endDate, (d) => setState(() => _endDate = d)),
                      () => setState(() => _endDate = '')),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.accent,
            title: Text('💰 Powiąż z budżetem',
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text(
              'Tworzy/aktualizuje powiązany wpis w budżecie (referencja).',
              style:
                  GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
            ),
            value: _isBudgetLinked,
            onChanged: (v) => setState(() => _isBudgetLinked = v),
          ),
          if (_isBudgetLinked) ...[
            _field(
              'Szacowany koszt (zł)',
              TextField(
                controller: _estimatedCost,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _dec(hint: '0', suffix: 'zł'),
              ),
            ),
            _field(
              'Kategoria budżetowa',
              DropdownButtonFormField<String>(
                initialValue: _budgetCategory,
                isExpanded: true,
                decoration: _dec(),
                items: [
                  for (final c in kVendorBudgetCategories)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) =>
                    setState(() => _budgetCategory = v ?? 'Sala'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dateField(String value, VoidCallback onTap, VoidCallback onClear) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: _dec(),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: AppColors.textLight),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value.isEmpty ? 'Wybierz' : value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: value.isEmpty ? AppColors.textLight : AppColors.text,
                ),
              ),
            ),
            if (value.isNotEmpty)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close,
                    size: 16, color: AppColors.textLight),
              ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 2),
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text)),
          ),
          child,
        ],
      ),
    );
  }

  InputDecoration _dec({String? hint, String? suffix}) => InputDecoration(
        hintText: hint,
        suffixText: suffix,
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF8FAFF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDCE4F2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDCE4F2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
      );
}
