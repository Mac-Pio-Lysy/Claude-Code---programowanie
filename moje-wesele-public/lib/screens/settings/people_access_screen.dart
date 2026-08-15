import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../layout/responsive.dart';
import '../../models/couple.dart';
import '../../models/membership.dart';
import '../../services/membership_service.dart';
import '../../services/wedding_service.dart';
import '../../utils/warsaw_time.dart';
import '../../utils/app_format.dart';
import '../../l10n/app_text.dart';

/// Panel „Osoby i dostęp" — widoczny TYLKO dla właściciela (owner).
///
/// Owner widzi wszystkie osoby powiązane z weselem i zarządza nimi:
///   • dodaje współorganizatora / planera (po e-mailu lub kodem zaproszenia),
///   • planerowi ustawia/zmienia datę ważności,
///   • blokuje, przywraca i usuwa dostęp.
/// Pary Młodej (owner) nie można zablokować ani usunąć.
class PeopleAccessScreen extends StatefulWidget {
  const PeopleAccessScreen({
    super.key,
    required this.weddingId,
    required this.currentUserId,
  });

  final String weddingId;
  final String currentUserId;

  @override
  State<PeopleAccessScreen> createState() => _PeopleAccessScreenState();
}

class _PeopleAccessScreenState extends State<PeopleAccessScreen> {
  final MembershipService _memberships = MembershipService();
  final WeddingService _weddings = WeddingService();

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _addPerson() async {
    final req = await showModalBottomSheet<_AddRequest>(
      context: context,
      constraints: const BoxConstraints(maxWidth: kSheetMaxWidth),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => const _AddPersonSheet(),
    );
    if (req == null || !mounted) return;

    // POTWIERDZENIE (świadoma zgoda właściciela).
    final roleLabel = _roleLabel(req.role);
    final withExpiry = req.role == 'planner' && req.expiresAt != null;
    final confirmText = req.method == 'email'
        ? AppText.t.people_addConfirm(req.email, roleLabel)
        : (withExpiry
            ? AppText.t
                .people_codeConfirmUntil(roleLabel, _dateLabel(req.expiresAt))
            : AppText.t.people_codeConfirm(roleLabel));
    final ok = await _confirm(AppText.t.common_confirm, confirmText);
    if (ok != true || !mounted) return;

    if (req.method == 'email') {
      final outcome = await _weddings.addPersonByEmail(
        weddingId: widget.weddingId,
        email: req.email,
        role: req.role,
        expiresAt: req.expiresAt,
      );
      if (!mounted) return;
      switch (outcome) {
        case AddPersonOutcome.success:
          _toast(AppText.t.people_added(roleLabel));
        case AddPersonOutcome.noAccount:
          _toast(AppText.t.people_noAccount(req.email));
        case AddPersonOutcome.alreadyMember:
          _toast(AppText.t.people_alreadyMember);
        case AddPersonOutcome.error:
          _toast(AppText.t.people_error);
      }
    } else {
      final code = await _weddings.createRoleInvite(
        weddingId: widget.weddingId,
        role: req.role,
        expiresAt: req.expiresAt,
      );
      if (!mounted) return;
      await _showInviteCode(code, roleLabel);
    }
  }

