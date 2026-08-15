import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/setup_task.dart';
import '../../models/wedding_data.dart';
import '../../navigation/app_sections.dart';
import '../../l10n/app_text.dart';

/// Wynik kreatora: dokąd przejść po jego zamknięciu.
class SetupJump {
  const SetupJump(this.section, this.subTab);

  final AppSection section;
  final int? subTab;
}

/// Kreator „Poprowadź mnie za rękę" (#17) — mówi, CO wpisać, i prowadzi
/// do właściwego miejsca.
///
/// Nie powiela przewodnika (ten pokazuje, GDZIE co jest) ani listy „Od czego
/// zacząć?" (ta dotyczy organizacji wesela w realnym świecie). Stan zadań
/// liczy się z danych — patrz [SetupTask].
class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key, required this.data});

  final WeddingData? data;

  /// Otwiera kreator. Zwraca [SetupJump], gdy użytkownik wybrał „Przejdź".
  static Future<SetupJump?> open(BuildContext context, WeddingData? data) =>
      Navigator.of(context).push<SetupJump>(
        MaterialPageRoute(builder: (_) => SetupWizardScreen(data: data)),
      );

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  SetupLevel _level = SetupLevel.basic;

  List<SetupTask> get _all => buildSetupTasks();

  /// Zadania widoczne na wybranym poziomie.
  ///
  /// Poziom zaawansowany pokazuje TAKŻE podstawowe — inaczej nie byłoby widać,
  /// że coś z podstaw zostało pominięte.
  List<SetupTask> get _visible => _level == SetupLevel.basic
      ? _all.where((t) => t.level == SetupLevel.basic).toList()
      : _all;

  bool _isDone(SetupTask t) =>
      widget.data != null && t.done(widget.data!);

  @override
  Widget build(BuildContext context) {
    final tasks = _visible;
    final progress = setupProgress(tasks, widget.data);
    final todo = tasks.where((t) => !_isDone(t)).toList();
    final done = tasks.where(_isDone).toList();

    return Scaffold(
      backgroundColor: AppColors.bgGradient.last,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.text),
        title: Text(AppText.t.settings_setupWizardButton,
            style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.text)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.bgGradient,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            _levelPicker(),
            const SizedBox(height: 14),
            _progressCard(progress),
            const SizedBox(height: 14),
            if (todo.isEmpty)
              _allDoneCard()
            else ...[
              _sectionLabel(AppText.t.setup_todo(todo.length)),
              for (final t in todo) _taskTile(t, isDone: false),
            ],
            if (done.isNotEmpty) ...[
              const SizedBox(height: 8),
              // Ukończone zwinięte — poziom zaawansowany ma pokazywać, co
              // zostało, a nie zasypywać listą już zrobionych rzeczy.
              _doneGroup(done),
            ],
          ],
        ),
      ),
    );
  }

  Widget _levelPicker() {
    return Row(
      children: [
        for (final l in SetupLevel.values) ...[
          Expanded(
            child: _levelChip(l),
          ),
          if (l != SetupLevel.values.last) const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _levelChip(SetupLevel level) {
    final selected = _level == level;
    final tasks = level == SetupLevel.basic
        ? _all.where((t) => t.level == SetupLevel.basic).toList()
        : _all;
    final p = setupProgress(tasks, widget.data);

    return Material(
      color: selected ? AppColors.accent : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _level = level),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: selected ? AppColors.accent : const Color(0xFFDCE4F2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                level == SetupLevel.basic ? AppText.t.setup_basic : AppText.t.setup_advanced,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                AppText.t.setup_progress(p.done, p.total),
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: selected
                      ? Colors.white.withValues(alpha: 0.85)
                      : AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _progressCard(SetupProgress p) {
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
          Text(_level.label,
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text)),
          const SizedBox(height: 4),
          Text(_level.intro,
              style: GoogleFonts.inter(
                  fontSize: 12.5, height: 1.45, color: AppColors.textLight)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: p.ratio,
              minHeight: 8,
              backgroundColor: const Color(0xFFEAF1FB),
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            p.complete
                ? AppText.t.setup_allDone
                : AppText.t.setup_partial(p.done, p.total, p.left),
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.accent),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(text,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textLight)),
      );

  Widget _allDoneCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _level == SetupLevel.basic
                  ? AppText.t.setup_basicDone
                  : AppText.t.setup_complete,
              style: GoogleFonts.inter(
                  fontSize: 13, height: 1.45, color: const Color(0xFF065F46)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _doneGroup(List<SetupTask> done) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE2EAF7)),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE2EAF7)),
        ),
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        leading: const Icon(Icons.check_circle, color: Color(0xFF059669)),
        title: Text(AppText.t.setup_done(done.length),
            style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.text)),
        children: [for (final t in done) _taskTile(t, isDone: true)],
      ),
    );
  }

  Widget _taskTile(SetupTask task, {required bool isDone}) {
    return Container(
      key: ValueKey('setup-${task.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDone ? const Color(0xFFD1FAE5) : const Color(0xFFE2EAF7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: isDone ? const Color(0xFF059669) : AppColors.textLight,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.label,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text)),
                const SizedBox(height: 3),
                Text(task.hint,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.45,
                        color: AppColors.textLight)),
                const SizedBox(height: 4),
                Text(AppText.t.setup_goTo(task.section.label),
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => Navigator.of(context)
                .pop(SetupJump(task.section, task.subTab)),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: Text(isDone ? AppText.t.setup_fix : AppText.t.setup_go),
          ),
        ],
      ),
    );
  }
}
