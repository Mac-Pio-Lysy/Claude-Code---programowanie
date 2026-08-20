part of 'guest_web_app.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Sekcje gościa 5b-part-2: galeria, muzyka, gry.
//
// Wszystko działa BEZ LOGOWANIA, wyłącznie pod tokenem z linku:
//   • treść (pytania, wyzwania, pola bingo) czytana z mirrora guestSpaces/{token},
//   • odpowiedzi/zdjęcia zapisywane do podkolekcji guestSpaces/{token}/…,
//   • zdjęcia lądują w Cloudinary, w Firestore zostaje sam adres.
//
// Odczyt PUBLICZNY (goście widzą się nawzajem): galeria, foto-wyzwania.
// Odczyt TYLKO ORGANIZATOR: propozycje muzyki, wyniki quizu / prawda-fałsz /
// zgadnij zdjęcie / bingo — dlatego te sekcje nie pokazują cudzych wyników.
// ═══════════════════════════════════════════════════════════════════════════

/// Pole „Twoje imię" — wspólne dla wszystkich sekcji 5b-part-2.
Widget _nameField(TextEditingController c) => TextField(
      controller: c,
      maxLength: 80,
      textCapitalization: TextCapitalization.words,
      decoration: _guestDec(AppText.t.gw_yourName),
    );

/// Komunikat na środku (pusto / sekcja nieaktywna).
Widget _centerInfo(String text, {IconData icon = Icons.info_outline}) => Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 38, color: AppColors.textLight),
            const SizedBox(height: 12),
            Text(text,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 15, color: AppColors.textLight)),
          ],
        ),
      ),
    );

/// Lista map z mirrora (pytania, wyzwania, pola bingo).
List<Map<String, dynamic>> _mapsFrom(dynamic raw) => [
      for (final e in (raw is List ? raw : const []))
        if (e is Map) Map<String, dynamic>.from(e),
    ];

// ───────────────────────────────────────────────────────────────────────────
// GALERIA — zdjęcia gości, odczyt PUBLICZNY
// ───────────────────────────────────────────────────────────────────────────

class _GalleryPage extends StatefulWidget {
  const _GalleryPage({required this.service, required this.showAuthorNames});
  final GuestSpaceService service;

  /// Etap 8 — `false` pokazuje „gość" zamiast imienia autora zdjęcia.
  final bool showAuthorNames;

