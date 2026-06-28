import 'package:shared_preferences/shared_preferences.dart';

/// Stan ukończenia przewodnika (onboardingu) — przechowywany lokalnie per
/// użytkownik (klucz z identyfikatorem konta), jak w wersji web
/// (`weddingOnboardingDone:<email>` w localStorage).
class OnboardingService {
  OnboardingService({required this.uid});

  final String uid;

  String get _key => 'onboarding_done_$uid';

  Future<bool> isDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  /// Reset (np. gdy użytkownik chce zobaczyć przewodnik od nowa — choć zwykle
  /// uruchamiamy go po prostu ponownie z Ustawień).
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
