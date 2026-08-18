import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/wedding_summary.dart';
import '../../services/user_service.dart';
import '../../services/wedding_service.dart';
import 'create_wedding_sheet.dart';
import 'join_wedding_screen.dart';
import '../../utils/app_format.dart';
import '../../l10n/app_text.dart';
import '../../models/join_code.dart';

/// Ekran „Twoje wesela" — pokazywany po wejściu do aplikacji, przed panelem.
///
/// Lista wesel, do których użytkownik ma dostęp (z jego członkostw) oraz
/// przycisk „+ Nowe wesele". Wybór wesela ustawia aktywne `weddingId`
/// (przez [onOpen]) i wczytuje jego dane w panelu głównym.
class WeddingsListScreen extends StatefulWidget {
  const WeddingsListScreen({
    super.key,
    required this.userId,
    required this.onOpen,
    this.displayName,
    this.email,
    this.onSignOut,
  });

  /// Identyfikator zalogowanego użytkownika (uid).
  final String userId;

  /// Wywoływane po wyborze wesela — przekazuje `weddingId` i rolę użytkownika
  /// w tym weselu ('owner'/'planner'/'collaborator'/'guest').
  final void Function(String weddingId, String role) onOpen;

  final String? displayName;
  final String? email;

  /// Opcjonalne wylogowanie (pokazuje przycisk w nagłówku, gdy podane).
  final VoidCallback? onSignOut;

  @override
  State<WeddingsListScreen> createState() => _WeddingsListScreenState();
}

class _WeddingsListScreenState extends State<WeddingsListScreen> {
  final WeddingService _weddings = WeddingService();
  final UserService _users = UserService();

  late Future<List<WeddingSummary>> _future;

  @override
  void initState() {
    super.initState();
    // Upewnij się, że profil użytkownika istnieje (users/{uid}).
    _users.ensureUser(
      uid: widget.userId,
      displayName: widget.displayName,
      email: widget.email,
    );
    _future = _load();
  }

