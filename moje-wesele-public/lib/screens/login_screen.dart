import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';
import '../l10n/app_text.dart';

/// Ekran powitalny przed zalogowaniem — jasnoniebieski gradient, pierścionek
/// w zdobionej odznace, nazwa aplikacji fontem Playfair Display i subtelne
/// ornamenty w tle.
///
/// To czysty widget prezentacyjny — logikę logowania dostarcza rodzic
/// ([AuthGate]) przez [onGoogleSignIn], [isLoading] i [errorMessage].
class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    required this.onGoogleSignIn,
    required this.onEmailAuth,
    this.isLoading = false,
    this.errorMessage,
  });

  final VoidCallback onGoogleSignIn;

  /// Przechodzi do ekranu logowania/rejestracji e-mailem ([EmailAuthScreen]).
  final VoidCallback onEmailAuth;

  final bool isLoading;
  final String? errorMessage;

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
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: _buildCard(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(40, 44, 40, 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2EAF7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.14),
            blurRadius: 44,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Odznaka z ikoną pierścionka
          const _RingBadge(),
          const SizedBox(height: 22),

          // Nazwa aplikacji — Playfair Display
          Text(
            'Moje Wesele',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              height: 1.1,
              color: const Color(0xFF0F1F4A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'WEDDING PLANNER',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 3.2,
              color: AppColors.accent,
            ),
          ),

          // Ornament — mała ozdobna linia z rombem
          const _FlourishDivider(),

          // Przycisk Google
          _GoogleSignInButton(
            isLoading: isLoading,
            onPressed: isLoading ? null : onGoogleSignIn,
          ),

          // Separator „lub" i wejście do logowania/rejestracji e-mailem
          const _OrDivider(),
          _EmailSignInButton(
            onPressed: isLoading ? null : onEmailAuth,
          ),

          // Komunikat błędu / braku dostępu
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            _ErrorBox(message: errorMessage!),
          ],

          // Informacja o logowaniu / rejestracji
          const SizedBox(height: 22),
          Text(
            AppText.t.login_subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppText.t.login_secure,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFFA0AEC0),
            ),
          ),
        ],
      ),
    );
  }
}

/// Okrągła odznaka z ikoną pierścionka, otoczona delikatną poświatą.
class _RingBadge extends StatelessWidget {
  const _RingBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Poświata w tle
          Container(
            width: 96,
            height: 96,
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
          // Właściwa odznaka
          Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEAF1FF), Color(0xFFD6E4FB)],
              ),
              border: Border.all(color: const Color(0xFFC7D8F7), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Text('💍', style: TextStyle(fontSize: 34)),
          ),
        ],
      ),
    );
  }
}

/// Ozdobny separator: cienka linia — romb — cienka linia.
class _FlourishDivider extends StatelessWidget {
  const _FlourishDivider();

  @override
  Widget build(BuildContext context) {
    Widget line() => Container(
          width: 30,
          height: 1.4,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accent.withValues(alpha: 0.05),
                AppColors.accent.withValues(alpha: 0.55),
              ],
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 22, 0, 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          line(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: AppColors.accent,
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

/// Subtelne, rozmyte kręgi ozdobne w rogach ekranu logowania.
class _BackgroundOrnaments extends StatelessWidget {
  const _BackgroundOrnaments();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -70,
            left: -60,
            child: _blob(220, AppColors.accent2.withValues(alpha: 0.14)),
          ),
          Positioned(
            bottom: -90,
            right: -70,
            child: _blob(260, AppColors.accent.withValues(alpha: 0.10)),
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

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.6 : 1.0,
      child: Material(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDCE4F2), width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(AppColors.accent),
                    ),
                  )
                else
                  const _GoogleBadge(),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    isLoading ? AppText.t.login_signingIn : AppText.t.login_google,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Separator „lub" między przyciskiem Google a wejściem do logowania e-mailem.
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: const Color(0xFFE2EAF7))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              AppText.t.login_or,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFA0AEC0),
              ),
            ),
          ),
          Expanded(child: Container(height: 1, color: const Color(0xFFE2EAF7))),
        ],
      ),
    );
  }
}

/// Przycisk wejścia do logowania/rejestracji e-mailem.
class _EmailSignInButton extends StatelessWidget {
  const _EmailSignInButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.6 : 1.0,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDCE4F2), width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mail_outline_rounded,
                    size: 20, color: AppColors.accent),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    AppText.t.login_emailButton,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Stylizowana litera „G" w kolorowym kółku (jak w wersji webowej).
class _GoogleBadge extends StatelessWidget {
  const _GoogleBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4285F4), Color(0xFF34A853), Color(0xFFEA4335)],
        ),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
      ),
      child: Text(
        message,
        style: GoogleFonts.inter(
          fontSize: 13,
          height: 1.5,
          color: const Color(0xFFC0392B),
        ),
      ),
    );
  }
}
