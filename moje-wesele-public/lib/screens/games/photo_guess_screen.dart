import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../app_colors.dart';
import '../../layout/responsive.dart';
import '../../config/public_urls.dart';
import '../../models/photo_guess.dart';
import '../../models/wedding_data.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firestore_service.dart';
import '../../services/photo_guess_service.dart';
import '../../widgets/guest_page_tab.dart';
import '../../l10n/app_text.dart';

/// Podzakładka „Zgadnij zdjęcie" (w sekcji „Ślubne gry").
///
/// Trzy wewnętrzne zakładki: „Zdjęcia" (panel organizatora — pytania ze
/// zdjęciami), „Wyniki" (ranking + najtrudniejsze zdjęcia) oraz „Strona dla
/// gości" (kod QR/link do `zgadnijzdjecie.html`). Zdjęcia trzyma Cloudinary.
class PhotoGuessScreen extends StatefulWidget {
  PhotoGuessScreen(
      {super.key, required this.data, required FirestoreService firestore})
      : service = PhotoGuessService(firestore: firestore);

  final WeddingData? data;
  final PhotoGuessService service;

  @override
  State<PhotoGuessScreen> createState() => _PhotoGuessScreenState();
}

class _PhotoGuessScreenState extends State<PhotoGuessScreen> {
  late final Stream<List<PhotoGuessResult>> _resultsStream =
      widget.service.watchResults();

  List<PhotoQuestion> get _questions => [
        for (final e in widget.data?.raw['photoQuestions'] ?? const [])
          if (e is Map) PhotoQuestion(Map<String, dynamic>.from(e)),
      ];

  bool get _active => widget.data?.raw['photoGuessActive'] == true;

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
              Tab(text: 'Zdjęcia'),
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
                  links: [
                    ('📸 Zgadnij zdjęcie', PublicPages.zgadnijZdjecie(base))
                  ],
                  intro:
                      AppText.t.photoGuess_txt1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── ZDJĘCIA ──────────────────────────────────────────────────────────
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
                _empty()
              else
                _reorderable(questions),
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
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(AppText.t.photoGuess_add),
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
        onChanged: hasQuestions ? (v) => widget.service.setActive(v) : null,
        title: Text(AppText.t.games_activeForGuests,
            style:
                GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
        subtitle: Text(
          hasQuestions
              ? (_active
                  ? 'Goście mogą teraz grać przez stronę / kod QR.'
                  : 'Włącz, aby goście mogli zgadywać.')
              : 'Najpierw dodaj przynajmniej jedno zdjęcie.',
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
        ),
      ),
    );
  }

  Widget _empty() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Column(
        children: [
          const Text('📸', style: TextStyle(fontSize: 34)),
          const SizedBox(height: 10),
          Text(AppText.t.photoGuess_empty,
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text)),
          const SizedBox(height: 6),
          Text(
            AppText.t.photoGuess_txt2,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _reorderable(List<PhotoQuestion> questions) {
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

  Widget _questionCard(PhotoQuestion q, int index, {required Key key}) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.network(
                  q.photoUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : Container(
                          color: const Color(0xFFEEF3FF),
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator()),
                  errorBuilder: (_, _, _) => Container(
                    color: const Color(0xFFEEF3FF),
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined,
                        color: AppColors.textLight, size: 40),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ReorderableDragStartListener(
                    index: index,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.drag_handle,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text('${index + 1}',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(q.question,
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text)),
                    ),
                    IconButton(
                      onPressed: () => _openForm(existing: q),
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
                      tooltip: AppText.t.common_delete,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                for (var i = 0; i < q.answers.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      children: [
                        Icon(
                          i == q.correctIndex
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 15,
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
          ),
        ],
      ),
    );
  }

  Future<void> _openForm({PhotoQuestion? existing}) async {
    final draft = await showModalBottomSheet<_PGDraft>(
      context: context,
      constraints: const BoxConstraints(maxWidth: kSheetMaxWidth),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PhotoFormSheet(existing: existing),
    );
    if (draft == null) return;
    try {
      if (existing?.id != null) {
        await widget.service.updateQuestion(existing!.id!,
            photoUrl: draft.photoUrl,
            photoPublicId: draft.photoPublicId,
            question: draft.question,
            answers: draft.answers,
            correctIndex: draft.correctIndex);
        _toast(AppText.t.photoGuess_saved);
      } else {
        await widget.service.addQuestion(
            photoUrl: draft.photoUrl,
            photoPublicId: draft.photoPublicId,
            question: draft.question,
            answers: draft.answers,
            correctIndex: draft.correctIndex);
        _toast(AppText.t.photoGuess_added);
      }
    } catch (e) {
      _toast(AppText.t.common_saveErrorToast('$e'));
    }
  }

  Future<void> _confirmDelete(PhotoQuestion q) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppText.t.photoGuess_deleteTitle),
        content: Text(AppText.t.photoGuess_deleteBody(q.question)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppText.t.common_cancel),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: const Color(0xFFC0392B)),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppText.t.common_delete),
          ),
        ],
      ),
    );
    if (ok != true || q.id == null) return;
    try {
      await widget.service.deleteQuestion(q.id!);
      _toast(AppText.t.photoGuess_deleted);
    } catch (e) {
      _toast(AppText.t.common_deleteErrorToast('$e'));
    }
  }

  // ── WYNIKI ───────────────────────────────────────────────────────────
  Widget _resultsTab() {
    return StreamBuilder<List<PhotoGuessResult>>(
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
            Text(AppText.t.games_ranking,
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
              Text(AppText.t.photoGuess_hardest,
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

  Widget _resultsSummary(List<PhotoGuessResult> results, int count) {
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
          _stat('$count', 'Zdjęć', const Color(0xFF7C3AED)),
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

  List<Widget> _ranking(List<PhotoGuessResult> results) {
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
                child: Text(AppText.t.games_scoreOf(sorted[i].score, sorted[i].total),
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
      List<PhotoGuessResult> results, List<PhotoQuestion> questions) {
    final stats = <({PhotoQuestion q, int answered, int wrong})>[];
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
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(s.q.photoUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                          width: 48,
                          height: 48,
                          color: const Color(0xFFEEF3FF),
                          child: const Icon(Icons.image_not_supported_outlined,
                              size: 18, color: AppColors.textLight),
                        )),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.q.question,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                              ? 'brak'
                              : '${s.wrong}/${s.answered} błędnych',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.textLight),
                        ),
                      ],
                    ),
                  ],
                ),
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

