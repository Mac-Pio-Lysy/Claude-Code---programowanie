import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/photo_contest.dart';
import '../../models/wedding_data.dart';
import '../../services/firestore_service.dart';
import '../../services/guest_space_service.dart';
import '../../services/photo_contest_service.dart';
import '../../services/wedding_service.dart';
import '../../utils/app_format.dart';
import '../../utils/warsaw_time.dart';
import '../../l10n/app_text.dart';
import 'photo_contest_results_screen.dart';

/// Etap 1 „Konkursów fotograficznych z głosowaniem": konfiguracja konkursów
/// przez organizatora (nazwa, podkategorie, rozmiar rankingu, tryb
/// ujawnienia wyników). Zgłaszanie zdjęć i głosowanie gości (etapy 2-3)
/// dochodzą w kolejnych partiach — ten ekran tylko zakłada/edytuje konkursy.
///
/// Zero zmian w regułach Firestore: zapis idzie przez zwykły
/// `weddings/{id}` (`fullAccess`), tak jak `photoChallengeTasks`.
class PhotoContestScreen extends StatefulWidget {
  PhotoContestScreen(
      {super.key, required this.data, required FirestoreService firestore})
      : _firestore = firestore,
        service = PhotoContestService(firestore: firestore);

  final WeddingData? data;
  final FirestoreService _firestore;
  final PhotoContestService service;

  @override
  State<PhotoContestScreen> createState() => _PhotoContestScreenState();
}

class _PhotoContestScreenState extends State<PhotoContestScreen> {
  Map<int, PhotoContest> get _contests =>
      PhotoContest.mapFromRaw(widget.data?.raw['photoContests']);

  String get _guestToken => (widget.data?.raw['guestToken'] as String?)?.trim() ?? '';

  bool _autoRevealChecked = false;

