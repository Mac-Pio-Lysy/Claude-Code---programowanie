import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/guest_visibility.dart';
import '../../services/firestore_service.dart';
import '../../services/guest_visibility_service.dart';
import '../../services/wedding_service.dart';
import '../../utils/warsaw_time.dart';
import '../../utils/app_format.dart';
import '../../l10n/app_text.dart';

/// Panel właściciela: „Widoczność dla gości" — steruje tym, KIEDY każda sekcja
/// jest widoczna na stronach publicznych dla gości.
///
/// Główny przełącznik (cała strona) + osobne przełączniki per sekcja, każda
/// z opcjonalnymi datami OD/DO i wyborem, co widzi gość poza zakresem
/// (komunikat lub ukrycie). Ustawienia zapisywane przy weselu (`weddings/{id}`).
class GuestVisibilityScreen extends StatefulWidget {
  GuestVisibilityScreen({
    super.key,
    required this.firestore,
    required Map<String, dynamic> raw,
  }) : initial = GuestVisibility.fromRaw(raw);

  final FirestoreService firestore;
  final GuestVisibility initial;

  @override
  State<GuestVisibilityScreen> createState() => _GuestVisibilityScreenState();
}

class _GuestVisibilityScreenState extends State<GuestVisibilityScreen> {
  late final GuestVisibilityService _service =
      GuestVisibilityService(firestore: widget.firestore);

  late bool _master;
  late Map<String, SectionVisibility> _sections;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _master = widget.initial.masterEnabled;
    // Kopia robocza dla wszystkich znanych sekcji (domyślne, gdy brak zapisu).
    _sections = {
      for (final s in kGuestSections) s.key: widget.initial.sectionFor(s.key),
    };
  }

  GuestVisibility get _current =>
      GuestVisibility(masterEnabled: _master, sections: _sections);

  void _updateSection(String key, SectionVisibility value) {
    setState(() => _sections = {..._sections, key: value});
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _service.save(_current);
      // Odśwież publiczny mirror gościa (widoczność sekcji na stronie web).
      try {
        await WeddingService().ensureGuestToken(widget.firestore.weddingId);
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text(AppText.t.vis_saved)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(AppText.t.common_saveErrorToast('$e'))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<String?> _pickDate(String? current) async {
    final now = warsawToday();
    final initial = AppFormat.parseIso(current) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      cancelText: AppText.t.common_cancel,
      confirmText: AppText.t.common_select,
    );
    if (picked == null) return null;
    return '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
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
          AppText.t.vis_title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              _introCard(),
              const SizedBox(height: 12),
              _masterCard(),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                child: Text(
                  AppText.t.vis_sectionsHeader,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: AppColors.textLight,
                  ),
                ),
              ),
              for (final s in kGuestSections) ...[
                _SectionCard(
                  def: s,
                  value: _sections[s.key]!,
                  masterEnabled: _master,
                  state: _current.stateOf(s.key, warsawToday()),
                  onChanged: (v) => _updateSection(s.key, v),
                  onPickDate: _pickDate,
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: _saveBar(),
    );
  }

  Widget _saveBar() {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save_outlined),
          label: Text(
            _saving ? AppText.t.vis_saving : AppText.t.vis_save,
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
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
          const Icon(Icons.visibility_outlined, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppText.t.vis_intro,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.45,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _masterCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _master ? AppColors.accent : const Color(0xFFE2EAF7),
          width: _master ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.10),
            ),
            child: Icon(
              _master ? Icons.public : Icons.public_off,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppText.t.vis_masterTitle,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  _master
                      ? AppText.t.vis_masterOn
                      : AppText.t.vis_masterOff,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textLight),
                ),
              ],
            ),
          ),
          Switch(
            value: _master,
            activeThumbColor: AppColors.accent,
            onChanged: (v) => setState(() => _master = v),
          ),
        ],
      ),
    );
  }

}

