import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';

/// Modalny formularz dodawania / edycji zadania.
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

  String _startDate = '';
  String _endDate = '';
  String _dueDate = '';
  String _responsible = 'both';
  String _status = 'todo';
  String _priority = 'med';

  bool get _isEdit => widget.existing != null;

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
  }

  @override
  void dispose() {
    _name.dispose();
    _assignee.dispose();
    super.dispose();
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
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
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
                        Row(
                          children: [
                            Expanded(
                              child: _field(
                                'Data rozpoczęcia',
                                _dateField(_startDate,
                                    () => _pickDate(_startDate,
                                        (d) => setState(() => _startDate = d)),
                                    () => setState(() => _startDate = '')),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _field(
                                'Data zakończenia',
                                _dateField(_endDate,
                                    () => _pickDate(_endDate,
                                        (d) => setState(() => _endDate = d)),
                                    () => setState(() => _endDate = '')),
                              ),
                            ),
                          ],
                        ),
                        _field(
                          'Termin (deadline)',
                          _dateField(_dueDate,
                              () => _pickDate(_dueDate,
                                  (d) => setState(() => _dueDate = d)),
                              () => setState(() => _dueDate = '')),
                        ),
                        _field(
                          'Osoba odpowiedzialna',
                          DropdownButtonFormField<String>(
                            initialValue: _responsible,
                            isExpanded: true,
                            decoration: _dec(),
                            items: [
                              for (final p in TaskPerson.all)
                                DropdownMenuItem(
                                    value: p.id, child: Text(p.label)),
                            ],
                            onChanged: (v) =>
                                setState(() => _responsible = v ?? 'both'),
                          ),
                        ),
                        _field(
                          'Własna osoba (opcjonalnie)',
                          TextField(
                            controller: _assignee,
                            decoration:
                                _dec(hint: 'Imię — nadpisuje powyższy wybór'),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _field(
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
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _field(
                                'Priorytet',
                                DropdownButtonFormField<String>(
                                  initialValue: _priority,
                                  isExpanded: true,
                                  decoration: _dec(),
                                  items: [
                                    for (final p in TaskPriority.all)
                                      DropdownMenuItem(
                                          value: p.id,
                                          child: Text('${p.icon} ${p.label}')),
                                  ],
                                  onChanged: (v) =>
                                      setState(() => _priority = v ?? 'med'),
                                ),
                              ),
                            ),
                          ],
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

  InputDecoration _dec({String? hint}) => InputDecoration(
        hintText: hint,
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