  @override
  void initState() {
    super.initState();
    // Etap 6: sprawdzenie best-effort — bez Cloud Function nic nie „budzi
    // się" samo o określonej godzinie, więc robimy to przy KAŻDYM otwarciu
    // tego ekranu przez organizatora. Raz na wejście na ekran (nie przy
    // każdym rebuildzie po zapisie) — stąd `_autoRevealChecked`.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAutoReveal());
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Po każdym zapisie konfiguracji odświeżamy publiczny mirror gościa —
  /// ten sam krok, co przy widoczności sekcji (`guest_visibility_screen`).
  Future<void> _resync() async {
    try {
      await WeddingService().ensureGuestToken(widget._firestore.weddingId);
    } catch (_) {}
  }

  /// Etap 6 — automatyczne ujawnienie po dacie, BEST-EFFORT (patrz plan,
  /// ryzyko #2): wyniki pojawią się u gości dopiero, gdy KTOŚ z organizacji
  /// otworzy ten ekran po `revealDate`. Liczy ranking dokładnie tak samo
  /// jak przycisk ręczny (`PhotoContestService.revealSubcategory`) — bez
  /// werdyktu Pary Młodej (ten organizator ustawia ręcznie w ekranie
  /// wyników; auto-ujawnienie nie nadpisuje go, jeśli już istnieje, bo
  /// `revealSubcategory` z `coupleChoice: null` zostawia poprzedni wpis
  /// przez `Map.from(c.coupleChoice)` w `publishResults`).
  Future<void> _checkAutoReveal() async {
    if (_autoRevealChecked || !mounted) return;
    _autoRevealChecked = true;
    final token = _guestToken;
    if (token.isEmpty) return;
    final today = warsawToday();
    final guestSpace = GuestSpaceService(token: token);
    var revealedAny = false;
    for (final c in _contests.values) {
      if (!c.active || c.revealMode != ContestRevealMode.auto) continue;
      final revealDate = AppFormat.parseIso(c.revealDate);
      if (revealDate == null) continue;
      final due = !today.isBefore(DateTime(revealDate.year, revealDate.month, revealDate.day));
      if (!due) continue;
      for (final sub in c.subcategories) {
        if (c.isSubcategoryRevealed(sub.id)) continue;
        try {
          await widget.service.revealSubcategory(
            guestSpace: guestSpace,
            contestId: c.id,
            subcategoryId: sub.id,
            rankingSize: c.rankingSize,
          );
          revealedAny = true;
        } catch (_) {
          // Best-effort — pojedyncza nieudana podkategoria nie przerywa
          // reszty, spróbujemy ponownie przy następnym otwarciu ekranu.
        }
      }
    }
    if (revealedAny) {
      await _resync();
      if (mounted) setState(() {});
    }
  }

  void _openResults(PhotoContest c) {
    final token = _guestToken;
    if (token.isEmpty) {
      _toast(AppText.t.contest_noGuestToken);
      return;
    }
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => ContestResultsScreen(
            contest: c,
            service: widget.service,
            guestToken: token,
            weddingId: widget._firestore.weddingId,
          ),
        ))
        .then((_) => mounted ? setState(() {}) : null);
  }

  @override
  Widget build(BuildContext context) {
    final contests = _contests.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: contests.isEmpty
              ? _empty()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  children: [for (final c in contests) _contestCard(c)],
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add),
                label: Text(AppText.t.contest_add),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle:
                      GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 34)),
              const SizedBox(height: 10),
              Text(AppText.t.contest_empty,
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
              const SizedBox(height: 6),
              Text(AppText.t.contest_emptyHint,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight)),
            ],
          ),
        ),
      );

  Widget _contestCard(PhotoContest c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
              Expanded(
                child: Text(c.name,
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
              ),
              IconButton(
                onPressed: () => _openResults(c),
                icon: const Icon(Icons.leaderboard_outlined, size: 18),
                color: AppColors.accent,
                visualDensity: VisualDensity.compact,
                tooltip: AppText.t.contest_results,
              ),
              IconButton(
                onPressed: () => _manageSubcategories(c),
                icon: const Icon(Icons.list_alt_outlined, size: 18),
                color: AppColors.accent,
                visualDensity: VisualDensity.compact,
                tooltip: AppText.t.contest_subcategories,
              ),
              IconButton(
                onPressed: () => _openForm(existing: c),
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: AppColors.accent,
                visualDensity: VisualDensity.compact,
                tooltip: AppText.t.common_edit,
              ),
              IconButton(
                onPressed: () => _confirmDelete(c),
                icon: const Icon(Icons.delete_outline, size: 18),
                color: const Color(0xFFC0392B),
                visualDensity: VisualDensity.compact,
                tooltip: AppText.t.common_delete,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chip(AppText.t.contest_subcategoriesCount(c.subcategories.length)),
              _chip('Top ${c.rankingSize}'),
              _chip(c.revealMode == ContestRevealMode.auto
                  ? '${AppText.t.contest_revealAuto}${c.revealDate != null ? ' (${c.revealDate})' : ''}'
                  : AppText.t.contest_revealManual),
              if (!c.active)
                _chip(AppText.t.contest_active, off: true),
            ],
          ),
          if (c.subcategories.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(c.subcategories.map((s) => s.label).join(' • '),
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight)),
          ],
        ],
      ),
    );
  }

  Widget _chip(String text, {bool off = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: off ? const Color(0xFFFDECEA) : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text,
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: off ? const Color(0xFFC0392B) : AppColors.accent)),
      );

  Future<void> _confirmDelete(PhotoContest c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(AppText.t.contest_deleteTitle),
        content: Text(AppText.t.contest_deleteBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppText.t.common_cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC0392B)),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppText.t.common_delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await widget.service.deleteContest(c.id);
      await _resync();
    }
  }

  Future<void> _openForm({PhotoContest? existing}) async {
    final result = await showDialog<_ContestFormResult>(
      context: context,
      builder: (context) => _ContestFormDialog(existing: existing),
    );
    if (result == null) return;
    if (existing == null) {
      await widget.service.createContest(
        name: result.name,
        subcategoryLabels: result.subcategoryLabels,
        rankingSize: result.rankingSize,
        revealMode: result.revealMode,
        revealDate: result.revealDate,
      );
    } else {
      await widget.service.updateContest(
        existing.id,
        name: result.name,
        rankingSize: result.rankingSize,
        revealMode: result.revealMode,
        revealDate: result.revealDate,
        clearRevealDate: result.revealMode == ContestRevealMode.manual,
        active: result.active,
      );
    }
    await _resync();
    if (mounted) _toast(AppText.t.common_save);
  }

  /// Podkategorie ISTNIEJĄCEGO konkursu zarządzane osobno (dodaj/zmień
  /// nazwę/usuń pojedynczo), nie przez nadpisanie całej listy jak przy
  /// zakładaniu — inaczej łatwo byłoby przypadkiem przesunąć/skasować ID,
  /// do którego mogą już się odwoływać zgłoszenia/głosy z etapów 2-3.
  Future<void> _manageSubcategories(PhotoContest c) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _SubcategoriesDialog(service: widget.service, contest: c),
    );
    await _resync();
    if (mounted) setState(() {});
  }
}

