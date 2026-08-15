import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/task.dart';
import '../../models/vendor.dart' show kVendorBudgetCategories;
import '../../models/wedding_data.dart';
import '../../services/task_service.dart';
import '../../utils/format.dart';
import '../../l10n/app_text.dart';
import '../../utils/app_format.dart';

/// Sentinel wartości dropdowna celu, gdy użytkownik chce wpisać własny tekst.
const _kCustomGoal = '__custom__';

/// Modalny formularz dodawania / edycji zadania.
///
/// Podstawowy widok pokazuje tylko najważniejsze pola (nazwa, cel/zdarzenie,
/// status); reszta jest rozwijana przyciskiem „Pokaż więcej opcji", aby nie
/// przytłaczać formularza przy dodawaniu.
class TaskFormSheet extends StatefulWidget {
  const TaskFormSheet({super.key, this.existing, this.data});

  final Task? existing;

  /// Dane wesela — do wypełnienia list wyboru w sekcji „Powiązania".
  final WeddingData? data;

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

/// Sentinel wartości „utwórz nowy element" w rozwijanych powiązań.
const int _kCreateNew = -1;

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

  // Powiązania (null = brak, _kCreateNew = utwórz nowy, >=0 = istniejący ID).
  int? _vendorSel;
  int? _transportSel;
  int? _accommodationSel;
  int? _musicSel;
  bool _showLinks = false;

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