  @override
  State<_GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<_GalleryPage> {
  final _nameCtrl = TextEditingController(text: GuestSession.displayName);
  final _captionCtrl = TextEditingController();
  final _picker = ImagePicker();
  final _cloudinary = CloudinaryService();
  bool _busy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _captionCtrl.dispose();
    super.dispose();
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  Future<void> _addPhoto(ImageSource source) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _snack(AppText.t.gw_nameFirst);
      return;
    }
    try {
      final file = await _picker.pickImage(
          source: source, maxWidth: 1600, imageQuality: 85);
      if (file == null) return;
      setState(() => _busy = true);
      final bytes = await file.readAsBytes();
      final up = await _cloudinary.uploadImage(bytes, filename: file.name);
      await widget.service.addGalleryPhoto(
        name: name,
        photoUrl: up.url,
        photoPublicId: up.publicId,
        caption: _captionCtrl.text.trim(),
        authorUid: GuestIdentity.uid,
      );
      _captionCtrl.clear();
      if (mounted) _snack(AppText.t.gw_photoThanks);
    } catch (e) {
      if (mounted) _snack(AppText.t.gw_photoError('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _nameField(_nameCtrl),
              TextField(
                  controller: _captionCtrl,
                  maxLength: 200,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _guestDec(AppText.t.gw_photoCaption)),
              const SizedBox(height: 6),
              _PhotoButtons(busy: _busy, onPick: _addPhoto),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: widget.service.watchGallery(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _centerInfo(AppText.t.gw_galleryError,
                    icon: Icons.cloud_off);
              }
              final items = snapshot.data ?? const [];
              if (items.isEmpty) {
                return _centerInfo(AppText.t.gw_galleryEmpty,
                    icon: Icons.photo_camera_outlined);
              }
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                itemCount: items.length,
                itemBuilder: (context, i) => _photoTile(items[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _photoTile(Map<String, dynamic> item) {
    final url = (item['photoUrl'] as String?) ?? '';
    final name = widget.showAuthorNames
        ? (item['name'] as String?) ?? AppText.t.gw_guest
        : AppText.t.gw_guest;
    final caption = (item['caption'] as String?) ?? '';
    return GestureDetector(
      onTap: url.isEmpty ? null : () => _openFull(url, name, caption),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2EAF7)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: url.isEmpty
                  ? const ColoredBox(color: Color(0xFFF1F5FC))
                  : Image.network(url, fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const ColoredBox(
                            color: Color(0xFFF1F5FC),
                            child: Icon(Icons.broken_image_outlined,
                                color: AppColors.textLight),
                          )),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent)),
                  if (caption.isNotEmpty)
                    Text(caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textLight)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFull(String url, String name, String caption) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: InteractiveViewer(child: Image.network(url))),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                caption.isEmpty ? name : '$name — $caption',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Para przycisków „Aparat / Galeria" ze wskaźnikiem wysyłki.
class _PhotoButtons extends StatelessWidget {
  const _PhotoButtons({required this.busy, required this.onPick, this.label});
  final bool busy;
  final void Function(ImageSource) onPick;
  final String? label;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.accent)),
            SizedBox(width: 10),
            Text(AppText.t.gw_photoUploading),
          ],
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => onPick(ImageSource.camera),
            icon: const Icon(Icons.photo_camera_outlined, size: 18),
            label: Text(AppText.t.gw_camera),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => onPick(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined, size: 18),
            label: Text(label ?? AppText.t.gw_pickPhoto),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// MUZYKA — propozycje utworów, odczyt TYLKO ORGANIZATOR
// ───────────────────────────────────────────────────────────────────────────

class _MusicPage extends StatefulWidget {
  const _MusicPage({required this.service});
  final GuestSpaceService service;

  @override
  State<_MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<_MusicPage> {
  final _nameCtrl = TextEditingController(text: GuestSession.displayName);
  final _searchCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _artistCtrl = TextEditingController();
  final _deezer = DeezerService();

  List<DeezerTrack>? _results;
  bool _searching = false;
  bool _sending = false;

  /// Wyszukiwarka niedostępna (na Flutter Web Deezer blokuje CORS) — wtedy
  /// pokazujemy ręczne dodawanie tytułu i wykonawcy.
  bool _manualOnly = false;

  /// Co ten gość wysłał w tej sesji — odczyt kolekcji ma tylko organizator,
  /// więc bez tego gość nie miałby żadnego potwierdzenia.
  final List<String> _sent = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _searchCtrl.dispose();
    _titleCtrl.dispose();
    _artistCtrl.dispose();
    super.dispose();
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() => _searching = true);
    final res = await _deezer.search(q);
    if (!mounted) return;
    setState(() {
      _searching = false;
      _results = res;
      // null = błąd sieci/CORS → przechodzimy w tryb ręczny na stałe.
      if (res == null) _manualOnly = true;
    });
    if (res == null) {
      _snack(AppText.t.gw_searchUnavailable);
    }
  }

  Future<void> _send({
    required String title,
    String artist = '',
    String cover = '',
  }) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _snack(AppText.t.gw_nameFirst);
      return;
    }
    if (title.isEmpty) {
      _snack(AppText.t.gw_needSongTitle);
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.service.addMusicProposal(
          name: name, title: title, artist: artist, cover: cover);
      if (!mounted) return;
      setState(() {
        _sent.add(artist.isEmpty ? title : '$title — $artist');
        _titleCtrl.clear();
        _artistCtrl.clear();
      });
      _snack(AppText.t.gw_proposalSent);
    } catch (e) {
      if (mounted) _snack(AppText.t.gw_sendError('$e'));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _nameField(_nameCtrl),
        const SizedBox(height: 4),
        Text(
          AppText.t.gw_musicIntro,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
        ),
        const SizedBox(height: 12),
        if (!_manualOnly) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: _guestDec(AppText.t.gw_musicSearch),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _searching ? null : _search,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                  ),
                  child: _searching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.search),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final t in _results ?? const <DeezerTrack>[]) _trackTile(t),
          if (_results != null && _results!.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(AppText.t.gw_noResults,
                  style: GoogleFonts.inter(color: AppColors.textLight)),
            ),
          const SizedBox(height: 8),
          const Divider(),
        ],
        const SizedBox(height: 8),
        Text(AppText.t.gw_addManually,
            style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
        const SizedBox(height: 8),
        TextField(
            controller: _titleCtrl,
            maxLength: 200,
            decoration: _guestDec(AppText.t.gw_songTitle)),
        TextField(
            controller: _artistCtrl,
            maxLength: 200,
            decoration: _guestDec(AppText.t.gw_artistOptional)),
        const SizedBox(height: 6),
        _SubmitButton(
          label: AppText.t.gw_sendProposal,
          sending: _sending,
          onTap: () => _send(
              title: _titleCtrl.text.trim(), artist: _artistCtrl.text.trim()),
        ),
        if (_sent.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(AppText.t.gw_yourProposals,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text)),
          const SizedBox(height: 8),
          for (final s in _sent) ...[
            _entryCard(s, ''),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }

  Widget _trackTile(DeezerTrack t) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2EAF7)),
        ),
        child: ListTile(
          leading: t.cover.isEmpty
              ? const Icon(Icons.music_note, color: AppColors.accent)
              : ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(t.cover,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.music_note, color: AppColors.accent)),
                ),
          title: Text(t.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text(t.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 12)),
          trailing: IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.accent),
            onPressed: _sending
                ? null
                : () =>
                    _send(title: t.title, artist: t.artist, cover: t.cover),
          ),
        ),
      );
}

// ───────────────────────────────────────────────────────────────────────────
// QUIZ i ZGADNIJ ZDJĘCIE — pytania z odpowiedziami A/B/C/D
// ───────────────────────────────────────────────────────────────────────────

