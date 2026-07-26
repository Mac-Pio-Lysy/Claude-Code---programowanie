import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../config/public_urls.dart';
import '../../models/song.dart';
import '../../models/wedding_data.dart';
import '../../services/deezer_service.dart';
import '../../services/firestore_service.dart';
import '../../services/music_service.dart';
import '../../widgets/filter_toggle_button.dart';
import '../../widgets/guest_page_tab.dart';
import '../../widgets/public_link_card.dart';
import '../budget/budget_fields.dart';
import 'music_export.dart';

/// Sekcja „Muzyka" (panel organizatora) — lista utworów, wyszukiwanie Deezer,
/// filtry, sekcja niedopasowanych oraz eksport/import.
class MusicScreen extends StatefulWidget {
  MusicScreen({
    super.key,
    required this.data,
    required FirestoreService firestore,
  }) : service = MusicService(firestore: firestore);

  final WeddingData? data;
  final MusicService service;

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final _searchCtrl = TextEditingController();
  final _deezer = DeezerService();

  bool _searching = false;
  List<DeezerTrack>? _results;
  bool _searchError = false;

  String _momentFilter = 'all';
  String _statusFilter = 'all';
  bool _filtersVisible = false;
  String _genreFilter = '';

  /// Liczba kolumn w widoku kafelkowym (0 = widok listy).
  int _columns = 0;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Song> get _songs => [
        for (final e in widget.data?.raw['songs'] ?? const [])
          if (e is Map) Song(Map<String, dynamic>.from(e)),
      ];

