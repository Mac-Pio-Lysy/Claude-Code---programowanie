import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/wedding_data.dart';
import '../../services/firestore_service.dart';
import '../gallery/gallery_screen.dart';
import '../games/games_screen.dart';
import '../keepsakes/keepsakes_screen.dart';
import '../music/music_screen.dart';
import '../rsvp/rsvp_screen.dart';
import '../schedule/schedule_screen.dart';

/// Uproszczony panel GOŚCIA (rola „guest"). Pokazuje wyłącznie sekcje dozwolone
/// dla gości: swoje miejsce, harmonogram, galeria, muzyka, gry, RSVP i pamiątki.
///
/// Gość NIE widzi budżetu, pełnej listy gości, planu sali (edycji), dostawców,
/// zadań, analityki ani ustawień. To ograniczenie na poziomie INTERFEJSU —
/// egzekwowanie przez reguły bezpieczeństwa Firestore powstanie w kroku izolacji.
class GuestHomeScreen extends StatefulWidget {
  GuestHomeScreen({
    super.key,
    required this.user,
    required this.weddingId,
    required this.onSwitchWedding,
    required this.onSignOut,
    FirestoreService? firestoreService,
  }) : firestore = firestoreService ?? FirestoreService(weddingId: weddingId);

  final User? user;
  final String weddingId;
  final VoidCallback onSwitchWedding;
  final VoidCallback onSignOut;
  final FirestoreService firestore;

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen> {
  late final Stream<WeddingData?> _dataStream =
      widget.firestore.watchWeddingData();

  static const List<_GuestSection> _sections = [
    _GuestSection('seat', 'Twoje miejsce', Icons.event_seat_outlined),
    _GuestSection('schedule', 'Harmonogram', Icons.event_outlined),
    _GuestSection('gallery', 'Galeria', Icons.photo_library_outlined),
    _GuestSection('music', 'Muzyka', Icons.music_note_outlined),
    _GuestSection('games', 'Ślubne gry', Icons.casino_outlined),
    _GuestSection('rsvp', 'Potwierdź obecność', Icons.how_to_reg_outlined),
    _GuestSection('keepsakes', 'Ślubne pamiątki', Icons.favorite_outline),
  ];

  void _openSection(_GuestSection section, WeddingData? data) {
    Widget child;
    switch (section.key) {
      case 'schedule':
        child = ScheduleScreen(data: data, firestore: widget.firestore);
      case 'gallery':
        child = GalleryScreen(data: data, firestore: widget.firestore);
      case 'music':
        child = MusicScreen(data: data, firestore: widget.firestore);
      case 'games':
        child = GamesScreen(data: data, firestore: widget.firestore);
      case 'rsvp':
        child = RsvpScreen(data: data, firestore: widget.firestore);
      case 'keepsakes':
        child = KeepsakesScreen(data: data, firestore: widget.firestore);
      case 'seat':
      default:
        child = const _GuestSeatView();
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _SectionPage(title: section.label, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<WeddingData?>(
      stream: _dataStream,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final eventName = (data?.eventName?.trim().isNotEmpty ?? false)
            ? data!.eventName!.trim()
            : 'Wesele';
        return Scaffold(
          backgroundColor: AppColors.bgGradient.last,
          appBar: _appBar(eventName, data?.displayNames?.trim()),
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  _welcomeCard(),
                  const SizedBox(height: 18),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.05,
                    children: [
                      for (final s in _sections)
                        _sectionCard(s, () => _openSection(s, data)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _appBar(String eventName, String? persons) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0.5,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eventName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          if (persons != null && persons.isNotEmpty)
            Text(
              persons,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.accent),
            ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Center(child: _guestChip()),
        ),
        PopupMenuButton<String>(
          tooltip: 'Konto',
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (v) {
            if (v == 'switch') widget.onSwitchWedding();
            if (v == 'logout') widget.onSignOut();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              enabled: false,
              child: Text(
                widget.user?.email ?? widget.user?.displayName ?? 'Gość',
                style:
                    GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'switch',
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz, size: 20),
                  const SizedBox(width: 10),
                  Text('Zmień wesele', style: GoogleFonts.inter(fontSize: 14)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  const Icon(Icons.logout, size: 20, color: Color(0xFFC0392B)),
                  const SizedBox(width: 10),
                  Text('Wyloguj',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: const Color(0xFFC0392B))),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _guestChip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline,
                size: 14, color: Color(0xFF8A6D26)),
            const SizedBox(width: 4),
            Text(
              'Gość',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF8A6D26),
              ),
            ),
          ],
        ),
      );

  Widget _welcomeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.10),
            AppColors.accent2.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E4FB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💍', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Witaj jako gość! Poniżej znajdziesz sekcje przygotowane specjalnie '
              'dla Ciebie — potwierdź obecność, sprawdź harmonogram, dodaj zdjęcia '
              'i baw się dobrze.',
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.45,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(_GuestSection s, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE3EAF6)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withValues(alpha: 0.10),
                ),
                child: Icon(s.icon, size: 26, color: AppColors.accent),
              ),
              const SizedBox(height: 12),
              Text(
                s.label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestSection {
  const _GuestSection(this.key, this.label, this.icon);
  final String key;
  final String label;
  final IconData icon;
}

/// Opakowanie sekcji w osobny ekran z paskiem i przyciskiem powrotu.
class _SectionPage extends StatelessWidget {
  const _SectionPage({required this.title, required this.child});

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
        title: Text(
          title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
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
        child: SafeArea(top: false, child: child),
      ),
    );
  }
}

/// „Twoje miejsce" — placeholder. Powiązanie konta gościa z konkretnym wpisem
/// na liście gości (a więc przypisanym stolikiem) powstanie w kolejnym kroku.
class _GuestSeatView extends StatelessWidget {
  const _GuestSeatView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.08),
              ),
              child: const Icon(Icons.event_seat_outlined,
                  size: 44, color: AppColors.accent),
            ),
            const SizedBox(height: 24),
            Text(
              'Twoje miejsce przy stole',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Informacja o Twoim stoliku pojawi się tutaj, gdy organizator '
              'przypisze Cię do miejsca i połączy Twoje konto z listą gości.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
