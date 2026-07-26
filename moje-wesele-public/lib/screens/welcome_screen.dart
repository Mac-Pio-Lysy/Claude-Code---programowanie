import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';

/// Ekran tytułowy / powitalny — pierwszy ekran aplikacji.
///
/// Elegancki, jasnoniebieski gradient ze subtelnymi ZŁOTYMI akcentami
/// (spójnymi z paskiem nawigacji): pierścionek w okręgu ze złotą obwódką,
/// nazwa „Moje Wesele – Wedding Planner" fontem Playfair Display i ozdobny
/// złoty separator.
///
/// Docelowo miejsce logowania/rejestracji. Na razie [onEnter] przechodzi do
/// aplikacji (zgodnie z trybem testowym `bypassLogin`).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onEnter});

  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: Stack(
          children: [
            const Positioned.fill(child: _BackgroundOrnaments()),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    // Logo aplikacji — wyśrodkowane na górze ekranu powitalnego.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        'assets/ikona.png',
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const Spacer(flex: 3),
                    const _RingBadge(),
                    const SizedBox(height: 28),
                    Text(
                      'Moje Wesele',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 42,
                        height: 1.05,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F1F4A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // „Wedding Planner" — Playfair Display, złoty akcent.
                    ShaderMask(
                      shaderCallback: (r) => const LinearGradient(
                        colors: [Color(0xFFB8860B), Color(0xFFE6C878)],
                      ).createShader(r),
                      child: Text(
                        'Wedding Planner',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const _GoldFlourish(),
                    Text(
                      'PANEL ORGANIZACJI WESELA',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3,
                        color: AppColors.accent,
                      ),
                    ),
                    const Spacer(flex: 4),
                    _EnterButton(onTap: onEnter),
                    const SizedBox(height: 14),
                    Text(
                      'Tryb testowy — wejście bez logowania',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFFA0AEC0),
                      ),
                    ),
                    const Spacer(flex: 1),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Okrągła odznaka z pierścionkiem, otoczona ZŁOTĄ obwódką i delikatną poświatą.
class _RingBadge extends StatelessWidget {
  const _RingBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128,
      height: 128,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Miękka poświata
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.accent2.withValues(alpha: 0.22),
                  AppColors.accent2.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          // Cienki złoty pierścień na zewnątrz
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.goldLight.withValues(alpha: 0.9), width: 1.4),
            ),
          ),
          // Właściwa odznaka ze złotą obwódką
          Container(
            width: 92,
            height: 92,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEAF1FF), Color(0xFFD6E4FB)],
              ),
              border: Border.all(color: AppColors.goldLight, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.20),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Text('💍', style: TextStyle(fontSize: 42)),
          ),
        ],
      ),
    );
  }
}

/// Ozdobny ZŁOTY separator: linia — romb — linia.
class _GoldFlourish extends StatelessWidget {
  const _GoldFlourish();

  @override
  Widget build(BuildContext context) {
    Widget line() => Container(
          width: 34,
          height: 1.4,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0x00B8860B), Color(0xFFCBA24B)],
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 22, 0, 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          line(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ),
          Transform.flip(flipX: true, child: line()),
        ],
      ),
    );
  }
}

/// Przycisk wejścia do aplikacji — gradient indygo ze złotą obwódką.
class _EnterButton extends StatelessWidget {
  const _EnterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.accent, Color(0xFF4F46E5)],
            ),
            border: Border.all(
                color: AppColors.goldLight.withValues(alpha: 0.85), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.30),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Wejdź do aplikacji',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded,
                  size: 20, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

/// Subtelne, rozmyte kręgi ozdobne — jeden z lekkim złotym akcentem.
class _BackgroundOrnaments extends StatelessWidget {
  const _BackgroundOrnaments();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: _blob(230, AppColors.accent2.withValues(alpha: 0.14)),
          ),
          Positioned(
            bottom: -100,
            right: -70,
            child: _blob(280, AppColors.gold.withValues(alpha: 0.08)),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}
