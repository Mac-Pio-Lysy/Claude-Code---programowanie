import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';
import '../models/wedding_data.dart';
import '../navigation/app_sections.dart';
import '../onboarding/onboarding_overlay.dart';
import '../onboarding/onboarding_steps.dart';
import '../services/app_lock_service.dart';
import '../services/firestore_service.dart';
import '../services/nav_config_service.dart';
import '../services/onboarding_service.dart';
import 'accommodation/accommodation_screen.dart';
import 'analytics/analytics_screen.dart';
import 'bingo/bingo_screen.dart';
import 'budget/budget_screen.dart';
import 'dashboard_screen.dart';
import 'gallery/gallery_screen.dart';
import 'gifts/gifts_screen.dart';
import 'guests/guests_section_screen.dart';
import 'lock/security_setup.dart';
import 'music/music_screen.dart';
import 'planning/planning_guide_screen.dart';
import 'room/room_plan_screen.dart';
import 'rsvp/rsvp_all_screen.dart';
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
  late final OnboardingService _onboarding;
  AppSection _current = AppSection.dashboard;
  List<AppSection> _bar = List.of(NavConfigService.defaultBar);

  // ── Stan przewodnika (onboarding) ──
  List<OnbStep>? _tourSteps;
  int _tourIndex = 0;
  bool _tourOffersLock = false;
  bool get _tourActive => _tourSteps != null;

  // Klucze celów spotlightu w nawigacji.
  final _logoKey = GlobalKey();
  final _barKey = GlobalKey();
  final _railKey = GlobalKey();

  /// Strumień danych tworzony RAZ — nie w `build`, by zmiana orientacji /
  /// przebudowa nie powodowała ponownej subskrypcji i migotania „ładowanie".
  late final Stream<WeddingData?> _dataStream;

  /// Stały klucz ciała ekranu. Dzięki niemu State bieżącej sekcji (indeks
  /// zakładki, filtry, scroll) przeżywa zmianę layoutu telefon↔tablet przy
  /// obrocie — element jest przenoszony, a nie budowany od zera.
  final _bodyKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _navConfig = NavConfigService(uid: widget.user.uid);
    _onboarding = OnboardingService(uid: widget.user.uid);
    _dataStream = widget.firestore.watchWeddingData();
    _navConfig.load().then((bar) {
      if (mounted) setState(() => _bar = bar);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _firstRunFlow());
  }

  void _select(AppSection section) => setState(() => _current = section);

  // ── Pierwsze uruchomienie: przewodnik → propozycja biometrii ──
  Future<void> _firstRunFlow() async {
    if (await _onboarding.isDone()) {
      if (mounted) await _maybeOfferLockSetup();
      return;
    }
    if (!mounted) return;
    final mode = await showOnboardingIntro(context);
    if (mode == null) {
      await _onboarding.markDone();
      if (mounted) await _maybeOfferLockSetup();
      return;
    }
    _startTour(mode, offersLock: true);
  }

  /// Uruchamia przewodnik z wybranego trybu z Ustawień (z ekranem wyboru tempa).
  Future<void> _promptAndStartTour() async {
    final mode = await showOnboardingIntro(context);
    if (mode == null || !mounted) return;
    _startTour(mode, offersLock: false);
  }

  void _startTour(String mode, {required bool offersLock}) {
    final all = buildOnboardingSteps();
    final steps = mode == 'basic' ? all.where((s) => s.basic).toList() : all;
    if (steps.isEmpty) return;
    setState(() {
      _tourSteps = steps;
      _tourIndex = 0;
      _tourOffersLock = offersLock;
    });
    _applyTourStep();
  }

  void _applyTourStep() {
    final step = _tourSteps![_tourIndex];
    _select(step.section);
    if (step.subTab != null && tabbedSections.contains(step.section)) {
      OnboardingTabBus.requestTab(step.section, step.subTab!);
    } else {
      OnboardingTabBus.clear();
    }
  }

  void _tourNext() {
    if (_tourIndex >= _tourSteps!.length - 1) {
      _finishTour();
      return;
    }
    setState(() => _tourIndex++);
    _applyTourStep();
  }

  void _tourPrev() {
    if (_tourIndex <= 0) return;
    setState(() => _tourIndex--);
    _applyTourStep();
  }

  Future<void> _finishTour() async {
    final offers = _tourOffersLock;
    setState(() => _tourSteps = null);
    OnboardingTabBus.clear();
    await _onboarding.markDone();
    if (offers && mounted) await _maybeOfferLockSetup();
  }

  /// Globalny prostokąt podświetlanego przycisku nawigacji (lub null).
  Rect? _tourSpotlightRect(OnbStep step) {
    if (!step.nav) return null;
    final s = step.section;
    if (s == AppSection.settings) return _rectOfKey(_logoKey);
    // Dashboard jest pierwszą pozycją paska/szyny; pozostałe sekcje po nim.
    final items = [AppSection.dashboard, ..._bar];
    final total = items.length + 1; // + „Więcej"
    var idx = items.indexOf(s);
    if (idx < 0) idx = total - 1;
    final isTablet = MediaQuery.sizeOf(context).width >= _tabletBreakpoint;
    if (isTablet) {
      final r = _rectOfKey(_railKey);
      if (r == null) return null;
      final slot = r.height / total;
      return Rect.fromLTWH(r.left, r.top + slot * idx, r.width, slot);
    }
    final r = _rectOfKey(_barKey);
    if (r == null) return null;
    final slot = r.width / total;
    return Rect.fromLTWH(r.left + slot * idx, r.top, slot, r.height);
  }

  Rect? _rectOfKey(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.attached) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// Jednorazowa propozycja włączenia logowania biometrycznego/PIN — po
  /// przewodniku przy pierwszym logowaniu. Bez czytnika proponujemy PIN/wzór.
  Future<void> _maybeOfferLockSetup() async {
    final lock = AppLockService();
    if (!await lock.shouldOfferSetup()) return;
    final canBio = await lock.canUseBiometrics();
    if (!mounted) return;

    final accept = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Text('🔐 ', style: TextStyle(fontSize: 22)),
            Expanded(
              child: Text(
                canBio
                    ? 'Czy chcesz logować się odciskiem palca?'
                    : 'Czy chcesz zabezpieczyć aplikację?',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text),
              ),
            ),
          ],
        ),
        content: Text(
          canBio
              ? 'Przy kolejnych otwarciach odblokujesz aplikację odciskiem '
                  'palca. Ustawisz też zapasowy PIN lub wzór na wypadek, gdyby '
                  'czytnik nie zadziałał. Konto Google pozostaje zalogowane.'
              : 'To urządzenie nie ma czytnika biometrycznego. Możesz ustawić '
                  'PIN lub wzór, aby odblokowywać aplikację przy kolejnych '
                  'otwarciach.',
          style: GoogleFonts.inter(
              fontSize: 13, height: 1.5, color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Nie teraz',
                style: GoogleFonts.inter(color: AppColors.textLight)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Tak, włącz'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (accept != true) {
      await lock.markPromptDone();
      return;
    }
    final ok = await SecuritySetupScreen.start(context, withBiometric: canBio);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
            const SnackBar(content: Text('Zabezpieczenia włączone ✓')));
    }
  }

  /// Wylogowanie z opcją wyłączenia zabezpieczeń urządzenia. Gdy blokada jest
  /// aktywna, pytamy czy wyczyścić biometrię/PIN (np. gdy z aplikacji korzysta
  /// inne konto) — zgodnie z wymaganiem bezpieczeństwa.
  Future<void> _handleSignOut() async {
    final lock = AppLockService();
    if (await lock.isLockEnabled()) {
      if (!mounted) return;
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Wylogować się?'),
          content: const Text(
              'Czy wyłączyć też zabezpieczenia (odcisk palca / PIN) na tym '
              'urządzeniu? Przydatne, gdy z aplikacji może korzystać inna osoba.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('cancel'),
              child: const Text('Anuluj'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('keep'),
              child: const Text('Wyloguj, zachowaj'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop('clear'),
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFC0392B)),
              child: const Text('Wyloguj i wyłącz'),
            ),
          ],
        ),
      );
      if (choice == null || choice == 'cancel') return;
      if (choice == 'clear') await lock.clearAll();
    }
    widget.onSignOut();
  }

  /// Ikona zakładki Dashboard (assets/ikona_dashBoard.png).
  /// Wyszarzona, gdy sekcja nie jest aktywna.
  Widget _dashIcon({required bool selected, double size = 28}) => Opacity(
        opacity: selected ? 1 : 0.5,
        child:
            Image.asset('assets/ikona_dashBoard.png', width: size, height: size),
      );

  /// Sekcje „Więcej": wszystko poza Dashboardem, sekcjami z paska oraz
  /// Ustawieniami (te są dostępne wyłącznie przez menu logo). Analityka jest
  /// zawsze ostatnią pozycją na liście.
  List<AppSection> get _moreSections {
    final list = AppSection.values
        .where((s) =>
            s != AppSection.dashboard &&
            s != AppSection.settings &&
            s != AppSection.analytics &&
            !_bar.contains(s))
        .toList();
    if (!_bar.contains(AppSection.analytics)) {
      list.add(AppSection.analytics);
    }
    return list;
  }

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
      stream: _dataStream,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final isTablet = MediaQuery.sizeOf(context).width >= _tabletBreakpoint;

        final scaffold = Scaffold(
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
                  : KeyedSubtree(
                      key: _bodyKey,
                      child: _screenFor(_current, data, loading),
                    ),
            ),
          ),
        );

        if (!_tourActive) return scaffold;
        return Stack(
          children: [
            scaffold,
            Positioned.fill(
              child: OnboardingOverlay(
                step: _tourSteps![_tourIndex],
                index: _tourIndex,
                total: _tourSteps!.length,
                resolve: _tourSpotlightRect,
                onPrev: _tourPrev,
                onNext: _tourNext,
                onSkip: _finishTour,
              ),
            ),
          ],
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(WeddingData? data) {
    return AppBar(
      toolbarHeight: 76,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0.5,
      scrolledUnderElevation: 0.5,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: const SizedBox.shrink(),
      flexibleSpace: SafeArea(
        child: Stack(
          children: [
            // Nagłówek wyśrodkowany na całej szerokości; margines po bokach
            // chroni przed nachodzeniem na logo i utrzymuje symetrię.
            Positioned.fill(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: _headerTitle(data),
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: KeyedSubtree(
                  key: _logoKey,
                  child: _UserMenu(
                    user: widget.user,
                    onSettings: () => _select(AppSection.settings),
                    onSignOut: _handleSignOut,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dwuwierszowy nagłówek: „Nazwa wydarzenia" nad „Osobami", wyśrodkowany.
  /// Każdy wiersz skaluje się w dół (FittedBox), aby był w pełni widoczny.
  Widget _headerTitle(WeddingData? data) {
    final eventName = (data?.eventName?.trim().isNotEmpty ?? false)
        ? data!.eventName!.trim()
        : 'Moje Wesele';
    final persons = data?.displayNames?.trim() ?? '';
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            eventName,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: GoogleFonts.playfairDisplay(
              fontSize: 19,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
        ),
        if (persons.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                persons,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 14,
                  height: 1.1,
                  fontWeight: FontWeight.w500,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
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
          key: _railKey,
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
                icon: s == AppSection.dashboard
                    ? _dashIcon(selected: _current == s)
                    : Icon(s.icon),
                label: Text(s.label),
              ),
            const NavigationRailDestination(
              icon: Icon(Icons.more_horiz),
              label: Text('Więcej'),
            ),
          ],
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: KeyedSubtree(
            key: _bodyKey,
            child: _screenFor(_current, data, loading),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    // Dashboard zawsze pierwszy z lewej; potem konfigurowalne sloty i „Więcej".
    final int selectedIndex;
    if (_current == AppSection.dashboard) {
      selectedIndex = 0;
    } else if (_bar.contains(_current)) {
      selectedIndex = 1 + _bar.indexOf(_current);
    } else {
      selectedIndex = _bar.length + 1;
    }

    return GestureDetector(
      key: _barKey,
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
          if (index == 0) {
            _select(AppSection.dashboard);
          } else if (index <= _bar.length) {
            _select(_bar[index - 1]);
          } else {
            _openMore();
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: _dashIcon(
                selected: _current == AppSection.dashboard, size: 24),
            label: AppSection.dashboard.label,
          ),
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
      case AppSection.rsvpAll:
        return RsvpAllScreen(data: data, firestore: widget.firestore);
      case AppSection.analytics:
        return AnalyticsScreen(data: data);
      case AppSection.settings:
        return SettingsScreen(
          data: data,
          firestore: widget.firestore,
          onSignOut: _handleSignOut,
          onStartTour: _promptAndStartTour,
          onOpenPlanning: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PlanningGuideScreen(
                  data: data, firestore: widget.firestore),
            ),
          ),
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
      .where((s) =>
          s != AppSection.dashboard &&
          s != AppSection.settings &&
          !_items.contains(s))
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
