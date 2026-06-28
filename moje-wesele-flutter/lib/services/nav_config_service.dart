import 'package:shared_preferences/shared_preferences.dart';

import '../navigation/app_sections.dart';

/// Konfiguracja dolnego paska nawigacji — które 4 sekcje i w jakiej kolejności.
/// Zapis lokalny (shared_preferences), kluczowany identyfikatorem użytkownika.
///
/// Dashboard NIE jest częścią paska — jest przypięty na stałe w lewym górnym
/// rogu (AppBar), więc nie pojawia się tu ani w „Więcej".
class NavConfigService {
  NavConfigService({required this.uid});

  final String uid;

  static const int slots = 4;

  /// Domyślny zestaw 4 sekcji w pasku.
  static const List<AppSection> defaultBar = [
    AppSection.guests,
    AppSection.budget,
    AppSection.room,
    AppSection.schedule,
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
      if (!sections.contains(s)) sections.add(s);
    }
    if (sections.isEmpty) return List.of(defaultBar);
    return sections.take(slots).toList();
  }

  Future<void> save(List<AppSection> sections) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      sections.where((s) => s != AppSection.dashboard).map((s) => s.name).toList(),
    );
  }
}
