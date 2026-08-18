import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../l10n/app_text.dart';
import '../../models/invite_identity.dart';
import '../../services/guest_service.dart';
import '../../services/guest_space_service.dart';
import '../../services/invite_identity_service.dart';

/// Etap 5 — tożsamości z paczek zaproszeniowych bez wskazanego gościa
/// (`identities` z `guestId == null`).
///
/// Trzy źródła takich wpisów: gość wybrał „osoba towarzysząca" i wpisał
/// imię, którego nie było w żadnym oczekującym miejscu paczki; gość kliknął
/// „to nie moje zaproszenie"; albo skład paczki zmienił się po wydrukowaniu
/// kodu. Organizator decyduje, co z takim wpisem zrobić.
///
/// ⚠️ Nie pokazuje wpisów z księgi gości / rad — te NIE są jeszcze powiązane
/// z `uid` gościa (dowiązanie autorstwa to osobny etap, świadomie odłożony).
/// Pokazuje wyłącznie to, co już dziś ma `doc.id == uid`: RSVP i wpis na
/// mapę gości.
class UnassignedIdentitiesScreen extends StatefulWidget {
  const UnassignedIdentitiesScreen({super.key, required this.guestToken});

  final String guestToken;

  @override
  State<UnassignedIdentitiesScreen> createState() =>
      _UnassignedIdentitiesScreenState();
}