  Future<void> _showInviteCode(String code, String roleLabel) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(AppText.t.people_inviteCodeTitle(roleLabel),
            style: GoogleFonts.playfairDisplay(
                fontSize: 18, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppText.t.people_inviteCodeBody,
              style:
                  GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accent, width: 1.4),
              ),
              child: Text(
                code,
                style: GoogleFonts.robotoMono(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                    color: AppColors.accent),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              _toast(AppText.t.people_codeCopied(code));
            },
            icon: const Icon(Icons.copy, size: 16),
            label: Text(AppText.t.common_copy),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppText.t.common_done),
          ),
        ],
      ),
    );
  }

  Future<void> _blockOrRestore(Membership m) async {
    final blocking = !m.isBlocked;
    final ok = await _confirm(
      blocking ? AppText.t.people_blockTitle : AppText.t.people_unblockTitle,
      blocking
          ? AppText.t.people_blockBody(_who(m))
          : AppText.t.people_unblockBody(_who(m)),
    );
    if (ok != true) return;
    await _memberships.update(m.id, status: blocking ? 'blocked' : 'active');
    if (mounted) _toast(blocking ? AppText.t.people_blocked : AppText.t.people_unblocked);
  }

  Future<void> _remove(Membership m) async {
    final ok = await _confirm(
      AppText.t.people_removeTitle,
      AppText.t.people_removeBody(_who(m)),
      danger: true,
    );
    if (ok != true) return;
    await _memberships.delete(m.id);
    if (mounted) _toast(AppText.t.people_removed);
  }

  Future<void> _editExpiry(Membership m) async {
    final now = warsawToday();
    final initial = _parse(m.expiresAt) ?? DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      helpText: AppText.t.people_expiryTitle,
      cancelText: AppText.t.common_cancel,
      confirmText: AppText.t.common_save,
    );
    if (picked == null) return;
    final str = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    await _memberships.update(m.id, expiresAt: str);
    if (mounted) _toast(AppText.t.people_expiryUpdated);
  }

  Future<bool?> _confirm(String title, String body, {bool danger = false}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title,
            style: GoogleFonts.playfairDisplay(
                fontSize: 18, fontWeight: FontWeight.w700)),
        content: Text(body,
            style: GoogleFonts.inter(
                fontSize: 13, height: 1.5, color: AppColors.textLight)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppText.t.common_cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor:
                    danger ? const Color(0xFFC0392B) : AppColors.accent),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppText.t.common_confirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = warsawToday();
    return Scaffold(
      backgroundColor: AppColors.bgGradient.last,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        title: Text(AppText.t.people_title,
            style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.text)),
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
          child: StreamBuilder<List<Membership>>(
            stream: _memberships.watchForWedding(widget.weddingId),
            builder: (context, snapshot) {
              final people = [...(snapshot.data ?? const <Membership>[])];
              // Kolejność: owner, potem planer/współorganizator, potem goście.
              people.sort((a, b) => _rank(a.role).compareTo(_rank(b.role)));
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _introCard(),
                  const SizedBox(height: 12),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.accent),
                      ),
                    )
                  else
                    for (final m in people) ...[
                      _personCard(m, today),
                      const SizedBox(height: 10),
                    ],
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _addPerson,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            icon: const Icon(Icons.person_add_alt_1),
            label: Text(AppText.t.people_add,
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }

  Widget _introCard() {
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
          const Icon(Icons.admin_panel_settings_outlined,
              color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppText.t.people_intro,
              style: GoogleFonts.inter(
                  fontSize: 13, height: 1.45, color: AppColors.text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _personCard(Membership m, DateTime today) {
    final isOwner = m.isOwner;
    final isSelf = m.userId == widget.currentUserId;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.10),
            ),
            child: Icon(_roleIcon(m.role), color: AppColors.accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _who(m) + (isSelf ? AppText.t.people_you : ''),
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _chip(m.roleLabel, AppColors.accent),
                    _statusChip(m, today),
                    if (m.role == 'planner' && m.expiresAt != null)
                      Text(AppText.t.people_validUntil(_dateLabel(m.expiresAt)),
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.textLight)),
                    if (m.isPending && m.inviteCode != null)
                      Text(AppText.t.people_code('${m.inviteCode}'),
                          style: GoogleFonts.robotoMono(
                              fontSize: 11, color: AppColors.textLight)),
                  ],
                ),
              ],
            ),
          ),
          // Owner — brak akcji (nieusuwalny, niezablokowany).
          if (isOwner)
            const Padding(
              padding: EdgeInsets.only(right: 8, top: 6),
              child: Icon(Icons.lock_outline, size: 18, color: Color(0xFFB0B8C8)),
            )
          else
            _actionsMenu(m),
        ],
      ),
    );
  }

  Widget _actionsMenu(Membership m) {
    return PopupMenuButton<String>(
      tooltip: AppText.t.people_actions,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (v) {
        switch (v) {
          case 'block':
          case 'restore':
            _blockOrRestore(m);
          case 'expiry':
            _editExpiry(m);
          case 'remove':
            _remove(m);
        }
      },
      itemBuilder: (context) => [
        if (m.role == 'planner' && !m.isPending)
          _menuItem('expiry', Icons.event_available, AppText.t.people_changeExpiry),
        if (!m.isBlocked)
          _menuItem('block', Icons.block, AppText.t.people_block)
        else
          _menuItem('restore', Icons.lock_open, AppText.t.people_unblock),
        _menuItem('remove', Icons.delete_outline, AppText.t.people_remove, danger: true),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label,
      {bool danger = false}) {
    final color = danger ? const Color(0xFFC0392B) : AppColors.text;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.inter(fontSize: 14, color: color)),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      );

  Widget _statusChip(Membership m, DateTime today) {
    // Kolor dobierany po STANIE, nie po etykiecie: etykieta jest tłumaczona,
    // więc porównanie tekstu przestałoby trafiać po zmianie języka.
    final color = switch (m.statusKindOn(today)) {
      MembershipStatusKind.active => const Color(0xFF059669),
      MembershipStatusKind.blocked => const Color(0xFFC0392B),
      MembershipStatusKind.expired => const Color(0xFFB7791F),
      MembershipStatusKind.pending => AppColors.textLight,
    };
    return _chip(m.statusLabelOn(today), color);
  }

  String _who(Membership m) {
    if (m.displayName.trim().isNotEmpty) return m.displayName.trim();
    if (m.email.trim().isNotEmpty) return m.email.trim();
    if (m.isOwner) return CoupleLabels.current.coupleCategoryLabel;
    if (m.isPending) return AppText.t.people_pendingInvite;
    return AppText.t.people_person;
  }

  static int _rank(String role) => switch (role) {
        'owner' => 0,
        'planner' => 1,
        'collaborator' => 2,
        'guest' => 3,
        _ => 4,
      };

  static IconData _roleIcon(String role) => switch (role) {
        'owner' => Icons.favorite,
        'planner' => Icons.event_note_outlined,
        'collaborator' => Icons.groups_outlined,
        'guest' => Icons.person_outline,
        _ => Icons.person_outline,
      };

  static String _roleLabel(String role) => switch (role) {
        'planner' => AppText.t.role_planner,
        'collaborator' => AppText.t.role_collaborator,
        'owner' => CoupleLabels.current.coupleCategoryLabel,
        'guest' => AppText.t.role_guest,
        _ => role,
      };

  static DateTime? _parse(String? s) {
    if (s == null) return null;
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(s);
    if (m == null) return null;
    return DateTime(
        int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));
  }

  static String _dateLabel(String? date) =>
      AppFormat.dateLongFromIso(date) ?? '—';
}

