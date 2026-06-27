import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';
import '../models/wedding_data.dart';
import '../navigation/app_sections.dart';
import '../services/firestore_service.dart';
import '../services/nav_config_service.dart';
import 'accommodation/accommodation_screen.dart';
import 'analytics/analytics_screen.dart';
import 'bingo/bingo_screen.dart';
import 'budget/budget_screen.dart';
import 'dashboard_screen.dart';
import 'gallery/gallery_screen.dart';
import 'gifts/gifts_screen.dart';
import 'guests/guests_section_screen.dart';
import 'music/music_screen.dart';
import 'room/room_plan_screen.dart';
import 'rsvp/rsvp_screen.dart';
import 'schedule/schedule_screen.dart';
import 'settings/settings_screen.dart';
import 'tasks/tasks_screen.dart';
import 'transport/transport_screen.dart';
import 'vendors/vendors_screen.dart';

/// Główny ekran aplikacji po zalogowaniu.
///
/// • Dashboard jest przypięty na stałe w lewym górnym rogu (AppBar).
/// • Telefon: konfigurowalny [BottomNavigationBar] (4 sloty + „Więcej").
/// • Tablet (≥ 720 px): [NavigationRail] (Dashboard + konfigurowalne sekcje).
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

  late final NavConfigService _navConfig;
  AppSection _current = AppSection.dashboard;
  List<AppSection> _bar = List.of(NavConfigService.defaultBar);

  @override
  void initState() {
    super.initState();
    _navConfig = NavConfigService(uid: widget.user.uid);
    _navConfig.load().then((bar) {
      if (mounted) setState(() => _bar = bar);
    });
  }

  void _select(AppSection section) => setState(() => _current = section);

  /// Sekcje „Więcej": wszystko poza Dashboardem i sekcjami z paska.
  List<AppSection> get _moreSections => AppSection.values
      .where((s) => s != AppSection.dashboard && !_bar.contains(s))
      .toList();

  Future<void> _openMore() async {
    final selected = await showModalBottomSheet<_MoreResult>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          _MoreSheet(sections: _moreSections, current: _current),
    );
    if (selected == null) return;
    if (selected.editBar) {
      await _editBar();
    } else if (selected.section != null) {
      _select(selected.section!);
    }
  }

  Future<void> _editBar() async {
    final result = await showModalBottomSheet<List<AppSection>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _BarEditSheet(initial: _bar),
    );
    if (result == null || result.isEmpty) return;
    setState(() => _bar = result);
    await _navConfig.save(result);
    // Jeśli bieżąca sekcja zniknęła z dostępu, nic nie zmieniamy — i tak jest
    // osiągalna przez „Więcej".
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<WeddingData?>(
      stream: widget.firestore.watchWeddingData(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final isTablet = MediaQuery.sizeOf(context).width >= _tabletBreakpoint;

        return Scaffold(
          backgroundColor: AppColors.bgGradient.last,
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
              top: false,
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
    final dashSelected = _current == AppSection.dashboard;
    return AppBar(
      toolbarHeight: 68,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0.5,
      scrolledUnderElevation: 0.5,
      titleSpacing: 4,
      leading: IconButton(
        tooltip: 'Dashboard',
        onPressed: () => _select(AppSection.dashboard),
        icon: Icon(
          Icons.dashboard_rounded,
          color: dashSelected ? AppColors.accent : AppColors.textLight,
        ),
      ),
      title: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          data?.eventName ?? 'Moje Wesele',
          maxLines: 2,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.playfairDisplay(
            fontSize: 17,
            height: 1.15,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
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
    // Rail: Dashboard (przypięty) + sekcje z paska + „Więcej".
    final rail = [AppSection.dashboard, ..._bar];
    final selectedIndex =
        rail.contains(_current) ? rail.indexOf(_current) : rail.length;

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
          unselectedLabelTextStyle:
              GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
          onDestinationSelected: (index) {
            if (index < rail.length) {
              _select(rail[index]);
            } else {
              _openMore();
            }
          },
          destinations: [
            for (final s in rail)
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
    final selectedIndex =
        _bar.contains(_current) ? _bar.indexOf(_current) : _bar.length;

    return GestureDetector(
      onLongPress: _editBar,
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textLight,
        selectedLabelStyle:
            GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
        onTap: (index) {
          if (index < _bar.length) {
            _select(_bar[index]);
          } else {
            _openMore();
          }
        },
        items: [
          for (final s in _bar)
            BottomNavigationBarItem(icon: Icon(s.icon), label: s.label),
          const BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'Więcej',
          ),
        ],
      ),
    );
  }

  Widget _screenFor(AppSection section, WeddingData? data, bool loading) {
    switch (section) {
      case AppSection.dashboard:
        return DashboardScreen(
          data: data,
          isLoading: loading,
          uid: widget.user.uid,
          onOpenSection: _select,
        );
      case AppSection.guests:
        return GuestsSectionScreen(data: data, firestore: widget.firestore);
      case AppSection.room:
        return RoomPlanScreen(data: data, firestore: widget.firestore);
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

/// Wynik arkusza „Więcej": wybrana sekcja albo żądanie edycji paska.
class _MoreResult {
  _MoreResult({this.section, this.editBar = false});
  final AppSection? section;
  final bool editBar;
}

/// Arkusz „Więcej" — lista pozostałych sekcji + „Konfiguruj pasek".
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
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Więcej sekcji',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pop(_MoreResult(editBar: true)),
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('Konfiguruj pasek'),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final s in sections)
                  ListTile(
                    leading: Icon(s.icon,
                        color: s == current
                            ? AppColors.accent
                            : AppColors.textLight),
                    title: Text(
                      s.label,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight:
                            s == current ? FontWeight.w700 : FontWeight.w500,
                        color: s == current ? AppColors.accent : AppColors.text,
                      ),
                    ),
                    onTap: () =>
                        Navigator.of(context).pop(_MoreResult(section: s)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Arkusz edycji dolnego paska — wybór i kolejność 4 sekcji (drag & drop).
class _BarEditSheet extends StatefulWidget {
  const _BarEditSheet({required this.initial});
  final List<AppSection> initial;

  @override
  State<_BarEditSheet> createState() => _BarEditSheetState();
}

class _BarEditSheetState extends State<_BarEditSheet> {
  late final List<AppSection> _items = List.of(widget.initial);

  List<AppSection> get _available => AppSection.values
      .where((s) => s != AppSection.dashboard && !_items.contains(s))
      .toList();

  Future<void> _add() async {
    final picked = await showModalBottomSheet<AppSection>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final s in _available)
              ListTile(
                leading: Icon(s.icon, color: AppColors.textLight),
                title: Text(s.label),
                onTap: () => Navigator.of(context).pop(s),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _items.add(picked));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Konfiguruj dolny pasek',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text)),
            const SizedBox(height: 4),
            Text(
              'Wybierz do ${NavConfigService.slots} sekcji i ustaw kolejność '
              '(przeciągnij za uchwyt). Dashboard zawsze jest w lewym górnym rogu.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
            ),
            const SizedBox(height: 12),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorderItem: (oldIndex, newIndex) {
                setState(() {
                  final item = _items.removeAt(oldIndex);
                  _items.insert(newIndex, item);
                });
              },
              children: [
                for (var i = 0; i < _items.length; i++)
                  Container(
                    key: ValueKey(_items[i]),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDCE4F2)),
                    ),
                    child: Row(
                      children: [
                        ReorderableDragStartListener(
                          index: i,
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(Icons.drag_handle,
                                color: AppColors.textLight),
                          ),
                        ),
                        Icon(_items[i].icon, size: 20, color: AppColors.accent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_items[i].label,
                              style: GoogleFonts.inter(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                        IconButton(
                          onPressed: _items.length > 1
                              ? () => setState(() => _items.removeAt(i))
                              : null,
                          icon: const Icon(Icons.close, size: 18),
                          color: const Color(0xFFC0392B),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (_items.length < NavConfigService.slots && _available.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _add,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Dodaj sekcję'),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textLight,
                      side: const BorderSide(color: Color(0xFFD7DEEC)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Anuluj'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_items),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Zapisz'),
                  ),
                ),
              ],
            ),
          ],
        ),
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
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
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
                    fontSize: 14, color: const Color(0xFFC0392B)),
              ),
            ],
          ),
        ),
      ],
      child: CircleAvatar(
        radius: 17,
        backgroundColor: AppColors.accent,
        foregroundImage: (photoUrl != null && photoUrl.isNotEmpty)
            ? NetworkImage(photoUrl)
            : null,
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
    final parts =
        source.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return source.substring(0, 1).toUpperCase();
  }
}
