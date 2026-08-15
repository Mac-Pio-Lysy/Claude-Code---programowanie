import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';
import '../models/planning_step.dart';
import 'onboarding_steps.dart';
import '../l10n/app_text.dart';

/// Pełnoekranowa nakładka przewodnika: przyciemnione tło ze „światłem"
/// (spotlight) na omawianym elemencie nawigacji oraz dymek z opisem,
/// licznikiem postępu i przyciskami Wstecz / Pomiń / Dalej.
class OnboardingOverlay extends StatefulWidget {
  const OnboardingOverlay({
    super.key,
    required this.step,
    required this.index,
    required this.total,
    required this.resolve,
    required this.onPrev,
    required this.onNext,
    required this.onSkip,
  });

  final OnbStep step;
  final int index;
  final int total;

  /// Zwraca globalny prostokąt podświetlanego elementu (lub null → wyśrodkuj).
  final Rect? Function(OnbStep step) resolve;

  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<OnboardingOverlay>
    with WidgetsBindingObserver {
  Rect? _rect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleRecompute();
  }

  @override
  void didUpdateWidget(OnboardingOverlay old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) _scheduleRecompute();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() => _scheduleRecompute();

  /// Przelicza pozycję po przebudowie widoku oraz raz jeszcze po animacjach
  /// przejścia (zmiana sekcji / podzakładki).
  void _scheduleRecompute() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _recompute());
    Future.delayed(const Duration(milliseconds: 280), _recompute);
  }

  void _recompute() {
    if (!mounted) return;
    final r = widget.step.nav ? widget.resolve(widget.step) : null;
    if (r != _rect) setState(() => _rect = r);
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final last = widget.index >= widget.total - 1;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Przyciemnione tło z wycięciem (pochłania dotknięcia tła).
          Positioned.fill(
            child: GestureDetector(
              onTap: () {},
              child: CustomPaint(painter: _SpotlightPainter(_rect)),
            ),
          ),
          _positionedCard(screen, last),
        ],
      ),
    );
  }

  Widget _positionedCard(Size screen, bool last) {
    final card = _card(last);
    final rect = _rect;
    const gap = 14.0;

    if (rect == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            // Przewijanie na wypadek niskiego ekranu — dymek kroku
            // „Od czego zacząć?" niesie dodatkową listę.
            child: SingleChildScrollView(child: card),
          ),
        ),
      );
    }

    // Szyna nawigacji po lewej (tablet) — dymek po prawej stronie elementu.
    if (rect.center.dx < screen.width * 0.33 && rect.width < 170) {
      return Positioned(
        left: rect.right + gap,
        right: 16,
        top: 24,
        child: _capped(card),
      );
    }
    // Dolny pasek — dymek nad elementem.
    if (rect.center.dy > screen.height * 0.6) {
      return Positioned(
        left: 16,
        right: 16,
        bottom: screen.height - rect.top + gap,
        child: _capped(card),
      );
    }
    // Element u góry — dymek pod nim.
    return Positioned(
      left: 16,
      right: 16,
      top: rect.bottom + gap,
      child: _capped(card),
    );
  }

  Widget _capped(Widget card) => Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: card,
        ),
      );

  /// Podgląd kilku pierwszych kroków listy „Od czego zacząć?".
  ///
  /// Pokazujemy listę domyślną, a nie zapisany stan wesela — to ilustracja
  /// w przewodniku, nie panel do odhaczania. Pełną listę użytkownik otwiera
  /// z Ustawień.
  Widget _planningPreview() {
    const shown = 5;
    final items = PlanningStep.defaults.take(shown).toList();
    final rest = PlanningStep.defaults.length - items.length;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_box_outline_blank,
                      size: 15, color: AppColors.accent.withValues(alpha: 0.7)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      items[i].$1,
                      style: GoogleFonts.inter(
                          fontSize: 12.5, height: 1.35, color: AppColors.text),
                    ),
                  ),
                ],
              ),
            ),
          if (rest > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 23),
              child: Text(AppText.t.onb_moreSteps(rest),
                  style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textLight)),
            ),
        ],
      ),
    );
  }


  Widget _card(bool last) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EAF7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.22),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppText.t.onb_stepHeader(widget.step.title),
              style: GoogleFonts.playfairDisplay(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text)),
          const SizedBox(height: 8),
          Text(widget.step.desc,
              style: GoogleFonts.inter(
                  fontSize: 13.5, height: 1.5, color: AppColors.textLight)),
          // Krok „Od czego zacząć?" nie podświetla żadnego przycisku — panel
          // jest osobnym ekranem. Zamiast pustego dymka pokazujemy podgląd
          // pierwszych kroków planowania, żeby było widać, o czym mowa (#18).
          if (widget.step.planning) _planningPreview(),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (widget.index + 1) / widget.total,
              minHeight: 6,
              backgroundColor: const Color(0xFFEAF1FB),
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(AppText.t.onb_stepCounter(widget.index + 1, widget.total),
                  style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent)),
              const Spacer(),
              TextButton(
                onPressed: widget.onSkip,
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.textLight),
                child: Text(AppText.t.onb_skip),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (widget.index > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onPrev,
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: Text(AppText.t.common_back),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
              if (widget.index > 0) const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: widget.onNext,
                  icon: Icon(last ? Icons.check : Icons.arrow_forward, size: 16),
                  label: Text(last ? AppText.t.onb_finish : AppText.t.common_next),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Rysuje przyciemnione tło z wycięciem (spotlight) na podanym prostokącie.
class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter(this.hole);
  final Rect? hole;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = const Color(0xD90B1B3A);
    final full = Offset.zero & size;
    if (hole == null) {
      canvas.drawRect(full, scrim);
      return;
    }
    final r = hole!.inflate(8);
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(14));
    final path = Path.combine(
      PathOperation.difference,
      Path()..addRect(full),
      Path()..addRRect(rr),
    );
    canvas.drawPath(path, scrim);
    canvas.drawRRect(
      rr,
      Paint()
        ..color = const Color(0xFF60A5FA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) => old.hole != hole;
}