/// Gra wyboru: quiz o Parze Młodej i „zgadnij zdjęcie" (ta sama mechanika,
/// różni je tylko zdjęcie nad pytaniem). Wynik liczony na urządzeniu gościa,
/// wysyłany raz — cudzych wyników gość NIE widzi (odczyt ma organizator).
class _ChoiceGamePage extends StatefulWidget {
  const _ChoiceGamePage({
    required this.service,
    required this.questions,
    required this.collection,
    required this.active,
    this.withPhoto = false,
  });

  final GuestSpaceService service;
  final List<Map<String, dynamic>> questions;
  final String collection;
  final bool active;
  final bool withPhoto;

  @override
  State<_ChoiceGamePage> createState() => _ChoiceGamePageState();
}

class _ChoiceGamePageState extends State<_ChoiceGamePage> {
  final _nameCtrl = TextEditingController(text: GuestSession.displayName);
  final Map<String, int> _picked = {};
  bool _sending = false;
  bool _done = false;
  int _score = 0;

  /// Wynik pochodzi z wcześniejszego podejścia (wczytany, nie policzony teraz).
  bool _earlier = false;

  @override
  void initState() {
    super.initState();
    _loadOwn();
  }

  /// Wczytuje własny, wcześniejszy wynik — gość widzi, że już grał, i decyduje,
  /// czy podejść ponownie (powtórka nadpisze wpis).
  Future<void> _loadOwn() async {
    final uid = GuestIdentity.uid;
    if (uid == null) return;
    final data = await widget.service.readOwn(widget.collection, uid);
    if (!mounted || data == null) return;
    setState(() {
      _score = (data['score'] as num?)?.toInt() ?? 0;
      _nameCtrl.text = (data['name'] as String?) ?? '';
      _done = true;
      _earlier = true;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  List<String> _answersOf(Map<String, dynamic> q) => [
        for (final a in (q['answers'] is List ? q['answers'] as List : const []))
          a?.toString() ?? '',
      ];

  String _idOf(Map<String, dynamic> q, int index) =>
      '${(q['id'] as num?)?.toInt() ?? index}';

  Future<void> _finish() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _snack(AppText.t.gw_nameFirst);
      return;
    }
    if (_picked.length < widget.questions.length) {
      _snack(AppText.t.gw_answerAllQuestions);
      return;
    }
    final uid = GuestIdentity.uid;
    if (uid == null) {
      _snack(AppText.t.gw_sessionError);
      return;
    }
    var score = 0;
    for (var i = 0; i < widget.questions.length; i++) {
      final q = widget.questions[i];
      final correct = (q['correctIndex'] as num?)?.toInt() ?? 0;
      if (_picked[_idOf(q, i)] == correct) score++;
    }
    setState(() => _sending = true);
    try {
      await widget.service.saveGameResult(
        coll: widget.collection,
        uid: uid,
        name: name,
        score: score,
        total: widget.questions.length,
        answers: _picked,
      );
      if (!mounted) return;
      setState(() {
        _score = score;
        _done = true;
        _earlier = false;
      });
    } catch (e) {
      if (mounted) _snack(AppText.t.gw_scoreError('$e'));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return _centerInfo(AppText.t.gw_gameInactive,
          icon: Icons.pause_circle_outline);
    }
    if (widget.questions.isEmpty) {
      return _centerInfo(AppText.t.gw_questionsSoon,
          icon: Icons.hourglass_empty);
    }
    if (_done) {
      return _ResultSummary(
        score: _score,
        total: widget.questions.length,
        earlier: _earlier,
        onReplay: () => setState(() {
          _done = false;
          _earlier = false;
          _picked.clear();
        }),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _nameField(_nameCtrl),
        const SizedBox(height: 8),
        for (var i = 0; i < widget.questions.length; i++)
          _questionCard(widget.questions[i], i),
        const SizedBox(height: 8),
        _SubmitButton(
            label: AppText.t.gw_finishAndSend, sending: _sending, onTap: _finish),
        const SizedBox(height: 8),
        Text(
          AppText.t.gw_scorePrivate,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
        ),
      ],
    );
  }

  Widget _questionCard(Map<String, dynamic> q, int index) {
    final answers = _answersOf(q);
    final qid = _idOf(q, index);
    final photo = (q['photoUrl'] as String?) ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.withPhoto && photo.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(photo,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox(
                        height: 180,
                        child: ColoredBox(
                          color: Color(0xFFF1F5FC),
                          child: Icon(Icons.broken_image_outlined,
                              color: AppColors.textLight),
                        ),
                      )),
            ),
            const SizedBox(height: 10),
          ],
          Text('${index + 1}. ${(q['question'] as String?) ?? ''}',
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text)),
          const SizedBox(height: 8),
          for (var a = 0; a < answers.length; a++)
            _AnswerRow(
              text: answers[a],
              selected: _picked[qid] == a,
              onTap: () => setState(() => _picked[qid] = a),
            ),
        ],
      ),
    );
  }

}

