import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';
import '../models/wedding_data.dart';
import '../navigation/app_sections.dart';
import '../services/firestore_service.dart';
import 'accommodation/accommodation_screen.dart';
import 'analytics/analytics_screen.dart';
import 'bingo/bingo_screen.dart';
import 'budget/budget_screen.dart';
import 'dashboard_screen.dart';
import 'gallery/gallery_screen.dart';
import 'gifts/gifts_screen.dart';
import 'guests/guests_section_screen.dart';
import 'music/music_screen.dart';
import 'rsvp/rsvp_screen.dart';
import 'schedule/schedule_screen.dart';
import 'settings/settings_screen.dart';
import 'tables/tables_screen.dart';
import 'tasks/tasks_screen.dart';
import 'transport/transport_screen.dart';
import 'vendors/vendors_screen.dart';

/// Główny ekran aplikacji po zalogowaniu.
///
/// Responsywnie dobiera nawigację:
///  • telefon (< 720 px) → [BottomNavigationBar] z 4 sekcjami + „Więcej",
///  • tablet (≥ 720 px)  → [NavigationRail] z 7 sekcjami + „Więcej".
class MainNavigation extends StatefulWidget {
  MainNavigation({
    super.key,
    required this.user,
    required this.onSignOut,
    FirestoreService? firestoreService,
  }) : firestore = firestoreService ?? FirestoreService();

  final User user;
  final VoidCallback onSignOut;
  final FirestoreService firestore;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  static const double _tabletBreakpoint = 720;

  AppSection _current = AppSection.dashboard;

  void _select(AppSection section) => setState(() => _current = section);

