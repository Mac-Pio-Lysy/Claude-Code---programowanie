import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../l10n/app_text.dart';
import '../../models/invite_identity.dart';
import '../../services/guest_session.dart';
import '../../services/invite_identity_service.dart';
import 'guest_web_app.dart';

/// Wejście do strefy gości KODEM PACZKI (`?i=KOD`).
///
/// Kolejność: odczyt publicznego dokumentu kodu → wybór tożsamości → ta sama
/// strefa gości, co przy wspólnym linku. Kod paczki jest bramką tożsamości,
/// nie osobnym miejscem — dlatego wszystko poniżej kończy się na
/// [GuestWebHome] z tokenem z dokumentu kodu.
class InviteEntryApp extends StatelessWidget {
  const InviteEntryApp({super.key, required this.code, this.service});

  final String code;
  final InviteIdentityService? service;

  @override
  Widget build(BuildContext context) => GuestRootApp(
        home: (context) => InviteEntryScreen(code: code, service: service),
      );
}

/// Ekran startowy wejścia kodem — wczytuje kod i decyduje, co pokazać.
class InviteEntryScreen extends StatefulWidget {
  const InviteEntryScreen({super.key, required this.code, this.service});

  final String code;
  final InviteIdentityService? service;

  @override
  State<InviteEntryScreen> createState() => _InviteEntryScreenState();
}

class _InviteEntryScreenState extends State<InviteEntryScreen> {
  late final InviteIdentityService _service =
      widget.service ?? InviteIdentityService();

  bool _loading = true;
  InviteCodeDoc? _doc;

  /// Wybór już dokonany — albo wczytany z pamięci, albo z tego ekranu.
  PackageIdentity? _identity;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final doc = await _service.load(widget.code);
    // Zapamiętany wybór pomija ekran „Kim jesteś?" przy kolejnych wejściach.
    final local = doc == null ? null : await _service.loadLocal(doc.code);
    if (!mounted) return;
    GuestSession.apply(local);
    setState(() {
      _doc = doc;
      _identity = local;
      _loading = false;
    });
  }

  /// „To nie ja" — kasuje zapamiętany wybór i wraca do ekranu wyboru.
  Future<void> _forget() async {
    final doc = _doc;
    if (doc == null) return;
    await _service.clearLocal(doc.code);
    GuestSession.clear();
    if (mounted) setState(() => _identity = null);
  }

  Future<void> _onPicked(PackageIdentity identity) async {
    final doc = _doc!;
    await _service.saveLocal(identity);
    GuestSession.apply(identity);
    final ok = await _service.claim(doc, identity);
    if (!mounted) return;
    setState(() => _identity = identity);
    if (!ok) {
      // Zapis tożsamości jest „best effort" — gość i tak wchodzi. Mówimy mu
      // o tym wprost, zamiast udawać, że wszystko się udało.
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(AppText.t.id_claimFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F9FE),
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    final doc = _doc;
    if (doc == null) {
      return _InfoScreen(
        icon: Icons.link_off,
        title: AppText.t.id_invalidTitle,
        body: AppText.t.id_invalidBody,
      );
    }
    if (doc.revoked) {
      return _InfoScreen(
        icon: Icons.event_busy_outlined,
        title: AppText.t.id_revokedTitle,
        body: AppText.t.id_revokedBody,
      );
    }
    if (doc.guestToken.isEmpty) {
      return _InfoScreen(
        icon: Icons.hourglass_empty,
        title: AppText.t.id_notReadyTitle,
        body: AppText.t.id_notReadyBody,
      );
    }

    if (_identity == null) {
      return IdentityPickerScreen(doc: doc, onPicked: _onPicked);
    }

    // Tożsamość ustalona → dokładnie ta sama strefa, co przy wspólnym linku.
    return GuestWebHome(
      token: doc.guestToken,
      showHelp: true,
      onForgetIdentity: _forget,
    );
  }
}

/// Ekran wyboru „Kim jesteś?".
class IdentityPickerScreen extends StatefulWidget {
  const IdentityPickerScreen({
    super.key,
    required this.doc,
    required this.onPicked,
  });

  final InviteCodeDoc doc;
  final Future<void> Function(PackageIdentity identity) onPicked;

  @override
  State<IdentityPickerScreen> createState() => _IdentityPickerScreenState();
}

