import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app_colors.dart';
import '../../config/public_urls.dart';
import '../../layout/responsive.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/language_picker.dart';
import '../../l10n/app_text.dart';
import '../../l10n/locale_controller.dart';
import '../../models/children.dart';
import '../../models/couple.dart';
import '../../models/currency.dart';
import '../../models/wedding_data.dart';
import '../../services/backup_service.dart';
import '../../services/config_service.dart';
import '../../services/firestore_service.dart';
import '../../services/guest_service.dart';
import '../../services/legacy_migration_service.dart';
import '../../services/wedding_service.dart';
import '../../utils/app_format.dart';
import '../../utils/format.dart';
import 'guest_interactions_screen.dart';
import 'guest_visibility_screen.dart';
import 'invitations_screen.dart';
import 'notification_settings_screen.dart';
import 'people_access_screen.dart';
import 'security_settings_screen.dart';
import 'package:pdf/pdf.dart';
import '../../models/join_code.dart';
import '../../services/pdf_service.dart';

/// Sekcja „Ustawienia" — konfiguracja, dostęp, narzędzia programistyczne,
/// status synchronizacji i wylogowanie.
class SettingsScreen extends StatefulWidget {
  SettingsScreen({
    super.key,
    required this.data,
    required this.firestore,
    required this.onSignOut,
    required this.onStartTour,
    required this.onOpenPlanning,
    required this.onOpenSetupWizard,
    required this.onOpenHelp,
    this.isOwner = true,
    this.currentUserId = '',
  }) : config = ConfigService(firestore: firestore);

  final WeddingData? data;
  final FirestoreService firestore;

  /// Czy bieżący użytkownik jest właścicielem (owner) — tylko owner widzi
  /// sekcję „Osoby i dostęp".
  final bool isOwner;

  /// UID bieżącego użytkownika (do panelu osób — oznaczenie „Ty").
  final String currentUserId;

  final VoidCallback onSignOut;

  /// Uruchamia przewodnik (z ekranem wyboru tempa).
  final VoidCallback onStartTour;

  /// Otwiera listę „Od czego zacząć?".
  final VoidCallback onOpenPlanning;

  /// Otwiera kreator „Poprowadź mnie za rękę" (#17).
  final VoidCallback onOpenSetupWizard;

  /// Otwiera ekran Pomocy w wariancie zgodnym z rolą (panel zna rolę, Ustawienia
  /// nie — dlatego przychodzi tu jako wywołanie zwrotne, tak jak przewodnik).
  final VoidCallback onOpenHelp;
  final ConfigService config;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _backups = BackupService();

  late final TextEditingController _eventName;
  late final TextEditingController _displayNames;
  late final TextEditingController _ceremony;
  late final TextEditingController _reception;
  late final TextEditingController _person1;
  late final TextEditingController _person2;
  late final TextEditingController _menu;
  late final TextEditingController _expenseCats;
  late final TextEditingController _witnessCount;
  late final TextEditingController _plannedBudget;
  late final TextEditingController _reserve;
  String _weddingDate = '';
  String _weddingTime = '16:00';

  /// Trwa składanie PDF-u z zaproszeniem (blokuje przycisk).
  bool _printing = false;

  /// Wybrany format wydruku karty z danymi dostępu.
  String _inviteFormat = 'A5';

  /// Typ uroczystości — steruje etykietami pary w całej aplikacji.
  CoupleType _coupleType = CoupleType.mixed;

  /// Czy na weselu będą dzieci (`budgetData.withChildren`).
  bool _withChildren = false;

  /// Waluta budżetu (`appConfig.currency`) — sam symbol, bez przeliczania.
  Currency _currency = Currency.fallback;

  /// Nazwiska do weryfikacji gościa (nigdzie nie wyświetlane).
  late final TextEditingController _surnames;

  /// Kod dołączenia dla gości (z `weddings/{id}.joinCode`). Null = jeszcze
  /// wczytywany/generowany.
  String? _joinCode;

  /// Token gościa (długi) do linku/QR strony web dla gości. Null = wczytywany.
  String? _guestToken;

  /// Trwa migracja/podgląd danych legacy (blokuje przyciski).
  bool _legacyBusy = false;

  /// Ostatni raport z migracji legacy (null = jeszcze nie uruchamiano).
  String? _legacyReport;