  /// Skonfigurowane kluczowe momenty (kolejność = chronologia) lub domyślne.
  List<String> get _specialMoments =>
      resolveSpecialMoments(widget.data?.raw ?? const {});

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _searching = true;
      _results = null;
      _searchError = false;
    });
    final res = await _deezer.search(q);
    if (!mounted) return;
    setState(() {
      _searching = false;
      _searchError = res == null;
      _results = res ?? [];
    });
  }

  Future<void> _addManual() async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (context) => const _ManualAddDialog(),
    );
    if (result == null) return;
    await widget.service.addSong(title: result.$1, artist: result.$2);
    _toast('Dodano utwór');
  }

  bool _matches(Song s) {
    if (_momentFilter != 'all' && s.moment != _momentFilter) return false;
    if (_statusFilter != 'all' && s.statusId != _statusFilter) return false;
    final g = _genreFilter.trim().toLowerCase();
    if (g.isNotEmpty && !s.genre.toLowerCase().contains(g)) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _songs.where(_matches).toList();
    final unmatched = filtered.where((s) => s.unmatched).toList();
    final matched = filtered.where((s) => !s.unmatched).toList();

    return DefaultTabController(
      length: 3,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: Text('Muzyka',
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
              ),
              IconButton(
                tooltip: 'Kod QR dla gości',
                onPressed: () {
                  final base = PublicPages.baseUrl(widget.data?.raw);
                  showPublicLinkDialog(
                      context, '🎵 Muzyka — propozycje gości',
                      PublicPages.muzyka(base));
                },
                icon: const Icon(Icons.qr_code_2, color: AppColors.accent),
              ),
              IconButton(
                tooltip: 'Eksport',
                onPressed: _showExport,
                icon: const Icon(Icons.ios_share, color: AppColors.accent),
              ),
              IconButton(
                tooltip: 'Import',
                onPressed: _showImport,
                icon: const Icon(Icons.file_download_outlined,
                    color: AppColors.accent),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.accent,
          dividerColor: const Color(0xFFE2EAF7),
          labelStyle:
              GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Propozycje'),
            Tab(text: '⭐ Specjalne'),
            Tab(text: 'Strona dla gości'),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: [
              _searchCard(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text('Filtry i sortowanie',
                        style: GoogleFonts.inter(
                            fontSize: 14,
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
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.topCenter,
                curve: Curves.easeInOut,
                child: _filtersVisible
                    ? _filters()
                    : const SizedBox(width: double.infinity),
              ),
              const SizedBox(height: 12),
              _viewToggle(),
              const SizedBox(height: 12),
              if (unmatched.isNotEmpty) ...[
                Text('⚠ Niedopasowane / do weryfikacji (${unmatched.length})',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFB45309))),
                const SizedBox(height: 6),
                if (_columns == 0)
                  for (final s in unmatched) _songCard(s, unmatched: true)
                else
                  _grid(unmatched),
                const SizedBox(height: 12),
              ],
              Text('Lista utworów (${matched.length})',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text)),
              const SizedBox(height: 6),
              if (matched.isEmpty)
                Text('Brak utworów spełniających kryteria.',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textLight))
              else if (_columns == 0)
                for (final s in matched) _songCard(s)
              else
                _grid(matched),
            ],
          ),
              _specialTab(),
              GuestPageTab(
                links: [
                  (
                    '🎵 Muzyka — propozycje gości',
                    PublicPages.muzyka(PublicPages.baseUrl(widget.data?.raw)),
                  ),
                ],
                intro:
                    'Strona, na której goście proponują utwory do zagrania. '
                    'Pokaż im kod QR lub wyślij link.',
              ),
            ],
          ),
        ),
      ],
      ),
    );
  }

  Widget _searchCard() {
    return Container(
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
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: 'Szukaj utworu (Deezer)…',
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFF),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFDCE4F2)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _searching ? null : _search,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: _searching
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Szukaj'),
              ),
            ],
          ),
          if (_results != null) _searchResults(),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addManual,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Dodaj ręcznie'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchResults() {
    final results = _results!;
    final query = _searchCtrl.text.trim();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_searchError)
            Text('Nie udało się połączyć z Deezer (sprawdź internet/CORS).',
                style: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFFC0392B)))
          else if (results.isEmpty)
            Text('Nie znaleziono w Deezer.',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textLight))
          else
            for (final t in results.take(15))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    _cover(t.cover, 36),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(t.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: AppColors.textLight)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await widget.service.addSong(
                          title: t.title,
                          artist: t.artist,
                          cover: t.cover,
                          preview: t.preview,
                        );
                        _toast('Dodano: ${t.title}');
                      },
                      icon: const Icon(Icons.add_circle, color: AppColors.accent),
                    ),
                  ],
                ),
              ),
          if ((_searchError || results.isEmpty) && query.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: TextButton.icon(
                onPressed: () async {
                  await widget.service
                      .addSong(title: query, artist: '', unmatched: true);
                  _toast('Dodano jako niedopasowany');
                },
                icon: const Icon(Icons.add, size: 16),
                label: Text('Dodaj „$query" do weryfikacji'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _momentFilter,
                isExpanded: true,
                decoration: _miniDec('Moment'),
                items: [
                  const DropdownMenuItem(
                      value: 'all', child: Text('Wszystkie momenty')),
                  for (final m in kMusicMoments)
                    DropdownMenuItem(value: m, child: Text(m)),
                ],
                onChanged: (v) => setState(() => _momentFilter = v ?? 'all'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                decoration: _miniInputDec('Gatunek'),
                onChanged: (v) => setState(() => _genreFilter = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _statusChip('Wszystkie', 'all'),
              for (final s in MusicStatus.all)
                _statusChip('${s.icon} ${s.label}', s.id),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String label, String value) {
    final selected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _statusFilter = value),
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
      ),
    );
  }

  /// Przełącznik widoku: lista lub kafelki (4 / 6 / 8 w rzędzie).
  Widget _viewToggle() {
    Widget chip(String label, int cols) {
      final selected = _columns == cols;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => setState(() => _columns = cols),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );
    }

    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Text('Widok:',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight)),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                chip('Lista', 0),
                chip('4', 4),
                chip('6', 6),
                chip('8', 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Siatka kafelków utworów (klik → edycja w oknie).
  Widget _grid(List<Song> songs) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _columns,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.62,
      ),
      itemCount: songs.length,
      itemBuilder: (_, i) => _songTile(songs[i]),
    );
  }

  Widget _songTile(Song s) {
    return InkWell(
      onTap: () => _openSongEditor(s),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: s.unmatched
                  ? const Color(0xFFFCD34D)
                  : const Color(0xFFE2EAF7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(aspectRatio: 1, child: _coverFill(s.cover)),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 5, 6, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.title.isEmpty ? '—' : s.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text)),
                  Text(s.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 10, color: AppColors.textLight)),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: s.status.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('${s.status.icon} ${s.status.label}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: s.status.color)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Okładka wypełniająca kafelek (placeholder, gdy brak).
  Widget _coverFill(String url) {
    if (url.isEmpty) {
      return Container(
        color: const Color(0xFFEEF3FF),
        child: const Center(
            child: Icon(Icons.music_note, color: AppColors.accent)),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: const Color(0xFFEEF3FF),
        child: const Center(
            child: Icon(Icons.music_note, color: AppColors.accent)),
      ),
    );
  }

  /// Edycja utworu w oknie (ten sam formularz co w widoku listy).
  Future<void> _openSongEditor(Song s) async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _songCard(s, unmatched: s.unmatched),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Zamknij'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _songCard(Song s, {bool unmatched = false}) {
    final id = s.id ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: unmatched ? const Color(0xFFFCD34D) : const Color(0xFFE2EAF7)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cover(s.cover, 48),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BudgetTextField(
                      key: ValueKey('song-title-$id'),
                      initial: s.title,
                      hint: 'Tytuł',
                      onSaved: (v) => widget.service.updateSong(id, title: v),
                    ),
                    const SizedBox(height: 4),
                    BudgetTextField(
                      key: ValueKey('song-artist-$id'),
                      initial: s.artist,
                      hint: 'Wykonawca',
                      onSaved: (v) => widget.service.updateSong(id, artist: v),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => widget.service.deleteSong(id),
                icon: const Icon(Icons.delete_outline, size: 18),
                color: const Color(0xFFC0392B),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (s.isSpecial)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCFE0FB)),
                  ),
                  child: Text(
                    '⭐ ${specialMomentIcon(s.specialMoment)} ${s.specialMoment}',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent),
                  ),
                ),
              ),
            ),
          if (s.fromGuest)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF2F8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '👤 od gościa${s.guestName.isNotEmpty ? ': ${s.guestName}' : ''}',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFDB2777)),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue:
                      kMusicMoments.contains(s.moment) ? s.moment : 'Inne',
                  isExpanded: true,
                  decoration: _miniDec('Moment'),
                  items: [
                    for (final m in kMusicMoments)
                      DropdownMenuItem(value: m, child: Text(m)),
                  ],
                  onChanged: (v) => widget.service.updateSong(id, moment: v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: s.statusId,
                  isExpanded: true,
                  decoration: _miniDec('Status'),
                  items: [
                    for (final st in MusicStatus.all)
                      DropdownMenuItem(
                          value: st.id, child: Text('${st.icon} ${st.label}')),
                  ],
                  onChanged: (v) => widget.service.updateSong(id, status: v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          BudgetTextField(
            key: ValueKey('song-genre-$id'),
            initial: s.genre,
            hint: 'Gatunek / gust',
            onSaved: (v) => widget.service.updateSong(id, genre: v),
          ),
          const SizedBox(height: 8),
          _specialMomentDropdown(s, id),
        ],
      ),
    );
  }

  /// Selektor kluczowego momentu (utwór specjalny) dla utworu z listy.
  Widget _specialMomentDropdown(Song s, int id) {
    final moments = _specialMoments;
    // Dołącz aktualny moment, gdyby był spoza listy (własny/legacy).
    final values = <String>{
      '',
      ...moments,
      if (s.specialMoment.isNotEmpty) s.specialMoment,
    }.toList();
    return DropdownButtonFormField<String>(
      initialValue: values.contains(s.specialMoment) ? s.specialMoment : '',
      isExpanded: true,
      decoration: _miniDec('⭐ Moment specjalny'),
      items: [
        for (final m in values)
          DropdownMenuItem(
            value: m,
            child: Text(m.isEmpty
                ? '— nie jest specjalny —'
                : '${specialMomentIcon(m)} $m'),
          ),
      ],
      onChanged: (v) => widget.service.updateSong(id, specialMoment: v ?? ''),
    );
  }

  // ── Zakładka „⭐ Specjalne" (kluczowe momenty wesela) ──────────────────
  Widget _specialTab() {
    final moments = _specialMoments;
    final byMoment = <String, List<Song>>{};
    for (final s in _songs) {
      if (s.isSpecial) byMoment.putIfAbsent(s.specialMoment, () => []).add(s);
    }
    final orphans =
        byMoment.keys.where((m) => !moments.contains(m)).toList()..sort();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFCFE0FB)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.star_outline, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Utwory do kluczowych momentów wesela. Przeciągnij, by ustawić '
                  'chronologię. Przy każdym momencie dodaj nowy utwór lub przypisz '
                  'istniejący z listy.',
                  style: GoogleFonts.inter(
                      fontSize: 13, height: 1.45, color: AppColors.text),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: (oldIndex, newIndex) {
            final list = [...moments];
            final m = list.removeAt(oldIndex);
            list.insert(newIndex, m);
            widget.service.setSpecialMoments(list);
          },
          children: [
            for (var i = 0; i < moments.length; i++)
              _momentCard(moments[i], byMoment[moments[i]] ?? const [],
                  index: i, key: ValueKey('mom-${moments[i]}')),
          ],
        ),
        for (final o in orphans)
          _momentCard(o, byMoment[o]!, index: null, key: ValueKey('orphan-$o')),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _addSpecialMomentLabel,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Dodaj własny moment'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accent,
            side: const BorderSide(color: AppColors.accent),
            minimumSize: const Size.fromHeight(46),
          ),
        ),
      ],
    );
  }

  Widget _momentCard(String label, List<Song> assigned,
      {required int? index, required Key key}) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
              if (index != null)
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.drag_handle,
                        color: AppColors.textLight, size: 20),
                  ),
                ),
              Text(specialMomentIcon(label),
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
              ),
              if (index == null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text('spoza listy',
                      style: GoogleFonts.inter(
                          fontSize: 10, color: const Color(0xFFB45309))),
                ),
              IconButton(
                onPressed: () => _deleteSpecialMomentLabel(label),
                icon: const Icon(Icons.delete_outline, size: 18),
                color: const Color(0xFFC0392B),
                visualDensity: VisualDensity.compact,
                tooltip: 'Usuń moment z listy',
              ),
            ],
          ),
          if (assigned.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text('Brak utworu — dodaj lub przypisz.',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textLight)),
            )
          else
            for (final s in assigned) _assignedSongRow(s),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _addSongToMoment(label),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Dodaj nowy'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _assignExistingToMoment(label),
                  icon: const Icon(Icons.playlist_add, size: 16),
                  label: const Text('Przypisz'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _assignedSongRow(Song s) {
    final id = s.id ?? 0;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _cover(s.cover, 40),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.title.isEmpty ? '—' : s.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                Text(
                    '${s.artist}${s.artist.isNotEmpty ? ' · ' : ''}${s.status.icon} ${s.status.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textLight)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _openSongEditor(s),
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: AppColors.accent,
            visualDensity: VisualDensity.compact,
            tooltip: 'Edytuj',
          ),
          IconButton(
            onPressed: () async {
              await widget.service.updateSong(id, specialMoment: '');
              _toast('Usunięto przypisanie');
            },
            icon: const Icon(Icons.link_off, size: 18),
            color: const Color(0xFFC0392B),
            visualDensity: VisualDensity.compact,
            tooltip: 'Usuń przypisanie',
          ),
        ],
      ),
    );
  }

  Future<void> _addSpecialMomentLabel() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nowy moment'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
              labelText: 'Nazwa momentu',
              hintText: 'np. Poprawiny',
              border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anuluj')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(ctrl.text.trim()),
            child: const Text('Dodaj'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final list = [..._specialMoments];
    if (list.contains(name)) {
      _toast('Taki moment już istnieje');
      return;
    }
    list.add(name);
    await widget.service.setSpecialMoments(list);
    _toast('Dodano moment: $name');
  }

  Future<void> _deleteSpecialMomentLabel(String label) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć moment z listy?'),
        content: Text(
            'Moment „$label" zniknie z listy. Przypisane utwory NIE zostaną '
            'usunięte — pokażą się jako „spoza listy", możesz je przypisać '
            'ponownie lub odłączyć.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Anuluj')),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: const Color(0xFFC0392B)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final list = [..._specialMoments]..remove(label);
    await widget.service.setSpecialMoments(list);
  }

  Future<void> _assignExistingToMoment(String label) async {
    final songs = _songs;
    if (songs.isEmpty) {
      _toast('Brak utworów na liście. Dodaj najpierw utwór.');
      return;
    }
    final picked = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Przypisz do: $label'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final s in songs)
                ListTile(
                  dense: true,
                  leading: _cover(s.cover, 36),
                  title: Text(s.title.isEmpty ? '—' : s.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                      s.isSpecial
                          ? '⭐ ${s.specialMoment}'
                          : s.artist,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => Navigator.of(context).pop(s.id),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anuluj')),
        ],
      ),
    );
    if (picked == null) return;
    await widget.service.updateSong(picked, specialMoment: label);
    _toast('Przypisano utwór do: $label');
  }

  Future<void> _addSongToMoment(String label) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _AddSpecialSongDialog(
        service: widget.service,
        deezer: _deezer,
        moment: label,
      ),
    );
  }

  Widget _cover(String url, double size) {
    if (url.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFEEF3FF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.music_note, color: AppColors.accent),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: size,
          height: size,
          color: const Color(0xFFEEF3FF),
          child: const Icon(Icons.music_note, color: AppColors.accent),
        ),
      ),
    );
  }

  Future<void> _showExport() async {
    final songs = _songs;
    if (songs.isEmpty) {
      _toast('Brak utworów do eksportu');
      return;
    }
    final format = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: const Text('Eksport CSV'),
              onTap: () => Navigator.of(context).pop('csv'),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Eksport tekstowy'),
              onTap: () => Navigator.of(context).pop('txt'),
            ),
          ],
        ),
      ),
    );
    if (format == null || !mounted) return;
    final content = format == 'csv'
        ? MusicExport.toCsv(songs)
        : MusicExport.toTxt(songs, specialMoments: _specialMoments);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(format == 'csv' ? 'Eksport CSV' : 'Eksport tekstowy'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(content,
                style: GoogleFonts.robotoMono(fontSize: 12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: content));
              _toast('Skopiowano do schowka');
            },
            child: const Text('Kopiuj'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }

  Future<void> _showImport() async {
    final controller = TextEditingController();
    final imported = await showDialog<List<ParsedSong>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import utworów'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(MusicExport.importHelp,
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.textLight)),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'Wklej tutaj…',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anuluj')),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(MusicExport.parse(controller.text)),
            child: const Text('Importuj'),
          ),
        ],
      ),
    );
    if (imported == null || imported.isEmpty) {
      if (imported != null) _toast('Nie rozpoznano utworów');
      return;
    }
    for (final p in imported) {
      await widget.service.addSong(
        title: p.title,
        artist: p.artist,
        status: p.status,
        unmatched: true,
      );
    }
    _toast('Zaimportowano ${imported.length} utworów');
  }

  InputDecoration _miniDec(String label) => InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDCE4F2)),
        ),
      );

  InputDecoration _miniInputDec(String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF8FAFF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDCE4F2)),
        ),
      );
}