class _ContestFormResult {
  _ContestFormResult({
    required this.name,
    required this.subcategoryLabels,
    required this.rankingSize,
    required this.revealMode,
    required this.revealDate,
    required this.active,
  });

  final String name;
  final List<String> subcategoryLabels;
  final int rankingSize;
  final String revealMode;
  final String? revealDate;
  final bool active;
}

class _ContestFormDialog extends StatefulWidget {
  const _ContestFormDialog({this.existing});

  final PhotoContest? existing;

  @override
  State<_ContestFormDialog> createState() => _ContestFormDialogState();
}

class _ContestFormDialogState extends State<_ContestFormDialog> {
  late final _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
  late final List<TextEditingController> _subCtrls = widget.existing == null
      ? [TextEditingController()]
      : [for (final s in widget.existing!.subcategories) TextEditingController(text: s.label)];
  late int _rankingSize = widget.existing?.rankingSize ?? 10;
  late String _revealMode = widget.existing?.revealMode ?? ContestRevealMode.manual;
  late String? _revealDate = widget.existing?.revealDate;
  late bool _active = widget.existing?.active ?? true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (final c in _subCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = warsawToday();
    final picked = await showDatePicker(
      context: context,
      initialDate: AppFormat.parseIso(_revealDate) ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      cancelText: AppText.t.common_cancel,
      confirmText: AppText.t.common_select,
    );
    if (picked == null) return;
    setState(() => _revealDate =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final cleanLabels = [for (final c in _subCtrls) c.text.trim()]
      ..removeWhere((s) => s.isEmpty);
    if (name.isEmpty) return;
    if (widget.existing == null && cleanLabels.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(AppText.t.contest_subcategoriesEmpty)));
      return;
    }
    Navigator.of(context).pop(_ContestFormResult(
      name: name,
      subcategoryLabels: cleanLabels,
      rankingSize: _rankingSize,
      revealMode: _revealMode,
      revealDate: _revealMode == ContestRevealMode.auto ? _revealDate : null,
      active: _active,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(isNew ? AppText.t.contest_add : AppText.t.contest_edit),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(labelText: AppText.t.contest_name),
              ),
              const SizedBox(height: 14),
              if (isNew) ...[
                Text(AppText.t.contest_subcategories,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                for (var i = 0; i < _subCtrls.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _subCtrls[i],
                            decoration:
                                InputDecoration(hintText: AppText.t.contest_subcategoryLabel),
                          ),
                        ),
                        if (_subCtrls.length > 1)
                          IconButton(
                            onPressed: () => setState(() => _subCtrls.removeAt(i).dispose()),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                      ],
                    ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _subCtrls.add(TextEditingController())),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(AppText.t.contest_addSubcategory),
                  ),
                ),
                const SizedBox(height: 8),
              ] else
                Text(
                  '${AppText.t.contest_subcategories}: ${widget.existing!.subcategories.map((s) => s.label).join(', ')}',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
                ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                initialValue: _rankingSize,
                decoration: InputDecoration(labelText: AppText.t.contest_rankingSize),
                items: const [10, 15, 20]
                    .map((n) => DropdownMenuItem(value: n, child: Text('Top $n')))
                    .toList(),
                onChanged: (v) => setState(() => _rankingSize = v ?? 10),
              ),
              const SizedBox(height: 14),
              Text(AppText.t.contest_revealMode,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
              RadioGroup<String>(
                groupValue: _revealMode,
                onChanged: (v) => setState(() => _revealMode = v ?? ContestRevealMode.manual),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      value: ContestRevealMode.manual,
                      title: Text(AppText.t.contest_revealManual),
                    ),
                    RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      value: ContestRevealMode.auto,
                      title: Text(AppText.t.contest_revealAuto),
                    ),
                  ],
                ),
              ),
              if (_revealMode == ContestRevealMode.auto)
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 8),
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.event, size: 16),
                    label: Text(_revealDate ?? AppText.t.contest_revealDate),
                  ),
                ),
              if (!isNew)
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.accent,
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                  title: Text(AppText.t.contest_active),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppText.t.common_cancel)),
        FilledButton(onPressed: _submit, child: Text(AppText.t.common_save)),
      ],
    );
  }
}

