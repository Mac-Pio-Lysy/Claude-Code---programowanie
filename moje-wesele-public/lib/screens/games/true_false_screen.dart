import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../layout/responsive.dart';
import '../../config/public_urls.dart';
import '../../models/true_false.dart';
import '../../models/wedding_data.dart';
import '../../services/firestore_service.dart';
import '../../services/true_false_service.dart';
import '../../widgets/guest_page_tab.dart';

/// Podzakładka „Prawda czy Fałsz" (w sekcji „Ślubne gry").
///
/// Trzy wewnętrzne zakładki: „Stwierdzenia" (panel organizatora), „Wyniki"
/// (ranking + statystyki mylących stwierdzeń) oraz „Strona dla gości"
/// (kod QR/link do publicznej strony `prawdafalsz.html`).
class TrueFalseScreen extends StatefulWidget {
  TrueFalseScreen(
      {super.key, required this.data, required FirestoreService firestore})
      : service = TrueFalseService(firestore: firestore);

  final WeddingData? data;
  final TrueFalseService service;

  @override
  State<TrueFalseScreen> createState() => _TrueFalseScreenState();
}

class _TrueFalseScreenState extends State<TrueFalseScreen> {
  late final Stream<List<TFResult>> _resultsStream =
      widget.service.watchResults();

  List<TFStatement> get _statements => [
        for (final e in widget.data?.raw['tfStatements'] ?? const [])
          if (e is Map) TFStatement(Map<String, dynamic>.from(e)),
      ];