/// Dialog ręcznego dodawania utworu.
class _ManualAddDialog extends StatefulWidget {
  const _ManualAddDialog();

  @override
  State<_ManualAddDialog> createState() => _ManualAddDialogState();
}

class _ManualAddDialogState extends State<_ManualAddDialog> {
  final _title = TextEditingController();
  final _artist = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dodaj utwór ręcznie'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(
                labelText: 'Tytuł', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _artist,
            decoration: const InputDecoration(
                labelText: 'Wykonawca', border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj')),
        FilledButton(
          onPressed: () {
            final t = _title.text.trim();
            if (t.isEmpty) return;
            Navigator.of(context).pop((t, _artist.text.trim()));
          },
          child: const Text('Dodaj'),
        ),
      ],
    );
  }
}

/// Dialog dodawania nowego utworu wprost do kluczowego momentu — wyszukiwanie
/// Deezer lub wpis ręczny. Dodany utwór jest oznaczony jako specjalny.
class _AddSpecialSongDialog extends StatefulWidget {
  const _AddSpecialSongDialog({
    required this.service,
    required this.deezer,
    required this.moment,
  });

  final MusicService service;
  final DeezerService deezer;
  final String moment;

  @override
  State<_AddSpecialSongDialog> createState() => _AddSpecialSongDialogState();
}