class _UnassignedIdentitiesScreenState
    extends State<UnassignedIdentitiesScreen> {
  late final GuestSpaceService _space =
      GuestSpaceService(token: widget.guestToken);
  final InviteIdentityService _identities = InviteIdentityService();
  final GuestService _guests = GuestService();

  bool _busy = false;

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _assign(Map<String, dynamic> entry, InviteMember member) async {
    setState(() => _busy = true);
    try {
      await _space.updateEntry(
          InviteIdentityService.collectionName,
          entry['id'] as String,
          {'guestId': member.guestId});
      if (mounted) _toast(AppText.t.unassigned_assigned);
    } catch (e) {
      if (mounted) _toast(AppText.t.unassigned_error('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createGuest(
      Map<String, dynamic> entry, InviteCodeDoc doc) async {
    final main = doc.members.where((m) => m.isMain).firstOrNull;
    if (main == null) return;
    final result = await _NameDialog.show(
      context,
      initial: (entry['displayName'] as String?) ?? '',
    );
    if (result == null) return;

    setState(() => _busy = true);
    try {
      final newId = await _guests.createCompanionWithId(
        main.guestId,
        firstName: result.$1,
        lastName: result.$2,
      );
      await _space.updateEntry(InviteIdentityService.collectionName,
          entry['id'] as String, {'guestId': newId});
      if (mounted) _toast(AppText.t.unassigned_created);
    } catch (e) {
      if (mounted) _toast(AppText.t.unassigned_error('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject(Map<String, dynamic> entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(AppText.t.unassigned_rejectTitle,
            style: GoogleFonts.playfairDisplay(
                fontSize: 18, fontWeight: FontWeight.w700)),
        content: Text(AppText.t.unassigned_rejectBody,
            style: GoogleFonts.inter(fontSize: 13.5, height: 1.45)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppText.t.common_cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC0392B)),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppText.t.unassigned_reject),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      await _space.deleteEntry(
          InviteIdentityService.collectionName, entry['id'] as String);
      if (mounted) _toast(AppText.t.unassigned_rejected);
    } catch (e) {
      if (mounted) _toast(AppText.t.unassigned_error('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGradient.last,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        title: Text(
          AppText.t.unassigned_title,
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
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _space.watchUnassignedIdentities(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.accent));
              }
              final entries = snapshot.data ?? const [];
              if (entries.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      AppText.t.unassigned_empty,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 13.5,
                          height: 1.45,
                          color: AppColors.textLight),
                    ),
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  Text(
                    AppText.t.unassigned_hint,
                    style: GoogleFonts.inter(
                        fontSize: 12.5,
                        height: 1.45,
                        color: AppColors.textLight),
                  ),
                  const SizedBox(height: 14),
                  for (final e in entries) ...[
                    _EntryCard(
                      key: ValueKey(e['id']),
                      entry: e,
                      space: _space,
                      identityService: _identities,
                      busy: _busy,
                      onAssign: (member) => _assign(e, member),
                      onCreate: (doc) => _createGuest(e, doc),
                      onReject: () => _reject(e),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Jedna karta — dociąga skład paczki i (jeśli już są) RSVP/wpis na mapę.
///
/// `StatefulWidget`, żeby te dwa doczyty policzyć RAZ na kartę (w `initState`),
/// a nie przy każdej przebudowie listy — np. przełączenie `busy` w rodzicu
/// (podczas przypisywania innej karty) odświeża CAŁĄ listę i bez tego
/// odpytywałoby Firestore od nowa za każdym razem.
class _EntryCard extends StatefulWidget {
  const _EntryCard({
    super.key,
    required this.entry,
    required this.space,
    required this.identityService,
    required this.busy,
    required this.onAssign,
    required this.onCreate,
    required this.onReject,
  });

  final Map<String, dynamic> entry;
  final GuestSpaceService space;
  final InviteIdentityService identityService;
  final bool busy;
  final ValueChanged<InviteMember> onAssign;
  final ValueChanged<InviteCodeDoc> onCreate;
  final VoidCallback onReject;

  @override
  State<_EntryCard> createState() => _EntryCardState();
}

class _EntryCardState extends State<_EntryCard> {
  late final Future<InviteCodeDoc?> _docFuture =
      widget.identityService.load((widget.entry['code'] as String?) ?? '');

  late final Future<List<Map<String, dynamic>?>>? _extrasFuture =
      widget.entry['uid'] == null
          ? null
          : Future.wait([
              widget.space.readOwn('rsvp', widget.entry['uid'] as String),
              widget.space.readOwn('guestMap', widget.entry['uid'] as String),
            ]);

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final code = (entry['code'] as String?) ?? '';
    final displayName = (entry['displayName'] as String?) ?? '';
    final source = entry['source'] as String?;
    final busy = widget.busy;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_search, size: 20, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayName.isEmpty ? AppText.t.role_guest : displayName,
                  style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text),
                ),
              ),
              _sourceBadge(source),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            AppText.t.unassigned_fromCode(code),
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
          ),
          if (_extrasFuture != null) _extras(),
          const SizedBox(height: 10),
          FutureBuilder<InviteCodeDoc?>(
            future: _docFuture,
            builder: (context, snap) {
              final doc = snap.data;
              if (doc == null) return const SizedBox.shrink();
              return Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final m in doc.members)
                    if (m.guestId != -1)
                      OutlinedButton(
                        onPressed: busy ? null : () => widget.onAssign(m),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          side: const BorderSide(color: AppColors.accent),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(
                          AppText.t.unassigned_assignTo(
                              m.namePending || m.name.isEmpty
                                  ? AppText.t.inv_noName
                                  : m.name),
                          style: GoogleFonts.inter(fontSize: 12),
                        ),
                      ),
                  OutlinedButton.icon(
                    onPressed: busy ? null : () => widget.onCreate(doc),
                    icon: const Icon(Icons.person_add_alt, size: 16),
                    label: Text(AppText.t.unassigned_createGuest,
                        style: GoogleFonts.inter(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text,
                      side: const BorderSide(color: Color(0xFFDCE4F2)),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: busy ? null : widget.onReject,
                    icon: const Icon(Icons.block, size: 16),
                    label: Text(AppText.t.unassigned_reject,
                        style: GoogleFonts.inter(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFC0392B),
                      side: const BorderSide(color: Color(0xFFF3C6C0)),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// RSVP / wpis na mapę gości — jedyne dwie rzeczy dostępne bez dowiązania
  /// autorstwa (oba mają `doc.id == uid`).
  Widget _extras() => FutureBuilder<List<Map<String, dynamic>?>>(
        future: _extrasFuture,
        builder: (context, snap) {
          final rsvp = snap.data?[0];
          final map = snap.data?[1];
          if (rsvp == null && map == null) return const SizedBox.shrink();
          final chips = <Widget>[];
          if (rsvp != null) {
            final attending = rsvp['attending'] == true;
            chips.add(_infoChip(attending
                ? AppText.t.unassigned_hasRsvpYes
                : AppText.t.unassigned_hasRsvpNo));
          }
          if (map != null) {
            chips.add(_infoChip(AppText.t.unassigned_hasMapEntry));
          }
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(spacing: 6, runSpacing: 4, children: chips),
          );
        },
      );

  Widget _infoChip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textLight)),
      );

  Widget _sourceBadge(String? source) {
    final picked = source == 'picked';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        picked ? AppText.t.unassigned_sourcePicked : AppText.t.unassigned_sourceTyped,
        style: GoogleFonts.inter(
            fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFFB45309)),
      ),
    );
  }
}

/// Prosty dialog imię + nazwisko (dla „utwórz nowego gościa").
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});

  final String initial;

  static Future<(String, String)?> show(BuildContext context,
          {required String initial}) =>
      showDialog<(String, String)>(
        context: context,
        builder: (_) => _NameDialog(initial: initial),
      );

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _first = TextEditingController(
      text: widget.initial.split(' ').firstOrNull ?? '');
  late final _last = TextEditingController(
      text: widget.initial.split(' ').skip(1).join(' '));

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(AppText.t.unassigned_createGuest,
          style:
              GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _first,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
                labelText: AppText.t.guests_formFirstName,
                hintText: AppText.t.guests_formFirstNameHint),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _last,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
                labelText: AppText.t.guests_formLastName,
                hintText: AppText.t.guests_formLastNameHint),
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
          onPressed: () => Navigator.of(context)
              .pop((_first.text.trim(), _last.text.trim())),
          child: Text(AppText.t.common_confirm),
        ),
      ],
    );
  }
}