  bool get _active => widget.data?.raw['tfActive'] == true;

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
              Tab(text: 'Stwierdzenia'),
              Tab(text: 'Wyniki'),
              Tab(text: 'Strona dla gości'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _statementsTab(),
                _resultsTab(),
                GuestPageTab(
                  links: [
                    (
                      '🤔 Prawda czy Fałsz o Parze Młodej',
                      PublicPages.prawdaFalsz(base)
                    )
                  ],
                  intro:
                      'Strona, na której goście zgadują, czy stwierdzenia o '
                      'Parze Młodej są prawdą czy fałszem. Włącz grę w zakładce '
                      '„Stwierdzenia", pokaż kod QR lub wyślij link.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── STWIERDZENIA ─────────────────────────────────────────────────────
  Widget _statementsTab() {
    final statements = _statements;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            children: [
              _activeCard(statements.isNotEmpty),
              const SizedBox(height: 14),
              if (statements.isEmpty)
                _emptyStatements()
              else
                _reorderable(statements),
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
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add),
                label: const Text('Dodaj stwierdzenie'),
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

  Widget _activeCard(bool hasStatements) {
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
        onChanged: hasStatements ? (v) => widget.service.setActive(v) : null,
        title: Text('Gra aktywna dla gości',
            style:
                GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
        subtitle: Text(
          hasStatements
              ? (_active
                  ? 'Goście mogą teraz grać przez stronę / kod QR.'
                  : 'Włącz, aby goście mogli odpowiadać.')
              : 'Najpierw dodaj przynajmniej jedno stwierdzenie.',
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
        ),
      ),
    );
  }

  Widget _emptyStatements() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Column(
        children: [
          const Text('🤔', style: TextStyle(fontSize: 34)),
          const SizedBox(height: 10),
          Text('Brak stwierdzeń',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text)),
          const SizedBox(height: 6),
          Text(
            'Dodaj własne stwierdzenia lub zacznij od gotowych przykładów.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () async {
              await widget.service.seedExamples();
              _toast('Dodano przykładowe stwierdzenia');
            },
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('Dodaj przykładowe'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reorderable(List<TFStatement> statements) {
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      onReorderItem: (oldIndex, newIndex) {
        final ids = statements.map((s) => s.id ?? 0).toList();
        final id = ids.removeAt(oldIndex);
        ids.insert(newIndex, id);
        widget.service.reorderStatements(ids);
      },
      children: [
        for (var i = 0; i < statements.length; i++)
          _statementCard(statements[i], i, key: ValueKey(statements[i].id)),
      ],
    );
  }

  Widget _statementCard(TFStatement s, int index, {required Key key}) {
    final trueColor = const Color(0xFF059669);
    final falseColor = const Color(0xFFC0392B);
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
                  child: Icon(Icons.drag_handle,
                      color: AppColors.textLight, size: 20),
                ),
              ),
              Expanded(
                child: Text('${index + 1}. ${s.text}',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
              ),
              IconButton(
                onPressed: () => _openForm(existing: s),
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: AppColors.accent,
                visualDensity: VisualDensity.compact,
                tooltip: 'Edytuj',
              ),
              IconButton(
                onPressed: () => _confirmDelete(s),
                icon: const Icon(Icons.delete_outline, size: 18),
                color: const Color(0xFFC0392B),
                visualDensity: VisualDensity.compact,
                tooltip: 'Usuń',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (s.isTrue ? trueColor : falseColor).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(s.isTrue ? '✓ PRAWDA' : '✗ FAŁSZ',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: s.isTrue ? trueColor : falseColor)),
          ),
          if (s.explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('💡 ${s.explanation}',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textLight)),
          ],
        ],
      ),
    );
  }

  Future<void> _openForm({TFStatement? existing}) async {
    final draft = await showModalBottomSheet<_TFDraft>(
      context: context,
      constraints: const BoxConstraints(maxWidth: kSheetMaxWidth),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StatementFormSheet(existing: existing),
    );
    if (draft == null) return;
    try {
      if (existing?.id != null) {
        await widget.service.updateStatement(existing!.id!,
            text: draft.text,
            isTrue: draft.isTrue,
            explanation: draft.explanation);
        _toast('Zapisano stwierdzenie');
      } else {
        await widget.service
            .addStatement(draft.text, draft.isTrue, draft.explanation);
        _toast('Dodano stwierdzenie');
      }
    } catch (e) {
      _toast('Błąd zapisu: $e');
    }
  }

  Future<void> _confirmDelete(TFStatement s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć stwierdzenie?'),
        content: Text('Czy na pewno usunąć „${s.text}"?'),
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
    if (ok != true || s.id == null) return;
    try {
      await widget.service.deleteStatement(s.id!);
      _toast('Usunięto stwierdzenie');
    } catch (e) {
      _toast('Błąd usuwania: $e');
    }
  }

  // ── WYNIKI ───────────────────────────────────────────────────────────
  Widget _resultsTab() {
    return StreamBuilder<List<TFResult>>(
      stream: _resultsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _info('Nie udało się wczytać wyników. Sprawdź połączenie.');
        }
        final results = [...?snapshot.data];
        final statements = _statements;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _resultsSummary(results, statements.length),
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
            if (results.isNotEmpty && statements.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('📊 Najbardziej mylące stwierdzenia',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text)),
              const SizedBox(height: 8),
              ..._difficulty(results, statements),
            ],
          ],
        );
      },
    );
  }

  Widget _resultsSummary(List<TFResult> results, int count) {
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
          _stat('$count', 'Stwierdzeń', const Color(0xFF7C3AED)),
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
              style:
                  GoogleFonts.inter(fontSize: 11, color: AppColors.textLight)),
        ],
      ),
    );
  }

  List<Widget> _ranking(List<TFResult> results) {
    final sorted = [...results]..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        return a.timestamp.compareTo(b.timestamp);
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

  List<Widget> _difficulty(List<TFResult> results, List<TFStatement> statements) {
    final stats = <({TFStatement s, int answered, int wrong})>[];
    for (final st in statements) {
      final key = '${st.id}';
      var answered = 0, wrong = 0;
      for (final r in results) {
        final pick = r.answers[key];
        if (pick == null) continue;
        answered++;
        if (pick != st.isTrue) wrong++;
      }
      stats.add((s: st, answered: answered, wrong: wrong));
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
              Text(s.s.text,
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

/// Dane stwierdzenia z formularza.
class _TFDraft {
  _TFDraft(this.text, this.isTrue, this.explanation);
  final String text;
  final bool isTrue;
  final String explanation;
}

/// Formularz dodawania / edycji stwierdzenia.
class _StatementFormSheet extends StatefulWidget {
  const _StatementFormSheet({this.existing});
  final TFStatement? existing;

  @override
  State<_StatementFormSheet> createState() => _StatementFormSheetState();
}

class _StatementFormSheetState extends State<_StatementFormSheet> {
  late final TextEditingController _text;
  late final TextEditingController _explanation;
  late bool _isTrue;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _text = TextEditingController(text: e?.text ?? '');
    _explanation = TextEditingController(text: e?.explanation ?? '');
    _isTrue = e?.isTrue ?? true;
  }

  @override
  void dispose() {
    _text.dispose();
    _explanation.dispose();
    super.dispose();
  }

  void _submit() {
    final t = _text.text.trim();
    if (t.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Wpisz treść stwierdzenia')));
      return;
    }
    Navigator.of(context).pop(_TFDraft(t, _isTrue, _explanation.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
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
                        _isEdit ? 'Edytuj stwierdzenie' : 'Dodaj stwierdzenie',
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
                      _label('Treść stwierdzenia'),
                      TextField(
                        controller: _text,
                        maxLines: 2,
                        decoration:
                            _dec(hint: 'np. Para Młoda poznała się w pracy'),
                      ),
                      const SizedBox(height: 16),
                      _label('Czy to prawda?'),
                      Row(
                        children: [
                          Expanded(
                            child: _truthOption(
                                'Prawda', true, const Color(0xFF059669)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _truthOption(
                                'Fałsz', false, const Color(0xFFC0392B)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _label('Wyjaśnienie (opcjonalnie)'),
                      TextField(
                        controller: _explanation,
                        maxLines: 2,
                        decoration: _dec(
                            hint: 'np. Poznali się przez wspólnych znajomych'),
                      ),
                      const SizedBox(height: 20),
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

  Widget _truthOption(String label, bool value, Color color) {
    final selected = _isTrue == value;
    return InkWell(
      onTap: () => setState(() => _isTrue = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? color : const Color(0xFFDCE4F2),
              width: selected ? 2 : 1.5),
        ),
        child: Text(
          '${value ? '✓' : '✗'} $label',
          style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: selected ? color : AppColors.textLight),
        ),
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