class _AddSpecialSongDialogState extends State<_AddSpecialSongDialog> {
  final _search = TextEditingController();
  final _title = TextEditingController();
  final _artist = TextEditingController();
  bool _searching = false;
  List<DeezerTrack>? _results;

  @override
  void dispose() {
    _search.dispose();
    _title.dispose();
    _artist.dispose();
    super.dispose();
  }

  void _msg(String m) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _doSearch() async {
    final q = _search.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _searching = true;
      _results = null;
    });
    final res = await widget.deezer.search(q);
    if (!mounted) return;
    setState(() {
      _searching = false;
      _results = res ?? [];
    });
  }

  Future<void> _addDeezer(DeezerTrack t) async {
    await widget.service.addSong(
      title: t.title,
      artist: t.artist,
      cover: t.cover,
      preview: t.preview,
      status: 'approved',
      specialMoment: widget.moment,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    _msg('Dodano: ${t.title}');
  }

  Future<void> _addManual() async {
    final t = _title.text.trim();
    if (t.isEmpty) {
      _msg('Podaj tytuł utworu');
      return;
    }
    await widget.service.addSong(
      title: t,
      artist: _artist.text.trim(),
      status: 'approved',
      unmatched: true,
      specialMoment: widget.moment,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    _msg('Dodano utwór');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${specialMomentIcon(widget.moment)} ${widget.moment}',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _search,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _doSearch(),
                      decoration: const InputDecoration(
                        hintText: 'Szukaj w Deezer…',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _searching ? null : _doSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                    ),
                    child: _searching
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Szukaj'),
                  ),
                ],
              ),
              if (_results != null) ...[
                const SizedBox(height: 8),
                if (_results!.isEmpty)
                  Text('Nic nie znaleziono (możesz dodać ręcznie poniżej).',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textLight))
                else
                  for (final t in _results!.take(12))
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: t.cover.isEmpty
                            ? const Icon(Icons.music_note,
                                color: AppColors.accent)
                            : Image.network(t.cover,
                                width: 36, height: 36, fit: BoxFit.cover),
                      ),
                      title: Text(t.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(t.artist,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle,
                            color: AppColors.accent),
                        onPressed: () => _addDeezer(t),
                      ),
                    ),
              ],
              const Divider(height: 24),
              Text('…lub dodaj ręcznie',
                  style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: _title,
                decoration: const InputDecoration(
                    labelText: 'Tytuł',
                    isDense: true,
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _artist,
                decoration: const InputDecoration(
                    labelText: 'Wykonawca',
                    isDense: true,
                    border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
          onPressed: _addManual,
          child: const Text('Dodaj ręcznie'),
        ),
      ],
    );
  }
}