  Future<List<WeddingSummary>> _load() =>
      _weddings.listForUser(widget.userId);

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _createWedding() async {
    final draft = await showCreateWeddingSheet(context);
    if (draft == null || !mounted) return;

    String weddingId;
    try {
      weddingId = await _weddings.createWedding(
        userId: widget.userId,
        name: draft.name,
        persons: draft.persons,
        date: draft.date,
        coupleType: draft.coupleType,
        person1: draft.person1,
        person2: draft.person2,
        withChildren: draft.withChildren,
        childrenCount: draft.childrenCount,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(AppText.t.wl_createFailed('$e'))));
      return;
    }
    if (!mounted) return;
    // Od razu otwieramy nowo utworzone wesele (twórca = owner).
    widget.onOpen(weddingId, 'owner');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGradient.last,
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
              _header(),
              Expanded(
                child: FutureBuilder<List<WeddingSummary>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation(AppColors.accent),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return _errorState(snapshot.error);
                    }
                    final weddings = snapshot.data ?? const [];
                    if (weddings.isEmpty) return _emptyState();
                    return _list(weddings);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _actionBar(),
    );
  }

  /// Dwa główne przyciski: „Załóż wesele" (tworzy nowe) i „Dołącz do wesela"
  /// (placeholder — pełne dołączanie kodem w kroku 4b).
  Widget _actionBar() {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _createWedding,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              icon: const Text('➕', style: TextStyle(fontSize: 15)),
              label: Text(
                AppText.t.wl_create,
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _joinWedding,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Text('🔗', style: TextStyle(fontSize: 15)),
              label: Text(
                AppText.t.jw_title,
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _claimInvite,
            icon: const Icon(Icons.vpn_key_outlined, size: 16),
            label: Text(AppText.t.wl_haveCodeLong),
            style: TextButton.styleFrom(foregroundColor: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  /// Odbieranie zaproszenia kodem (współorganizator/planer) — kod od Pary Młodej.
  Future<void> _claimInvite() async {
    final codeCtrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(AppText.t.wl_haveCode,
            style: GoogleFonts.playfairDisplay(
                fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppText.t.wl_haveCodeBody,
              style:
                  GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              textCapitalization: TextCapitalization.characters,
              style: GoogleFonts.robotoMono(
                  fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 2),
              decoration: InputDecoration(
                hintText: AppText.t.jw_codeHint,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppText.t.common_cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: () =>
                Navigator.of(context).pop(JoinCode.normalize(codeCtrl.text)),
            child: Text(AppText.t.wl_redeem),
          ),
        ],
      ),
    );
    if (code == null || code.isEmpty || !mounted) return;

    final result = await _weddings.claimRoleInvite(
      userId: widget.userId,
      email: widget.email ?? '',
      displayName: widget.displayName ?? '',
      code: code,
    );
    if (!mounted) return;
    switch (result.outcome) {
      case ClaimOutcome.success:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(AppText.t.wl_redeemed)));
        widget.onOpen(result.weddingId!, result.role ?? 'collaborator');
      case ClaimOutcome.alreadyMember:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
              SnackBar(content: Text(AppText.t.wl_alreadyAccess)));
        widget.onOpen(result.weddingId!, result.role ?? 'collaborator');
      case ClaimOutcome.invalid:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              content: Text(AppText.t.wl_badCode)));
      case ClaimOutcome.error:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
              SnackBar(content: Text(AppText.t.wl_error)));
    }
  }

  /// Dołączanie do wesela jako gość — otwiera formularz (kod + data + nazwisko).
  /// Po pomyślnej weryfikacji otwiera wesele w uproszczonym widoku gościa.
  Future<void> _joinWedding() async {
    final weddingId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => JoinWeddingScreen(userId: widget.userId),
      ),
    );
    if (weddingId == null || !mounted) return;
    widget.onOpen(weddingId, 'guest');
  }

  /// Przygotowanie strefy gości (D1, etap 2) dla wszystkich wesel użytkownika,
  /// w których ma pełny dostęp. Idempotentne — można powtarzać.
  ///
  /// Każde wesele jest po zapisie weryfikowane odczytem z serwera, więc raport
  /// pokazuje stan faktyczny, a nie samą „próbę zapisu".
  Future<void> _prepareGuestZone() async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.accent)),
            const SizedBox(width: 16),
            Expanded(child: Text(AppText.t.wl_preparing)),
          ],
        ),
      ),
    );

    List<GuestViewSyncResult> results;
    try {
      results = await _weddings.ensureGuestViewForUser(widget.userId);
    } catch (e) {
      results = [];
      if (mounted) {
        Navigator.of(context).pop(); // zamknij „w toku"
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(AppText.t.wl_failed('$e'))));
      }
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(); // zamknij „w toku"
    await _showGuestZoneReport(results);
  }

  Future<void> _showGuestZoneReport(List<GuestViewSyncResult> results) async {
    final ok = results.where((r) => r.ok).length;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          results.isEmpty
              ? AppText.t.wl_nothingToPrepare
              : AppText.t.wl_prepareResult(ok, results.length),
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: results.isEmpty
              ? Text(
                  AppText.t.wl_noFullAccess,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textLight),
                )
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final r in results)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: Icon(
                          r.ok ? Icons.check_circle : Icons.error_outline,
                          color: r.ok
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFC0392B),
                          size: 20,
                        ),
                        title: Text(r.name,
                            style: GoogleFonts.inter(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          r.ok ? AppText.t.wl_itemOk : AppText.t.wl_itemError('${r.error}'),
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: r.ok
                                ? AppColors.textLight
                                : const Color(0xFFC0392B),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppText.t.common_close)),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppText.t.wl_title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppText.t.wl_subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: AppText.t.wl_more,
            icon: const Icon(Icons.more_vert, color: AppColors.textLight),
            onSelected: (v) {
              if (v == 'guestView') _prepareGuestZone();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'guestView',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.groups_outlined, size: 20),
                  title: Text(AppText.t.wl_prepareGuestZone),
                  subtitle: Text(AppText.t.wl_prepareForAll),
                ),
              ),
            ],
          ),
          if (widget.onSignOut != null)
            IconButton(
              tooltip: AppText.t.settings_logoutButton,
              onPressed: widget.onSignOut,
              icon: const Icon(Icons.logout, color: Color(0xFFC0392B)),
            ),
        ],
      ),
    );
  }

  Widget _list(List<WeddingSummary> weddings) {
    return RefreshIndicator(
      onRefresh: () async => _reload(),
      color: AppColors.accent,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
        itemCount: weddings.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _WeddingCard(
          wedding: weddings[i],
          onTap: () => widget.onOpen(weddings[i].id, weddings[i].role),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(alpha: 0.08),
                  ),
                  child: const Icon(Icons.favorite_border,
                      size: 44, color: AppColors.accent),
                ),
                const SizedBox(height: 24),
                Text(
                  AppText.t.wl_empty,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppText.t.wl_emptyBody,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _createWedding,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                  ),
                  icon: const Text('➕', style: TextStyle(fontSize: 15)),
                  label: Text(
                    AppText.t.wl_createFirst,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 44, color: Color(0xFFC0392B)),
            const SizedBox(height: 16),
            Text(
              AppText.t.wl_loadError,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              label: Text(AppText.t.common_retry),
            ),
          ],
        ),
      ),
    );
  }
}

/// Karta pojedynczego wesela na liście.
class _WeddingCard extends StatelessWidget {
  const _WeddingCard({required this.wedding, required this.onTap});

  final WeddingSummary wedding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0.5,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE3EAF6)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.accent.withValues(alpha: 0.14),
                      AppColors.accent2.withValues(alpha: 0.10),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: const Text('💍', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wedding.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    if (wedding.persons.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        wedding.persons,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.event,
                            size: 14, color: AppColors.textLight),
                        const SizedBox(width: 4),
                        Text(
                          _dateLabel(wedding.date),
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.textLight),
                        ),
                        const SizedBox(width: 12),
                        _roleChip(wedding.roleLabel),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textLight),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleChip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8A6D26),
          ),
        ),
      );

  static String _dateLabel(DateTime? date) {
    if (date == null) return AppText.t.wl_dateTbd;
    return AppFormat.dateLong(date);
  }
}
