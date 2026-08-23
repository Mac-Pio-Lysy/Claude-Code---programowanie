import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';
import '../app_flags.dart';
import '../models/wedding_data.dart';
import '../navigation/app_sections.dart';
import '../help/help_screen.dart';
import '../l10n/locale_controller.dart';
import '../layout/responsive.dart';
import '../onboarding/onboarding_overlay.dart';
import '../onboarding/onboarding_steps.dart';
import '../services/app_lock_service.dart';
import '../services/firestore_service.dart';
import '../services/nav_config_service.dart';
import '../services/notification_service.dart';
import '../services/onboarding_service.dart';
import '../widgets/floating_bottom_nav.dart';
import '../widgets/notification_bell.dart';
import 'accommodation/accommodation_screen.dart';
import 'analytics/analytics_screen.dart';
import 'budget/budget_screen.dart';
import 'dashboard_screen.dart';
import 'gallery/gallery_screen.dart';
import 'games/games_screen.dart';
import 'gifts/gifts_screen.dart';
import 'keepsakes/keepsakes_screen.dart';
import 'guests/guests_section_screen.dart';
import 'lock/security_setup.dart';
import 'music/music_screen.dart';
import 'planning/planning_guide_screen.dart';
import 'setup/setup_wizard_screen.dart';
import 'room/room_plan_screen.dart';
import 'rsvp/rsvp_all_screen.dart';
import 'rsvp/rsvp_screen.dart';
import 'schedule/schedule_screen.dart';
import 'settings/settings_screen.dart';
import 'tasks/tasks_screen.dart';
import 'transport/transport_screen.dart';
import 'vendors/vendors_screen.dart';
import '../l10n/app_text.dart';

/// Główny ekran aplikacji po zalogowaniu.
///
/// • Telefon: [FloatingBottomNav] — 7 stałych pozycji: 3 konfigurowalne
///   skróty z lewej, pływający Dashboard na środku, 2 konfigurowalne skróty
///   + stałe „Więcej" z prawej (przy prawej krawędzi ekranu). Konfigurowalne
///   jest tylko tych 5 skrótów ([_bar]) — Dashboard i „Więcej" są zawsze na
///   swoich miejscach, a środek pod Dashboardem jest zarezerwowany wyłącznie
///   dla niego.
/// • Tablet (≥ 720 px): [NavigationRail] (Dashboard + konfigurowalne sekcje).
class MainNavigation extends StatefulWidget {
  MainNavigation({
    super.key,
    required this.user,
    required this.weddingId,
    required this.onSignOut,
    this.role = 'owner',
    this.onSwitchWedding,
    FirestoreService? firestoreService,
  }) : firestore = firestoreService ?? FirestoreService(weddingId: weddingId);

  final User? user;

  /// ID aktywnego wesela (multi-wedding) — wyznacza dokument `weddings/{id}`.
  final String weddingId;

  /// Rola użytkownika w tym weselu ('owner'/'planner'/'collaborator'). Decyduje
  /// m.in. o widoczności sekcji „Osoby i dostęp" (tylko owner).
  final String role;

  final VoidCallback onSignOut;

  /// Powrót do listy „Twoje wesela" (zmiana aktywnego wesela). Gdy `null`,
  /// pozycja „Zmień wesele" nie jest pokazywana.
  final VoidCallback? onSwitchWedding;

  final FirestoreService firestore;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  /// Identyfikator używany do per-użytkownikowej konfiguracji (pasek
  /// nawigacji, onboarding).
  String get _uid => widget.user?.uid ?? 'tryb-testowy';

  late final NavConfigService _navConfig;
  late final OnboardingService _onboarding;
  AppSection _current = AppSection.dashboard;
  List<AppSection> _bar = List.of(NavConfigService.defaultBar);

  // ── Stan przewodnika (onboarding) ──
  List<OnbStep>? _tourSteps;
  int _tourIndex = 0;
  bool _tourOffersLock = false;

  /// Wariant aktualnie odtwarzanego przewodnika — bywa inny niż rola, gdy
  /// właściciel lub planer ogląda podgląd strefy gości.
  OnbVariant _tourVariant = OnbVariant.owner;
  bool get _tourActive => _tourSteps != null;

