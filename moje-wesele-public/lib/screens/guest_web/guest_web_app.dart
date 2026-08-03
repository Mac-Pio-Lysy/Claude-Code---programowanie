import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/guest_visibility.dart';
import '../../services/guest_space_service.dart';
import '../../utils/warsaw_time.dart';

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
      home: GuestWebHome(token: token),
    );
  }
}

class GuestWebHome extends StatefulWidget {
  const GuestWebHome({super.key, required this.token});

  final String token;

  @override
  State<GuestWebHome> createState() => _GuestWebHomeState();
}

class _GuestWebHomeState extends State<GuestWebHome> {
  late final GuestSpaceService _service =
      GuestSpaceService(token: widget.token);

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
          child: StreamBuilder<Map<String, dynamic>?>(
            stream: _service.watchSpace(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                );
              }
              final space = snapshot.data;
              if (space == null) return _invalid();
              return _content(space);
            },
          ),
        ),
      ),
    );
  }

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
        _header(eventName, persons, space),
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
        page = _GuestbookPage(service: _service);
      case 'schedule':
        page = _ScheduleView(events: space['scheduleEvents']);
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
  const _ScheduleView({required this.events});
  final dynamic events;

  @override
  Widget build(BuildContext context) {
    final list = events is List ? events as List : const [];
    if (list.isEmpty) {
      return Center(
        child: Text('Harmonogram pojawi się wkrótce.',
            style: GoogleFonts.inter(color: AppColors.textLight)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final e = list[i] is Map ? Map<String, dynamic>.from(list[i]) : {};
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

/// Księga gości — działająca interakcja (odczyt wpisów + dodanie).
class _GuestbookPage extends StatefulWidget {
  const _GuestbookPage({required this.service});
  final GuestSpaceService service;

  @override
  State<_GuestbookPage> createState() => _GuestbookPageState();
}

class _GuestbookPageState extends State<_GuestbookPage> {
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
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Podaj imię i wpis.')));
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.service.addGuestbookEntry(name: name, message: msg);
      _msgCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Dziękujemy za wpis ✓')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Nie udało się wysłać: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
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
              TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _dec('Twoje imię'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _msgCtrl,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: _dec('Twój wpis dla Pary Młodej…'),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sending ? null : _send,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send),
                  label: Text(_sending ? 'Wysyłanie…' : 'Dodaj wpis',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: widget.service.watchGuestbook(),
            builder: (context, snapshot) {
              final entries = snapshot.data ?? const [];
              if (entries.isEmpty) {
                return Center(
                  child: Text('Bądź pierwszy — zostaw wpis!',
                      style: GoogleFonts.inter(color: AppColors.textLight)),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: entries.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final e = entries[i];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2EAF7)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text((e['name'] as String?) ?? 'Gość',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent)),
                        const SizedBox(height: 4),
                        Text((e['message'] as String?) ?? '',
                            style: GoogleFonts.inter(
                                fontSize: 14, color: AppColors.text)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: AppColors.textLight, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
}