/// Ekran powitalny przewodnika — wybór tempa (Podstawy / Pełny).
/// Zwraca `'basic'`, `'full'` lub `null` (gdy pominięto).
/// Wybór dokonany na ekranie powitalnym przewodnika.
class OnbChoice {
  const OnbChoice(this.mode, this.variant);

  /// `basic` — skrócona forma, `full` — rozszerzona, `setup` — kreator
  /// konfiguracji „Poprowadź mnie za rękę" (zamiast zwiedzania).
  final String mode;

  /// Czy zamiast przewodnika uruchomić kreator konfiguracji (#17).
  bool get isSetupWizard => mode == 'setup';

  /// Wariant do uruchomienia. Zwykle zgodny z rolą, ale właściciel i planer
  /// mogą wybrać podgląd przewodnika gościa.
  final OnbVariant variant;

  bool get isBasic => mode == 'basic';
}

/// Ekran powitalny przewodnika: wybór tempa (skrócony / rozszerzony), a dla
/// właściciela i planera dodatkowo podgląd przewodnika gościa.
///
/// Zwraca `null`, gdy użytkownik pominął przewodnik.
Future<OnbChoice?> showOnboardingIntro(
  BuildContext context, {
  OnbVariant variant = OnbVariant.owner,
}) async {
  final mode = await _showIntroDialog(context, variant);
  if (mode == null) return null;
  if (mode == 'guest') {
    // Podgląd strefy gości dla organizatora — drugi ekran uprzedza, że gość
    // ogląda to na zupełnie innym interfejsie (#21).
    if (!context.mounted) return null;
    final guestMode =
        await _showIntroDialog(context, OnbVariant.guest, preview: true);
    if (guestMode == null || guestMode == 'guest') return null;
    return OnbChoice(guestMode, OnbVariant.guest);
  }
  return OnbChoice(mode, variant);
}

