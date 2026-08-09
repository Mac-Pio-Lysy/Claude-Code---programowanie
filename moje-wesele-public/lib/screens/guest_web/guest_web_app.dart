import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../app_colors.dart';
import '../../models/wedding_countdown.dart';
import '../../widgets/wedding_countdown_card.dart';
import '../../help/help_screen.dart';
import '../../models/guest_visibility.dart';
import '../../onboarding/onboarding_steps.dart' show OnbVariant;
import '../../services/cloudinary_service.dart';
import '../../services/deezer_service.dart';
import '../../services/guest_identity.dart';
import '../../services/guest_space_service.dart';
import '../../utils/warsaw_time.dart';

part 'guest_web_sections.dart';

/// Aplikacja w TRYBIE GOŚCIA WEB — uruchamiana, gdy w URL jest token (`?t=...`).
/// Bez logowania: czyta publiczny mirror `guestSpaces/{token}` i pokazuje
/// wyłącznie sekcje dla gości, respektując ustawienia widoczności (daty od/do,
/// przełączniki). Nie ma dostępu do budżetu, planu sali, dostawców, zadań itd.
class GuestWebApp extends StatelessWidget {
  const GuestWebApp({super.key, required this.token});

  final String token;

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        primary: AppColors.accent,
      ),
      useMaterial3: true,
    );
    return MaterialApp(
      title: 'Wesele — strefa gości',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(textTheme: GoogleFonts.interTextTheme(base.textTheme)),
      home: GuestWebHome(token: token, showHelp: true),
    );
  }
}

class GuestWebHome extends StatefulWidget {
  const GuestWebHome({super.key, required this.token, this.showHelp = false});

  final String token;

  /// Czy pokazać własny przycisk „Pomoc".
  ///
  /// `true` dla gościa wchodzącego z linku/QR (nie ma wtedy paska aplikacji),
  /// `false` gdy stronę osadza [GuestHomeScreen] — tam pomoc jest już w pasku
  /// i drugi przycisk byłby zbędny.
  final bool showHelp;

  @override
  State<GuestWebHome> createState() => _GuestWebHomeState();
}

class _GuestWebHomeState extends State<GuestWebHome> {
  late final GuestSpaceService _service =
      GuestSpaceService(token: widget.token);

  /// Komunikat, gdy nie udało się ustalić tożsamości gościa (null = w porządku).
  /// Nie blokuje strony — treść jest publiczna i czyta się bez logowania.
  /// Ostrzega tylko, że wysyłanie wpisów może nie zadziałać.
  String? _identityError;

  /// Trwa ustalanie tożsamości (blokuje przycisk „Spróbuj ponownie").
  bool _identityBusy = false;

  @override
  void initState() {
    super.initState();
    _ensureIdentity();
  }