/// Karta pojedynczej sekcji: przełącznik, daty OD/DO, zachowanie poza zakresem
/// oraz aktualny status widoczności.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.def,
    required this.value,
    required this.masterEnabled,
    required this.state,
    required this.onChanged,
    required this.onPickDate,
  });

  final GuestSectionDef def;
  final SectionVisibility value;
  final bool masterEnabled;
  final VisibilityState state;
  final ValueChanged<SectionVisibility> onChanged;
  final Future<String?> Function(String? current) onPickDate;

  /// Sekcje z wpisami PODPISANYMI imieniem gościa — tylko tu przełącznik ma
  /// sens (etap 8). Pozostałe sekcje (RSVP, harmonogram, muzyka, kapsuła,
  /// gry) albo są organizatorskie, albo nie mają autorskiego wpisu do ukrycia.
  bool get _showsAuthorNames => const {
        'guestbook',
        'advice',
        'guestMap',
        'gallery',
        'photoChallenge',
      }.contains(def.key);

  @override
  Widget build(BuildContext context) {
    final dimmed = !masterEnabled;
    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 12),
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
                Icon(def.icon, size: 22, color: AppColors.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    def.label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ),
                Switch(
                  value: value.enabled,
                  activeThumbColor: AppColors.accent,
                  onChanged: masterEnabled
                      ? (v) => onChanged(value.copyWith(enabled: v))
                      : null,
                ),
              ],
            ),
            _statusChip(),
            if (value.enabled && masterEnabled) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _dateField(
                      context,
                      label: AppText.t.vis_from,
                      value: value.from,
                      onPick: () async {
                        final d = await onPickDate(value.from);
                        if (d != null) onChanged(value.copyWith(from: d));
                      },
                      onClear: () => onChanged(value.copyWith(clearFrom: true)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dateField(
                      context,
                      label: AppText.t.vis_to,
                      value: value.to,
                      onPick: () async {
                        final d = await onPickDate(value.to);
                        if (d != null) onChanged(value.copyWith(to: d));
                      },
                      onClear: () => onChanged(value.copyWith(clearTo: true)),
                    ),
                  ),
                ],
              ),
            ],
            if (_showsAuthorNames && value.enabled && masterEnabled) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppText.t.vis_showAuthorNames,
                      style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.text),
                    ),
                  ),
                  Switch(
                    value: value.showAuthorNames,
                    activeThumbColor: AppColors.accent,
                    onChanged: (v) =>
                        onChanged(value.copyWith(showAuthorNames: v)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Text(
              AppText.t.vis_outOfRange,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            _behaviorSelector(),
          ],
        ),
      ),
    );
  }

  Widget _behaviorSelector() {
    Widget chip(String mode, String label, IconData icon) {
      final selected = value.outOfRange == mode;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: masterEnabled
              ? () => onChanged(value.copyWith(outOfRange: mode))
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
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
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.accent : AppColors.textLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(OutOfRangeMode.message, AppText.t.vis_showMessage, Icons.info_outline),
        const SizedBox(width: 8),
        chip(OutOfRangeMode.hide, AppText.t.vis_hideSection, Icons.visibility_off_outlined),
      ],
    );
  }

  Widget _dateField(
    BuildContext context, {
    required String label,
    required String? value,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    final has = value != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDCE4F2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.event, size: 16, color: AppColors.accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    has ? _dateLabel(value) : '—',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: has ? AppColors.text : AppColors.textLight,
                    ),
                  ),
                ),
                if (has)
                  GestureDetector(
                    onTap: onClear,
                    child: const Icon(Icons.close,
                        size: 16, color: AppColors.textLight),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChip() {
    final (label, color, bg) = _statusStyle();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, Color, Color) _statusStyle() {
    const green = Color(0xFF059669);
    const amber = Color(0xFFB7791F);
    const grey = AppColors.textLight;
    switch (state) {
      case VisibilityState.visible:
        return (AppText.t.vis_stateVisible, green, green.withValues(alpha: 0.10));
      case VisibilityState.beforeStart:
        return (
          AppText.t.vis_stateFrom(_dateLabel(value.from)),
          amber,
          amber.withValues(alpha: 0.12)
        );
      case VisibilityState.afterEnd:
        return (
          AppText.t.vis_stateTo(_dateLabel(value.to)),
          grey,
          const Color(0xFFEEF2F8)
        );
      case VisibilityState.disabled:
        return (AppText.t.vis_stateOff, grey, const Color(0xFFEEF2F8));
      case VisibilityState.masterOff:
        return (
          AppText.t.vis_stateMasterOff,
          grey,
          const Color(0xFFEEF2F8)
        );
    }
  }

  static String _dateLabel(String? date) =>
      AppFormat.dateLongFromIso(date) ?? '—';
}
