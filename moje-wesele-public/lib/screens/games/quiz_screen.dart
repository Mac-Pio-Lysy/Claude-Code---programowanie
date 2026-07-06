import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../config/public_urls.dart';
import '../../models/quiz.dart';
import '../../models/wedding_data.dart';
import '../../services/firestore_service.dart';
import '../../services/quiz_service.dart';
import '../../widgets/guest_page_tab.dart';

/// Podzakładka „Quiz o Parze Młodej" (w sekcji „Ślubne gry").
///
/// Trzy wewnętrzne zakładki: „Pytania" (panel organizatora), „Wyniki"
/// (ranking + statystyki trudności) oraz „Strona dla gości" (kod QR/link do
/// publicznej strony `quiz.html`).
class QuizScreen extends StatefulWidget {
  QuizScreen({super.key, required this.data, required FirestoreService firestore})
      : service = QuizService(firestore: firestore);

  final WeddingData? data;
  final QuizService service;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final Stream<List<QuizResult>> _resultsStream =
      widget.service.watchResults();

  List<QuizQuestion> get _questions => [
        for (final e in widget.data?.raw['quizQuestions'] ?? const [])
          if (e is Map) QuizQuestion(Map<String, dynamic>.from(e)),
      ];

  bool get _active => widget.data?.raw['quizActive'] == true;

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final base = PublicPages.baseUrl(widget.data?.raw);
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textLight,
            indicatorColor: AppColors.accent,
            dividerColor: const Color(0xFFE2EAF7),
            labelStyle:
                GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'Pytania'),
              Tab(text: 'Wyniki'),
              Tab(text: 'Strona dla gości'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _questionsTab(),
                _resultsTab(),
                GuestPageTab(
                  links: [('🧠 Quiz o Parze Młodej', PublicPages.quiz(base))],
                  intro:
                      'Strona, na której goście odpowiadają na pytania o Parę '
                      'Młodą i poznają swój wynik. Włącz quiz w zakładce '
                      '„Pytania", pokaż kod QR lub wyślij link.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── PYTANIA ──────────────────────────────────────────────────────────
  Widget _questionsTab() {
    final questions = _questions;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            children: [
              _activeCard(questions.isNotEmpty),
              const SizedBox(height: 14),
              if (questions.isEmpty)
                _emptyQuestions()
              else
                _reorderableQuestions(questions),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openQuestionForm(),
                icon: const Icon(Icons.add),
                label: const Text('Dodaj pytanie'),
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

  Widget _activeCard(bool hasQuestions) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        activeThumbColor: AppColors.accent,
        value: _active,
        onChanged: hasQuestions
            ? (v) => widget.service.setActive(v)
            : null,
        title: Text('Quiz aktywny dla gości',
            style:
                GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
        subtitle: Text(
          hasQuestions
              ? (_active
                  ? 'Goście mogą teraz grać przez stronę / kod QR.'
                  : 'Włącz, aby goście mogli odpowiadać.')
              : 'Najpierw dodaj przynajmniej jedno pytanie.',
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
        ),
      ),
    );
  }

  Widget _emptyQuestions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Column(
        children: [
          const Text('🧠', style: TextStyle(fontSize: 34)),
          const SizedBox(height: 10),
          Text('Brak pytań',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text)),
          const SizedBox(height: 6),
          Text(
            'Dodaj własne pytania lub zacznij od gotowych przykładów.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () async {
              await widget.service.seedExamples();
              _toast('Dodano przykładowe pytania');
            },
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('Dodaj przykładowe pytania'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reorderableQuestions(List<QuizQuestion> questions) {
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      onReorderItem: (oldIndex, newIndex) {
        final ids = questions.map((q) => q.id ?? 0).toList();
        final id = ids.removeAt(oldIndex);
        ids.insert(newIndex, id);
        widget.service.reorderQuestions(ids);
      },
      children: [
        for (var i = 0; i < questions.length; i++)
          _questionCard(questions[i], i, key: ValueKey(questions[i].id)),
      ],
    );
  }

  Widget _questionCard(QuizQuestion q, int index, {required Key key}) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.only(top: 2, right: 8),
                  child:
                      Icon(Icons.drag_handle, color: AppColors.textLight, size: 20),
                ),
              ),
              Expanded(
                child: Text('${index + 1}. ${q.question}',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
              ),
              IconButton(
                onPressed: () => _openQuestionForm(existing: q),
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: AppColors.accent,
                visualDensity: VisualDensity.compact,
                tooltip: 'Edytuj',
              ),
              IconButton(
                onPressed: () => _confirmDelete(q),
                icon: const Icon(Icons.delete_outline, size: 18),
                color: const Color(0xFFC0392B),
                visualDensity: VisualDensity.compact,
                tooltip: 'Usuń',
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < q.answers.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    i == q.correctIndex
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 16,
                    color: i == q.correctIndex
                        ? const Color(0xFF059669)
                        : AppColors.textLight,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(q.answers[i],
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: i == q.correctIndex
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: i == q.correctIndex
                                ? const Color(0xFF059669)
                                : AppColors.text)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openQuestionForm({QuizQuestion? existing}) async {
    final draft = await showModalBottomSheet<_QuestionDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuestionFormSheet(existing: existing),
    );
    if (draft == null) return;
    try {
      if (existing?.id != null) {
        await widget.service.updateQuestion(existing!.id!,
            question: draft.question,
            answers: draft.answers,
            correctIndex: draft.correctIndex);
        _toast('Zapisano pytanie');
      } else {
        await widget.service
            .addQuestion(draft.question, draft.answers, draft.correctIndex);
        _toast('Dodano pytanie');
      }
    } catch (e) {
      _toast('Błąd zapisu: $e');
    }
  }

  Future<void> _confirmDelete(QuizQuestion q) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć pytanie?'),
        content: Text('Czy na pewno usunąć „${q.question}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: const Color(0xFFC0392B)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (ok != true || q.id == null) return;
    try {
      await widget.service.deleteQuestion(q.id!);
      _toast('Usunięto pytanie');
    } catch (e) {
      _toast('Błąd usuwania: $e');
    }
  }

  // ── WYNIKI ───────────────────────────────────────────────────────────
  Widget _resultsTab() {
    return StreamBuilder<List<QuizResult>>(
      stream: _resultsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _info('Nie udało się wczytać wyników. Sprawdź połączenie.');
        }
        final results = [...?snapshot.data];
        final questions = _questions;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _resultsSummary(results, questions.length),
            const SizedBox(height: 16),
            Text('🏆 Ranking gości',
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text)),
            const SizedBox(height: 8),
            if (results.isEmpty)
              _info('Brak wyników. Udostępnij gościom kod QR, aby zagrali.')
            else
              ..._ranking(results),
            if (results.isNotEmpty && questions.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('📊 Najtrudniejsze pytania',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text)),
              const SizedBox(height: 8),
              ..._difficulty(results, questions),
            ],
          ],
        );
      },
    );
  }

  Widget _resultsSummary(List<QuizResult> results, int questionCount) {
    final participants = results.length;
    final avg = results.isEmpty
        ? 0.0
        : results.fold<int>(0, (s, r) => s + r.score) / results.length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EAF7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _stat('$participants', 'Uczestników', AppColors.accent),
          _stat('$questionCount', 'Pytań', const Color(0xFF7C3AED)),
          _stat(avg.toStringAsFixed(1), 'Śr. wynik', const Color(0xFF059669)),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight)),
        ],
      ),
    );
  }

  List<Widget> _ranking(List<QuizResult> results) {
    final sorted = [...results]..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        return a.timestamp.compareTo(b.timestamp); // szybciej = wyżej
      });
    const medals = ['🥇', '🥈', '🥉'];
    return [
      for (var i = 0; i < sorted.length; i++)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: i < 3 ? AppColors.accent : const Color(0xFFE2EAF7)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 34,
                child: Text(i < 3 ? medals[i] : '${i + 1}.',
                    style: GoogleFonts.inter(
                        fontSize: i < 3 ? 20 : 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textLight)),
              ),
              Expanded(
                child: Text(sorted[i].name.isEmpty ? 'Gość' : sorted[i].name,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${sorted[i].score}/${sorted[i].total}',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent)),
              ),
            ],
          ),
        ),
    ];
  }

  List<Widget> _difficulty(
      List<QuizResult> results, List<QuizQuestion> questions) {
    // Dla każdego pytania: ile odpowiedzi było (any answer) i ile błędnych.
    final stats = <({QuizQuestion q, int answered, int wrong})>[];
    for (final q in questions) {
      final key = '${q.id}';
      var answered = 0, wrong = 0;
      for (final r in results) {
        final sel = r.answers[key];
        if (sel == null) continue;
        answered++;
        if (sel != q.correctIndex) wrong++;
      }
      stats.add((q: q, answered: answered, wrong: wrong));
    }
    stats.sort((a, b) {
      final ra = a.answered == 0 ? 0.0 : a.wrong / a.answered;
      final rb = b.answered == 0 ? 0.0 : b.wrong / b.answered;
      return rb.compareTo(ra);
    });
    return [
      for (final s in stats)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2EAF7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.q.question,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: s.answered == 0 ? 0 : s.wrong / s.answered,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFEFF3FF),
                        color: const Color(0xFFC0392B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    s.answered == 0
                        ? 'brak odpowiedzi'
                        : '${s.wrong}/${s.answered} błędnych',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textLight),
                  ),
                ],
              ),
            ],
          ),
        ),
    ];
  }

  Widget _info(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Text(text,
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.inter(fontSize: 14, color: AppColors.textLight)),
        ),
      );
}

