import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';
import 'onboarding_steps.dart';

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
            child: card,
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
          Text('🧭  ${widget.step.title}',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text)),
          const SizedBox(height: 8),
          Text(widget.step.desc,
              style: GoogleFonts.inter(
                  fontSize: 13.5, height: 1.5, color: AppColors.textLight)),
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
              Text('Krok ${widget.index + 1} z ${widget.total}',
                  style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent)),
              const Spacer(),
              TextButton(
                onPressed: widget.onSkip,
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.textLight),
                child: const Text('Pomiń'),
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
                    label: const Text('Wstecz'),
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
                  label: Text(last ? 'Zakończ' : 'Dalej'),
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

  /// `basic` — skrócona forma, `full` — rozszerzona.
  final String mode;

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
    // Podgląd strefy gości — pytamy o tempo jeszcze raz, już w wariancie gościa.
    if (!context.mounted) return null;
    final guestMode = await _showIntroDialog(context, OnbVariant.guest);
    if (guestMode == null || guestMode == 'guest') return null;
    return OnbChoice(guestMode, OnbVariant.guest);
  }
  return OnbChoice(mode, variant);
}

/// Teksty ekranu powitalnego zależne od wariantu.
({String title, String desc, String basicSub, String fullSub}) _introTexts(
    OnbVariant v) {
  return switch (v) {
    OnbVariant.guest => (
        title: 'Przewodnik dla gościa',
        desc: 'Pokażemy Ci, co możesz zrobić na stronie przygotowanej przez '
            'Parę Młodą. Zajmie to chwilę.',
        basicSub: 'Najważniejsze: RSVP, harmonogram, galeria, gry',
        fullSub: 'Wszystkie sekcje strefy gości',
      ),
    OnbVariant.planner => (
        title: 'Przewodnik dla planera',
        desc: 'Pokażemy Ci panel wesela klienta i to, czym różni się praca '
            'planera od konta Pary Młodej. Wznowisz go z Ustawień.',
        basicSub: 'Główne sekcje panelu i zasady pracy planera',
        fullSub: 'Wszystkie sekcje, podzakładki i ustawienia',
      ),
    OnbVariant.owner => (
        title: 'Przewodnik po aplikacji',
        desc: 'Pokażemy Ci najważniejsze miejsca w aplikacji. Wybierz tempo — '
            'przewodnik wznowisz w każdej chwili z Ustawień (pod logo).',
        basicSub: 'Tylko główne sekcje — szybki przegląd',
        fullSub: 'Wszystkie sekcje i podzakładki',
      ),
  };
}

Future<String?> _showIntroDialog(BuildContext context, OnbVariant variant) {
  final t = _introTexts(variant);
  final offerGuestPreview = variant != OnbVariant.guest;
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
              const SizedBox(height: 18),
              _introBtn(
                context,
                icon: Icons.flag_outlined,
                title: 'Skrócony',
                subtitle: t.basicSub,
                value: 'basic',
                filled: false,
              ),
              const SizedBox(height: 10),
              _introBtn(
                context,
                icon: Icons.explore_outlined,
                title: 'Rozszerzony',
                subtitle: t.fullSub,
                value: 'full',
                filled: true,
              ),
              if (offerGuestPreview) ...[
                const SizedBox(height: 10),
                _introBtn(
                  context,
                  icon: Icons.groups_outlined,
                  title: 'Zobacz przewodnik gościa',
                  subtitle: 'Sprawdź, co widzą Wasi goście',
                  value: 'guest',
                  filled: false,
                ),
              ],
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.textLight),
                child: const Text('Pomiń przewodnik'),
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
