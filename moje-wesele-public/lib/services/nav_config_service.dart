import 'package:shared_preferences/shared_preferences.dart';

import '../navigation/app_sections.dart';

/// Konfiguracja dolnego paska nawigacji — które sekcje i w jakiej kolejności.
/// Zapis lokalny (shared_preferences), kluczowany identyfikatorem użytkownika.
///
/// Dashboard (środek, pływający przycisk) i „Więcej" (skrajnie prawy slot,
/// przy prawej krawędzi ekranu) są STAŁE i niekonfigurowalne — nie pojawiają
/// się tu. Reszta ([_bar] w `MainNavigation`) jest dzielona połowa-na-połowę
/// pomiędzy lewą i prawą stronę Dashboardu (patrz `FloatingBottomNav`) — żeby
/// to zawsze wyszło symetrycznie (bez „wjeżdżania" ikon pod Dashboard),
/// dozwolone są WYŁĄCZNIE dwie długości paska: [compactSlots] (3 → razem
/// z „Więcej" 4 ikony poza Dashboardem, układ 2+2) albo [slots] (5 → razem
/// z „Więcej" 6 ikon, układ 3+3).
class NavConfigService {
  NavConfigService({required this.uid});

  final String uid;

  /// Pełna liczba konfigurowalnych skrótów (układ 3 z lewej + 2 z prawej).
  static const int slots = 5;

  /// Kompaktowa liczba konfigurowalnych skrótów (układ 2 z lewej + 1 z prawej).
  static const int compactSlots = 3;

  /// Domyślny (pełny) zestaw 5 sekcji w pasku (3 z lewej + 2 z prawej Dashboardu).
  static const List<AppSection> defaultBar = [
    AppSection.guests,
    AppSection.budget,
    AppSection.room,
    AppSection.schedule,
    AppSection.transport,
  ];

  String get _key => 'nav_bar_$uid';

  Future<List<AppSection>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);
    if (raw == null || raw.isEmpty) return List.of(defaultBar);
    final sections = <AppSection>[];
    for (final name in raw) {
      final match = AppSection.values.where((s) => s.name == name);
      if (match.isEmpty) continue;
      final s = match.first;
      if (s == AppSection.dashboard) continue; // pinned osobno
      if (s == AppSection.settings) continue; // tylko przez menu logo
      // Sekcja tymczasowo ukryta (patrz FeatureFlags) — pomijamy nawet gdy
      // była już zapisana we wcześniejszej konfiguracji użytkownika.
      if (s.hiddenFromNav) continue;
      if (!sections.contains(s)) sections.add(s);
    }
    if (sections.isEmpty) return List.of(defaultBar);
    return _normalized(sections.take(slots).toList());
  }

  Future<void> save(List<AppSection> sections) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      _normalized(sections)
          .where((s) => s != AppSection.dashboard)
          .map((s) => s.name)
          .toList(),
    );
  }

  /// Wymusza jedną z dwóch dozwolonych długości ([compactSlots] lub [slots])
  /// — zabezpieczenie na wypadek starszych/nieprawidłowych zapisów sprzed
  /// wprowadzenia tego ograniczenia (np. zapisanych, gdy dało się usuwać
  /// skróty pojedynczo aż do 1). Dopełnia listę kolejnymi sekcjami, gdy jest
  /// za krótka, i przycina, gdy jest za długa.
  List<AppSection> _normalized(List<AppSection> sections) {
    final target = sections.length >= 4 ? slots : compactSlots;
    if (sections.length == target) return sections;

    final result = List.of(sections);
    if (result.length > target) return result.sublist(0, target);

    for (final candidate in [...defaultBar, ...AppSection.values]) {
      if (result.length >= target) break;
      if (candidate == AppSection.dashboard) continue;
      if (candidate == AppSection.settings) continue;
      if (candidate.hiddenFromNav) continue;
      if (!result.contains(candidate)) result.add(candidate);
    }
    return result.take(target).toList();
  }
}
