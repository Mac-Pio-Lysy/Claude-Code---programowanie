import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';

import '../../app_colors.dart';
import '../../config/public_urls.dart';
import '../../l10n/app_text.dart';
import '../../models/guest.dart';
import '../../models/invite_package.dart';
import '../../models/join_code.dart';
import '../../services/config_service.dart';
import '../../services/guest_space_service.dart';
import '../../services/invite_code_service.dart';
import '../../services/pdf_service.dart';
import 'unassigned_identities_screen.dart';

/// Ekran „Zaproszenia dla gości" — wybór trybu i podgląd paczek.
///
/// ETAPY 1–2: podział na paczki, przełącznik trybu i kody per paczka.
/// Wydruk i ścieżka gościa dochodzą w kolejnych etapach — ekran mówi o tym
/// wprost, żeby nikt nie szukał przycisku, którego jeszcze nie ma.
///
/// Paczki są WYLICZANE z listy gości przy każdym otwarciu (patrz
/// [InvitePackage]), więc ten ekran nie ma własnych danych do zapisania poza
/// jednym polem `appConfig.inviteMode`.
class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({
    super.key,
    required this.raw,
    required this.config,
    this.codeService,
  });

  /// Surowy dokument wesela — źródło listy gości i bieżącego trybu.
  final Map<String, dynamic> raw;

  final ConfigService config;

  /// Wstrzykiwalny serwis kodów (testy). Domyślnie tworzony wewnętrznie.
  final InviteCodeService? codeService;

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  late String _mode = InviteMode.fromRaw(widget.raw);
  bool _saving = false;

  late final InviteCodeService _codes = widget.codeService ?? InviteCodeService();

  /// Token strefy gości — `null`/pusty, dopóki wesele go jeszcze nie ma
  /// (zanim organizator włączy stronę dla gości).
  String get _guestToken => (widget.raw['guestToken'] as String?)?.trim() ?? '';

  late final GuestSpaceService? _guestSpace =
      _guestToken.isEmpty ? null : GuestSpaceService(token: _guestToken);

  /// Prywatny indeks kodów. Trzymany w stanie, bo po każdej operacji
  /// odświeżamy go lokalnie — ekran dostaje `raw` jako zdjęcie z chwili
  /// wejścia i nie odświeża się sam.
  late Map<int, PackageCode> _index = InviteCodeService.indexOf(widget.raw);

  // ── Wydruk zaproszeń per paczka (etap 6) ──────────────────────────────
  static const Map<String, PdfPageFormat> _printFormats = {
    'A6': PdfPageFormat.a6,
    'A5': PdfPageFormat.a5,
    'A4': PdfPageFormat.a4,
  };
  String _printFormat = 'A6';

  /// Ile kart na arkuszu — ma znaczenie tylko dla formatu A4.
  int _perPage = 1;

  /// Zakres wydruku: wszystkie / zaznaczone / bez wygenerowanego kodu.
  String _printRange = 'all';
  final Set<int> _selectedForPrint = {};
  bool _printing = false;

  /// `null` = brak paska (jeszcze nie liczymy), `0..1` = postęp.
  double? _printProgress;

  /// Trwa generowanie / synchronizacja (blokuje przyciski).
  bool _busy = false;
  String? _progress;

  List<InvitePackage> get _packages =>
      InvitePackage.buildAll(widget.raw['guests'] is List
          ? widget.raw['guests'] as List
          : const []);

  @override
  void initState() {
    super.initState();
    // Odświeżenie składu paczek, które rozjechały się z listą gości.
    // Zapisuje TYLKO zmienione, więc wejście bez zmian nie kosztuje zapisu.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncRosters());
  }

  Future<void> _syncRosters() async {
    if (_mode != InviteMode.individual) return;
    final stale = InviteCodeService.staleOf(_packages, _index);
    if (stale.isEmpty) return;
    try {
      final r = await _codes.syncRosters(_packages, _rawWithIndex());
      if (!mounted || !r.anythingDone) return;
      setState(() {
        for (final p in stale) {
          final c = _index[p.id];
          if (c != null) {
            _index[p.id] = PackageCode(
              packageId: p.id,
              code: c.code,
              revoked: c.revoked,
              roster: p.rosterFingerprint,
            );
          }
        }
      });
      if (r.updated > 0) _toast(AppText.t.inv_synced(r.updated));
      if (r.failed > 0) _toast(AppText.t.inv_syncFailed(r.failed));
    } catch (_) {
      // Cisza: brak reguł albo sieci nie może blokować przeglądania paczek.
    }
  }

  /// `raw` z aktualnym indeksem — serwis czyta z niego stan kodów.
  Map<String, dynamic> _rawWithIndex() => {
        ...widget.raw,
        InviteCodeService.indexField: {
          for (final e in _index.entries) '${e.key}': e.value.toMap(),
        },
      };

  Future<void> _generateMissing() async {
    setState(() => _busy = true);
    try {
      final count = await _codes.generateMissing(
        _packages,
        _rawWithIndex(),
        onProgress: (done, total) => setState(
            () => _progress = AppText.t.inv_generating(done, total)),
      );
      await _reloadIndex();
      if (mounted) _toast(AppText.t.inv_generated(count));
    } catch (e) {
      if (mounted) _toast(AppText.t.inv_error('$e'));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = null;
        });
      }
    }
  }

  Future<void> _regenerate(InvitePackage p) async {
    final ok = await _confirm(
      AppText.t.inv_regenerateTitle,
      AppText.t.inv_regenerateBody,
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await _codes.regenerate(p, _rawWithIndex());
      await _reloadIndex();
      if (mounted) _toast(AppText.t.inv_regenerated);
    } catch (e) {
      if (mounted) _toast(AppText.t.inv_error('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleRevoked(InvitePackage p, bool revoked) async {
    if (revoked) {
      final ok = await _confirm(
        AppText.t.inv_revokeTitle,
        AppText.t.inv_revokeBody,
      );
      if (ok != true) return;
    }
    setState(() => _busy = true);
    try {
      await _codes.setRevoked(p, _rawWithIndex(), revoked: revoked);
      await _reloadIndex();
      if (mounted) {
        _toast(revoked ? AppText.t.inv_revoked : AppText.t.inv_restored);
      }
    } catch (e) {
      if (mounted) _toast(AppText.t.inv_error('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Ponowny odczyt indeksu z dokumentu wesela — po zapisie serwisu.
  Future<void> _reloadIndex() async {
    final fresh = await _codes.readIndex();
    if (mounted) setState(() => _index = fresh);
  }

  /// Paczki wybrane do wydruku wg aktualnego zakresu.
  List<InvitePackage> _printTargets(List<InvitePackage> packages) =>
      switch (_printRange) {
        'selected' =>
          packages.where((p) => _selectedForPrint.contains(p.id)).toList(),
        'missing' => packages.where((p) => !_index.containsKey(p.id)).toList(),
        _ => packages,
      };

  Future<void> _printInvitations() async {
    final packages = _packages;
    var targets = _printTargets(packages);
    if (targets.isEmpty) {
      _toast(AppText.t.inv_printNothingSelected);
      return;
    }

    setState(() {
      _printing = true;
      _printProgress = null;
    });
    try {
      // Zakres „bez kodu" najpierw dogenerowuje kody dokładnie tym paczkom —
      // bez kodu nie ma czego zakodować w QR.
      if (_printRange == 'missing') {
        await _codes.generateMissing(
          targets,
          _rawWithIndex(),
          onProgress: (done, total) =>
              setState(() => _progress = AppText.t.inv_generating(done, total)),
        );
        await _reloadIndex();
        setState(() => _progress = null);
        // Po dogenerowaniu kodów `targets` (obliczone przed chwilą) wskazują
        // wciąż te same paczki — kody teraz już istnieją w `_index`.
      }

      final toPrint = <({String code, String names})>[];
      for (final p in targets) {
        final c = _index[p.id];
        if (c == null || c.code.isEmpty || c.revoked) continue;
        toPrint.add((
          code: c.code,
          names: _joinNames(p.everyone.map((g) => g.fullName).toList()),
        ));
      }
      if (toPrint.isEmpty) {
        if (mounted) _toast(AppText.t.inv_printNoCodes);
        return;
      }
      final skipped = targets.length - toPrint.length;

      final cfg = widget.raw['appConfig'];
      final eventName =
          (cfg is Map ? cfg['eventName'] as String? : null)?.trim() ?? '';
      final persons =
          (cfg is Map ? cfg['displayNames'] as String? : null)?.trim() ?? '';
      final baseUrl = PublicPages.baseUrl(widget.raw);

      final bytes = await PdfService.individualInvitations(
        packages: toPrint,
        baseUrl: baseUrl,
        eventName: eventName,
        persons: persons,
        format: _printFormats[_printFormat] ?? PdfPageFormat.a6,
        perPage: _printFormat == 'A4' ? _perPage : 1,
        onProgress: (done, total) => setState(
            () => _printProgress = total == 0 ? null : done / total),
      );
      await PdfService.preview(bytes, AppText.t.inv_printFileName);
      // Zakres „bez kodu" dogenerował kody wszystkim swoim celom, więc tam
      // pominięcia nie mają prawa wystąpić — komunikat tylko dla „wszystkie"
      // / „zaznaczone", gdzie część paczek mogła nie mieć jeszcze kodu.
      if (mounted && skipped > 0 && _printRange != 'missing') {
        _toast(AppText.t.inv_printSkipped(skipped));
      }
    } catch (e) {
      if (mounted) _toast(AppText.t.inv_error('$e'));
    } finally {
      if (mounted) {
        setState(() {
          _printing = false;
          _printProgress = null;
        });
      }
    }
  }

  /// „Anna, Wojtek i Kasia" — imiona paczki do zdania na karcie.
  String _joinNames(List<String> names) {
    final clean = [
      for (final n in names)
        if (n.trim().isNotEmpty) n.trim()
    ];
    if (clean.isEmpty) return '';
    if (clean.length == 1) return clean.first;
    return '${clean.sublist(0, clean.length - 1).join(', ')} ${AppText.t.common_and} ${clean.last}';
  }

  Future<bool?> _confirm(String title, String body) => showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(title,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          content: Text(body,
              style: GoogleFonts.inter(fontSize: 13.5, height: 1.45)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppText.t.common_cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(AppText.t.common_confirm),
            ),
          ],
        ),
      );

  Future<void> _setMode(String mode) async {
    if (mode == _mode || _saving) return;
    setState(() {
      _mode = mode;
      _saving = true;
    });
    try {
      await widget.config.saveInviteMode(mode);
      if (mounted) _toast(AppText.t.inv_saved);
    } catch (e) {
      if (mounted) _toast(AppText.t.common_saveErrorToast('$e'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final packages = _packages;
    final stats = InvitePackage.statsOf(packages);
    final individual = _mode == InviteMode.individual;
    final guestSpace = _guestSpace;

    return Scaffold(
      backgroundColor: AppColors.bgGradient.last,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        title: Text(
          AppText.t.inv_title,
          style: GoogleFonts.playfairDisplay(
              fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text),
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
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _sectionLabel(AppText.t.inv_modeHeader),
              const SizedBox(height: 8),
              _modeTile(
                mode: InviteMode.shared,
                icon: Icons.public,
                title: AppText.t.inv_modeShared,
                hint: AppText.t.inv_modeSharedHint,
              ),
              const SizedBox(height: 8),
              _modeTile(
                mode: InviteMode.individual,
                icon: Icons.qr_code_2,
                title: AppText.t.inv_modeIndividual,
                hint: AppText.t.inv_modeIndividualHint,
              ),
              // Oba ostrzeżenia pokazujemy TYLKO w trybie indywidualnym —
              // w trybie wspólnym nie dotyczą niczego i byłyby szumem.
              if (individual) ...[
                const SizedBox(height: 12),
                _note(
                  icon: Icons.link,
                  title: AppText.t.inv_sharedStaysTitle,
                  body: AppText.t.inv_sharedStaysBody,
                  color: const Color(0xFF1040B0),
                  background: const Color(0xFFF1F5FF),
                  border: const Color(0xFFD6E0F5),
                ),
                const SizedBox(height: 8),
                // ⚠️ Świadomie mocny ton: kod jedzie wydrukowany na
                // zaproszeniu, więc rozpoznanie gościa jest wygodą, nie
                // dowodem tożsamości. Organizator musi to wiedzieć, zanim
                // oprze na tym jakąkolwiek decyzję.
                _note(
                  icon: Icons.info_outline,
                  title: AppText.t.inv_notProofTitle,
                  body: AppText.t.inv_notProofBody,
                  color: const Color(0xFFB45309),
                  background: const Color(0xFFFFF7ED),
                  border: const Color(0xFFFCD9A6),
                ),
              ],
              if (individual) ...[
                const SizedBox(height: 20),
                _sectionLabel(AppText.t.inv_codesHeader),
                const SizedBox(height: 8),
                _codesCard(packages),
              ],
              if (individual && guestSpace != null) ...[
                const SizedBox(height: 12),
                _unassignedCard(guestSpace),
              ],
              if (individual && packages.isNotEmpty) ...[
                const SizedBox(height: 20),
                _sectionLabel(AppText.t.inv_printHeader),
                const SizedBox(height: 8),
                _printCard(packages),
              ],
              const SizedBox(height: 20),
              _sectionLabel(AppText.t.inv_packagesHeader),
              const SizedBox(height: 8),
              _statsCard(stats),
              const SizedBox(height: 10),
              Text(
                AppText.t.inv_previewHint,
                style: GoogleFonts.inter(
                    fontSize: 12, height: 1.45, color: AppColors.textLight),
              ),
              const SizedBox(height: 12),
              if (packages.isEmpty)
                _emptyCard()
              else
                for (final p in packages) ...[
                  _packageCard(
                    p,
                    showCode: individual,
                    selectable: individual && _printRange == 'selected',
                    selected: _selectedForPrint.contains(p.id),
                    onSelect: (v) => setState(() {
                      if (v) {
                        _selectedForPrint.add(p.id);
                      } else {
                        _selectedForPrint.remove(p.id);
                      }
                    }),
                  ),
                  const SizedBox(height: 8),
                ],
              const SizedBox(height: 12),
              Text(
                AppText.t.inv_codesLater,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textLight),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: AppColors.textLight,
          ),
        ),
      );

  Widget _modeTile({
    required String mode,
    required IconData icon,
    required String title,
    required String hint,
  }) {
    final selected = _mode == mode;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _saving ? null : () => _setMode(mode),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.accent : const Color(0xFFE2EAF7),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 20,
                color: selected ? AppColors.accent : AppColors.textLight,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 18, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hint,
                      style: GoogleFonts.inter(
                          fontSize: 12.5,
                          height: 1.4,
                          color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _note({
    required IconData icon,
    required String title,
    required String body,
    required Color color,
    required Color background,
    required Color border,
  }) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: color),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: GoogleFonts.inter(
                        fontSize: 12, height: 1.45, color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _statsCard(PackageStats s) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2EAF7)),
        ),
        child: Row(
          children: [
            _stat('${s.packages}', AppText.t.inv_statPackages),
            _stat('${s.people}', AppText.t.inv_statPeople),
            _stat('${s.multi}', AppText.t.inv_statMulti),
            _stat('${s.pendingNames}', AppText.t.inv_statPending,
                alert: s.pendingNames > 0),
          ],
        ),
      );

  Widget _stat(String value, String label, {bool alert = false}) => Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: alert ? const Color(0xFFB45309) : AppColors.accent,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
            ),
          ],
        ),
      );

  Widget _emptyCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2EAF7)),
        ),
        child: Text(
          AppText.t.inv_empty,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              fontSize: 13, height: 1.45, color: AppColors.textLight),
        ),
      );

  /// Panel operacji na kodach: generowanie brakujących, znacznik nieaktualnych
  /// i przypomnienie o regule, bez której zapis się nie uda.
  Widget _codesCard(List<InvitePackage> packages) {
    final missing =
        packages.where((p) => !_index.containsKey(p.id)).length;
    final stale = InviteCodeService.staleOf(packages, _index);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _note(
          icon: Icons.gpp_maybe_outlined,
          title: AppText.t.inv_rulesNeededTitle,
          body: AppText.t.inv_rulesNeededBody,
          color: const Color(0xFF6B7A90),
          background: const Color(0xFFF4F6FA),
          border: const Color(0xFFDCE4F2),
        ),
        if (stale.isNotEmpty) ...[
          const SizedBox(height: 8),
          _note(
            icon: Icons.sync_problem_outlined,
            title: AppText.t.inv_staleTitle(stale.length),
            body: AppText.t.inv_staleBody,
            color: const Color(0xFFB45309),
            background: const Color(0xFFFFF7ED),
            border: const Color(0xFFFCD9A6),
          ),
        ],
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: (_busy || missing == 0 || packages.isEmpty)
                ? null
                : _generateMissing,
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.qr_code_2, size: 18),
            label: Text(_progress ?? AppText.t.inv_generate),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
      ],
    );
  }

  /// Karta „Do przypisania" (etap 5) — link do tożsamości z paczek, dla
  /// których gość nie trafił w konkretny rekord. Pokazuje się tylko, gdy
  /// jest choć jedna taka tożsamość — inaczej byłaby szumem na ekranie,
  /// który organizator otwiera głównie po kody.
  Widget _unassignedCard(GuestSpaceService space) =>
      StreamBuilder<List<Map<String, dynamic>>>(
        stream: space.watchUnassignedIdentities(),
        builder: (context, snapshot) {
          final count = snapshot.data?.length ?? 0;
          if (count == 0) return const SizedBox.shrink();
          return Material(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    UnassignedIdentitiesScreen(guestToken: _guestToken),
              )),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFCD9A6)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_search,
                        size: 20, color: Color(0xFFB45309)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppText.t.unassigned_badge(count),
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFB45309)),
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 20, color: Color(0xFFB45309)),
                  ],
                ),
              ),
            ),
          );
        },
      );

  /// Karta wydruku zaproszeń per paczka (etap 6): zakres, format, pasek
  /// postępu przy większej liczbie paczek.
  Widget _printCard(List<InvitePackage> packages) {
    final missingCount =
        packages.where((p) => !_index.containsKey(p.id)).length;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppText.t.inv_printRangeLabel,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _rangeChip('all', AppText.t.inv_printRangeAll),
            _rangeChip('selected',
                AppText.t.inv_printRangeSelected(_selectedForPrint.length)),
            _rangeChip(
                'missing', AppText.t.inv_printRangeMissing(missingCount)),
          ]),
          const SizedBox(height: 14),
          Text(AppText.t.inv_printFormatLabel,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final f in _printFormats.keys) _formatChip(f),
          ]),
          if (_printFormat == 'A4') ...[
            const SizedBox(height: 10),
            Text(AppText.t.inv_printPerPageLabel,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, children: [
              _perPageChip(1, AppText.t.inv_printPerPageOne),
              _perPageChip(2, AppText.t.inv_printPerPageTwo),
              _perPageChip(4, AppText.t.inv_printPerPageFour),
            ]),
          ],
          const SizedBox(height: 14),
          if (_printProgress != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _printProgress,
                minHeight: 6,
                backgroundColor: const Color(0xFFE2EAF7),
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _printing ? null : _printInvitations,
              icon: _printing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.print_outlined, size: 18),
              label: Text(AppText.t.inv_printGenerate),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rangeChip(String value, String label) => ChoiceChip(
        label: Text(label),
        selected: _printRange == value,
        onSelected: _printing ? null : (_) => setState(() => _printRange = value),
        labelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _printRange == value ? AppColors.accent : AppColors.textLight),
        selectedColor: AppColors.accent.withValues(alpha: 0.12),
      );

  Widget _formatChip(String f) => ChoiceChip(
        label: Text(f),
        selected: _printFormat == f,
        onSelected: _printing ? null : (_) => setState(() => _printFormat = f),
        labelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _printFormat == f ? AppColors.accent : AppColors.textLight),
        selectedColor: AppColors.accent.withValues(alpha: 0.12),
      );

  Widget _perPageChip(int n, String label) => ChoiceChip(
        label: Text(label),
        selected: _perPage == n,
        onSelected: _printing ? null : (_) => setState(() => _perPage = n),
        labelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _perPage == n ? AppColors.accent : AppColors.textLight),
        selectedColor: AppColors.accent.withValues(alpha: 0.12),
      );

  /// Wiersz z kodem paczki i akcjami.
  Widget _codeRow(InvitePackage p) {
    final c = _index[p.id];
    final stale = c != null && c.roster != p.rosterFingerprint;

    if (c == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          AppText.t.inv_noCode,
          style: GoogleFonts.inter(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.textLight),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Divider(height: 1),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                JoinCode.format(c.code),
                style: GoogleFonts.robotoMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: c.revoked ? AppColors.textLight : AppColors.accent,
                  decoration:
                      c.revoked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (c.revoked)
              _badge(AppText.t.inv_codeRevoked, AppColors.textLight,
                  const Color(0xFFF1F3F7))
            else if (stale)
              _badge(AppText.t.inv_codeStale, const Color(0xFFB45309),
                  const Color(0xFFFFF7ED)),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          children: [
            _codeAction(Icons.copy, AppText.t.inv_copyCode, () {
              final pretty = JoinCode.format(c.code);
              Clipboard.setData(ClipboardData(text: pretty));
              _toast(AppText.t.inv_codeCopied(pretty));
            }),
            _codeAction(Icons.autorenew, AppText.t.inv_regenerate,
                _busy ? null : () => _regenerate(p)),
            if (c.revoked)
              _codeAction(Icons.lock_open, AppText.t.inv_restore,
                  _busy ? null : () => _toggleRevoked(p, false))
            else
              _codeAction(Icons.block, AppText.t.inv_revoke,
                  _busy ? null : () => _toggleRevoked(p, true)),
          ],
        ),
      ],
    );
  }

  Widget _codeAction(IconData icon, String label, VoidCallback? onTap) =>
      TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 15),
        label: Text(label, style: GoogleFonts.inter(fontSize: 12)),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(0, 32),
          visualDensity: VisualDensity.compact,
        ),
      );

  Widget _packageCard(
    InvitePackage p, {
    bool showCode = false,
    bool selectable = false,
    bool selected = false,
    ValueChanged<bool>? onSelect,
  }) =>
      Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selectable && selected
                  ? AppColors.accent
                  : const Color(0xFFE2EAF7),
              width: selectable && selected ? 1.4 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (selectable) ...[
                  Checkbox(
                    value: selected,
                    activeColor: AppColors.accent,
                    onChanged: (v) => onSelect?.call(v ?? false),
                  ),
                  const SizedBox(width: 2),
                ],
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(alpha: 0.10),
                  ),
                  child: Text(
                    '${p.size}',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppText.t.inv_packageSize(p.size),
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textLight),
                  ),
                ),
                if (p.hasPendingNames)
                  _badge(AppText.t.inv_pendingBadge,
                      const Color(0xFFB45309), const Color(0xFFFFF7ED)),
              ],
            ),
            const SizedBox(height: 8),
            for (final g in p.everyone) _memberRow(g, isMain: g == p.main),
            if (showCode) _codeRow(p),
          ],
        ),
      );

  Widget _memberRow(Guest g, {required bool isMain}) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(
              isMain ? Icons.mail_outline : Icons.subdirectory_arrow_right,
              size: 16,
              color: isMain ? AppColors.accent : AppColors.textLight,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                g.namePending || g.fullName.isEmpty
                    ? AppText.t.inv_noName
                    : g.fullName,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: isMain ? FontWeight.w600 : FontWeight.w400,
                  fontStyle: g.namePending ? FontStyle.italic : FontStyle.normal,
                  color: g.namePending ? AppColors.textLight : AppColors.text,
                ),
              ),
            ),
            if (isMain)
              _badge(AppText.t.inv_mainBadge, AppColors.accent,
                  AppColors.accent.withValues(alpha: 0.10)),
          ],
        ),
      );

  Widget _badge(String text, Color color, Color background) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
              fontSize: 10.5, fontWeight: FontWeight.w600, color: color),
        ),
      );
}
