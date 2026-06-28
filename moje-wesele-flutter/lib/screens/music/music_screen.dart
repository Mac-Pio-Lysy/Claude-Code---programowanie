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
  String _genreFilter = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Song> get _songs => [
        for (final e in widget.data?.raw['songs'] ?? const [])
          if (e is Map) Song(Map<String, dynamic>.from(e)),
      ];

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
      length: 2,
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
              _filters(),
              const SizedBox(height: 12),
              if (unmatched.isNotEmpty) ...[
                Text('⚠ Niedopasowane / do weryfikacji (${unmatched.length})',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFB45309))),
                const SizedBox(height: 6),
                for (final s in unmatched) _songCard(s, unmatched: true),
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
              else
                for (final s in matched) _songCard(s),
            ],
          ),
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
        ],
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
    final content =
        format == 'csv' ? MusicExport.toCsv(songs) : MusicExport.toTxt(songs);
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
