import 'package:shared_preferences/shared_preferences.dart';

import '../onboarding/onboarding_steps.dart';

/// Stan ukończenia przewodnika (onboardingu) — przechowywany lokalnie
/// **per użytkownik i per wariant** (właściciel / planer / gość).
///
/// Osobny stan na wariant ma znaczenie praktyczne: właściciel, który przeszedł
/// swój przewodnik, nie powinien przez to stracić podpowiedzi przy pierwszym
/// wejściu w podgląd strefy gości — i odwrotnie.
///
/// Zapis jest lokalny (jak w wersji web: `weddingOnboardingDone:<email>`
/// w localStorage), więc na nowym urządzeniu przewodnik pokaże się ponownie.
class OnboardingService {
  OnboardingService({required this.uid});

  final String uid;

  /// Klucz sprzed podziału na warianty — używany do jednorazowej migracji,
  /// żeby dotychczasowi użytkownicy nie zobaczyli przewodnika drugi raz.
  String get _legacyKey => 'onboarding_done_$uid';

  String _keyFor(OnbVariant variant) =>
      'onboarding_done_${uid}_${variantKey(variant)}';

  Future<bool> isDone(OnbVariant variant) async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool(_keyFor(variant));
    if (done != null) return done;

    // Migracja: stary, wspólny klucz oznaczał ukończenie przewodnika panelu.
    // Zaliczamy go wariantom organizatora; gość dostaje swój przewodnik od nowa.
    if (variant != OnbVariant.guest && (prefs.getBool(_legacyKey) ?? false)) {
      await prefs.setBool(_keyFor(variant), true);
      return true;
    }
    return false;
  }

  Future<void> markDone(OnbVariant variant) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFor(variant), true);
  }

  /// Reset wariantu (np. „pokaż przewodnik od nowa").
  Future<void> reset(OnbVariant variant) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(variant));
  }
}
