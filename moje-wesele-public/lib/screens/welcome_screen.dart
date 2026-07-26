import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';

/// Ekran tytułowy / powitalny — pierwszy ekran aplikacji.
///
/// Kolorystyka spójna z logo (`assets/ikona.png`): głęboki, królewski
/// granat/indygo jak tło pierścionka, jasnoniebieskie (szafirowe) refleksy
/// oraz subtelne złote akcenty. Logo wtapia się w tło, tworząc jedną,
/// elegancką kompozycję. Nazwa „Moje Wesele" fontem Playfair Display,
/// „Wedding Planner" w złocie, ozdobny złoty separator.
///
/// Docelowo miejsce logowania/rejestracji. Na razie [onEnter] przechodzi do
/// aplikacji (zgodnie z trybem testowym `bypassLogin`).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onEnter});

  final VoidCallback onEnter;

  // Paleta wyprowadzona bezpośrednio z logo (ikona.png).
  /// Królewski granat — górna część tła pierścionka na logo.
  static const Color _royalTop = Color(0xFF274B82);

  /// Granat środkowy — otoczenie logo (płynne wtopienie).
  static const Color _royalMid = Color(0xFF1E3A6B);

  /// Głębokie indygo/granat — dół ekranu.
  static const Color _indigoDeep = Color(0xFF13284C);

  /// Jasnoniebieski (szafirowy) refleks z kamienia.
  static const Color _sapphire = Color(0xFFBFE0F5);

  /// Miękki, przygaszony błękit — teksty pomocnicze.
  static const Color _sapphireSoft = Color(0xFF9DBFDE);

  /// Marmurowa biel — tytuł.
  static const Color _marble = Color(0xFFF3F2EC);

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
            stops: [0.0, 0.42, 1.0],
            colors: [_royalTop, _royalMid, _indigoDeep],
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
                    const Spacer(flex: 3),
                    // Logo aplikacji — jedyne logo ekranu (assets/ikona.png).
                    // Delikatna złota obwódka i szafirowa poświata sprawiają,
                    // że logo wtapia się w granatowe tło jak część kompozycji.
                    const _Logo(),
                    const SizedBox(height: 34),
                    Text(
                      'Moje Wesele',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 44,
                        height: 1.05,
                        fontWeight: FontWeight.w700,
                        color: _marble,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // „Wedding Planner" — Playfair Display, złoty akcent.
                    ShaderMask(
                      shaderCallback: (r) => const LinearGradient(
                        colors: [Color(0xFFE6C878), Color(0xFFCBA24B)],
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
                        color: _sapphire,
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
                        color: _sapphireSoft.withValues(alpha: 0.75),
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

/// Logo aplikacji (assets/ikona.png) w subtelnej złotej ramce z szafirową
/// poświatą — jedyne logo ekranu powitalnego.
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 184,
      height: 184,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Miękka szafirowa poświata za logo.
          Container(
            width: 184,
            height: 184,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0x3FBFE0F5),
                  Color(0x00BFE0F5),
                ],
              ),
            ),
          ),
          // Samo logo w zaokrąglonej, cienkiej złotej ramce.
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppColors.goldLight.withValues(alpha: 0.55),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0B1A38).withValues(alpha: 0.55),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                'assets/ikona.png',
                width: 132,
                height: 132,
                fit: BoxFit.cover,
              ),
            ),
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

/// Przycisk wejścia do aplikacji — szafirowo-indygowy gradient
/// (jak kamień i tło logo) ze złotą obwódką i błękitną poświatą.
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
              colors: [Color(0xFF3C6BB8), Color(0xFF4F46E5)],
            ),
            border: Border.all(
                color: AppColors.goldLight.withValues(alpha: 0.85), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7FB4E8).withValues(alpha: 0.30),
                blurRadius: 22,
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

/// Subtelne, rozmyte kręgi i błyski ozdobne — szafirowa poświata i złoty
/// akcent, wraz z drobnymi iskrami jak na logo.
class _BackgroundOrnaments extends StatelessWidget {
  const _BackgroundOrnaments();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -90,
            left: -70,
            child: _blob(250, const Color(0xFFBFE0F5).withValues(alpha: 0.12)),
          ),
          Positioned(
            bottom: -110,
            right: -80,
            child: _blob(300, AppColors.gold.withValues(alpha: 0.10)),
          ),
          // Drobne iskry (jak szafirowy błysk w rogu logo).
          Positioned(
            top: 96,
            right: 44,
            child: _sparkle(16, const Color(0xFFBFE0F5).withValues(alpha: 0.75)),
          ),
          Positioned(
            bottom: 150,
            left: 40,
            child: _sparkle(12, AppColors.goldLight.withValues(alpha: 0.6)),
          ),
          Positioned(
            top: 210,
            left: 54,
            child: _sparkle(9, const Color(0xFFBFE0F5).withValues(alpha: 0.5)),
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

  Widget _sparkle(double size, Color color) =>
      Icon(Icons.auto_awesome, size: size, color: color);
}