/// Zarządzanie podkategoriami POJEDYNCZO (dodaj/zmień nazwę/usuń) — patrz
/// komentarz przy `_manageSubcategories`.
class _SubcategoriesDialog extends StatefulWidget {
  const _SubcategoriesDialog({required this.service, required this.contest});

  final PhotoContestService service;
  final PhotoContest contest;

  @override
  State<_SubcategoriesDialog> createState() => _SubcategoriesDialogState();
}

class _SubcategoriesDialogState extends State<_SubcategoriesDialog> {
  late PhotoContest _contest = widget.contest;
  final _newCtrl = TextEditingController();

  @override
  void dispose() {
    _newCtrl.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final all = await widget.service.readContests();
    final updated = all[_contest.id];
    if (updated != null && mounted) setState(() => _contest = updated);
  }

  Future<void> _add() async {
    final label = _newCtrl.text.trim();
    if (label.isEmpty) return;
    await widget.service.addSubcategory(_contest.id, label);
    _newCtrl.clear();
    await _reload();
  }

  Future<void> _rename(int subId, String label) async {
    if (label.trim().isEmpty) return;
    await widget.service.renameSubcategory(_contest.id, subId, label);
    await _reload();
  }

  Future<void> _delete(int subId) async {
    await widget.service.deleteSubcategory(_contest.id, subId);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(AppText.t.contest_subcategories),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final s in _contest.subcategories)
              _SubcategoryRow(
                key: ValueKey(s.id),
                initial: s.label,
                onRenamed: (v) => _rename(s.id, v),
                onDeleted: () => _delete(s.id),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newCtrl,
                    decoration:
                        InputDecoration(hintText: AppText.t.contest_subcategoryLabel),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                IconButton(onPressed: _add, icon: const Icon(Icons.add)),
              ],
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppText.t.common_close),
        ),
      ],
    );
  }
}

/// Pole edycji jednej podkategorii z zapisem `onSubmitted`/przy utracie
/// fokusu — bez osobnego przycisku „zapisz" per wiersz.
class _SubcategoryRow extends StatefulWidget {
  const _SubcategoryRow(
      {super.key, required this.initial, required this.onRenamed, required this.onDeleted});

  final String initial;
  final ValueChanged<String> onRenamed;
  final VoidCallback onDeleted;

  @override
  State<_SubcategoryRow> createState() => _SubcategoryRowState();
}

class _SubcategoryRowState extends State<_SubcategoryRow> {
  late final _ctrl = TextEditingController(text: widget.initial);
  late final _focus = FocusNode()..addListener(_onFocusChange);

  void _onFocusChange() {
    if (!_focus.hasFocus && _ctrl.text.trim() != widget.initial) {
      widget.onRenamed(_ctrl.text);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              onSubmitted: widget.onRenamed,
              decoration: const InputDecoration(isDense: true),
            ),
          ),
          IconButton(
            onPressed: widget.onDeleted,
            icon: const Icon(Icons.delete_outline, size: 18),
            color: const Color(0xFFC0392B),
          ),
        ],
      ),
    );
  }
}
