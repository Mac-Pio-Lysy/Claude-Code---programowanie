import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../services/guest_space_service.dart';

/// Rodzaj treści w zakładce — decyduje o sposobie wyświetlenia wpisu.
enum _Kind {
  /// Imię + treść (RSVP, księga, rady, mapa, kapsuła).
  text,

  /// Miniatura zdjęcia + podpis (galeria, foto-wyzwania).
  photo,

  /// Tytuł/wykonawca + status do zmiany (propozycje muzyki).
  music,

  /// Wynik punktowy (quiz, prawda/fałsz, zgadnij zdjęcie).
  score,

  /// Skreślone pola z planszy (bingo).
  bingo,
}

/// Moderacja interakcji gości (z trybu web gościa) — dla organizatora.
///
/// Czyta podkolekcje `guestSpaces/{guestToken}/…` i pozwala usuwać wpisy.
/// Odczyt PUBLICZNY mają: księga, rady, mapa, galeria, foto-wyzwania — tu
/// organizator widzi to samo co goście, plus kasowanie. Odczyt TYLKO dla
/// organizatora mają: RSVP, kapsuła czasu, propozycje muzyki i wszystkie
/// wyniki gier — gość nie zobaczy ich nigdzie.
class GuestInteractionsScreen extends StatelessWidget {
  const GuestInteractionsScreen({super.key, required this.guestToken});

  final String guestToken;

  static const _tabs = <({String coll, String label, _Kind kind})>[
    (coll: 'rsvp', label: 'RSVP', kind: _Kind.text),
    (coll: 'guestbook', label: 'Księga', kind: _Kind.text),
    (coll: 'advice', label: 'Rady', kind: _Kind.text),
    (coll: 'guestMap', label: 'Mapa', kind: _Kind.text),
    (coll: 'timeCapsule', label: 'Kapsuła', kind: _Kind.text),
    (coll: 'gallery', label: 'Galeria', kind: _Kind.photo),
    (coll: 'photoChallenges', label: 'Foto-wyzwania', kind: _Kind.photo),
    (coll: 'musicProposals', label: 'Muzyka', kind: _Kind.music),
    (coll: 'quizResults', label: 'Quiz', kind: _Kind.score),
    (coll: 'trueFalseResults', label: 'Prawda/Fałsz', kind: _Kind.score),
    (coll: 'photoGuessResults', label: 'Zgadnij zdjęcie', kind: _Kind.score),
    (coll: 'bingoResults', label: 'Bingo', kind: _Kind.bingo),
  ];

