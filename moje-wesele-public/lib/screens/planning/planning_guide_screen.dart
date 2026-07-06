import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/planning_step.dart';
import '../../models/wedding_data.dart';
import '../../services/firestore_service.dart';
import '../../services/planning_service.dart';

/// Ekran „Od czego zacząć?" — sugerowana kolejność organizacji wesela.
/// Odhaczalne kroki z paskiem postępu; tryb edycji pozwala dodawać, zmieniać,
/// usuwać i przywracać domyślne kroki. Dane w Firestore (współdzielone z web).
class PlanningGuideScreen extends StatefulWidget {
  PlanningGuideScreen({
    super.key,
    required this.data,
    required FirestoreService firestore,
  }) : service = PlanningService(firestore: firestore);

  final WeddingData? data;
  final PlanningService service;

  @override
  State<PlanningGuideScreen> createState() => _PlanningGuideScreenState();
}

class _PlanningGuideScreenState extends State<PlanningGuideScreen> {
  late List<PlanningStep> _steps;
  bool _editMode = false;

  @override
  void initState() {
    super.initState();
    _steps = PlanningService.fromRaw(widget.data?.raw);
  }

  void _persist() => widget.service.save(_steps);

  int get _doneCount => _steps.where((s) => s.done).length;
  double get _pct => _steps.isEmpty ? 0 : _doneCount / _steps.length;

  void _toggle(PlanningStep s) {
    setState(() => s.done = !s.done);
    _persist();
  }

  void _edit(PlanningStep s, String value) {
    s.label = value.trim().isEmpty ? s.label : value.trim();
    s.note = '';
    _persist();
  }

  void _add() {
    final id = _steps.fold<int>(0, (m, s) => s.id > m ? s.id : m) + 1;
    setState(() {
      _steps.add(PlanningStep(id: id, label: 'Nowy krok'));
      _editMode = true;
    });
    _persist();
  }

  void _delete(PlanningStep s) {
    setState(() => _steps.remove(s));
    _persist();
  }

  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Przywrócić domyślną listę?'),
        content: const Text(
            'Lista kroków „Od czego zacząć?" wróci do domyślnej. '
            'Wprowadzone zmiany zostaną utracone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Anuluj')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Przywróć'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _steps = PlanningStep.defaultList());
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGradient.last,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.text),
        title: Text('Od czego zacząć?',
            style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.text)),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _editMode = !_editMode),
            icon: Icon(_editMode ? Icons.check : Icons.edit_outlined, size: 18),
            label: Text(_editMode ? 'Gotowe' : 'Edytuj'),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.45, 1.0],
            colors: AppColors.bgGradient,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _progressCard(),
            const SizedBox(height: 12),
            for (var i = 0; i < _steps.length; i++) _stepCard(i, _steps[i]),
            const SizedBox(height: 12),
            if (_editMode) _editActions(),
          ],
        ),
      ),
    );
  }

  Widget _progressCard() {
    final pct = (_pct * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sugerowana kolejność planowania wesela',
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text)),
          const SizedBox(height: 4),
          Text('Odhaczaj ukończone kroki — pasek pokaże postęp.',
              style:
                  GoogleFonts.inter(fontSize: 12, color: AppColors.textLight)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _pct,
              minHeight: 10,
              backgroundColor: const Color(0xFFEAF1FB),
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
          const SizedBox(height: 8),
          Text('$_doneCount z ${_steps.length} ukończonych · $pct%',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent)),
        ],
      ),
    );
  }

  Widget _stepCard(int index, PlanningStep s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: s.done ? const Color(0xFFF1F8F2) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: s.done ? const Color(0xFFBFE3C6) : const Color(0xFFE2EAF7)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Checkbox(
              value: s.done,
              activeColor: const Color(0xFF059669),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
              onChanged: (_) => _toggle(s),
            ),
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: s.done
                    ? const Color(0xFF059669)
                    : const Color(0xFFEEF3FF),
              ),
              child: Text('${index + 1}',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: s.done ? Colors.white : AppColors.accent)),
            ),
            Expanded(
              child: _editMode
                  ? TextFormField(
                      initialValue: s.label,
                      onChanged: (v) => _edit(s, v),
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: UnderlineInputBorder(),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.label,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                              decoration: s.done
                                  ? TextDecoration.lineThrough
                                  : null,
                            )),
                        if (s.note.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(s.note,
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.textLight)),
                          ),
                      ],
                    ),
            ),
            if (_editMode)
              IconButton(
                onPressed: () => _delete(s),
                icon: const Icon(Icons.close, size: 18),
                color: const Color(0xFFC0392B),
                tooltip: 'Usuń krok',
              ),
          ],
        ),
      ),
    );
  }

  Widget _editActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Dodaj krok'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Przywróć domyślne'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textLight,
              side: const BorderSide(color: Color(0xFFD7DEEC)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