  @override
  void initState() {
    super.initState();
    final raw = widget.data?.raw ?? const {};
    final cfg = (raw['appConfig'] is Map)
        ? raw['appConfig'] as Map
        : const {};
    final bd = (raw['budgetData'] is Map) ? raw['budgetData'] as Map : const {};
    final couple = (bd['coupleNames'] is List) ? bd['coupleNames'] as List : const [];

    _eventName = TextEditingController(text: (cfg['eventName'] as String?) ?? '');
    _displayNames =
        TextEditingController(text: (cfg['displayNames'] as String?) ?? '');
    _ceremony =
        TextEditingController(text: (cfg['ceremonyPlace'] as String?) ?? '');
    _reception =
        TextEditingController(text: (cfg['receptionPlace'] as String?) ?? '');
    _person1 = TextEditingController(
        text: couple.isNotEmpty ? couple[0]?.toString() ?? '' : '');
    _person2 = TextEditingController(
        text: couple.length > 1 ? couple[1]?.toString() ?? '' : '');
    _menu = TextEditingController(
        text: (cfg['menuOptions'] is List)
            ? (cfg['menuOptions'] as List).join('\n')
            : '');
    _expenseCats = TextEditingController(
        text: (cfg['expenseCategories'] is List)
            ? (cfg['expenseCategories'] as List).join('\n')
            : '');
    final wc = (cfg['witnessCount'] is num)
        ? (cfg['witnessCount'] as num).toInt()
        : 2;
    _witnessCount = TextEditingController(text: '${wc < 1 ? 2 : wc}');
    final totalNum = (bd['total'] is num) ? (bd['total'] as num).toDouble() : 0.0;
    final reserveNum =
        (bd['reserve'] is num) ? (bd['reserve'] as num).toDouble() : 0.0;
    _plannedBudget =
        TextEditingController(text: totalNum == 0 ? '' : formatPln(totalNum));
    _reserve =
        TextEditingController(text: reserveNum == 0 ? '' : formatPln(reserveNum));
    _weddingDate = (raw['weddingDate'] as String?) ?? '';
    _weddingTime = (raw['weddingTime'] as String?) ?? '16:00';
    _coupleType = CoupleType.fromRaw(cfg['coupleType']);
    _surnames = TextEditingController(
        text: (cfg['verificationSurnames'] as String?) ?? '');
    _withChildren = bd['withChildren'] == true;
    _currency = Currency.fromRaw(cfg['currency']);
    _loadJoinCode(raw);
    _loadGuestToken(raw);
  }

  /// Wczytuje token gościa; gdy brak — generuje i synchronizuje publiczny
  /// mirror (best-effort — wymaga reguł strefy publicznej).
  Future<void> _loadGuestToken(Map raw) async {
    final existing = (raw['guestToken'] as String?)?.trim();
    if (existing != null && existing.isNotEmpty) {
      setState(() => _guestToken = existing);
    }
    try {
      final token =
          await WeddingService().ensureGuestToken(widget.firestore.weddingId);
      if (mounted) setState(() => _guestToken = token);
    } catch (_) {
      // Reguły strefy publicznej jeszcze niewdrożone — pokaż sam token, jeśli był.
    }
  }

  /// Buduje link do strony gości z tokenem.
  String _guestLink(String token) {
    final base = kIsWeb
        ? Uri.base.origin
        : PublicPages.baseUrl(widget.data?.raw);
    return '$base/?t=$token';
  }

  /// Wczytuje kod dołączenia; gdy brak (starsze wesele) — generuje i zapisuje.
  Future<void> _loadJoinCode(Map raw) async {
    final existing = (raw['joinCode'] as String?)?.trim();
    if (existing != null && existing.isNotEmpty) {
      setState(() => _joinCode = existing);
      return;
    }
    try {
      final code =
          await WeddingService().ensureJoinCode(widget.firestore.weddingId);
      if (mounted) setState(() => _joinCode = code);
    } catch (_) {
      // Ciche niepowodzenie — karta pokaże stan „—".
    }
  }

