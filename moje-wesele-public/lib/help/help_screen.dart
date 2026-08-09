import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';
import '../onboarding/onboarding_steps.dart' show OnbVariant;
import 'help_content.dart';

/// Ekran „Pomoc" — encyklopedia funkcji do czytania.
///
/// Uzupełnia przewodnik: przewodnik prowadzi po ekranach i podświetla elementy,
/// pomoc odpowiada na konkretne pytanie „jak to działa i po co".
///
/// Treść dobiera się do roli ([OnbVariant]). Właściciel i planer mogą przełączyć
/// się na pomoc dla gości, żeby wiedzieć, co widzą zapraszani.
class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key, required this.variant});

  /// Wariant wynikający z roli zalogowanego użytkownika.
  final OnbVariant variant;

  /// Otwiera pomoc jako pełny ekran.
  static Future<void> open(BuildContext context, OnbVariant variant) =>
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => HelpScreen(variant: variant),
      ));

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _searchCtrl = TextEditingController();

  /// Aktualnie wyświetlany wariant — zmienia się przy podglądzie pomocy gościa.
  late OnbVariant _shown = widget.variant;

  String _query = '';

  bool get _canPreviewGuest => widget.variant != OnbVariant.guest;
  bool get _previewingGuest =>
      _canPreviewGuest && _shown == OnbVariant.guest;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<HelpCategory> get _categories => buildHelp(_shown);

  /// Hasła pasujące do zapytania, spłaszczone razem z nazwą kategorii.
  List<({HelpCategory cat, HelpTopic topic})> get _results {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return [
      for (final c in _categories)
        for (final t in c.topics)
          if (t.matches(q)) (cat: c, topic: t),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final searching = _query.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.bgGradient.last,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        title: Text(
          _previewingGuest ? 'Pomoc dla gości' : 'Pomoc',
          style: GoogleFonts.playfairDisplay(
              fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text),
        ),
        actions: [
          if (_canPreviewGuest)
            IconButton(
              tooltip: _previewingGuest
                  ? 'Wróć do swojej pomocy'
                  : 'Zobacz pomoc dla gości',
              icon: Icon(
                _previewingGuest ? Icons.arrow_back : Icons.groups_outlined,
                color: AppColors.accent,
              ),
              onPressed: () => setState(() {
                _shown = _previewingGuest ? widget.variant : OnbVariant.guest;
              }),
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
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              if (_previewingGuest) _previewBanner(),
              _searchField(),
              Expanded(
                child: searching ? _resultsList() : _categoryList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewBanner() => Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.visibility_outlined,
                size: 18, color: Color(0xFF8A6D26)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Oglądasz pomoc, którą widzą Wasi goście.',
                style: GoogleFonts.inter(
                    fontSize: 12.5, color: const Color(0xFF7A4E00)),
              ),
            ),
          ],
        ),
      );

  Widget _searchField() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _query = v),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Szukaj funkcji, np. „budżet", „QR", „RSVP"',
            hintStyle:
                GoogleFonts.inter(color: AppColors.textLight, fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: AppColors.textLight,
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                  ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDCE4F2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
            ),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );

  Widget _categoryList() => ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          for (final c in _categories) _categoryCard(c),
          const SizedBox(height: 8),
          Text(
            'Szukasz czegoś innego? Przewodnik pokaże Ci aplikację krok po '
            'kroku — uruchomisz go z Ustawień.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
          ),
        ],
      );

  Widget _categoryCard(HelpCategory c) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2EAF7)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          // Usuwa domyślne linie ExpansionTile, żeby karta była gładka.
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.10),
              ),
              child: Icon(c.icon, size: 20, color: AppColors.accent),
            ),
            title: Text(
              c.title,
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text),
            ),
            subtitle: Text(
              '${c.topics.length} ${_topicWord(c.topics.length)}',
              style:
                  GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
            ),
            iconColor: AppColors.accent,
            collapsedIconColor: AppColors.textLight,
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            children: [for (final t in c.topics) _topicTile(t)],
          ),
        ),
      );

  /// Odmiana słowa „hasło" — 1 hasło, 2–4 hasła, 5+ haseł.
  String _topicWord(int n) {
    if (n == 1) return 'hasło';
    final last = n % 10;
    final teen = n % 100 >= 12 && n % 100 <= 14;
    return (!teen && last >= 2 && last <= 4) ? 'hasła' : 'haseł';
  }

  Widget _topicTile(HelpTopic t) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent,
                  ),
                ),
                Expanded(
                  child: Text(
                    t.title,
                    style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 13, top: 3),
              child: Text(
                t.body,
                style: GoogleFonts.inter(
                    fontSize: 13, height: 1.5, color: AppColors.textLight),
              ),
            ),
          ],
        ),
      );

  Widget _resultsList() {
    final results = _results;
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off,
                  size: 38, color: AppColors.textLight),
              const SizedBox(height: 12),
              Text(
                'Nic nie znaleziono dla „${_query.trim()}".\n'
                'Spróbuj innego słowa — np. „gość", „stół", „płatność".',
                textAlign: TextAlign.center,
                style:
                    GoogleFonts.inter(fontSize: 14, color: AppColors.textLight),
              ),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 2),
          child: Text(
            'Znaleziono ${results.length} ${_topicWord(results.length)}',
            style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textLight),
          ),
        ),
        for (final r in results)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2EAF7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(r.cat.icon, size: 14, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      r.cat.title,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  r.topic.title,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text),
                ),
                const SizedBox(height: 4),
                Text(
                  r.topic.body,
                  style: GoogleFonts.inter(
                      fontSize: 13, height: 1.5, color: AppColors.textLight),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
