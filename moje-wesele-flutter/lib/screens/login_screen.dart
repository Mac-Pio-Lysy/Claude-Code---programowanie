import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';

/// Ekran logowania — wygląd odwzorowany z aplikacji webowej:
/// wyśrodkowana biała karta na jasnoniebieskim gradiencie.
///
/// To czysty widget prezentacyjny — logikę logowania dostarcza rodzic
/// ([AuthGate]) przez [onGoogleSignIn], [isLoading] i [errorMessage].
class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    required this.onGoogleSignIn,
    this.isLoading = false,
    this.errorMessage,
  });

  final VoidCallback onGoogleSignIn;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.45, 1.0],
            colors: AppColors.bgGradient,
          ),
        ),
        child: SafeArea(
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
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(40, 48, 40, 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2EAF7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.12),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ikona pierścionka
          const Text('💍', style: TextStyle(fontSize: 45)),
          const SizedBox(height: 18),

          // Tytuł — Playfair Display
          Text(
            'Ceremonia\nPatrycji i Piotra',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              height: 1.22,
              color: const Color(0xFF0F1F4A),
            ),
          ),
          const SizedBox(height: 10),

          // Podtytuł
          Text(
            'Panel organizacji wesela',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF6B7A99),
              letterSpacing: 0.2,
            ),
          ),

          // Dekoracyjna kreska
          Container(
            width: 40,
            height: 3,
            margin: const EdgeInsets.fromLTRB(0, 22, 0, 28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: const LinearGradient(colors: AppColors.dividerGradient),
            ),
          ),

          // Przycisk Google
          _GoogleSignInButton(
            isLoading: isLoading,
            onPressed: isLoading ? null : onGoogleSignIn,
          ),

          // Komunikat błędu / braku dostępu
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            _ErrorBox(message: errorMessage!),
          ],

          // Informacja o prywatności
          const SizedBox(height: 22),
          Text(
            '🔒 Aplikacja prywatna — dostęp tylko dla zaproszonych',
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
                    isLoading ? 'Logowanie…' : 'Zaloguj się przez Google',
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