  /// Zakłada w tle anonimowe konto gościa (albo używa istniejącej sesji).
  /// Świadomie NIE blokuje interfejsu: strona gościa ma się pokazać od razu,
  /// bo jej treść nie wymaga logowania.
  Future<void> _ensureIdentity() async {
    setState(() => _identityBusy = true);
    try {
      await GuestIdentity.ensure();
      if (mounted) setState(() => _identityError = null);
    } catch (e) {
      if (mounted) setState(() => _identityError = GuestIdentity.messageFor(e));
    } finally {
      if (mounted) setState(() => _identityBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGradient.last,
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
          child: Column(
            children: [
              if (_identityError != null) _identityBanner(_identityError!),
              Expanded(
                child: StreamBuilder<Map<String, dynamic>?>(
                  stream: _service.watchSpace(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.accent),
                      );
                    }
                    final space = snapshot.data;
                    if (space == null) return _invalid();
                    return _content(space);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Pasek ostrzegawczy, gdy nie udało się ustalić tożsamości gościa.
  ///
  /// Świadomie WIDOCZNY, a nie cichy: jeśli w dniu wesela wysyłanie wpisów
  /// przestanie działać, gość ma od razu wiedzieć, co się dzieje i móc spróbować
  /// ponownie, zamiast klikać „Wyślij" w pustkę.
  Widget _identityBanner(String message) => Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4E5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF0C48A)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 20, color: Color(0xFF9A6200)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                    fontSize: 12.5, height: 1.4, color: const Color(0xFF7A4E00)),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _identityBusy ? null : _ensureIdentity,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF9A6200),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 32),
              ),
              child: Text(_identityBusy ? 'Łączę…' : 'Spróbuj ponownie',
                  style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

  Widget _invalid() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link_off, size: 48, color: AppColors.textLight),
              const SizedBox(height: 16),
              Text(
                'Nieprawidłowy lub nieaktywny link',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text),
              ),
              const SizedBox(height: 8),
              Text(
                'Poproś Parę Młodą o aktualny link lub kod QR do strony gości.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textLight),
              ),
            ],
          ),
        ),
      );

  Widget _content(Map<String, dynamic> space) {
    final visibility = GuestVisibility.fromRaw(space);
    final today = warsawToday();
    final eventName = (space['eventName'] as String?)?.trim();
    final persons = (space['displayNames'] as String?)?.trim() ?? '';

    if (!visibility.masterEnabled) {
      return _masterOff(eventName, persons);
    }

    // Sekcje: widoczne + te „poza zakresem" z trybem „komunikat" (hide → pomiń).
    final cards = <Widget>[];
    for (final s in kGuestSections) {
      final state = visibility.stateOf(s.key, today);
      final sec = visibility.sectionFor(s.key);
      if (state != VisibilityState.visible &&
          sec.outOfRange == OutOfRangeMode.hide) {
        continue; // całkowicie ukryta
      }
      cards.add(_sectionCard(s, state, sec, space));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        if (widget.showHelp)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => HelpScreen.open(context, OnbVariant.guest),
              icon: const Icon(Icons.help_outline, size: 18),
              label: const Text('Pomoc'),
              style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            ),
          ),
        _header(eventName, persons, space),
        const SizedBox(height: 14),
        // Licznik do wesela (#24) — data i godzina z konfiguracji wesela,
        // przeniesione do mirrora gości.
        WeddingCountdownCard(
          weddingDate: space['weddingDate'] as String?,
          weddingTime: space['weddingTime'] as String?,
        ),
        const SizedBox(height: 18),
        if (cards.isEmpty)
          _emptyInfo()
        else
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.0,
            children: cards,
          ),
      ],
    );
  }

  Widget _masterOff(String? eventName, String persons) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('💍', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text(
                eventName?.isNotEmpty == true ? eventName! : 'Strefa gości',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text),
              ),
              const SizedBox(height: 10),
              Text(
                'Strona gości jest chwilowo niedostępna. Zajrzyj później.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textLight),
              ),
            ],
          ),
        ),
      );

  Widget _header(String? eventName, String persons, Map<String, dynamic> space) {
    final date = _dateLabel(space['weddingDate'] as String?);
    final reception = (space['receptionPlace'] as String?)?.trim() ?? '';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.12),
            AppColors.accent2.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD6E4FB)),
      ),
      child: Column(
        children: [
          const Text('💍', style: TextStyle(fontSize: 30)),
          const SizedBox(height: 8),
          Text(
            eventName?.isNotEmpty == true ? eventName! : 'Nasze Wesele',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
                fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.text),
          ),
          if (persons.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(persons,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: AppColors.accent)),
          ],
          if (date != null || reception.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              [?date, if (reception.isNotEmpty) reception].join(' • '),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyInfo() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2EAF7)),
        ),
        child: Text(
          'Sekcje dla gości pojawią się tutaj, gdy Para Młoda je udostępni.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textLight),
        ),
      );

  Widget _sectionCard(GuestSectionDef s, VisibilityState state,
      SectionVisibility sec, Map<String, dynamic> space) {
    final visible = state == VisibilityState.visible;
    final subtitle = switch (state) {
      VisibilityState.beforeStart => 'Dostępne od ${_dateLabel(sec.from) ?? '—'}',
      VisibilityState.afterEnd => 'Już niedostępne',
      VisibilityState.disabled => 'Niedostępne',
      VisibilityState.masterOff => 'Niedostępne',
      VisibilityState.visible => null,
    };
    return Opacity(
      opacity: visible ? 1 : 0.55,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: visible ? () => _openSection(s, space) : null,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE3EAF6)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(alpha: 0.10),
                  ),
                  child: Icon(s.icon, size: 24, color: AppColors.accent),
                ),
                const SizedBox(height: 10),
                Text(
                  s.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 10.5, color: AppColors.textLight),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openSection(GuestSectionDef s, Map<String, dynamic> space) {
    Widget page;
    switch (s.key) {
      case 'guestbook':
        page = _MessageWallPage(
          hint: 'Twój wpis dla Pary Młodej…',
          cta: 'Dodaj wpis',
          emptyText: 'Bądź pierwszy — zostaw wpis!',
          onSubmit: (name, msg) =>
              _service.addGuestbookEntry(name: name, message: msg),
          stream: _service.watchGuestbook(),
        );
      case 'advice':
        page = _MessageWallPage(
          hint: 'Twoja rada dla Pary Młodej…',
          cta: 'Dodaj radę',
          emptyText: 'Podziel się pierwszą radą!',
          onSubmit: (name, msg) => _service.addAdvice(name: name, message: msg),
          stream: _service.watchAdvice(),
        );
      case 'guestMap':
        page = _GuestMapPage(service: _service);
      case 'timeCapsule':
        page = _TimeCapsulePage(service: _service);
      case 'rsvp':
        page = _RsvpPage(service: _service);
      case 'schedule':
        page = _ScheduleView(
          events: space['scheduleEvents'],
          weddingDate: space['weddingDate'] as String?,
          weddingTime: space['weddingTime'] as String?,
        );
      // ── 5b-part-2 ──
      case 'gallery':
        page = _GalleryPage(service: _service);
      case 'music':
        page = _MusicPage(service: _service);
      case 'quiz':
        page = _ChoiceGamePage(
          service: _service,
          questions: _mapsFrom(space['quizQuestions']),
          collection: 'quizResults',
          active: space['quizActive'] == true,
        );
      case 'trueFalse':
        page = _TrueFalseGamePage(
          service: _service,
          statements: _mapsFrom(space['tfStatements']),
          active: space['tfActive'] == true,
        );
      case 'photoGuess':
        page = _ChoiceGamePage(
          service: _service,
          questions: _mapsFrom(space['photoQuestions']),
          collection: 'photoGuessResults',
          active: space['photoGuessActive'] == true,
          withPhoto: true,
        );
      case 'photoChallenge':
        page = _PhotoChallengePage(
          service: _service,
          tasks: _mapsFrom(space['photoChallengeTasks']),
          active: space['photoChallengesActive'] == true,
        );
      case 'bingo':
        page = _BingoPage(
          service: _service,
          fields: _mapsFrom(space['bingoFields']),
          centerLabel: space['bingoCenterMode'] == 'names'
              ? (((space['displayNames'] as String?)?.trim().isNotEmpty ?? false)
                  ? (space['displayNames'] as String).trim()
                  : 'GRATIS')
              : 'GRATIS',
        );
      default:
        page = const _ComingSoon();
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _GuestSectionScaffold(title: s.label, child: page),
    ));
  }

  static String? _dateLabel(String? date) {
    if (date == null || date.isEmpty) return null;
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(date);
    if (m == null) return date;
    const months = [
      'stycznia', 'lutego', 'marca', 'kwietnia', 'maja', 'czerwca',
      'lipca', 'sierpnia', 'września', 'października', 'listopada', 'grudnia'
    ];
    return '${int.parse(m.group(3)!)} ${months[int.parse(m.group(2)!) - 1]} ${m.group(1)}';
  }
}