/// Pojedyncza odpowiedź do wyboru (zamiast `RadioListTile`, którego API jest
/// wycofywane — zachowanie identyczne, bez przestarzałych wywołań).
class _AnswerRow extends StatelessWidget {
  const _AnswerRow(
      {required this.text, required this.selected, required this.onTap});
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 20,
                color: selected ? AppColors.accent : AppColors.textLight,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(text,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                        color: AppColors.text)),
              ),
            ],
          ),
        ),
      );
}

// ───────────────────────────────────────────────────────────────────────────
// PRAWDA / FAŁSZ
// ───────────────────────────────────────────────────────────────────────────

class _TrueFalseGamePage extends StatefulWidget {
  const _TrueFalseGamePage({
    required this.service,
    required this.statements,
    required this.active,
  });

  final GuestSpaceService service;
  final List<Map<String, dynamic>> statements;
  final bool active;

  @override
  State<_TrueFalseGamePage> createState() => _TrueFalseGamePageState();
}

class _TrueFalseGamePageState extends State<_TrueFalseGamePage> {
  final _nameCtrl = TextEditingController(text: GuestSession.displayName);
  final Map<String, bool> _picked = {};
  bool _sending = false;
  bool _done = false;
  bool _earlier = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _loadOwn();
  }

  /// Wczytuje własny, wcześniejszy wynik (powtórka go nadpisze).
  Future<void> _loadOwn() async {
    final uid = GuestIdentity.uid;
    if (uid == null) return;
    final data = await widget.service.readOwn('trueFalseResults', uid);
    if (!mounted || data == null) return;
    setState(() {
      _score = (data['score'] as num?)?.toInt() ?? 0;
      _nameCtrl.text = (data['name'] as String?) ?? '';
      _done = true;
      _earlier = true;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  String _idOf(Map<String, dynamic> s, int i) =>
      '${(s['id'] as num?)?.toInt() ?? i}';

  Future<void> _finish() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _snack(AppText.t.gw_nameFirst);
      return;
    }
    if (_picked.length < widget.statements.length) {
      _snack(AppText.t.gw_answerAllStatements);
      return;
    }
    final uid = GuestIdentity.uid;
    if (uid == null) {
      _snack(AppText.t.gw_sessionError);
      return;
    }
    var score = 0;
    for (var i = 0; i < widget.statements.length; i++) {
      final s = widget.statements[i];
      if (_picked[_idOf(s, i)] == (s['isTrue'] == true)) score++;
    }
    setState(() => _sending = true);
    try {
      await widget.service.saveGameResult(
        coll: 'trueFalseResults',
        uid: uid,
        name: name,
        score: score,
        total: widget.statements.length,
        answers: _picked,
      );
      if (!mounted) return;
      setState(() {
        _score = score;
        _done = true;
        _earlier = false;
      });
    } catch (e) {
      if (mounted) _snack(AppText.t.gw_scoreError('$e'));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return _centerInfo(AppText.t.gw_gameInactive,
          icon: Icons.pause_circle_outline);
    }
    if (widget.statements.isEmpty) {
      return _centerInfo(AppText.t.gw_statementsSoon,
          icon: Icons.hourglass_empty);
    }
    if (_done) {
      return _ResultSummary(
        score: _score,
        total: widget.statements.length,
        earlier: _earlier,
        onReplay: () => setState(() {
          _done = false;
          _earlier = false;
          _picked.clear();
        }),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _nameField(_nameCtrl),
        const SizedBox(height: 8),
        for (var i = 0; i < widget.statements.length; i++)
          _statementCard(widget.statements[i], i),
        const SizedBox(height: 8),
        _SubmitButton(
            label: AppText.t.gw_finishAndSend, sending: _sending, onTap: _finish),
        const SizedBox(height: 8),
        Text(
          AppText.t.gw_scorePrivate,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
        ),
      ],
    );
  }

  Widget _statementCard(Map<String, dynamic> s, int index) {
    final sid = _idOf(s, index);
    final chosen = _picked[sid];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${index + 1}. ${(s['text'] as String?) ?? ''}',
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _tfButton(AppText.t.gw_true, true, chosen == true,
                    () => setState(() => _picked[sid] = true)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _tfButton(AppText.t.gw_false, false, chosen == false,
                    () => setState(() => _picked[sid] = false)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tfButton(String label, bool value, bool selected, VoidCallback onTap) =>
      selected
          ? ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(label),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: Color(0xFFDCE4F2)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(label),
            );
}

/// Podsumowanie wyniku gry — wspólne dla wszystkich gier.
///
/// [onReplay] pokazuje przycisk powtórki. Ponowne podejście NADPISUJE wynik
/// (jeden wpis na gościa), więc gość może poprawić rezultat, a organizator ma
/// jedną pozycję na osobę zamiast listy prób.
class _ResultSummary extends StatelessWidget {
  const _ResultSummary({
    required this.score,
    required this.total,
    this.emoji,
    this.onReplay,
    this.earlier = false,
  });

  final int score;
  final int total;
  final String? emoji;
  final VoidCallback? onReplay;

  /// Czy to wynik wczytany z wcześniejszego podejścia (inny tekst).
  final bool earlier;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji ?? '🎉', style: const TextStyle(fontSize: 44)),
              const SizedBox(height: 12),
              Text(AppText.t.gw_yourScore(score, total),
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text)),
              const SizedBox(height: 10),
              Text(
                  earlier
                      ? AppText.t.gw_scoreEarlier
                      : AppText.t.gw_scoreThanks,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppColors.textLight)),
              if (onReplay != null) ...[
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: onReplay,
                  icon: const Icon(Icons.replay, size: 18),
                  label: Text(AppText.t.gw_playAgain),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}