  @override
  Widget build(BuildContext context) {
    final service = GuestSpaceService(token: guestToken);
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        backgroundColor: AppColors.bgGradient.last,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0.5,
          title: Text('Interakcje gości',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text)),
          bottom: TabBar(
            isScrollable: true,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textLight,
            indicatorColor: AppColors.accent,
            tabs: [for (final t in _tabs) Tab(text: t.label)],
          ),
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
            child: TabBarView(
              children: [
                for (final t in _tabs)
                  _InteractionList(
                      service: service, coll: t.coll, kind: t.kind),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractionList extends StatelessWidget {
  const _InteractionList(
      {required this.service, required this.coll, required this.kind});

  final GuestSpaceService service;
  final String coll;
  final _Kind kind;

  Future<void> _delete(BuildContext context, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Usunąć wpis?'),
        content: Text(kind == _Kind.photo
            ? 'Zdjęcie zniknie ze strony gości. Oryginał zostaje w Cloudinary.'
            : 'Wpis gościa zostanie trwale usunięty.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Anuluj')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC0392B)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (ok == true) await service.deleteEntry(coll, id);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: service.watchCollection(coll),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.accent));
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Nie udało się wczytać: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: AppColors.textLight)),
            ),
          );
        }
        final entries = snapshot.data ?? const [];
        if (entries.isEmpty) {
          return Center(
            child: Text('Brak wpisów.',
                style: GoogleFonts.inter(color: AppColors.textLight)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _card(context, entries[i]),
        );
      },
    );
  }

  Widget _card(BuildContext context, Map<String, dynamic> e) => Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2EAF7)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (kind == _Kind.photo) ...[
              _thumb((e['photoUrl'] as String?) ?? ''),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_title(e),
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent)),
                  if (_body(e).isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(_body(e),
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.text)),
                  ],
                  if (kind == _Kind.music) ...[
                    const SizedBox(height: 8),
                    _statusRow(e),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: () => _delete(context, e['id'] as String),
              icon: const Icon(Icons.delete_outline, size: 20),
              color: const Color(0xFFC0392B),
              tooltip: 'Usuń',
            ),
          ],
        ),
      );

  Widget _thumb(String url) => ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 56,
          height: 56,
          child: url.isEmpty
              ? const ColoredBox(color: Color(0xFFF1F5FC))
              : Image.network(url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const ColoredBox(
                        color: Color(0xFFF1F5FC),
                        child: Icon(Icons.broken_image_outlined,
                            size: 18, color: AppColors.textLight),
                      )),
        ),
      );

  /// Status propozycji muzycznej: brak pola = „Nowa".
  Widget _statusRow(Map<String, dynamic> e) {
    final id = e['id'] as String;
    final current = (e['status'] as String?) ?? 'new';
    const options = <({String value, String label})>[
      (value: 'new', label: 'Nowa'),
      (value: 'accepted', label: 'Zagramy'),
      (value: 'rejected', label: 'Odrzucona'),
    ];
    return Wrap(
      spacing: 6,
      children: [
        for (final o in options)
          ChoiceChip(
            label: Text(o.label, style: GoogleFonts.inter(fontSize: 11)),
            selected: current == o.value,
            onSelected: (_) =>
                service.updateEntry(coll, id, {'status': o.value}),
            selectedColor: AppColors.accent.withValues(alpha: 0.15),
            labelStyle: GoogleFonts.inter(
                fontSize: 11,
                color: current == o.value ? AppColors.accent : AppColors.text),
          ),
      ],
    );
  }

  String _title(Map<String, dynamic> e) {
    final name = (e['name'] as String?) ?? 'Gość';
    switch (kind) {
      case _Kind.music:
        final title = (e['title'] as String?) ?? '';
        final artist = (e['artist'] as String?) ?? '';
        return artist.isEmpty ? title : '$title — $artist';
      case _Kind.score:
        final score = (e['score'] as num?)?.toInt() ?? 0;
        final total = (e['total'] as num?)?.toInt() ?? 0;
        return '$name — $score/$total pkt';
      case _Kind.bingo:
        final marked = (e['marked'] as num?)?.toInt() ?? 0;
        final total = (e['total'] as num?)?.toInt() ?? 0;
        return '$name — skreślone $marked/$total';
      case _Kind.photo:
      case _Kind.text:
        if (coll == 'rsvp') {
          final attending = e['attending'] == true;
          final comp = (e['companions'] as num?)?.toInt() ?? 0;
          return '$name — ${attending ? 'Będzie' : 'Nie będzie'}'
              '${attending && comp > 0 ? ' (+$comp)' : ''}';
        }
        if (coll == 'guestMap') {
          final city = (e['city'] as String?) ?? '';
          return city.isNotEmpty ? '$name • $city' : name;
        }
        return name;
    }
  }

  String _body(Map<String, dynamic> e) {
    switch (kind) {
      case _Kind.music:
        return 'Zaproponował(a): ${(e['name'] as String?) ?? 'Gość'}';
      case _Kind.photo:
        if (coll == 'photoChallenges') {
          final ch = (e['challengeId'] as num?)?.toInt();
          return ch == null ? '' : 'Wyzwanie #$ch';
        }
        return (e['caption'] as String?) ?? '';
      case _Kind.score:
      case _Kind.bingo:
        return '';
      case _Kind.text:
        if (coll == 'rsvp') {
          final diet = (e['diet'] as String?) ?? '';
          final note = (e['note'] as String?) ?? '';
          return [
            if (diet.isNotEmpty) 'Dieta: $diet',
            if (note.isNotEmpty) note,
          ].join('\n');
        }
        return (e['message'] as String?) ??
            (e['greeting'] as String?) ??
            '';
    }
  }
}