  // Klucze celów spotlightu w nawigacji.
  final _logoKey = GlobalKey();
  final _barKey = GlobalKey();
  final _railKey = GlobalKey();
  final _dashFabKey = GlobalKey();
  final _dashRailKey = GlobalKey();
  final _moreNavKey = GlobalKey();
  final List<GlobalKey> _navItemKeys =
      List.generate(NavConfigService.slots, (_) => GlobalKey());

  /// Strumień danych tworzony RAZ — nie w `build`, by zmiana orientacji /
  /// przebudowa nie powodowała ponownej subskrypcji i migotania „ładowanie".
  late final Stream<WeddingData?> _dataStream;

  // ── Powiadomienia (dzwoneczek) ──
  late final NotificationService _notifications;
  final NotificationInbox _inbox = NotificationInbox();

  /// Osobna subskrypcja danych wesela — wyłącznie do wykrywania zmian.
  ///
  /// Nie korzystamy z [_dataStream], bo ten jest konsumowany przez
  /// `StreamBuilder` w `build`. Firestore i tak trzyma jeden nasłuch na
  /// dokument, więc druga subskrypcja nie generuje dodatkowych odczytów.
  StreamSubscription<WeddingData?>? _notifSub;

  /// Stały klucz ciała ekranu. Dzięki niemu State bieżącej sekcji (indeks
  /// zakładki, filtry, scroll) przeżywa zmianę layoutu telefon↔tablet przy
  /// obrocie — element jest przenoszony, a nie budowany od zera.
  final _bodyKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _navConfig = NavConfigService(uid: _uid);
    _onboarding = OnboardingService(uid: _uid);
    // Preferencja układu jest per użytkownik — wczytujemy ją, gdy znamy uid.
    DisplayModeController.load(_uid);
    // Język jest preferencją tego samego użytkownika — wczytujemy razem.
    LocaleController.load(_uid);
    _dataStream = widget.firestore.watchWeddingData();
    _navConfig.load().then((bar) {
      if (mounted) setState(() => _bar = bar);
    });
    // Serwis tworzymy synchronicznie — dzwoneczek jest klikalny od pierwszej
    // klatki, a `_openNotifications` musi mieć go gotowego.
    _notifications =
        NotificationService(uid: _uid, weddingId: widget.weddingId);
    _initNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) => _firstRunFlow());
  }

  /// Wczytuje stan przeczytania i uruchamia wykrywanie zmian.
  ///
  /// Pierwszy snapshot po instalacji zapisuje odcisk PO CICHU — dzwoneczek nie
  /// zapełnia się historią całego wesela (patrz `NotificationDetector`).
  Future<void> _initNotifications() async {
    _inbox.restoreRead(await _notifications.loadReadIds());

    _notifSub = widget.firestore.watchWeddingData().listen((data) async {
      final fresh = await _notifications.refresh(data);
      if (!mounted || fresh.isEmpty) return;
      setState(() => _inbox.add(fresh));
    });
  }

  /// Otwiera centrum powiadomień i realizuje wybrane przejście.
  Future<void> _openNotifications() async {
    final jump = await NotificationCenter.open(context, _inbox);
    // Stan przeczytania zapisujemy zawsze — także gdy użytkownik tylko
    // przejrzał listę i zamknął panel bez przechodzenia do sekcji.
    await _notifications.markRead(_inbox.readIds);
    if (!mounted) return;
    setState(() {});
    if (jump == null) return;

    _select(jump.section);
    if (jump.subTab != null && tabbedSections.contains(jump.section)) {
      OnboardingTabBus.requestTab(jump.section, jump.subTab!);
    } else {
      OnboardingTabBus.clear();
    }
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  void _select(AppSection section) => setState(() => _current = section);

  // ── Pierwsze uruchomienie: przewodnik → propozycja biometrii ──
  /// Wariant przewodnika wynikający z roli w tym weselu.
  OnbVariant get _variant => variantForRole(widget.role);

  Future<void> _firstRunFlow() async {
    if (await _onboarding.isDone(_variant)) {
      if (mounted) await _maybeOfferLockSetup();
      return;
    }
    if (!mounted) return;
    final choice = await showOnboardingIntro(context, variant: _variant);
    if (choice == null) {
      await _onboarding.markDone(_variant);
      if (mounted) await _maybeOfferLockSetup();
      return;
    }
    if (choice.isSetupWizard) {
      // Kreator zamiast zwiedzania — przewodnik zaliczamy, żeby nie wracał
      // przy każdym uruchomieniu.
      await _onboarding.markDone(_variant);
      if (mounted) await _openSetupWizard();
      if (mounted) await _maybeOfferLockSetup();
      return;
    }
    _startTour(choice, offersLock: true);
  }

  /// Uruchamia przewodnik z wybranego trybu z Ustawień (z ekranem wyboru tempa).
  Future<void> _promptAndStartTour() async {
    final choice = await showOnboardingIntro(context, variant: _variant);
    if (choice == null || !mounted) return;
    if (choice.isSetupWizard) {
      await _openSetupWizard();
      return;
    }
    _startTour(choice, offersLock: false);
  }

  /// Otwiera kreator „Poprowadź mnie za rękę" i realizuje wybrane „Przejdź".
  ///
  /// Kreator zamyka się przy przejściu — powrót do niego jest ręczny
  /// (Ustawienia albo ekran powitalny przewodnika).
  Future<void> _openSetupWizard() async {
    // Świeży odczyt zamiast trzymania danych w polu — kreator ma pokazać stan
    // z tej chwili, a wywołujemy go rzadko (z Ustawień albo ekranu przewodnika).
    final raw = await widget.firestore.readData();
    if (!mounted) return;
    final data = raw == null ? null : WeddingData.fromMap(raw);

    final jump = await SetupWizardScreen.open(context, data);
    if (jump == null || !mounted) return;
    _select(jump.section);
    // Podzakładkę przełączamy tą samą magistralą co przewodnik — bez nowej
    // infrastruktury nawigacji.
    if (jump.subTab != null && tabbedSections.contains(jump.section)) {
      OnboardingTabBus.requestTab(jump.section, jump.subTab!);
    } else {
      OnboardingTabBus.clear();
    }
  }

  void _startTour(OnbChoice choice, {required bool offersLock}) {
    final all = buildOnboardingSteps(variant: choice.variant);
    final steps = choice.isBasic ? all.where((s) => s.basic).toList() : all;
    if (steps.isEmpty) return;
    setState(() {
      _tourSteps = steps;
      _tourIndex = 0;
      _tourOffersLock = offersLock;
      // Podgląd przewodnika gościa nie zalicza przewodnika własnej roli.
      _tourVariant = choice.variant;
    });
    _applyTourStep();
  }

  void _applyTourStep() {
    final step = _tourSteps![_tourIndex];
    // Kroki wariantu gościa nie przełączają panelu — opisują strefę gości,
    // której w panelu organizatora nie ma.
    if (step.navigate) _select(step.section);
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
    final variant = _tourVariant;
    setState(() => _tourSteps = null);
    OnboardingTabBus.clear();
    // Zaliczamy TEN wariant, który był odtwarzany. Dzięki temu obejrzenie
    // podglądu gościa nie „odhacza" przewodnika własnej roli i odwrotnie.
    await _onboarding.markDone(variant);
    if (offers && mounted) await _maybeOfferLockSetup();
  }

  /// Globalny prostokąt podświetlanego przycisku nawigacji (lub null).
  Rect? _tourSpotlightRect(OnbStep step) {
    if (!step.nav) return null;
    final s = step.section;
    if (s == AppSection.settings) return _rectOfKey(_logoKey);
    final isTablet = isTabletLayout(context);
    if (isTablet) {
      // Dashboard jest przypięty osobno na górze szyny.
      if (s == AppSection.dashboard) return _rectOfKey(_dashRailKey);
      // Pozostałe sekcje — przewijana część szyny (bez Dashboardu).
      final items =
          _railSections.where((x) => x != AppSection.dashboard).toList();
      final total = items.length;
      var idx = items.indexOf(s);
      if (idx < 0) idx = 0;
      final r = _rectOfKey(_railKey);
      if (r == null) return null;
      final slot = r.height / total;
      return Rect.fromLTWH(r.left, r.top + slot * idx, r.width, slot);
    }
    // Telefon: Dashboard pływa na środku, pozostałe sekcje mają własne klucze.
    if (s == AppSection.dashboard) return _rectOfKey(_dashFabKey);
    final barIdx = _bar.indexOf(s);
    if (barIdx >= 0 && barIdx < _navItemKeys.length) {
      return _rectOfKey(_navItemKeys[barIdx]);
    }
    return _rectOfKey(_moreNavKey);
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
                    ? AppText.t.nav_biometricTitle
                    : AppText.t.nav_securityTitle,
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
              ? AppText.t.nav_biometricBody
              : AppText.t.nav_securityBody,
          style: GoogleFonts.inter(
              fontSize: 13, height: 1.5, color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppText.t.nav_notNow,
                style: GoogleFonts.inter(color: AppColors.textLight)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            child: Text(AppText.t.nav_enable),
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
            SnackBar(content: Text(AppText.t.sec_enabled)));
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
          title: Text(AppText.t.nav_logoutTitle),
          content: Text(
              AppText.t.nav_logoutBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('cancel'),
              child: Text(AppText.t.common_cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('keep'),
              child: Text(AppText.t.nav_logoutKeep),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop('clear'),
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFC0392B)),
              child: Text(AppText.t.nav_logoutClear),
            ),
          ],
        ),
      );
      if (choice == null || choice == 'cancel') return;
      if (choice == 'clear') await lock.clearAll();
    }
    widget.onSignOut();
  }

  /// Ścieżka ikony Dashboard — premium (`ikona_premium.png`) lub standardowa
  /// (`ikona.png`). Sterowane flagą [isPremium] (docelowo modułem płatności).
  static String get _dashAsset =>
      isPremium ? 'assets/ikona_premium.png' : 'assets/ikona.png';

  /// Ikona zakładki Dashboard — ZAWSZE przycięta do okręgu (ClipOval).
  /// Używana wewnątrz pływającego, okrągłego przycisku na telefonie.
  /// Wyszarzona, gdy sekcja nie jest aktywna.
  Widget _dashIcon({required bool selected, double size = 28}) => Opacity(
        opacity: selected ? 1 : 0.5,
        child: ClipOval(
          child: Image.asset(_dashAsset,
              width: size, height: size, fit: BoxFit.cover),
        ),
      );

  /// Okrągła ikona Dashboard dla bocznej szyny tabletu — ikona w białym
  /// okręgu ze złotą/indygo obwódką (zaznaczenie).
  Widget _dashRailIcon({required bool selected, double size = 34}) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFEAF1FF)],
          ),
          // Zawsze subtelna złota obwódka wokół okręgu Dashboard.
          border: Border.all(color: AppColors.goldLight, width: 2),
        ),
        padding: const EdgeInsets.all(3),
        child: ClipOval(
          child: Image.asset(_dashAsset, fit: BoxFit.cover),
        ),
      );

  /// Sekcje „Więcej": wszystko poza Dashboardem, sekcjami z paska ([_bar] —
  /// zawsze dokładnie 5: 3 z lewej + 2 z prawej Dashboardu) oraz Ustawieniami
  /// (dostępne wyłącznie przez menu logo). „Więcej" samo jest STAŁYM,
  /// skrajnie prawym slotem paska — analityka jest zawsze ostatnią pozycją
  /// na liście.
  List<AppSection> get _moreSections {
    final list = AppSection.values
        .where((s) =>
            s != AppSection.dashboard &&
            s != AppSection.settings &&
            s != AppSection.analytics &&
            !s.hiddenFromNav &&
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
      constraints: const BoxConstraints(maxWidth: kSheetMaxWidth),
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
        final isTablet = isTabletLayout(context);

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
                  : ContentWidth(
                      // Na wąskim ekranie ogranicznik nic nie robi; chroni
                      // układ przy „Wymuś telefon" na dużym ekranie, gdzie
                      // karty rozciągałyby się przez cały tablet.
                      child: KeyedSubtree(
                        key: _bodyKey,
                        child: _screenFor(_current, data, loading),
                      ),
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
            // Pomoc — po lewej stronie nagłówka, symetrycznie do menu konta.
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  tooltip: AppText.t.settings_helpButton,
                  icon: const Icon(Icons.help_outline, color: AppColors.accent),
                  onPressed: () => HelpScreen.open(context, _variant),
                ),
              ),
            ),
            // Dzwoneczek PRZED menu konta — `_logoKey` (cel spotlightu
            // przewodnika dla Ustawień) zostaje na swoim miejscu nietknięty.
            Positioned(
              right: 52,
              top: 0,
              bottom: 0,
              child: Center(
                child: NotificationBell(
                  inbox: _inbox,
                  onOpen: _openNotifications,
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
                    onSwitchWedding: widget.onSwitchWedding,
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
        : AppText.t.nav_appName;
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

  /// Wszystkie sekcje pokazywane w bocznej szynie tabletu — Dashboard
  /// (przypięty na górze) + wszystkie pozostałe sekcje. BEZ „Więcej":
  /// na tablecie jest miejsce, by pokazać wszystko naraz. Ustawienia zostają
  /// wyłącznie w menu logo (jak na telefonie).
  List<AppSection> get _railSections => [
        AppSection.dashboard,
        ...AppSection.values.where((s) =>
            s != AppSection.dashboard &&
            s != AppSection.settings &&
            !s.hiddenFromNav),
      ];

  Widget _buildTabletLayout(WeddingData? data, bool loading) {
    return Row(
      children: [
        _buildTabletRail(),
        // Złota linia oddzielająca szynę od treści.
        Container(
          width: 1.4,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: AppColors.goldGradient,
            ),
          ),
        ),
        Expanded(
          // Na bardzo szerokim ekranie treść nie rozjeżdża się na całą
          // szerokość — wiersze tekstu i formularze pozostają czytelne,
          // a kolumna jest wyśrodkowana obok szyny.
          child: ContentWidth(
            child: KeyedSubtree(
              key: _bodyKey,
              child: _screenFor(_current, data, loading),
            ),
          ),
        ),
      ],
    );
  }

  /// Boczna szyna nawigacji tabletu — ten sam styl co dolny pasek telefonu:
  /// gradient biały→indygo ze złotymi akcentami. Dashboard jest PRZYPIĘTY na
  /// górze (stałe miejsce, niekonfigurowalny, nieprzesuwalny, zawsze widoczny),
  /// a pozostałe sekcje są przewijane poniżej.
  Widget _buildTabletRail() {
    // Sekcje przewijane — wszystkie poza Dashboardem (i Ustawieniami).
    final other =
        _railSections.where((s) => s != AppSection.dashboard).toList();
    final idx = other.indexOf(_current);
    final unselected = Colors.white.withValues(alpha: 0.66);

    return Container(
      // Stała szerokość szyny — pozwala przypiąć Dashboard nad przewijaną
      // listą bez konfliktów układu (IntrinsicWidth nie współpracuje z
      // LayoutBuilderem użytym do przewijania).
      width: 88,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          // Jasno-niebieski (góra) → indygo (dół). Jasny akcent tylko wąskim
          // pasem u góry, reszta indygo — białe etykiety pozostają czytelne.
          colors: AppColors.navBarGradient,
          stops: [0.0, 0.12, 1.0],
        ),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Dashboard — PRZYPIĘTY, zawsze na górze, wyróżniony ──
            KeyedSubtree(key: _dashRailKey, child: _tabletDashboardButton()),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: AppColors.goldLight.withValues(alpha: 0.45),
            ),
            // ── Pozostałe sekcje — przewijane ──
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: NavigationRail(
                        key: _railKey,
                        backgroundColor: Colors.transparent,
                        selectedIndex: idx >= 0 ? idx : null,
                        labelType: NavigationRailLabelType.all,
                        indicatorColor: AppColors.gold.withValues(alpha: 0.26),
                        selectedIconTheme:
                            const IconThemeData(color: AppColors.goldLight),
                        unselectedIconTheme: IconThemeData(color: unselected),
                        selectedLabelTextStyle: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldLight,
                        ),
                        unselectedLabelTextStyle:
                            GoogleFonts.inter(fontSize: 12, color: unselected),
                        onDestinationSelected: (index) => _select(other[index]),
                        destinations: [
                          for (final s in other)
                            NavigationRailDestination(
                              icon: Icon(s.icon),
                              label: Text(s.label),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
  }

  /// Przypięty przycisk Dashboard na górze szyny tabletu — stałe miejsce,
  /// niekonfigurowalny; wyróżniony okrągłą, złotą obwódką i podświetleniem.
  Widget _tabletDashboardButton() {
    final selected = _current == AppSection.dashboard;
    return Material(
      color: selected ? Colors.white.withValues(alpha: 0.14) : Colors.transparent,
      child: InkWell(
        onTap: () => _select(AppSection.dashboard),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 16, 6, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dashRailIcon(selected: selected),
              const SizedBox(height: 6),
              Text(
                AppText.t.section_dashboard,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? AppColors.goldLight
                      : Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return FloatingBottomNav(
      barKey: _barKey,
      dashboardKey: _dashFabKey,
      moreKey: _moreNavKey,
      itemKeys: _navItemKeys.take(_bar.length).toList(),
      bar: _bar,
      current: _current,
      dashboardIcon: _dashIcon(
          selected: _current == AppSection.dashboard, size: 30),
      onSelect: _select,
      onMore: _openMore,
      onLongPress: _editBar,
    );
  }

  Widget _screenFor(AppSection section, WeddingData? data, bool loading) {
    switch (section) {
      case AppSection.dashboard:
        return DashboardScreen(
          data: data,
          isLoading: loading,
          uid: _uid,
          onOpenSection: _select,
        );
      case AppSection.guests:
        return GuestsSectionScreen(data: data, firestore: widget.firestore);
      case AppSection.room:
        return RoomPlanScreen(data: data, firestore: widget.firestore);
      case AppSection.budget:
        return BudgetScreen(
            data: data, firestore: widget.firestore, onOpenSection: _select);
      case AppSection.schedule:
        return ScheduleScreen(data: data, firestore: widget.firestore);
      case AppSection.tasks:
        return TasksScreen(
            data: data,
            firestore: widget.firestore,
            onOpenSection: _select);
      case AppSection.vendors:
        return VendorsScreen(
            data: data, firestore: widget.firestore, onOpenSection: _select);
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
      case AppSection.games:
        return GamesScreen(data: data, firestore: widget.firestore);
      case AppSection.keepsakes:
        return KeepsakesScreen(data: data, firestore: widget.firestore);
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
          isOwner: widget.role == 'owner',
          currentUserId: _uid,
          onSignOut: _handleSignOut,
          onStartTour: _promptAndStartTour,
          onOpenSetupWizard: _openSetupWizard,
          onOpenHelp: () => HelpScreen.open(context, _variant),
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
                    AppText.t.nav_moreSections,
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
                  label: Text(AppText.t.nav_configureBar),
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
  late List<AppSection> _items;

  /// Docelowa (jedyna dozwolona) długość paska — [NavConfigService.compactSlots]
  /// (4 ikony razem z „Więcej", układ 2+2) albo [NavConfigService.slots]
  /// (6 ikon razem z „Więcej", układ 3+3). Wymuszenie tylko tych dwóch
  /// długości gwarantuje, że pasek zawsze wyjdzie symetrycznie — bez tego
  /// przy nieparzystej/asymetrycznej liczbie skrótów pływający Dashboard
  /// „wjeżdżał" na inne ikony.
  late int _target;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.initial);
    _target = _items.length > NavConfigService.compactSlots
        ? NavConfigService.slots
        : NavConfigService.compactSlots;
    _fitToTarget();
  }

  List<AppSection> get _available => AppSection.values
      .where((s) =>
          s != AppSection.dashboard &&
          s != AppSection.settings &&
          !s.hiddenFromNav &&
          !_items.contains(s))
      .toList();

  /// Dopełnia/przycina `_items` do dokładnie `_target` pozycji.
  void _fitToTarget() {
    while (_items.length < _target && _available.isNotEmpty) {
      _items.add(_available.first);
    }
    if (_items.length > _target) {
      _items = _items.sublist(0, _target);
    }
  }

  void _setTarget(int target) {
    if (_target == target) return;
    setState(() {
      _target = target;
      _fitToTarget();
    });
  }

  /// Podmienia sekcję na konkretnej pozycji (liczba slotów pozostaje stała).
  Future<void> _replace(int index) async {
    final current = _items[index];
    final options = [current, ..._available];
    final picked = await showModalBottomSheet<AppSection>(
      context: context,
      constraints: const BoxConstraints(maxWidth: kSheetMaxWidth),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final s in options)
              ListTile(
                leading: Icon(s.icon,
                    color: s == current ? AppColors.accent : AppColors.textLight),
                title: Text(s.label),
                trailing:
                    s == current ? const Icon(Icons.check, color: AppColors.accent) : null,
                onTap: () => Navigator.of(context).pop(s),
              ),
          ],
        ),
      ),
    );
    if (picked != null && picked != current) {
      setState(() => _items[index] = picked);
    }
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
            Text(AppText.t.nav_configureBottomBar,
                style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text)),
            const SizedBox(height: 4),
            Text(
              AppText.t.nav_configureHint,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _countChip(
                        AppText.t.nav_icons4, NavConfigService.compactSlots)),
                const SizedBox(width: 8),
                Expanded(
                    child: _countChip(AppText.t.nav_icons6, NavConfigService.slots)),
              ],
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
                          onPressed: () => _replace(i),
                          icon: const Icon(Icons.swap_horiz, size: 20),
                          color: AppColors.accent,
                          tooltip: AppText.t.nav_changeSection,
                        ),
                      ],
                    ),
                  ),
              ],
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
                    child: Text(AppText.t.common_cancel),
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
                    child: Text(AppText.t.common_save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _countChip(String label, int target) {
    final selected = _target == target;
    return ChoiceChip(
      label: Center(child: Text(label)),
      selected: selected,
      onSelected: (_) => _setTarget(target),
      showCheckmark: false,
      labelStyle: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: selected ? Colors.white : AppColors.textLight,
      ),
      selectedColor: AppColors.accent,
      backgroundColor: Colors.white,
      side: BorderSide(
          color: selected ? AppColors.accent : const Color(0xFFDCE4F2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

/// Awatar użytkownika + menu (Ustawienia, Wyloguj).
class _UserMenu extends StatelessWidget {
  const _UserMenu({
    required this.user,
    required this.onSettings,
    required this.onSignOut,
    this.onSwitchWedding,
  });

  final User? user;
  final VoidCallback onSettings;
  final VoidCallback onSignOut;

  /// Powrót do listy wesel (opcjonalny — może być null).
  final VoidCallback? onSwitchWedding;

  @override
  Widget build(BuildContext context) {
    final photoUrl = user?.photoURL;
    return PopupMenuButton<String>(
      tooltip: AppText.t.gh_account,
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'settings') onSettings();
        if (value == 'switch') onSwitchWedding?.call();
        if (value == 'logout') onSignOut();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Text(
            user?.email ?? user?.displayName ?? '',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
          ),
        ),
        const PopupMenuDivider(),
        if (onSwitchWedding != null)
          PopupMenuItem(
            value: 'switch',
            child: Row(
              children: [
                const Icon(Icons.swap_horiz, size: 20),
                const SizedBox(width: 10),
                Text(AppText.t.gh_switchWedding, style: GoogleFonts.inter(fontSize: 14)),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              const Icon(Icons.settings_outlined, size: 20),
              const SizedBox(width: 10),
              Text(AppText.t.settings_title, style: GoogleFonts.inter(fontSize: 14)),
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
                AppText.t.settings_logoutButton,
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

  static String _initials(User? user) {
    final source = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : (user?.email ?? '?');
    final parts =
        source.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return source.substring(0, 1).toUpperCase();
  }
}
