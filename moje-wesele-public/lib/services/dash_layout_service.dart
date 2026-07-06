import 'package:shared_preferences/shared_preferences.dart';

import '../models/dash_widget.dart';

/// Zapis układu i widoczności kafelków dashboardu — per użytkownik
/// (shared_preferences, kluczowane uid). Odpowiednik dashLayout w wersji web.
class DashLayoutService {
  DashLayoutService({required this.uid});

  final String uid;

  String get _key => 'dash_layout_$uid';

  /// Wczytuje listę widocznych kafelków (w kolejności). Pomija nieznane id.
  Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);
    if (raw == null) return List.of(DashWidgets.defaultLayout);
    final seen = <String>{};
    final result = <String>[];
    for (final id in raw) {
      if (DashWidgets.byId(id) != null && seen.add(id)) result.add(id);
    }
    return result;
  }

  Future<void> save(List<String> layout) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, layout);
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