  Future<void> _openMore(List<AppSection> primary) async {
    final selected = await showModalBottomSheet<AppSection>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _MoreSheet(
        sections: moreSectionsFor(primary),
        current: _current,
      ),
    );
    if (selected != null) _select(selected);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<WeddingData?>(
      stream: widget.firestore.watchWeddingData(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final isTablet =
            MediaQuery.sizeOf(context).width >= _tabletBreakpoint;

        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: _buildAppBar(data),
          bottomNavigationBar: isTablet ? null : _buildBottomBar(),
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
              child: isTablet
                  ? _buildTabletLayout(data, loading)
                  : _screenFor(_current, data, loading),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(WeddingData? data) {
    return AppBar(
      backgroundColor: Colors.white.withValues(alpha: 0.85),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 16,
      title: Text(
        data?.eventName ?? 'Moje Wesele',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
      ),
      actions: [
        _UserMenu(
          user: widget.user,
          onSettings: () => _select(AppSection.settings),
          onSignOut: widget.onSignOut,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTabletLayout(WeddingData? data, bool loading) {
    final selectedIndex = kTabletPrimary.contains(_current)
        ? kTabletPrimary.indexOf(_current)
        : kTabletPrimary.length; // pozycja „Więcej"

    return Row(
      children: [
        NavigationRail(
          backgroundColor: Colors.white.withValues(alpha: 0.6),
          selectedIndex: selectedIndex,
          labelType: NavigationRailLabelType.all,
          indicatorColor: AppColors.accent.withValues(alpha: 0.14),
          selectedIconTheme: const IconThemeData(color: AppColors.accent),
          selectedLabelTextStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.accent,
          ),
          unselectedLabelTextStyle: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textLight,
          ),
          onDestinationSelected: (index) {
            if (index < kTabletPrimary.length) {
              _select(kTabletPrimary[index]);
            } else {
              _openMore(kTabletPrimary);
            }
          },
          destinations: [
            for (final s in kTabletPrimary)
              NavigationRailDestination(
                icon: Icon(s.icon),
                label: Text(s.label),
              ),
            const NavigationRailDestination(
              icon: Icon(Icons.more_horiz),
              label: Text('Więcej'),
            ),
          ],
        ),
        const VerticalDivider(width: 1),
        Expanded(child: _screenFor(_current, data, loading)),
      ],
    );
  }

  Widget _buildBottomBar() {
    final selectedIndex = kPhonePrimary.contains(_current)
        ? kPhonePrimary.indexOf(_current)
        : kPhonePrimary.length; // pozycja „Więcej"

    return BottomNavigationBar(
      currentIndex: selectedIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.textLight,
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
      onTap: (index) {
        if (index < kPhonePrimary.length) {
          _select(kPhonePrimary[index]);
        } else {
          _openMore(kPhonePrimary);
        }
      },
      items: [
        for (final s in kPhonePrimary)
          BottomNavigationBarItem(icon: Icon(s.icon), label: s.label),
        const BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz),
          label: 'Więcej',
        ),
      ],
    );
  }

  Widget _screenFor(AppSection section, WeddingData? data, bool loading) {
    switch (section) {
      case AppSection.dashboard:
        return DashboardScreen(data: data, isLoading: loading);
      case AppSection.guests:
        return GuestsSectionScreen(data: data, firestore: widget.firestore);
      case AppSection.room:
        return TablesScreen(data: data, firestore: widget.firestore);
      case AppSection.budget:
        return BudgetScreen(data: data, firestore: widget.firestore);
      case AppSection.schedule:
        return ScheduleScreen(data: data, firestore: widget.firestore);
      case AppSection.tasks:
        return TasksScreen(data: data, firestore: widget.firestore);
      case AppSection.vendors:
        return VendorsScreen(data: data, firestore: widget.firestore);
      case AppSection.transport:
        return TransportScreen(data: data, firestore: widget.firestore);
      case AppSection.accommodation:
        return AccommodationScreen(data: data, firestore: widget.firestore);
      case AppSection.gifts:
        return GiftsScreen(data: data, firestore: widget.firestore);
      case AppSection.music:
        return MusicScreen(data: data, firestore: widget.firestore);
      case AppSection.gallery:
        return GalleryScreen(data: data, firestore: widget.firestore);
      case AppSection.bingo:
        return BingoScreen(data: data, firestore: widget.firestore);
      case AppSection.rsvp:
        return RsvpScreen(data: data, firestore: widget.firestore);
      case AppSection.analytics:
        return AnalyticsScreen(data: data);
      case AppSection.settings:
        return SettingsScreen(
          data: data,
          firestore: widget.firestore,
          onSignOut: widget.onSignOut,
        );
    }
  }
}

/// Arkusz „Więcej" — lista pozostałych sekcji.
class _MoreSheet extends StatelessWidget {
  const _MoreSheet({required this.sections, required this.current});

  final List<AppSection> sections;
  final AppSection current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Więcej sekcji',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
          ),
          for (final s in sections)
            ListTile(
              leading: Icon(
                s.icon,
                color: s == current ? AppColors.accent : AppColors.textLight,
              ),
              title: Text(
                s.label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: s == current ? FontWeight.w700 : FontWeight.w500,
                  color: s == current ? AppColors.accent : AppColors.text,
                ),
              ),
              onTap: () => Navigator.of(context).pop(s),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Awatar użytkownika + menu (Ustawienia, Wyloguj).
class _UserMenu extends StatelessWidget {
  const _UserMenu({
    required this.user,
    required this.onSettings,
    required this.onSignOut,
  });

  final User user;
  final VoidCallback onSettings;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final photoUrl = user.photoURL;
    return PopupMenuButton<String>(
      tooltip: 'Konto',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'settings') onSettings();
        if (value == 'logout') onSignOut();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Text(
            user.email ?? user.displayName ?? 'Konto',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textLight,
            ),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              const Icon(Icons.settings_outlined, size: 20),
              const SizedBox(width: 10),
              Text('Ustawienia', style: GoogleFonts.inter(fontSize: 14)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout, size: 20, color: Color(0xFFC0392B)),
              const SizedBox(width: 10),
              Text(
                'Wyloguj',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFFC0392B),
                ),
              ),
            ],
          ),
        ),
      ],
      child: CircleAvatar(
        radius: 17,
        backgroundColor: AppColors.accent,
        foregroundImage:
            (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
        child: Text(
          _initials(user),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  static String _initials(User user) {
    final source = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : (user.email ?? '?');
    final parts = source.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return source.substring(0, 1).toUpperCase();
  }
}