class _IdentityPickerScreenState extends State<IdentityPickerScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();

  /// Wybrana droga: konkretna osoba, „osoba towarzysząca" albo „to nie ja".
  int? _pickedGuestId;
  bool _typingName = false;
  bool _unassigned = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  /// Identyfikator gościa dla wpisu bez imienia — bierzemy pierwszą osobę
  /// paczki oczekującą na dane. Dzięki temu wpis od razu trafia we właściwy
  /// rekord i nie ląduje w „do przypisania".
  int? get _pendingGuestId {
    for (final m in widget.doc.members) {
      if (m.namePending) return m.guestId;
    }
    return null;
  }

  Future<void> _submit() async {
    final name = _firstName.text.trim();
    if ((_typingName || _unassigned) && name.isEmpty) {
      setState(() => _error = AppText.t.id_needName);
      return;
    }

    final full = [name, _lastName.text.trim()]
        .where((s) => s.isNotEmpty)
        .join(' ');

    final identity = switch (true) {
      _ when _pickedGuestId != null => PackageIdentity(
          code: widget.doc.code,
          guestId: _pickedGuestId,
          displayName: widget.doc.members
              .firstWhere((m) => m.guestId == _pickedGuestId)
              .name,
          source: PackageIdentity.sourcePicked,
        ),
      // Osoba towarzysząca bez imienia — wskazujemy rekord, który na nie czeka.
      _ when _typingName => PackageIdentity(
          code: widget.doc.code,
          guestId: _pendingGuestId,
          displayName: full,
          source: PackageIdentity.sourceTyped,
        ),
      // „To nie moje zaproszenie" — bez przypisania, do ręcznego rozstrzygnięcia.
      _ => PackageIdentity(
          code: widget.doc.code,
          guestId: null,
          displayName: full,
          source: PackageIdentity.sourceTyped,
        ),
    };

    setState(() => _busy = true);
    await widget.onPicked(identity);
  }

  @override
  Widget build(BuildContext context) {
    final named = widget.doc.named;
    final needsName = _typingName || _unassigned;

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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
            children: [
              const Text('💍', style: TextStyle(fontSize: 34)),
              const SizedBox(height: 12),
              Text(
                AppText.t.id_title,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text),
              ),
              const SizedBox(height: 8),
              Text(
                named.length > 1 ? AppText.t.id_lead : AppText.t.id_leadSingle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 13.5, height: 1.45, color: AppColors.textLight),
              ),
              const SizedBox(height: 20),
              for (final m in named) ...[
                _choice(
                  selected: _pickedGuestId == m.guestId,
                  icon: m.isMain ? Icons.mail_outline : Icons.person_outline,
                  title: m.name,
                  onTap: () => setState(() {
                    _pickedGuestId = m.guestId;
                    _typingName = false;
                    _unassigned = false;
                    _error = null;
                  }),
                ),
                const SizedBox(height: 8),
              ],
              if (widget.doc.hasPending) ...[
                _choice(
                  selected: _typingName,
                  icon: Icons.person_add_alt,
                  title: AppText.t.id_companion,
                  hint: AppText.t.id_companionHint,
                  onTap: () => setState(() {
                    _typingName = true;
                    _unassigned = false;
                    _pickedGuestId = null;
                    _error = null;
                  }),
                ),
                const SizedBox(height: 8),
              ],
              _choice(
                selected: _unassigned,
                icon: Icons.help_outline,
                title: AppText.t.id_notMine,
                hint: AppText.t.id_notMineHint,
                onTap: () => setState(() {
                  _unassigned = true;
                  _typingName = false;
                  _pickedGuestId = null;
                  _error = null;
                }),
              ),
              if (needsName) ...[
                const SizedBox(height: 16),
                _field(_firstName, AppText.t.id_yourName,
                    hint: AppText.t.id_yourNameHint),
                const SizedBox(height: 8),
                _field(_lastName, AppText.t.id_lastNameOptional),
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 12.5, color: const Color(0xFFC0392B)),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (_busy || !_anythingPicked) ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          AppText.t.id_enter,
                          style: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                AppText.t.id_privacy,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 11.5, height: 1.45, color: AppColors.textLight),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _anythingPicked =>
      _pickedGuestId != null || _typingName || _unassigned;

  Widget _choice({
    required bool selected,
    required IconData icon,
    required String title,
    String? hint,
    required VoidCallback onTap,
  }) =>
      Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.accent : const Color(0xFFE2EAF7),
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon,
                    size: 20,
                    color: selected ? AppColors.accent : AppColors.textLight),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      if (hint != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          hint,
                          style: GoogleFonts.inter(
                              fontSize: 11.5, color: AppColors.textLight),
                        ),
                      ],
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle,
                      size: 20, color: AppColors.accent),
              ],
            ),
          ),
        ),
      );

  Widget _field(TextEditingController c, String label, {String? hint}) =>
      TextField(
        controller: c,
        maxLength: 80,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFDCE4F2))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFDCE4F2))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
        ),
      );
}

/// Prosty ekran komunikatu (nieprawidłowy / unieważniony / niegotowy kod).
class _InfoScreen extends StatelessWidget {
  const _InfoScreen({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Scaffold(
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
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 48, color: AppColors.textLight),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 14, height: 1.45, color: AppColors.textLight),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