/// Ramka sekcji gościa (pasek + powrót).
class _GuestSectionScaffold extends StatelessWidget {
  const _GuestSectionScaffold({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGradient.last,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        title: Text(title,
            style: GoogleFonts.playfairDisplay(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.text)),
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
        child: SafeArea(top: false, child: child),
      ),
    );
  }
}

/// Placeholder sekcji jeszcze niepodłączonej w trybie web (kolejny etap).
class _ComingSoon extends StatelessWidget {
  const _ComingSoon();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hourglass_empty,
                  size: 40, color: AppColors.textLight),
              const SizedBox(height: 12),
              Text('Ta sekcja będzie dostępna wkrótce',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text)),
            ],
          ),
        ),
      );
}

/// Harmonogram (tylko odczyt) — z mirrora, bez danych organizacyjnych.
class _ScheduleView extends StatelessWidget {
  const _ScheduleView(
      {required this.events, this.weddingDate, this.weddingTime});
  final dynamic events;
  final String? weddingDate;
  final String? weddingTime;

  @override
  Widget build(BuildContext context) {
    final list = events is List ? events as List : const [];
    // Ten sam licznik co na stronie głównej strefy gości (#24).
    final countdown = WeddingCountdown.from(weddingDate, time: weddingTime);
    final banner = countdown == null || countdown.isPast
        ? null
        : WeddingCountdownCard(
            weddingDate: weddingDate,
            weddingTime: weddingTime,
            compact: true,
          );
    if (list.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ?banner,
          const SizedBox(height: 16),
          Center(
            child: Text('Harmonogram pojawi się wkrótce.',
                style: GoogleFonts.inter(color: AppColors.textLight)),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length + (banner != null ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (banner != null && i == 0) return banner;
        final idx = banner != null ? i - 1 : i;
        final e = list[idx] is Map ? Map<String, dynamic>.from(list[idx]) : {};
        final time = _first(e, ['time', 'startTime', 'hour', 'start']);
        final title = _first(e, ['title', 'name', 'label', 'text']);
        final desc = _first(e, ['description', 'note', 'desc', 'details']);
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2EAF7)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (time.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(time,
                      style: GoogleFonts.robotoMono(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent)),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title.isEmpty ? 'Punkt programu' : title,
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(desc,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.textLight)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _first(Map e, List<String> keys) {
    for (final k in keys) {
      final v = e[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

}

/// Wspólna dekoracja pól tekstowych w trybie gościa.
InputDecoration _guestDec(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: AppColors.textLight, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDCE4F2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );

/// „Mur wiadomości": imię + treść + PUBLICZNA lista (księga gości, rady).
class _MessageWallPage extends StatefulWidget {
  const _MessageWallPage({
    required this.hint,
    required this.cta,
    required this.emptyText,
    required this.onSubmit,
    required this.stream,
  });

  final String hint;
  final String cta;
  final String emptyText;
  final Future<void> Function(String name, String message) onSubmit;
  final Stream<List<Map<String, dynamic>>> stream;

  @override
  State<_MessageWallPage> createState() => _MessageWallPageState();
}

class _MessageWallPageState extends State<_MessageWallPage> {
  final _nameCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final name = _nameCtrl.text.trim();
    final msg = _msgCtrl.text.trim();
    if (name.isEmpty || msg.isEmpty) {
      _snack('Podaj imię i treść.');
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.onSubmit(name, msg);
      _msgCtrl.clear();
      if (mounted) _snack('Dziękujemy ✓');
    } catch (e) {
      if (mounted) _snack('Nie udało się wysłać: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                maxLength: 80,
                decoration: _guestDec('Twoje imię'),
              ),
              TextField(
                controller: _msgCtrl,
                maxLines: 3,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                decoration: _guestDec(widget.hint),
              ),
              const SizedBox(height: 6),
              _SubmitButton(
                  label: widget.cta, sending: _sending, onTap: _send),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: widget.stream,
            builder: (context, snapshot) {
              final entries = snapshot.data ?? const [];
              if (entries.isEmpty) {
                return Center(
                  child: Text(widget.emptyText,
                      style: GoogleFonts.inter(color: AppColors.textLight)),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: entries.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _entryCard(
                  (entries[i]['name'] as String?) ?? 'Gość',
                  (entries[i]['message'] as String?) ?? '',
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

Widget _entryCard(String name, String body) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent)),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(body,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.text)),
          ],
        ],
      ),
    );

class _SubmitButton extends StatelessWidget {
  const _SubmitButton(
      {required this.label, required this.sending, required this.onTap});
  final String label;
  final bool sending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: sending ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: sending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.send),
          label: Text(sending ? 'Wysyłanie…' : label,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        ),
      );
}

/// Mapa gości — imię + miasto + pozdrowienie, PUBLICZNA lista.
class _GuestMapPage extends StatefulWidget {
  const _GuestMapPage({required this.service});
  final GuestSpaceService service;

  @override
  State<_GuestMapPage> createState() => _GuestMapPageState();
}

class _GuestMapPageState extends State<_GuestMapPage> {
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _greetCtrl = TextEditingController();
  bool _sending = false;

  /// Czy gość ma już swój wpis na mapie (zmienia teksty na „popraw").
  bool _existing = false;

  @override
  void initState() {
    super.initState();
    _loadOwn();
  }

  /// Wczytuje własny wpis, żeby gość poprawiał go zamiast dodawać kolejny.
  /// Mapa ma odczyt publiczny, więc to działa już przed etapem C reguł.
  Future<void> _loadOwn() async {
    final uid = GuestIdentity.uid;
    if (uid == null) return;
    final data = await widget.service.readOwn('guestMap', uid);
    if (!mounted || data == null) return;
    setState(() {
      _nameCtrl.text = (data['name'] as String?) ?? '';
      _cityCtrl.text = (data['city'] as String?) ?? '';
      _greetCtrl.text = (data['greeting'] as String?) ?? '';
      _existing = true;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _greetCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final name = _nameCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    if (name.isEmpty || city.isEmpty) {
      _snack('Podaj imię i miasto.');
      return;
    }
    final uid = GuestIdentity.uid;
    if (uid == null) {
      _snack('Nie udało się przygotować sesji gościa. '
          'Odśwież stronę i spróbuj ponownie.');
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.service.saveGuestMapEntry(
          uid: uid,
          name: name,
          city: city,
          greeting: _greetCtrl.text.trim());
      final wasExisting = _existing;
      if (mounted) {
        setState(() => _existing = true);
        _snack(wasExisting ? 'Zaktualizowano ✓' : 'Dziękujemy ✓');
      }
    } catch (e) {
      if (mounted) _snack('Nie udało się wysłać: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                  controller: _nameCtrl,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.words,
                  decoration: _guestDec('Twoje imię')),
              TextField(
                  controller: _cityCtrl,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.words,
                  decoration: _guestDec('Skąd przyjeżdżasz (miasto)')),
              TextField(
                  controller: _greetCtrl,
                  maxLength: 300,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _guestDec('Pozdrowienie (opcjonalnie)')),
              const SizedBox(height: 6),
              _SubmitButton(
                  label: _existing ? 'Zapisz zmiany' : 'Dodaj na mapę',
                  sending: _sending,
                  onTap: _send),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: widget.service.watchGuestMap(),
            builder: (context, snapshot) {
              final entries = snapshot.data ?? const [];
              if (entries.isEmpty) {
                return Center(
                  child: Text('Bądź pierwszy na mapie gości!',
                      style: GoogleFonts.inter(color: AppColors.textLight)),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: entries.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final e = entries[i];
                  final name = (e['name'] as String?) ?? 'Gość';
                  final city = (e['city'] as String?) ?? '';
                  final greet = (e['greeting'] as String?) ?? '';
                  return _entryCard(
                    '$name${city.isNotEmpty ? ' • $city' : ''}',
                    greet,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Kapsuła czasu — wiadomość dla Pary Młodej (bez listy; odczyt tylko organizator).
class _TimeCapsulePage extends StatefulWidget {
  const _TimeCapsulePage({required this.service});
  final GuestSpaceService service;

  @override
  State<_TimeCapsulePage> createState() => _TimeCapsulePageState();
}

class _TimeCapsulePageState extends State<_TimeCapsulePage> {
  final _nameCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final name = _nameCtrl.text.trim();
    final msg = _msgCtrl.text.trim();
    if (name.isEmpty || msg.isEmpty) {
      _snack('Podaj imię i wiadomość.');
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.service.addTimeCapsule(name: name, message: msg);
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) _snack('Nie udało się wysłać: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    if (_sent) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mark_email_read_outlined,
                  size: 48, color: AppColors.accent),
              const SizedBox(height: 12),
              Text('Wiadomość zapieczętowana!',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text)),
              const SizedBox(height: 8),
              Text(
                'Para Młoda otworzy Twoją wiadomość w wybranym czasie. Dziękujemy!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textLight),
              ),
            ],
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Zostaw wiadomość, którą Para Młoda otworzy w przyszłości. '
            'Inni goście jej nie zobaczą.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
          ),
          const SizedBox(height: 12),
          TextField(
              controller: _nameCtrl,
              maxLength: 80,
              textCapitalization: TextCapitalization.words,
              decoration: _guestDec('Twoje imię')),
          TextField(
              controller: _msgCtrl,
              maxLength: 2000,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: _guestDec('Twoja wiadomość do kapsuły czasu…')),
          const SizedBox(height: 6),
          _SubmitButton(
              label: 'Zapieczętuj wiadomość', sending: _sending, onTap: _send),
        ],
      ),
    );
  }
}

/// RSVP — potwierdzenie obecności (bez listy; odczyt tylko organizator).
class _RsvpPage extends StatefulWidget {
  const _RsvpPage({required this.service});
  final GuestSpaceService service;

  @override
  State<_RsvpPage> createState() => _RsvpPageState();
}

class _RsvpPageState extends State<_RsvpPage> {
  final _nameCtrl = TextEditingController();
  final _dietCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _attending = true;
  int _companions = 0;
  bool _sending = false;
  bool _sent = false;

  /// Trwa wczytywanie własnego, wcześniejszego potwierdzenia.
  bool _loading = true;

  /// Czy gość ma już zapisane potwierdzenie (zmienia teksty na „popraw").
  bool _existing = false;

  @override
  void initState() {
    super.initState();
    _loadOwn();
  }

  /// Wczytuje WŁASNE potwierdzenie i wypełnia nim formularz.
  ///
  /// Do etapu C reguł gość nie ma prawa odczytu `rsvp`, więc tu zwykle wyjdzie
  /// `null` i formularz wystartuje pusty. To nie jest błąd — zapis i tak działa.
  Future<void> _loadOwn() async {
    final uid = GuestIdentity.uid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final data = await widget.service.readOwn('rsvp', uid);
    if (!mounted) return;
    if (data != null) {
      _nameCtrl.text = (data['name'] as String?) ?? '';
      _dietCtrl.text = (data['diet'] as String?) ?? '';
      _noteCtrl.text = (data['note'] as String?) ?? '';
      _attending = data['attending'] == true;
      _companions = (data['companions'] as num?)?.toInt() ?? 0;
      _existing = true;
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dietCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _snack('Podaj imię i nazwisko.');
      return;
    }
    final uid = GuestIdentity.uid;
    if (uid == null) {
      _snack('Nie udało się przygotować sesji gościa. '
          'Odśwież stronę i spróbuj ponownie.');
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.service.saveRsvp(
        uid: uid,
        name: name,
        attending: _attending,
        companions: _attending ? _companions : 0,
        diet: _attending ? _dietCtrl.text.trim() : '',
        note: _noteCtrl.text.trim(),
      );
      if (mounted) {
        setState(() {
          _sent = true;
          _existing = true;
        });
      }
    } catch (e) {
      if (mounted) _snack('Nie udało się wysłać: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    if (_sent) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_attending ? Icons.celebration : Icons.favorite,
                  size: 48, color: AppColors.accent),
              const SizedBox(height: 12),
              Text(
                  _attending
                      ? 'Do zobaczenia na weselu! 🎉'
                      : 'Dziękujemy za odpowiedź',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text)),
              const SizedBox(height: 8),
              Text('Twoje potwierdzenie trafiło do Pary Młodej.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppColors.textLight)),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => setState(() => _sent = false),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Popraw odpowiedź'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.accent));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _existing
                  ? 'To Twoje wcześniejsze potwierdzenie. Możesz je poprawić — '
                      'zapiszemy nową wersję zamiast dodawać kolejną.'
                  : 'Wystarczy jedno potwierdzenie. Jeśli plany się zmienią, '
                      'wróć tutaj i popraw odpowiedź.',
              style: GoogleFonts.inter(
                  fontSize: 12.5, height: 1.4, color: AppColors.textLight),
            ),
          ),
          TextField(
              controller: _nameCtrl,
              maxLength: 80,
              textCapitalization: TextCapitalization.words,
              decoration: _guestDec('Imię i nazwisko')),
          const SizedBox(height: 4),
          Text('Czy będziesz na weselu?',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
          const SizedBox(height: 8),
          Row(
            children: [
              _choice('Będę', true),
              const SizedBox(width: 10),
              _choice('Nie dam rady', false),
            ],
          ),
          if (_attending) ...[
            const SizedBox(height: 16),
            Text('Liczba osób towarzyszących',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text)),
            const SizedBox(height: 6),
            Row(
              children: [
                IconButton(
                  onPressed: _companions > 0
                      ? () => setState(() => _companions--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppColors.accent,
                ),
                Text('$_companions',
                    style: GoogleFonts.inter(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                IconButton(
                  onPressed: _companions < 20
                      ? () => setState(() => _companions++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppColors.accent,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
                controller: _dietCtrl,
                maxLength: 200,
                textCapitalization: TextCapitalization.sentences,
                decoration:
                    _guestDec('Dieta / alergie (opcjonalnie)')),
          ],
          const SizedBox(height: 8),
          TextField(
              controller: _noteCtrl,
              maxLength: 500,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: _guestDec('Wiadomość dla Pary Młodej (opcjonalnie)')),
          const SizedBox(height: 6),
          _SubmitButton(
              label: _existing ? 'Zapisz zmiany' : 'Wyślij potwierdzenie',
              sending: _sending,
              onTap: _send),
        ],
      ),
    );
  }

  Widget _choice(String label, bool value) {
    final selected = _attending == value;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _attending = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.10)
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: selected ? AppColors.accent : const Color(0xFFDCE4F2),
                width: selected ? 1.4 : 1),
          ),
          child: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.accent : AppColors.textLight)),
        ),
      ),
    );
  }
}