/// Żądanie dodania osoby zebrane z arkusza (przed potwierdzeniem).
class _AddRequest {
  _AddRequest({
    required this.method,
    required this.role,
    required this.email,
    this.expiresAt,
  });
  final String method; // 'email' | 'code'
  final String role; // 'collaborator' | 'planner'
  final String email;
  final String? expiresAt;
}

/// Arkusz dodawania osoby: rola, metoda (e-mail/kod) i data ważności planera.
class _AddPersonSheet extends StatefulWidget {
  const _AddPersonSheet();

  @override
  State<_AddPersonSheet> createState() => _AddPersonSheetState();
}

class _AddPersonSheetState extends State<_AddPersonSheet> {
  String _role = 'collaborator';
  String _method = 'email';
  final _emailCtrl = TextEditingController();
  DateTime? _expiry;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  bool get _isPlanner => _role == 'planner';

  Future<void> _pickExpiry() async {
    final now = warsawToday();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiry ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      helpText: AppText.t.people_expiryTitle,
      cancelText: AppText.t.common_cancel,
      confirmText: AppText.t.common_select,
    );
    if (picked != null) setState(() => _expiry = picked);
  }

  void _submit() {
    if (_method == 'email' && _emailCtrl.text.trim().isEmpty) return;
    if (_isPlanner && _expiry == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text(AppText.t.people_setExpiry)));
      return;
    }
    final expiresAt = _expiry == null
        ? null
        : '${_expiry!.year.toString().padLeft(4, '0')}-${_expiry!.month.toString().padLeft(2, '0')}-${_expiry!.day.toString().padLeft(2, '0')}';
    Navigator.of(context).pop(_AddRequest(
      method: _method,
      role: _role,
      email: _emailCtrl.text.trim(),
      expiresAt: _isPlanner ? expiresAt : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCE4F2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(AppText.t.people_add,
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
                const SizedBox(height: 16),
                _label(AppText.t.people_role),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _roleChip('collaborator', AppText.t.role_collaborator,
                        Icons.groups_outlined),
                    const SizedBox(width: 8),
                    _roleChip('planner', AppText.t.role_planner, Icons.event_note_outlined),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _isPlanner
                      ? AppText.t.people_plannerHint
                      : AppText.t.people_collaboratorHint,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textLight),
                ),
                if (_isPlanner) ...[
                  const SizedBox(height: 14),
                  _label(AppText.t.people_expiry),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _pickExpiry,
                    borderRadius: BorderRadius.circular(10),
                    child: InputDecorator(
                      decoration: _dec(),
                      child: Row(
                        children: [
                          const Icon(Icons.event,
                              size: 20, color: AppColors.accent),
                          const SizedBox(width: 10),
                          Text(
                            _expiry == null
                                ? AppText.t.people_pickDate
                                : _dateLabel(_expiry!),
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                color: _expiry == null
                                    ? AppColors.textLight
                                    : AppColors.text),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _label(AppText.t.people_howToAdd),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _methodChip('email', AppText.t.people_byEmail, Icons.alternate_email),
                    const SizedBox(width: 8),
                    _methodChip('code', AppText.t.people_byCode, Icons.vpn_key_outlined),
                  ],
                ),
                if (_method == 'email') ...[
                  const SizedBox(height: 14),
                  _label(AppText.t.people_email),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _dec(hint: AppText.t.people_emailHint),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Text(
                    AppText.t.people_codeHint,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textLight),
                  ),
                ],
                const SizedBox(height: 22),
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
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(AppText.t.common_next,
                            style:
                                GoogleFonts.inter(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleChip(String value, String label, IconData icon) =>
      _selectChip(value == _role, label, icon, () => setState(() => _role = value));

  Widget _methodChip(String value, String label, IconData icon) => _selectChip(
      value == _method, label, icon, () => setState(() => _method = value));

  Widget _selectChip(
      bool selected, String label, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.10)
                : const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.accent : const Color(0xFFDCE4F2),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: selected ? AppColors.accent : AppColors.textLight),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color:
                            selected ? AppColors.accent : AppColors.textLight)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text));

  InputDecoration _dec({String hint = ''}) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: AppColors.textLight, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF8FAFF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDCE4F2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      );

  static String _dateLabel(DateTime date) =>
      AppFormat.dateLong(date);
}