    // Powiązania — ustaw bieżące ID, o ile element wciąż istnieje.
    _vendorSel = _initSel(t?.vendorId, _vendorList);
    _transportSel = _initSel(t?.transportId, _transportList);
    _accommodationSel = _initSel(t?.accommodationId, _accommodationList);
    _musicSel = _initSel(t?.musicId, _musicList);
    _showLinks = _vendorSel != null ||
        _transportSel != null ||
        _accommodationSel != null ||
        _musicSel != null;
  }

  int? _initSel(int? id, List<(int, String)> list) =>
      (id != null && list.any((e) => e.$1 == id)) ? id : null;

  // ── Listy wyboru powiązań (z danych wesela) ──
  List<Map<String, dynamic>> _rawList(String key) {
    final v = widget.data?.raw[key];
    return v is List
        ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];
  }

  List<(int, String)> _asChoices(
      String key, String Function(Map<String, dynamic>) nameOf) {
    return [
      for (final m in _rawList(key))
        if ((m['id'] as num?)?.toInt() != null)
          ((m['id'] as num).toInt(), nameOf(m)),
    ];
  }

  List<(int, String)> get _vendorList => _asChoices('vendors', (m) {
        final n = (m['companyName'] as String?)?.trim();
        return (n == null || n.isEmpty)
            ? ((m['category'] as String?) ?? 'Dostawca')
            : n;
      });

  List<(int, String)> get _transportList => _asChoices('vehicles', (m) {
        final d = (m['description'] as String?)?.trim();
        final type = (m['type'] as String?)?.trim() ?? '';
        return (d == null || d.isEmpty) ? (type.isEmpty ? 'Pojazd' : type) : d;
      });

  List<(int, String)> get _accommodationList => _asChoices('hotels', (m) {
        final n = (m['name'] as String?)?.trim();
        return (n == null || n.isEmpty) ? 'Nocleg' : n;
      });

  List<(int, String)> get _musicList => _asChoices('songs', (m) {
        final t = (m['title'] as String?)?.trim() ?? '';
        final a = (m['artist'] as String?)?.trim() ?? '';
        if (t.isEmpty) return AppText.t.tasks_song;
        return a.isEmpty ? t : '$t — $a';
      });

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
    TaskLinkChoice choice(int? sel) => sel == null
        ? TaskLinkChoice.none
        : sel == _kCreateNew
            ? const TaskLinkChoice(createNew: true)
            : TaskLinkChoice(existingId: sel);

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
        vendorLink: choice(_vendorSel),
        transportLink: choice(_transportSel),
        accommodationLink: choice(_accommodationSel),
        musicLink: choice(_musicSel),
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
                            decoration: _dec(hint: AppText.t.tasks_nameHint),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? AppText.t.tasks_nameRequired
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
                              DropdownMenuItem(
                                  value: '', child: Text(AppText.t.guests_formNoMenu)),
                              for (final g in TaskGoalPreset.all)
                                DropdownMenuItem(value: g, child: Text(g)),
                              DropdownMenuItem(
                                  value: _kCustomGoal,
                                  child: Text(AppText.t.tasks_customGoal)),
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
                              title: Text(AppText.t.tasks_goalDone,
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                AppText.t.tasks_goalDoneHint,
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
                                : AppText.t.tasks_showMore),
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
            AppText.t.tasks_customPerson,
            TextField(
              controller: _assignee,
              decoration: _dec(hint: AppText.t.tasks_customPersonHint),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _field(
                  AppText.t.tasks_startDate,
                  _dateField(_startDate,
                      () => _pickDate(
                          _startDate, (d) => setState(() => _startDate = d)),
                      () => setState(() => _startDate = '')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  AppText.t.tasks_endDate,
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
            title: Text(AppText.t.tasks_linkBudgetSwitch,
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text(
              AppText.t.tasks_linkBudgetHint,
              style:
                  GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
            ),
            value: _isBudgetLinked,
            onChanged: (v) => setState(() => _isBudgetLinked = v),
          ),
          if (_isBudgetLinked) ...[
            _field(
              AppText.t.tasks_estimatedCost(AppFormat.currency.symbol),
              TextField(
                controller: _estimatedCost,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _dec(hint: '0', suffix: 'zł'),
              ),
            ),
            _field(
              AppText.t.tasks_budgetCategory,
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
          const Divider(height: 24),
          _linksSection(),
        ],
      ),
    );
  }

  /// Sekcja „Powiązania" (rozwijana) — wybór po jednym elemencie na sekcję:
  /// istniejący lub „utwórz nowy" (referencja, bez duplikowania danych).
  Widget _linksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _showLinks = !_showLinks),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(AppText.t.tasks_links,
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                Icon(_showLinks ? Icons.expand_less : Icons.expand_more,
                    size: 18, color: AppColors.accent),
              ],
            ),
          ),
        ),
        Text(
          AppText.t.tasks_linksHint,
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          curve: Curves.easeInOut,
          child: _showLinks
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _linkDropdown(AppText.t.tasks_linkVendor, _vendorList, _vendorSel,
                          AppText.t.tasks_createVendor,
                          (v) => setState(() => _vendorSel = v)),
                      _linkDropdown('🚗 Transport', _transportList,
                          _transportSel, AppText.t.tasks_createTransport,
                          (v) => setState(() => _transportSel = v)),
                      _linkDropdown('🏨 Nocleg', _accommodationList,
                          _accommodationSel, AppText.t.tasks_createAccommodation,
                          (v) => setState(() => _accommodationSel = v)),
                      _linkDropdown('🎵 Muzyka', _musicList, _musicSel,
                          AppText.t.tasks_createSong,
                          (v) => setState(() => _musicSel = v)),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _linkDropdown(String label, List<(int, String)> options, int? value,
      String createLabel, ValueChanged<int?> onChanged) {
    return _field(
      label,
      DropdownButtonFormField<int?>(
        initialValue: value,
        isExpanded: true,
        decoration: _dec(),
        items: [
          DropdownMenuItem<int?>(value: null, child: Text(AppText.t.guests_formNoMenu)),
          DropdownMenuItem<int?>(value: _kCreateNew, child: Text(createLabel)),
          for (final (id, name) in options)
            DropdownMenuItem<int?>(
                value: id,
                child: Text(name, overflow: TextOverflow.ellipsis)),
        ],
        onChanged: onChanged,
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