/// Teksty ekranu powitalnego zależne od wariantu.
({String title, String desc, String basicSub, String fullSub}) _introTexts(
    OnbVariant v) {
  return switch (v) {
    // Gość ma JEDEN przewodnik — zawsze całość, bez wyboru tempa (#21).
    // `basicSub`/`fullSub` nie są dla niego używane.
    OnbVariant.guest => (
        title: AppText.t.onb_guestTitle,
        desc: AppText.t.onb_guestIntro,
        basicSub: '',
        fullSub: '',
      ),
    OnbVariant.planner => (
        title: AppText.t.onb_plannerTitle,
        desc: AppText.t.onb_plannerIntro,
        basicSub: AppText.t.onb_plannerShort,
        fullSub: AppText.t.onb_plannerFull,
      ),
    OnbVariant.owner => (
        title: AppText.t.onb_ownerTitle,
        desc: AppText.t.onb_ownerIntro,
        basicSub: AppText.t.onb_ownerShort,
        fullSub: AppText.t.onb_ownerFull,
      ),
  };
}

/// [preview] — organizator ogląda przewodnik gościa, a nie własny. Dokładamy
/// wtedy uprzedzenie, że u gościa wygląda to inaczej.
Future<String?> _showIntroDialog(BuildContext context, OnbVariant variant,
    {bool preview = false}) {
  final t = _introTexts(variant);
  final isGuest = variant == OnbVariant.guest;
  final offerGuestPreview = !isGuest;
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(variant == OnbVariant.guest ? '💍' : '🧭',
                  style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 10),
              Text(t.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text)),
              const SizedBox(height: 8),
              Text(
                t.desc,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 13.5, height: 1.5, color: AppColors.textLight),
              ),
              // Podgląd dla organizatora: uprzedzenie o innym interfejsie.
              if (preview) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCD9A6)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          size: 18, color: Color(0xFFB45309)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppText.t.onb_guestPreviewNote,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              height: 1.45,
                              color: const Color(0xFF7C4A03)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              // Gość ma jeden przewodnik — całość, bez wyboru tempa (#21).
              if (isGuest)
                _introBtn(
                  context,
                  icon: Icons.explore_outlined,
                  title: preview ? AppText.t.onb_guestPreview : AppText.t.onb_start,
                  subtitle: AppText.t.onb_guestFull,
                  value: 'full',
                  filled: true,
                )
              else ...[
                _introBtn(
                  context,
                  icon: Icons.flag_outlined,
                  title: AppText.t.onb_short,
                  subtitle: t.basicSub,
                  value: 'basic',
                  filled: false,
                ),
                const SizedBox(height: 10),
                _introBtn(
                  context,
                  icon: Icons.explore_outlined,
                  title: AppText.t.onb_full,
                  subtitle: t.fullSub,
                  value: 'full',
                  filled: true,
                ),
              ],
              if (offerGuestPreview) ...[
                const SizedBox(height: 10),
                _introBtn(
                  context,
                  icon: Icons.groups_outlined,
                  title: AppText.t.onb_guestPreview,
                  subtitle: AppText.t.onb_guestPreviewHint,
                  value: 'guest',
                  filled: false,
                ),
                const SizedBox(height: 10),
                // Kreator konfiguracji (#17) — inne pytanie niż przewodnik:
                // nie „gdzie co jest", tylko „co wpisać". Gość go nie ma.
                _introBtn(
                  context,
                  icon: Icons.checklist_rtl,
                  title: AppText.t.settings_setupWizardButton,
                  subtitle: AppText.t.onb_setupWizardHint,
                  value: 'setup',
                  filled: false,
                ),
              ],
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.textLight),
                child: Text(AppText.t.onb_skipTour),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _introBtn(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required String value,
  required bool filled,
}) {
  return Material(
    color: filled ? AppColors.accent : Colors.white,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context).pop(value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: filled ? AppColors.accent : const Color(0xFFDCE4F2),
              width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: filled ? Colors.white : AppColors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: filled ? Colors.white : AppColors.text)),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: filled
                              ? Colors.white.withValues(alpha: 0.9)
                              : AppColors.textLight)),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