/// Dane pytania ze zdjęciem z formularza.
class _PGDraft {
  _PGDraft(this.photoUrl, this.photoPublicId, this.question, this.answers,
      this.correctIndex);
  final String photoUrl;
  final String photoPublicId;
  final String question;
  final List<String> answers;
  final int correctIndex;
}

/// Formularz dodawania / edycji pytania ze zdjęciem (upload Cloudinary).
class _PhotoFormSheet extends StatefulWidget {
  const _PhotoFormSheet({this.existing});
  final PhotoQuestion? existing;

  @override
  State<_PhotoFormSheet> createState() => _PhotoFormSheetState();
}

class _PhotoFormSheetState extends State<_PhotoFormSheet> {
  final _cloudinary = CloudinaryService();
  final _picker = ImagePicker();

  late final TextEditingController _question;
  late final List<TextEditingController> _answers;
  int _correct = 0;

  String _photoUrl = '';
  String _photoPublicId = '';
  bool _uploading = false;

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
    _photoUrl = e?.photoUrl ?? '';
    _photoPublicId = e?.photoPublicId ?? '';
  }

  @override
  void dispose() {
    _question.dispose();
    for (final c in _answers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
          source: source, maxWidth: 1600, imageQuality: 85);
      if (file == null) return;
      setState(() => _uploading = true);
      final bytes = await file.readAsBytes();
      final up = await _cloudinary.uploadImage(bytes, filename: file.name);
      if (!mounted) return;
      setState(() {
        _photoUrl = up.url;
        _photoPublicId = up.publicId;
        _uploading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      _err('Nie udało się wgrać zdjęcia: $e');
    }
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
    if (_photoUrl.isEmpty) {
      _err('Najpierw dodaj zdjęcie');
      return;
    }
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
    final correctText = answers[_correct];
    final correctIndex = filled.indexOf(correctText);
    Navigator.of(context).pop(_PGDraft(_photoUrl, _photoPublicId, q, filled,
        correctIndex < 0 ? 0 : correctIndex));
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
                    child: Text(_isEdit ? 'Edytuj zdjęcie' : 'Dodaj zdjęcie',
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
                      _photoPicker(),
                      const SizedBox(height: 16),
                      _label('Pytanie'),
                      TextField(
                        controller: _question,
                        maxLines: 2,
                        decoration: _dec(hint: 'np. Kto to z dzieciństwa?'),
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
                                        activeColor: const Color(0xFF059669)),
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
                            label: Text(AppText.t.games_addAnswer),
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
                              child: Text(AppText.t.common_cancel),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _uploading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(_isEdit ? AppText.t.common_save : 'Dodaj'),
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

  Widget _photoPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Zdjęcie'),
        AspectRatio(
          aspectRatio: 16 / 10,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDCE4F2)),
            ),
            clipBehavior: Clip.antiAlias,
            child: _uploading
                ? const Center(child: CircularProgressIndicator())
                : _photoUrl.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_photo_alternate_outlined,
                                size: 40, color: AppColors.textLight),
                            const SizedBox(height: 6),
                            Text(AppText.t.photoGuess_noPhoto,
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: AppColors.textLight)),
                          ],
                        ),
                      )
                    : Image.network(_photoUrl, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _uploading ? null : () => _pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: Text(AppText.t.photoGuess_fromGallery),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _uploading ? null : () => _pick(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
                label: const Text('Aparat'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                ),
              ),
            ),
          ],
        ),
      ],
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