/// Dane pytania z formularza.
class _QuestionDraft {
  _QuestionDraft(this.question, this.answers, this.correctIndex);
  final String question;
  final List<String> answers;
  final int correctIndex;
}

/// Formularz dodawania / edycji pytania (2–4 odpowiedzi, wybór poprawnej).
class _QuestionFormSheet extends StatefulWidget {
  const _QuestionFormSheet({this.existing});
  final QuizQuestion? existing;

  @override
  State<_QuestionFormSheet> createState() => _QuestionFormSheetState();
}

class _QuestionFormSheetState extends State<_QuestionFormSheet> {
  late final TextEditingController _question;
  late final List<TextEditingController> _answers;
  int _correct = 0;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _question = TextEditingController(text: e?.question ?? '');
    final ans = e?.answers ?? const [];
    _answers = [
      for (var i = 0; i < 2; i++)
        TextEditingController(text: i < ans.length ? ans[i] : ''),
      for (var i = 2; i < ans.length && i < 4; i++)
        TextEditingController(text: ans[i]),
    ];
    _correct = (e?.correctIndex ?? 0).clamp(0, _answers.length - 1);
  }

  @override
  void dispose() {
    _question.dispose();
    for (final c in _answers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addAnswer() {
    if (_answers.length >= 4) return;
    setState(() => _answers.add(TextEditingController()));
  }

  void _removeAnswer(int i) {
    if (_answers.length <= 2) return;
    setState(() {
      _answers.removeAt(i).dispose();
      if (_correct >= _answers.length) _correct = _answers.length - 1;
    });
  }

  void _submit() {
    final q = _question.text.trim();
    final answers = _answers.map((c) => c.text.trim()).toList();
    final filled = answers.where((a) => a.isNotEmpty).toList();
    if (q.isEmpty) {
      _err('Wpisz treść pytania');
      return;
    }
    if (filled.length < 2) {
      _err('Podaj przynajmniej 2 odpowiedzi');
      return;
    }
    if (answers[_correct].isEmpty) {
      _err('Zaznaczona poprawna odpowiedź jest pusta');
      return;
    }
    // Przelicz indeks poprawnej po odfiltrowaniu pustych.
    final correctText = answers[_correct];
    final correctIndex = filled.indexOf(correctText);
    Navigator.of(context)
        .pop(_QuestionDraft(q, filled, correctIndex < 0 ? 0 : correctIndex));
  }

  void _err(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
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
                    child: Text(_isEdit ? 'Edytuj pytanie' : 'Dodaj pytanie',
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text)),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(
                        20, 8, 20, 20 + MediaQuery.paddingOf(context).bottom),
                    children: [
                      _label('Treść pytania'),
                      TextField(
                        controller: _question,
                        maxLines: 2,
                        decoration: _dec(hint: 'np. Gdzie się poznaliśmy?'),
                      ),
                      const SizedBox(height: 16),
                      _label('Odpowiedzi (zaznacz poprawną)'),
                      RadioGroup<int>(
                        groupValue: _correct,
                        onChanged: (v) => setState(() => _correct = v ?? 0),
                        child: Column(
                          children: [
                            for (var i = 0; i < _answers.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Radio<int>(
                                      value: i,
                                      activeColor: const Color(0xFF059669),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: _answers[i],
                                        decoration:
                                            _dec(hint: 'Odpowiedź ${i + 1}'),
                                      ),
                                    ),
                                    if (_answers.length > 2)
                                      IconButton(
                                        onPressed: () => _removeAnswer(i),
                                        icon: const Icon(Icons.close, size: 18),
                                        color: const Color(0xFFC0392B),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_answers.length < 4)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _addAnswer,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Dodaj odpowiedź'),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textLight,
                                side: const BorderSide(color: Color(0xFFD7DEEC)),
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
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 2),
        child: Text(text,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text)),
      );

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