  @override
  void dispose() {
    for (final c in [
      _eventName, _displayNames, _ceremony, _reception,
      _person1, _person2, _menu, _expenseCats, _witnessCount,
      _plannedBudget, _reserve, _surnames,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  List<String> _lines(TextEditingController c) =>
      c.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  Future<void> _saveConfig() async {
    await widget.config.saveConfig(AppConfigDraft(
      eventName: _eventName.text.trim(),
      displayNames: _displayNames.text.trim(),
      ceremonyPlace: _ceremony.text.trim(),
      receptionPlace: _reception.text.trim(),
      weddingDate: _weddingDate,
      weddingTime: _weddingTime,
      person1: _person1.text.trim(),
      person2: _person2.text.trim(),
      menuOptions: _lines(_menu),
      expenseCategories: _lines(_expenseCats),
      witnessCount: int.tryParse(_witnessCount.text.trim()) ?? 2,
      coupleType: _coupleType,
      verificationSurnames: _surnames.text.trim(),
      withChildren: _withChildren,
    ));
    // Odśwież publiczny indeks kodu + mirror gościa (data/nazwisko/harmonogram).
    try {
      final ws = WeddingService();
      await ws.ensureJoinCode(widget.firestore.weddingId);
      await ws.ensureGuestToken(widget.firestore.weddingId);
    } catch (_) {}
    _toast(AppText.t.settings_configSaved);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      AppText.t.settings_tabWedding,
      AppText.t.settings_tabGuests,
      AppText.t.settings_tabAccount,
      AppText.t.settings_tabApp,
      AppText.t.settings_tabHelp,
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text(AppText.t.settings_title,
                style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text)),
          ),
          const SizedBox(height: 12),
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textLight,
            indicatorColor: AppColors.accent,
            dividerColor: const Color(0xFFE2EAF7),
            labelStyle:
                GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle:
                GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
            tabs: [for (final t in tabs) Tab(text: t)],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _tabList([
                  _configCard(),
                  _budgetSettingsCard(),
                  _childrenDataCard(),
                  _syncCard(),
                  if (widget.isOwner) _legacyMigrationCard(),
                ]),
                _tabList([
                  _guestInteractionsCard(),
                  _guestLinkCard(),
                  _joinCodeCard(),
                  _invitationsCard(),
                  _guestVisibilityCard(),
                ]),
                _tabList([
                  _loginCard(),
                  // „Osoby i dostęp" — TYLKO dla właściciela (owner).
                  if (widget.isOwner) _peopleAccessCard(),
                  _accessCard(),
                ]),
                _tabList([
                  _languageCard(),
                  _displayModeCard(),
                  _notificationsCard(),
                ]),
                _tabList([
                  _helpCard(),
                  _devCard(),
                ]),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onSignOut,
                icon: const Icon(Icons.logout),
                label: Text(AppText.t.settings_logoutButton),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFC0392B),
                  side: const BorderSide(color: Color(0xFFE9A8A8)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Lista kart jednej podzakładki Ustawień — spójny odstęp, bez powtarzania
  /// `SizedBox` między każdą kartą przy wywołaniu.
  Widget _tabList(List<Widget> cards) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        children: [
          for (final c in cards) ...[c, const SizedBox(height: 12)],
        ],
      );

  Widget _syncCard() {
    final ok = widget.data != null;
    return _card(
      AppText.t.settings_syncCard,
      Row(
        children: [
          Icon(ok ? Icons.cloud_done_outlined : Icons.cloud_sync_outlined,
              color: ok ? const Color(0xFF059669) : AppColors.textLight),
          const SizedBox(width: 8),
          Text(ok ? AppText.t.settings_syncOk : AppText.t.settings_syncConnecting,
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _helpCard() {
    return _card(
      AppText.t.settings_guideCard,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppText.t.settings_guideHint,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onStartTour,
              icon: const Text('🧭', style: TextStyle(fontSize: 16)),
              label: Text(AppText.t.settings_tourButton),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onOpenHelp,
              icon: const Icon(Icons.help_outline, size: 18),
              label: Text(AppText.t.settings_helpOpen),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onOpenPlanning,
              icon: const Text('📋', style: TextStyle(fontSize: 16)),
              label: Text(AppLocalizations.of(context).settings_planningButton),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onOpenSetupWizard,
              icon: const Text('🤝', style: TextStyle(fontSize: 16)),
              label: Text(AppLocalizations.of(context).settings_setupWizardButton),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Jednorazowa migracja kolekcji legacy (`gallery`, `guestbook`, `advices`,
  /// `guestMap`, `timeCapsule`, wyniki gier) do modelu wielu wesel — dokłada
  /// `weddingId` do dokumentów, które go nie mają.
  ///
  /// ⚠️ Uruchomić PRZED wdrożeniem nowych reguł: nowe reguły blokują zapis
  /// dokumentu bez `weddingId`, więc później migracja już nie przejdzie.
  Widget _legacyMigrationCard() {
    return _card(
      AppText.t.settings_legacyCard,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppText.t.settings_legacyHint,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
          ),
          const SizedBox(height: 6),
          Text(
            AppText.t.settings_legacyBefore,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFC0392B)),
          ),
          if (_legacyReport != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bgGradient.last,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _legacyReport!,
                style: GoogleFonts.robotoMono(
                    fontSize: 12, color: AppColors.text),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _legacyBusy ? null : _legacyDryRun,
                  icon: const Icon(Icons.search, size: 18),
                  label: Text(AppText.t.settings_legacyCheck),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _legacyBusy ? null : _legacyMigrate,
                  icon: const Icon(Icons.move_down, size: 18),
                  label: Text(AppText.t.settings_legacyMigrate),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _legacySummary(List<LegacyMigrationResult> res, {required bool dry}) {
    final lines = <String>[];
    for (final r in res) {
      if (!r.ok) {
        lines.add(AppText.t.settings_legacyError(r.collection, '${r.error}'));
      } else if (dry) {
        lines.add(AppText.t.settings_legacyToDo(r.collection, r.stamped, r.skipped));
      } else {
        lines.add(AppText.t.settings_legacyDone(r.collection, r.stamped, r.skipped));
      }
    }
    return lines.join('\n');
  }

  Future<void> _legacyDryRun() async {
    setState(() => _legacyBusy = true);
    try {
      final res = await LegacyMigrationService().dryRun();
      if (!mounted) return;
      setState(() => _legacyReport = _legacySummary(res, dry: true));
    } catch (e) {
      if (mounted) _toast(AppText.t.settings_legacyCheckFailed('$e'));
    } finally {
      if (mounted) setState(() => _legacyBusy = false);
    }
  }

  Future<void> _legacyMigrate() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppText.t.settings_legacyConfirmTitle),
        content: Text(
          AppText.t.settings_legacyConfirmBody,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppText.t.common_cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(AppText.t.settings_legacyAssign)),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _legacyBusy = true);
    try {
      final res = await LegacyMigrationService().run();
      if (!mounted) return;
      setState(() => _legacyReport = _legacySummary(res, dry: false));
      _toast(AppText.t.settings_legacyFinished);
    } catch (e) {
      if (mounted) _toast(AppText.t.settings_legacyFailed('$e'));
    } finally {
      if (mounted) setState(() => _legacyBusy = false);
    }
  }

  /// Język interfejsu i waluta budżetu.
  ///
  /// Język jest preferencją UŻYTKOWNIKA (lokalnie, per konto), waluta —
  /// ustawieniem WESELA (w chmurze, wspólne dla wszystkich organizatorów).
  /// Dlatego zapisują się w różne miejsca, mimo że stoją na jednej karcie.
  Widget _languageCard() {
    final t = AppLocalizations.of(context);
    return _card(
      t.settings_languageCard,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.settings_language,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text)),
          const SizedBox(height: 2),
          Text(t.settings_languageHint,
              style: GoogleFonts.inter(
                  fontSize: 11.5, color: AppColors.textLight)),
          const SizedBox(height: 8),
          ValueListenableBuilder<Locale?>(
            valueListenable: LocaleController.locale,
            builder: (context, current, _) => Column(
              children: [
                _languageOption(t.settings_languageSystem, null, current),
                for (final locale in LocaleController.supported)
                  _languageOption(
                      languageName(t, locale.languageCode), locale, current),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(t.settings_currency,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text)),
          const SizedBox(height: 2),
          Text(t.settings_currencyHint,
              style: GoogleFonts.inter(
                  fontSize: 11.5, height: 1.4, color: AppColors.textLight)),
          const SizedBox(height: 8),
          DropdownButtonFormField<Currency>(
            initialValue: _currency,
            isExpanded: true,
            decoration: const InputDecoration(isDense: true),
            items: [
              for (final c in Currency.values)
                DropdownMenuItem(
                  value: c,
                  child: Text('${c.symbol}  ${c.label} (${c.code})'),
                ),
            ],
            onChanged: (c) async {
              if (c == null) return;
              setState(() => _currency = c);
              await widget.config.saveCurrency(c);
              _toast(AppText.t.settings_currencyToast(c.code));
            },
          ),
        ],
      ),
    );
  }

  Widget _languageOption(String label, Locale? value, Locale? current) {
    final selected = current?.languageCode == value?.languageCode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => LocaleController.set(_dmUid, value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.accent : const Color(0xFFDCE4F2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 18,
                color: selected ? AppColors.accent : AppColors.textLight,
              ),
              const SizedBox(width: 10),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: AppColors.text)),
            ],
          ),
        ),
      ),
    );
  }

  /// Wybór układu: automatyczny (wg szerokości ekranu) albo wymuszony.
  ///
  /// Zapis jest lokalny i per użytkownik — to preferencja urządzenia, a nie
  /// dana wesela, więc nie ma powodu trzymać jej w chmurze.
  Widget _displayModeCard() {
    return _card(
      AppText.t.settings_displayModeCard,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppText.t.settings_displayModeHint,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<DisplayMode>(
            valueListenable: DisplayModeController.mode,
            builder: (context, current, _) => Column(
              children: [
                for (final m in DisplayMode.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => DisplayModeController.set(_dmUid, m),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: current == m
                              ? AppColors.accent.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: current == m
                                ? AppColors.accent
                                : const Color(0xFFDCE4F2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              current == m
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              size: 20,
                              color: current == m
                                  ? AppColors.accent
                                  : AppColors.textLight,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.label,
                                      style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.text)),
                                  Text(m.hint,
                                      style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          color: AppColors.textLight)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Identyfikator do zapisu preferencji układu (ten sam, którego panel używa
  /// do konfiguracji nawigacji).
  String get _dmUid => widget.currentUserId;

  Widget _guestInteractionsCard() {
    final token = _guestToken;
    return _card(
      AppText.t.settings_interactionsCard,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppText.t.settings_interactionsHint,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: token == null
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              GuestInteractionsScreen(guestToken: token),
                        ),
                      ),
              icon: const Icon(Icons.forum_outlined, size: 18),
              label: Text(token == null
                  ? AppText.t.settings_loading
                  : AppText.t.settings_interactionsOpen),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _guestLinkCard() {
    final token = _guestToken;
    final link = token == null ? null : _guestLink(token);
    return _card(
      AppText.t.settings_guestLinkCard,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppText.t.settings_guestLinkHint,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
          ),
          const SizedBox(height: 14),
          if (link == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.accent),
                ),
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        link,
                        style: GoogleFonts.robotoMono(
                            fontSize: 12, color: AppColors.text),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: link));
                              _toast(AppText.t.settings_guestLinkCopied);
                            },
                            icon: const Icon(Icons.copy, size: 16),
                            label: Text(AppText.t.settings_copyLink),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.accent,
                              side: const BorderSide(color: AppColors.accent),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2EAF7)),
                      ),
                      child: QrImageView(
                        data: link,
                        size: 104,
                        eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF1040B0)),
                        dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF1040B0)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(AppText.t.settings_qrCode,
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textLight)),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _peopleAccessCard() {
    return _card(
      AppText.t.settings_peopleCard,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppText.t.settings_peopleHint,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PeopleAccessScreen(
                    weddingId: widget.firestore.weddingId,
                    currentUserId: widget.currentUserId,
                  ),
                ),
              ),
              icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
              label: Text(AppText.t.settings_peopleOpen),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Nazwisko, którego gość ma użyć przy dołączaniu.
  ///
  /// Pierwszeństwo ma dedykowane pole weryfikacji; gdy jest puste, weryfikacja
  /// nadal przyjmuje „Osoby" — pokazujemy więc to, co realnie zadziała.
  String get _verificationValue {
    final raw = widget.data?.raw ?? const {};
    final cfg = (raw['appConfig'] is Map) ? raw['appConfig'] as Map : const {};
    final surnames = (cfg['verificationSurnames'] as String?)?.trim() ?? '';
    if (surnames.isNotEmpty) return surnames;
    return (cfg['displayNames'] as String?)?.trim() ?? '';
  }

  /// Czy organizator uzupełnił dedykowane pole nazwiska.
  bool get _hasVerificationSurnames {
    final raw = widget.data?.raw ?? const {};
    final cfg = (raw['appConfig'] is Map) ? raw['appConfig'] as Map : const {};
    return ((cfg['verificationSurnames'] as String?)?.trim() ?? '').isNotEmpty;
  }

  /// Data ślubu w formie czytelnej dla gościa („12 czerwca 2027").
  ///
  /// Nazwy miesięcy idą z `intl`, więc po przełączeniu języka zaproszenie
  /// dla gościa też jest w tym języku.
  String get _weddingDateLabel =>
      AppFormat.dateLongFromIso(_weddingDate) ?? '';

  /// Gotowy tekst zaproszenia do wysłania gościom.
  String _inviteText(String code) {
    final date = _weddingDateLabel;
    return [
      AppText.t.settings_inviteTextHeader,
      '',
      AppText.t.settings_inviteTextStep1,
      AppText.t.settings_inviteTextStep2,
      AppText.t.settings_inviteTextStep3,
      AppText.t.settings_inviteTextCode(JoinCode.format(code)),
      if (date.isNotEmpty) AppText.t.settings_inviteTextDate(date),
      if (_verificationValue.isNotEmpty)
        AppText.t.settings_inviteTextSurname(_verificationValue),
      '',
      AppText.t.settings_inviteTextQr,
    ].join('\n');
  }

  Widget _joinCodeCard() {
    final code = _joinCode;
    return _card(
      AppText.t.settings_inviteCard,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppText.t.settings_inviteHint,
            style: GoogleFonts.inter(
                fontSize: 13, height: 1.45, color: AppColors.textLight),
          ),
          const SizedBox(height: 14),
          if (code == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.accent),
                ),
              ),
            )
          else
            Row(
              children: [
                // Kod + przycisk kopiowania
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.accent, width: 1.4),
                        ),
                        // Kod w grupach po cztery znaki — 12 znaków ciągiem
                        // przepisuje się z kartki dużo gorzej. Myślniki są
                        // wyłącznie wizualne; weryfikacja i tak je zdejmuje.
                        child: Text(
                          JoinCode.format(code),
                          style: GoogleFonts.robotoMono(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(AppText.t.invite_codeGroupHint,
                          style: GoogleFonts.inter(
                              fontSize: 10.5,
                              height: 1.35,
                              color: AppColors.textLight)),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          // Do schowka trafia postać czytelna — po wklejeniu
                          // w aplikacji separatory i tak zostaną zdjęte.
                          final pretty = JoinCode.format(code);
                          Clipboard.setData(ClipboardData(text: pretty));
                          _toast(AppText.t.settings_codeCopied(pretty));
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: Text(AppText.t.settings_copyCode),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          side: const BorderSide(color: AppColors.accent),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // QR z kodem
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2EAF7)),
                      ),
                      child: QrImageView(
                        data: code,
                        size: 96,
                        eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF1040B0)),
                        dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF1040B0)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(AppText.t.settings_qrCode,
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textLight)),
                    SizedBox(
                      width: 96,
                      child: Text(AppText.t.settings_qrScanHint,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                              fontSize: 10, color: AppColors.textLight)),
                    ),
                  ],
                ),
              ],
            ),
          if (code != null) ...[
            const SizedBox(height: 18),
            _inviteDataBlock(),
            const SizedBox(height: 16),
            _guestStepsBlock(),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _inviteText(code)));
                  _toast(AppText.t.settings_inviteCopied);
                },
                icon: const Icon(Icons.content_paste, size: 16),
                label: Text(AppText.t.settings_copyInvite),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _invitationPrintBlock(code),
          ],
        ],
      ),
    );
  }

  /// Wydruk karty z danymi dostępu — do włożenia do zaproszenia.
  ///
  /// Korzysta DOKŁADNIE z tych samych danych, które organizator widzi wyżej
  /// na tej karcie (kod, data, nazwisko weryfikacyjne, kod QR), więc wydruk
  /// nie może się rozjechać z tym, co pokazuje aplikacja.
  Widget _invitationPrintBlock(String code) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppText.t.invite_printHint,
            style: GoogleFonts.inter(
                fontSize: 11.5, height: 1.4, color: AppColors.textLight)),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(AppText.t.invite_printFormat,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textLight)),
            const SizedBox(width: 10),
            for (final f in _invitationFormats.keys) ...[
              ChoiceChip(
                label: Text(f),
                selected: _inviteFormat == f,
                onSelected: (_) => setState(() => _inviteFormat = f),
                labelStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _inviteFormat == f
                        ? AppColors.accent
                        : AppColors.textLight),
                selectedColor: AppColors.accent.withValues(alpha: 0.12),
              ),
              const SizedBox(width: 6),
            ],
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _printing ? null : () => _printInvitation(code),
            icon: _printing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.print_outlined, size: 18),
            label: Text(AppText.t.invite_printButton),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
      ],
    );
  }

  /// Formaty wydruku. A5 domyślnie — wchodzi do koperty na zaproszenie.
  static final Map<String, PdfPageFormat> _invitationFormats = {
    'A5': PdfPageFormat.a5,
    'A6': PdfPageFormat.a6,
    'A4': PdfPageFormat.a4,
  };

  Future<void> _printInvitation(String code) async {
    setState(() => _printing = true);
    try {
      final bytes = await PdfService.guestInvitation(
        // Na wydruku kod grupowany, w QR surowy — czytnik nie ma potrzeby
        // rozbierać separatorów.
        code: JoinCode.format(code),
        qrData: code,
        eventName: _eventName.text.trim(),
        persons: _displayNames.text.trim(),
        weddingDate: _weddingDateLabel,
        surname: _verificationValue,
        format: _invitationFormats[_inviteFormat] ?? PdfPageFormat.a5,
      );
      await PdfService.preview(bytes, AppText.t.invite_printFileName);
    } catch (e) {
      if (mounted) _toast(AppText.t.invite_printError('$e'));
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  /// Komplet danych, których potrzebuje gość — dokładnie te trzy pola widzi
  /// on na ekranie „Dołącz do wesela" (#23).
  Widget _inviteDataBlock() {
    final date = _weddingDateLabel;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppText.t.settings_inviteDataTitle,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text)),
          const SizedBox(height: 10),
          _inviteRow(AppText.t.settings_weddingCode,
              _joinCode == null
                  ? AppText.t.common_none
                  : JoinCode.format(_joinCode!)),
          _inviteRow(
            AppText.t.settings_weddingDate,
            date.isEmpty ? AppText.t.settings_notSet : date,
            missing: date.isEmpty,
          ),
          _inviteRow(
            AppText.t.settings_coupleSurname,
            _verificationValue.isEmpty ? AppText.t.settings_notSet : _verificationValue,
            missing: _verificationValue.isEmpty,
          ),
          if (!_hasVerificationSurnames) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCD9A6)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: Color(0xFFB45309)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _verificationValue.isEmpty
                          ? AppText.t.settings_surnameMissing
                          : AppText.t.settings_surnameFallback,
                      style: GoogleFonts.inter(
                          fontSize: 11.5,
                          height: 1.4,
                          color: const Color(0xFF7C4A03)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _inviteRow(String label, String value, {bool missing = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textLight)),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontStyle: missing ? FontStyle.italic : FontStyle.normal,
                color: missing ? const Color(0xFFB45309) : AppColors.text,
              ),
            ),
          ),
          if (!missing)
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                _toast(AppText.t.settings_copiedValue(value));
              },
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.copy, size: 15, color: AppColors.accent),
              ),
            ),
        ],
      ),
    );
  }

  /// Instrukcja krok po kroku — w kolejności, w jakiej gość faktycznie klika.
  Widget _guestStepsBlock() {
    final steps = [
      AppText.t.settings_joinStep1,
      AppText.t.settings_joinStep2,
      AppText.t.settings_joinStep3,
      AppText.t.settings_joinStep4,
      AppText.t.settings_joinStep5,
      AppText.t.settings_joinStep6,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppText.t.settings_joinStepsTitle,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.text)),
        const SizedBox(height: 8),
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Text('${i + 1}',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(steps[i],
                      style: GoogleFonts.inter(
                          fontSize: 12.5,
                          height: 1.45,
                          color: AppColors.textLight)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Tryb zapraszania gości (wspólny link / kod per zaproszenie).
  ///
  /// Sąsiaduje z „Zaproszenie dla gości" i „Link i QR dla gości", bo dotyczy
  /// tego samego: jak gość trafia do swojej strefy.
  Widget _invitationsCard() {
    return _card(
      AppText.t.settings_invitesCard,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppText.t.settings_invitesHint,
            style: GoogleFonts.inter(
                fontSize: 13, height: 1.45, color: AppColors.textLight),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => InvitationsScreen(
                    raw: widget.data?.raw ?? const {},
                    config: widget.config,
                  ),
                ),
              ),
              icon: const Icon(Icons.qr_code_2, size: 18),
              label: Text(AppText.t.settings_invitesOpen),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _guestVisibilityCard() {
    return _card(
      AppText.t.settings_visibilityCard,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppText.t.settings_visibilityHint,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GuestVisibilityScreen(
                    firestore: widget.firestore,
                    raw: widget.data?.raw ?? const {},
                  ),
                ),
              ),
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: Text(AppText.t.settings_visibilityOpen),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Ustawienia przyszłych powiadomień push. Dzwoneczek w aplikacji działa
  /// niezależnie — mówi o tym sam ekran.
  Widget _notificationsCard() {
    return _card(
      AppText.t.settings_notificationsCard,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppText.t.settings_notificationsHint,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      NotificationSettingsScreen(uid: widget.currentUserId),
                ),
              ),
              icon: const Icon(Icons.notifications_none, size: 18),
              label: Text(AppText.t.settings_notificationsOpen),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginCard() {
    return _card(
      AppText.t.settings_securityCard,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppText.t.settings_securityHint,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const SecuritySettingsScreen()),
              ),
              icon: const Icon(Icons.fingerprint, size: 18),
              label: Text(AppText.t.settings_securityOpen),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _configCard() {
    return _card(
      AppText.t.settings_configCard,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Publiczny indeks kodu dołączenia (weddingCodes) może odświeżyć tylko
          // owner — reguły celowo nie dają tego planerowi ani współorganizatorowi.
          if (!widget.isOwner)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                AppText.t.settings_configOwnerHint,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFC0392B)),
              ),
            ),
          // ── Typ uroczystości — steruje etykietami pary w całej aplikacji ──
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(AppText.t.settings_coupleType,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text)),
          ),
          DropdownButtonFormField<CoupleType>(
            initialValue: _coupleType,
            isExpanded: true,
            decoration: const InputDecoration(isDense: true),
            items: [
              for (final t in CoupleType.values)
                DropdownMenuItem(value: t, child: Text(t.label)),
            ],
            onChanged: (v) =>
                setState(() => _coupleType = v ?? CoupleType.mixed),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Text(
              AppText.t.settings_coupleTypeHint(_coupleType.hint),
              style: GoogleFonts.inter(
                  fontSize: 11.5, color: AppColors.textLight),
            ),
          ),
          _field(AppText.t.settings_eventName, _eventName),
          _field(AppText.t.settings_persons, _displayNames),
          // Nazwiska służą WYŁĄCZNIE weryfikacji gościa przy dołączaniu kodem —
          // nigdzie ich nie pokazujemy. Bez tego pola gość wpisujący nazwisko
          // był odrzucany, bo „Osoby" zawierają imiona (zgłoszenie #23).
          _field(AppText.t.settings_verificationSurnames, _surnames),
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 2),
            child: Text(
              AppText.t.settings_verificationHint,
              style: GoogleFonts.inter(
                  fontSize: 11.5, color: AppColors.textLight),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _pickerField(AppText.t.settings_weddingDate,
                    _weddingDate.isEmpty ? AppText.t.common_select : _weddingDate, _pickDate),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _pickerField(AppText.t.settings_time, _weddingTime, _pickTime),
              ),
            ],
          ),
          _field(AppText.t.settings_ceremonyPlace, _ceremony),
          _field(AppText.t.settings_receptionPlace, _reception),
          Row(
            children: [
              Expanded(child: _field(AppText.t.settings_person1, _person1)),
              const SizedBox(width: 12),
              Expanded(child: _field(AppText.t.settings_person2, _person2)),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _field(AppText.t.settings_witnesses, _witnessCount,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    AppText.t.settings_witnessesHint,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textLight),
                  ),
                ),
              ),
            ],
          ),
          // Dzieci na weselu — ta sama flaga co w Budżet → Sala, tutaj tylko
          // wystawiona w widocznym miejscu. Ceny menu dziecięcego zostają
          // w Budżecie, żeby nie rozdzielać szczegółów cenowych na dwa ekrany.
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.accent,
            title: Text(AppText.t.settings_children,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: Text(
              _withChildren
                  ? AppText.t.settings_childrenHint
                  : AppText.t.settings_childrenSwitch,
              style:
                  GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
            ),
            value: _withChildren,
            onChanged: (v) => setState(() => _withChildren = v),
          ),
          const SizedBox(height: 8),
          _field(AppText.t.settings_menuDict, _menu, maxLines: 4),
          _field(AppText.t.settings_expenseCategories, _expenseCats,
              maxLines: 4),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveConfig,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(AppText.t.settings_saveConfig),
            ),
          ),
        ],
      ),
    );
  }

  Widget _budgetSettingsCard() {
    return _card(
      AppText.t.settings_budgetCard,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppText.t.settings_budgetHint,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _field(AppText.t.settings_budgetPlanned(AppFormat.currency.symbol), _plannedBudget,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(AppText.t.settings_budgetReserve(AppFormat.currency.symbol), _reserve,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveBudgetSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(AppText.t.settings_budgetSave),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBudgetSettings() async {
    final planned = parsePln(_plannedBudget.text) ?? 0;
    final reserve = parsePln(_reserve.text) ?? 0;
    try {
      await widget.config
          .saveBudgetSettings(plannedBudget: planned, reserve: reserve);
      _toast(AppText.t.settings_budgetSaved);
    } catch (e) {
      _toast(AppText.t.common_saveErrorToast('$e'));
    }
  }

  /// Karta „Dane o dzieciach" — jedyne miejsce TRWAŁEGO usunięcia (w
  /// odróżnieniu od przełącznika „wesele z dziećmi" w Budżecie, który tylko
  /// ukrywa dane, nic nie kasując — patrz [ChildrenSettings]).
  Widget _childrenDataCard() {
    final bd = widget.data?.raw['budgetData'];
    final budget = bd is Map ? bd : const <String, dynamic>{};
    final guests = widget.data?.guests ?? const [];
    final children = ChildrenSettings.from(budget, guests);
    final hasData = children.fromGuests > 0 || children.manualCount > 0;

    return _card(
      AppText.t.settings_childrenDataCard,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppText.t.settings_childrenDataHint,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
          ),
          const SizedBox(height: 8),
          Text(
            AppText.t.settings_childrenDataCount('${children.fromGuests}'),
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: hasData ? _confirmDeleteChildrenData : null,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(AppText.t.settings_childrenDataButton),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFC0392B),
                side: const BorderSide(color: Color(0xFFE9A8A8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteChildrenData() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(AppText.t.settings_childrenDataConfirmTitle,
            style: GoogleFonts.playfairDisplay(
                fontSize: 18, fontWeight: FontWeight.w700)),
        content: Text(AppText.t.settings_childrenDataConfirmBody,
            style: GoogleFonts.inter(fontSize: 13.5, height: 1.45)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppText.t.common_cancel),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: const Color(0xFFC0392B)),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppText.t.settings_childrenDataConfirmButton),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await GuestService(firestore: widget.firestore).clearChildrenData();
      if (mounted) _toast(AppText.t.settings_childrenDataDeleted);
    } catch (e) {
      if (mounted) _toast(AppText.t.common_saveErrorToast('$e'));
    }
  }

  Widget _accessCard() {
    return _card(
      AppText.t.settings_accessCard,
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.group_add_outlined,
              size: 18, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppText.t.settings_accessHint,
              style: GoogleFonts.inter(
                  fontSize: 13, height: 1.45, color: AppColors.textLight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _devCard() {
    return _card(
      AppText.t.settings_devCard,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _exportData,
                icon: const Icon(Icons.ios_share, size: 18),
                label: Text(AppText.t.settings_exportData),
                style: _devBtnStyle(),
              ),
              OutlinedButton.icon(
                onPressed: _importData,
                icon: const Icon(Icons.file_download_outlined, size: 18),
                label: Text(AppText.t.settings_importData),
                style: _devBtnStyle(),
              ),
              OutlinedButton.icon(
                onPressed: _createBackup,
                icon: const Icon(Icons.backup_outlined, size: 18),
                label: Text(AppText.t.settings_backupCreate),
                style: _devBtnStyle(),
              ),
              OutlinedButton.icon(
                onPressed: _showBackups,
                icon: const Icon(Icons.history, size: 18),
                label: Text(AppText.t.settings_backupsCard),
                style: _devBtnStyle(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(AppText.t.settings_backupsHint,
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.textLight)),
        ],
      ),
    );
  }

  ButtonStyle _devBtnStyle() => OutlinedButton.styleFrom(
        foregroundColor: AppColors.accent,
        side: const BorderSide(color: AppColors.accent),
      );

  Future<void> _exportData() async {
    final data = await widget.config.exportData();
    final json = const JsonEncoder.withIndent('  ')
        .convert(_jsonSafe(data));
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppText.t.settings_exportTitle),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(json,
                style: GoogleFonts.robotoMono(fontSize: 11)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: json));
              _toast(AppText.t.common_copiedToast);
            },
            child: Text(AppText.t.common_copy),
          ),
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppText.t.common_close)),
        ],
      ),
    );
  }

  Future<void> _importData() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppText.t.settings_importData),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppText.t.settings_importWarning,
                style: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFFC0392B)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                maxLines: 8,
                decoration: InputDecoration(
                    hintText: AppText.t.settings_importHint, border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppText.t.common_cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC0392B)),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppText.t.settings_importButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final decoded = jsonDecode(controller.text);
      if (decoded is! Map) {
        _toast(AppText.t.settings_importBadFormat);
        return;
      }
      await widget.config.importData(Map<String, dynamic>.from(decoded));
      _toast(AppText.t.settings_importDone);
    } catch (e) {
      _toast(AppText.t.settings_importFailed('$e'));
    }
  }

  Future<void> _createBackup() async {
    final data = await widget.config.exportData();
    await _backups.create(_jsonSafe(data));
    _toast(AppText.t.settings_backupCreated);
  }

  Future<void> _showBackups() async {
    final list = await _backups.list();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      constraints: const BoxConstraints(maxWidth: kSheetMaxWidth),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(AppText.t.settings_backupsCard,
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            if (list.isEmpty)
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(AppText.t.settings_backupsEmpty),
              )
            else
              for (final b in list)
                ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(_fmtDate(b.timestamp)),
                  trailing: TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _restoreBackup(b);
                    },
                    child: Text(AppText.t.settings_backupRestore),
                  ),
                ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _restoreBackup(Backup b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppText.t.settings_backupRestoreTitle),
        content: Text(
            AppText.t.settings_backupRestoreBody(_fmtDate(b.timestamp))),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppText.t.common_cancel)),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(AppText.t.settings_backupRestore)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final data = await _backups.decode(b);
      await widget.config.importData(data);
      _toast(AppText.t.settings_backupRestored);
    } catch (e) {
      _toast(AppText.t.settings_backupRestoreFailed('$e'));
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_weddingDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _weddingDate =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _pickTime() async {
    final parts = _weddingTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.isNotEmpty ? parts[0] : '16') ?? 16,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() => _weddingTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
    }
  }

  Widget _field(String label, TextEditingController c,
      {int maxLines = 1,
      TextInputType? keyboardType,
      List<TextInputFormatter>? inputFormatters}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 2),
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text)),
          ),
          TextField(
            controller: c,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            decoration: _dec(),
          ),
        ],
      ),
    );
  }

  Widget _pickerField(String label, String value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 2),
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text)),
          ),
          InkWell(
            onTap: onTap,
            child: InputDecorator(
              decoration: _dec(),
              child: Text(value,
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.text)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec() => InputDecoration(
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF8FAFF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDCE4F2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDCE4F2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
      );

  Widget _card(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  /// Zamienia wartości nieserializowalne do JSON (np. Timestamp) na stringi.
  Map<String, dynamic> _jsonSafe(Map<String, dynamic> data) {
    final encoded = jsonEncode(data, toEncodable: (o) => o.toString());
    return jsonDecode(encoded) as Map<String, dynamic>;
  }
}