// ───────────────────────────────────────────────────────────────────────────
// FOTO-WYZWANIA — lista zadań + wspólna ściana zdjęć (odczyt PUBLICZNY)
// ───────────────────────────────────────────────────────────────────────────

class _PhotoChallengePage extends StatefulWidget {
  const _PhotoChallengePage({
    required this.service,
    required this.tasks,
    required this.active,
    required this.showAuthorNames,
  });

  final GuestSpaceService service;
  final List<Map<String, dynamic>> tasks;
  final bool active;

  /// Etap 8 — `false` pokazuje „gość" zamiast imienia autora zgłoszenia.
  final bool showAuthorNames;

  @override
  State<_PhotoChallengePage> createState() => _PhotoChallengePageState();
}

class _PhotoChallengePageState extends State<_PhotoChallengePage> {
  final _nameCtrl = TextEditingController(text: GuestSession.displayName);
  final _picker = ImagePicker();
  final _cloudinary = CloudinaryService();
  int? _busyTask;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  Future<void> _send(int challengeId, ImageSource source) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _snack(AppText.t.gw_nameFirst);
      return;
    }
    final uid = GuestIdentity.uid;
    if (uid == null) {
      _snack(AppText.t.gw_sessionError);
      return;
    }
    try {
      final file = await _picker.pickImage(
          source: source, maxWidth: 1600, imageQuality: 85);
      if (file == null) return;
      setState(() => _busyTask = challengeId);
      final bytes = await file.readAsBytes();
      final up = await _cloudinary.uploadImage(bytes, filename: file.name);
      await widget.service.savePhotoChallenge(
        uid: uid,
        name: name,
        challengeId: challengeId,
        photoUrl: up.url,
        photoPublicId: up.publicId,
      );
      if (mounted) _snack(AppText.t.gw_photoSent);
    } catch (e) {
      if (mounted) _snack(AppText.t.gw_sendError('$e'));
    } finally {
      if (mounted) setState(() => _busyTask = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return _centerInfo(AppText.t.gw_challengesInactive,
          icon: Icons.pause_circle_outline);
    }
    if (widget.tasks.isEmpty) {
      return _centerInfo(AppText.t.gw_challengesSoon,
          icon: Icons.hourglass_empty);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _nameField(_nameCtrl),
        const SizedBox(height: 4),
        Text(
          AppText.t.gw_challengeHint,
          style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textLight),
        ),
        const SizedBox(height: 10),
        for (final t in widget.tasks) _taskCard(t),
        const SizedBox(height: 16),
        Text(AppText.t.gw_guestPhotos,
            style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text)),
        const SizedBox(height: 10),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: widget.service.watchPhotoChallenges(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(AppText.t.gw_photosError,
                  style: GoogleFonts.inter(color: AppColors.textLight));
            }
            final items = snapshot.data ?? const [];
            if (items.isEmpty) {
              return Text(AppText.t.gw_photosEmpty,
                  style: GoogleFonts.inter(color: AppColors.textLight));
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final url = (items[i]['photoUrl'] as String?) ?? '';
                final name = widget.showAuthorNames
                    ? (items[i]['name'] as String?) ?? AppText.t.gw_guest
                    : AppText.t.gw_guest;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      url.isEmpty
                          ? const ColoredBox(color: Color(0xFFF1F5FC))
                          : Image.network(url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const ColoredBox(
                                    color: Color(0xFFF1F5FC),
                                    child: Icon(Icons.broken_image_outlined,
                                        color: AppColors.textLight),
                                  )),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          color: const Color(0x99000000),
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _taskCard(Map<String, dynamic> t) {
    final id = (t['id'] as num?)?.toInt() ?? 0;
    final points = (t['points'] as num?)?.toInt() ?? 1;
    return Container(
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
              Expanded(
                child: Text((t['text'] as String?) ?? '',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(AppText.t.gw_points(points),
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _PhotoButtons(
            busy: _busyTask == id,
            onPick: (src) => _send(id, src),
            label: AppText.t.gw_sendPhoto,
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// KONKURSY FOTOGRAFICZNE — etap 2: zgłaszanie zdjęć (BEZ głosowania, etap 3)
// ───────────────────────────────────────────────────────────────────────────

/// Lista aktywnych konkursów — tap wchodzi w podkategorie jednego z nich.
class _PhotoContestPage extends StatelessWidget {
  const _PhotoContestPage({
    required this.service,
    required this.contests,
    required this.showAuthorNames,
  });

  final GuestSpaceService service;
  final Map<int, PhotoContest> contests;

  /// Etap 8 — `false` pokazuje „gość" zamiast imienia autora zgłoszenia.
  final bool showAuthorNames;

  @override
  Widget build(BuildContext context) {
    final active = contests.values.where((c) => c.active).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    if (active.isEmpty) {
      return _centerInfo(AppText.t.gw_contestsSoon, icon: Icons.emoji_events_outlined);
    }
    // Jeden aktywny konkurs — wchodzimy w niego od razu, bez zbędnego kliku.
    if (active.length == 1) {
      return _ContestDetailPage(
          service: service, contest: active.first, showAuthorNames: showAuthorNames);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final c in active) _contestCard(context, c),
      ],
    );
  }

  Widget _contestCard(BuildContext context, PhotoContest c) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2EAF7)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: const Icon(Icons.emoji_events_outlined, color: AppColors.accent),
          title: Text(c.name,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
          subtitle: Text(
            AppText.t.contest_subcategoriesCount(c.subcategories.length),
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => _GuestSectionScaffold(
              title: c.name,
              child: _ContestDetailPage(
                  service: service, contest: c, showAuthorNames: showAuthorNames),
            ),
          )),
        ),
      );
}

/// Jeden konkurs: wybór podkategorii (jeśli jest ich więcej niż jedna) +
/// formularz zgłoszenia + siatka już zgłoszonych zdjęć tej podkategorii.
///
/// Głosowanie (system 3-2-1) dochodzi w etapie 3 — tu zdjęcia są tylko do
/// obejrzenia, bez interakcji.
class _ContestDetailPage extends StatefulWidget {
  const _ContestDetailPage({
    required this.service,
    required this.contest,
    required this.showAuthorNames,
  });

  final GuestSpaceService service;
  final PhotoContest contest;
  final bool showAuthorNames;

  @override
  State<_ContestDetailPage> createState() => _ContestDetailPageState();
}

class _ContestDetailPageState extends State<_ContestDetailPage> {
  static const _gold = Color(0xFFD4AF37);
  static const _silver = Color(0xFFB0B0B8);
  static const _bronze = Color(0xFFCD7F32);

  final _nameCtrl = TextEditingController(text: GuestSession.displayName);
  final _picker = ImagePicker();
  final _cloudinary = CloudinaryService();
  bool _busy = false;
  late int? _subcategoryId =
      widget.contest.subcategories.isEmpty ? null : widget.contest.subcategories.first.id;

  /// Własny głos bieżącej podkategorii: miejsce (1/2/3) → ID zgłoszenia.
  /// Serwer dopuszcza WYŁĄCZNIE kompletny zestaw trzech różnych zdjęć —
  /// dopóki brakuje któregoś miejsca, zmiana istnieje TYLKO tutaj, lokalnie
  /// (patrz `_applyPick`), i nie jest jeszcze zapisana.
  Map<int, String?> _picks = {1: null, 2: null, 3: null};
  StreamSubscription<Map<String, dynamic>?>? _voteSub;

  @override
  void initState() {
    super.initState();
    _resubscribeVote();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _voteSub?.cancel();
    super.dispose();
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  /// Nasłuchuje własnego głosu bieżącej podkategorii i wypełnia [_picks]
  /// PRZY PIERWSZYM zdarzeniu ze strumienia — kolejne zdarzenia (np. zapis
  /// z innej karty przeglądarki) świadomie ignorujemy, żeby nie nadpisać
  /// wyboru, który gość akurat w tej chwili układa lokalnie.
  void _resubscribeVote() {
    _voteSub?.cancel();
    _voteSub = null;
    final uid = GuestIdentity.uid;
    final subId = _subcategoryId;
    if (uid == null || subId == null) return;
    var seeded = false;
    _voteSub = widget.service
        .watchOwnContestVote(uid, widget.contest.id, subId)
        .listen((vote) {
      if (!mounted || seeded || vote == null) return;
      seeded = true;
      setState(() {
        _picks = {
          1: vote['first'] as String?,
          2: vote['second'] as String?,
          3: vote['third'] as String?,
        };
      });
    });
  }

  void _selectSubcategory(int id) {
    setState(() {
      _subcategoryId = id;
      _picks = {1: null, 2: null, 3: null};
    });
    _resubscribeVote();
  }

  int? _placeOf(String submissionId) {
    for (final e in _picks.entries) {
      if (e.value == submissionId) return e.key;
    }
    return null;
  }

  Color? _placeColor(int? place) => switch (place) {
        1 => _gold,
        2 => _silver,
        3 => _bronze,
        _ => null,
      };

  Future<void> _openPicker(Map<String, dynamic> submission) async {
    final id = submission['id'] as String;
    final current = _placeOf(id);
    final choice = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(AppText.t.gw_contestPickPlace),
        children: [
          for (final p in [1, 2, 3])
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(p),
              child: Row(
                children: [
                  Icon(Icons.emoji_events, color: _placeColor(p)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(AppText.t.gw_contestPlaceN(p))),
                  if (current == p) const Icon(Icons.check, color: AppColors.accent, size: 18),
                ],
              ),
            ),
          if (current != null)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(0),
              child: Row(
                children: [
                  const Icon(Icons.close, color: AppColors.textLight),
                  const SizedBox(width: 10),
                  Text(AppText.t.gw_contestUndo),
                ],
              ),
            ),
        ],
      ),
    );
    if (choice == null) return;
    await _applyPick(id, choice == 0 ? null : choice);
  }

  /// Przypisuje/zwalnia miejsce lokalnie; zdjęcie może zajmować TYLKO jedno
  /// miejsce naraz, więc jeśli miało inne — najpierw je zwalniamy (przełóż,
  /// nie duplikuj). Wysyła na serwer WYŁĄCZNIE gdy komplet 3 różnych zdjęć —
  /// serwer i tak odrzuciłby częściowy zapis (reguła `vContestVote` wymaga
  /// wszystkich trzech pól).
  Future<void> _applyPick(String submissionId, int? place) async {
    final next = Map<int, String?>.from(_picks)
      ..updateAll((k, v) => v == submissionId ? null : v);
    if (place != null) next[place] = submissionId;
    setState(() => _picks = next);

    final missing = next.values.where((v) => v == null).length;
    if (missing > 0) {
      _snack(AppText.t.gw_contestVotePending(missing));
      return;
    }
    final uid = GuestIdentity.uid;
    final subId = _subcategoryId;
    if (uid == null || subId == null) return;
    try {
      await widget.service.saveContestVote(
        uid: uid,
        contestId: widget.contest.id,
        subcategoryId: subId,
        first: next[1]!,
        second: next[2]!,
        third: next[3]!,
      );
      if (mounted) _snack(AppText.t.gw_contestVoteSaved);
    } catch (e) {
      if (mounted) _snack(AppText.t.gw_sendError('$e'));
    }
  }

  Future<void> _submit(ImageSource source) async {
    final subId = _subcategoryId;
    if (subId == null) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _snack(AppText.t.gw_nameFirst);
      return;
    }
    final uid = GuestIdentity.uid;
    if (uid == null) {
      _snack(AppText.t.gw_sessionError);
      return;
    }
    try {
      final file = await _picker.pickImage(source: source, maxWidth: 1600, imageQuality: 85);
      if (file == null) return;
      setState(() => _busy = true);
      final bytes = await file.readAsBytes();
      final up = await _cloudinary.uploadImage(bytes, filename: file.name);
      await widget.service.submitContestPhoto(
        contestId: widget.contest.id,
        subcategoryId: subId,
        name: name,
        photoUrl: up.url,
        photoPublicId: up.publicId,
        authorUid: uid,
      );
      if (mounted) _snack(AppText.t.gw_contestSubmitted);
    } catch (e) {
      if (mounted) _snack(AppText.t.gw_sendError('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subs = widget.contest.subcategories;
    if (subs.isEmpty) {
      return _centerInfo(AppText.t.gw_contestsSoon, icon: Icons.emoji_events_outlined);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (subs.length > 1) ...[
          Text(AppText.t.gw_contestPickCategory,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in subs)
                ChoiceChip(
                  label: Text(s.label),
                  selected: _subcategoryId == s.id,
                  onSelected: (_) => _selectSubcategory(s.id),
                  selectedColor: AppColors.accent.withValues(alpha: 0.15),
                  labelStyle: GoogleFonts.inter(
                      fontSize: 12,
                      color: _subcategoryId == s.id ? AppColors.accent : AppColors.text),
                ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        _nameField(_nameCtrl),
        const SizedBox(height: 4),
        Text(AppText.t.gw_contestSubmitHint,
            style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textLight)),
        const SizedBox(height: 8),
        _PhotoButtons(busy: _busy, onPick: _submit, label: AppText.t.gw_sendPhoto),
        const SizedBox(height: 18),
        Text(AppText.t.gw_contestSubmissions,
            style: GoogleFonts.playfairDisplay(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
        const SizedBox(height: 4),
        Text(AppText.t.gw_contestVoteHint,
            style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textLight)),
        const SizedBox(height: 10),
        if (_subcategoryId != null) _submissionsGrid(_subcategoryId!),
      ],
    );
  }

  Widget _submissionsGrid(int subId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.service.watchContestSubmissions(widget.contest.id, subId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(AppText.t.gw_photosError,
              style: GoogleFonts.inter(color: AppColors.textLight));
        }
        final items = snapshot.data ?? const [];
        if (items.isEmpty) {
          return Text(AppText.t.gw_photosEmpty,
              style: GoogleFonts.inter(color: AppColors.textLight));
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            final id = item['id'] as String;
            final url = (item['photoUrl'] as String?) ?? '';
            final isOwn = item['authorUid'] != null &&
                item['authorUid'] == GuestIdentity.uid;
            final name = widget.showAuthorNames
                ? (item['name'] as String?) ?? AppText.t.gw_guest
                : AppText.t.gw_guest;
            final place = _placeOf(id);
            final placeColor = _placeColor(place);
            return Opacity(
              opacity: isOwn ? 0.55 : 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: placeColor != null
                      ? Border.all(color: placeColor, width: 3)
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: GestureDetector(
                    onTap: isOwn || url.isEmpty ? null : () => _openPicker(item),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        url.isEmpty
                            ? const ColoredBox(color: Color(0xFFF1F5FC))
                            : Image.network(url,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const ColoredBox(
                                      color: Color(0xFFF1F5FC),
                                      child: Icon(Icons.broken_image_outlined,
                                          color: AppColors.textLight),
                                    )),
                        if (place != null)
                          Positioned(
                            top: 4,
                            left: 4,
                            child: Container(
                              width: 22,
                              height: 22,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: placeColor,
                                boxShadow: const [
                                  BoxShadow(color: Color(0x55000000), blurRadius: 3),
                                ],
                              ),
                              child: Text('$place',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                            ),
                          ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            color: const Color(0x99000000),
                            child: Text(
                              isOwn ? AppText.t.gw_contestOwnPhoto : name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// ŚLUBNE BINGO — plansza z pól organizatora, skreślanie lokalne
// ───────────────────────────────────────────────────────────────────────────

/// Plansza bingo generowana na urządzeniu gościa z pól `bingoFields`.
///
/// Skreślenia są WYŁĄCZNIE lokalne (nic nie leci do bazy przy każdym dotknięciu
/// — inaczej jeden gość generowałby setki zapisów). Do Firestore idzie jeden
/// wpis dopiero po kliknięciu „Mam bingo!".
class _BingoPage extends StatefulWidget {
  const _BingoPage({
    required this.service,
    required this.fields,
    required this.centerLabel,
  });

  final GuestSpaceService service;
  final List<Map<String, dynamic>> fields;
  final String centerLabel;

  @override
  State<_BingoPage> createState() => _BingoPageState();
}

class _BingoPageState extends State<_BingoPage> {
  final _nameCtrl = TextEditingController(text: GuestSession.displayName);
  final Set<int> _marked = {};
  late final List<String> _board;
  late final int _cols;
  late final int _freeIndex;
  bool _sending = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    final texts = [
      for (final f in widget.fields)
        if (f['enabled'] != false)
          ((f['text'] as String?) ?? '').trim(),
    ].where((t) => t.isNotEmpty).toList();
    texts.shuffle(Random());

    if (texts.length >= 24) {
      _cols = 5;
      _board = texts.take(24).toList();
    } else if (texts.length >= 8) {
      _cols = 3;
      _board = texts.take(8).toList();
    } else {
      _cols = texts.isEmpty ? 0 : 2;
      _board = texts;
    }
    // Darmowe pole na środku tylko dla pełnych plansz 5x5 i 3x3.
    _freeIndex = (_cols == 5) ? 12 : (_cols == 3 ? 4 : -1);
    if (_freeIndex >= 0) {
      _board.insert(_freeIndex, widget.centerLabel);
      _marked.add(_freeIndex);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  Future<void> _send() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _snack(AppText.t.gw_nameFirst);
      return;
    }
    final uid = GuestIdentity.uid;
    if (uid == null) {
      _snack(AppText.t.gw_sessionError);
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.service.saveBingoResult(
        uid: uid,
        name: name,
        marked: _marked.length,
        total: _board.length,
      );
      if (!mounted) return;
      setState(() => _done = true);
    } catch (e) {
      if (mounted) _snack(AppText.t.gw_sendError('$e'));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_board.isEmpty) {
      return _centerInfo(AppText.t.gw_bingoSoon,
          icon: Icons.hourglass_empty);
    }
    if (_done) {
      return _ResultSummary(
          score: _marked.length, total: _board.length, emoji: '🎯');
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _nameField(_nameCtrl),
        const SizedBox(height: 4),
        Text(
          AppText.t.gw_bingoIntro,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _cols,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemCount: _board.length,
          itemBuilder: (context, i) => _cell(i),
        ),
        const SizedBox(height: 12),
        Text(AppText.t.gw_bingoMarked(_marked.length, _board.length),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.text)),
        const SizedBox(height: 8),
        _SubmitButton(
            label: AppText.t.gw_bingoDone, sending: _sending, onTap: _send),
      ],
    );
  }

  Widget _cell(int i) {
    final marked = _marked.contains(i);
    final isFree = i == _freeIndex;
    return GestureDetector(
      onTap: isFree
          ? null
          : () => setState(() {
                if (!_marked.remove(i)) _marked.add(i);
              }),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: marked ? AppColors.accent : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: marked ? AppColors.accent : const Color(0xFFDCE4F2)),
        ),
        child: Center(
          child: Text(
            _board[i],
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: _cols >= 5 ? 9 : 11,
              fontWeight: isFree ? FontWeight.w800 : FontWeight.w600,
              color: marked ? Colors.white : AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}
