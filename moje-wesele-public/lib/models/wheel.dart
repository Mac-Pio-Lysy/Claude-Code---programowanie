import '../l10n/app_text.dart';
/// Tryby „Koła fortuny" (gotowe zestawy losowania).
enum WheelMode { toast, dance, couple, oczepiny, custom }

extension WheelModeX on WheelMode {
  String get id => name;

  String get label => switch (this) {
        WheelMode.toast => AppText.t.wheelEx_toast,
        WheelMode.dance => AppText.t.wheelMode_nextDance,
        WheelMode.couple => AppText.t.wheelMode_coupleTask,
        WheelMode.oczepiny => AppText.t.wheelEx_gamesTask,
        WheelMode.custom => AppText.t.wheelMode_custom,
      };

  String get emoji => switch (this) {
        WheelMode.toast => '🥂',
        WheelMode.dance => '💃',
        WheelMode.couple => '💍',
        WheelMode.oczepiny => '🎉',
        WheelMode.custom => '🎡',
      };

  /// Czy tryb losuje spośród gości (z listy `guests`).
  bool get guestBased => this == WheelMode.toast || this == WheelMode.dance;

  /// Klucz zestawu własnych pól w `wheelConfig.sets` (null dla trybów z gości).
  String? get setKey => switch (this) {
        WheelMode.couple => 'couple',
        WheelMode.oczepiny => 'oczepiny',
        WheelMode.custom => 'custom',
        _ => null,
      };

  /// Domyślne (przykładowe) pola dla trybów własnych — gdy nic nie zapisano.
  List<String> get defaults => switch (this) {
        WheelMode.couple => [
            AppText.t.wheelEx_veilKiss,
            AppText.t.wheelEx_blindDance,
            AppText.t.wheelEx_singSong,
            AppText.t.wheelEx_feedCake,
            AppText.t.wheelEx_longKiss,
            AppText.t.wheelEx_compliment,
          ],
        WheelMode.oczepiny => [
            AppText.t.wheelEx_bouquetToss,
            AppText.t.wheelEx_tieToss,
            AppText.t.wheelEx_chairDance,
            AppText.t.wheelEx_bestDance,
            AppText.t.wheelEx_charades,
            AppText.t.wheelEx_nextCouple,
          ],
        _ => const [],
      };

  static WheelMode fromId(String? id) =>
      WheelMode.values.firstWhere((m) => m.id == id,
          orElse: () => WheelMode.toast);
}

/// Konfiguracja koła fortuny (`weddingPlanner/main` → `wheelConfig`).
class WheelConfig {
  WheelConfig({
    required this.activeMode,
    required this.removeOnPick,
    required this.sets,
  });

  final WheelMode activeMode;
  final bool removeOnPick;

  /// Własne pola per tryb: `{couple: [...], oczepiny: [...], custom: [...]}`.
  final Map<String, List<String>> sets;

  /// Zapisane pola dla trybu (puste, gdy nic nie zapisano).
  List<String> savedItemsFor(WheelMode m) {
    final k = m.setKey;
    if (k == null) return const [];
    return sets[k] ?? const [];
  }

  /// Efektywne pola do edycji/losowania: zapisane lub domyślne (przykładowe).
  List<String> itemsFor(WheelMode m) {
    final saved = savedItemsFor(m);
    return saved.isNotEmpty ? saved : m.defaults;
  }

  factory WheelConfig.from(Map<String, dynamic>? raw) {
    final w = raw?['wheelConfig'];
    final map = w is Map ? Map<String, dynamic>.from(w) : <String, dynamic>{};
    final setsRaw = map['sets'];
    final sets = <String, List<String>>{};
    if (setsRaw is Map) {
      setsRaw.forEach((k, v) {
        if (v is List) {
          sets['$k'] = v.map((e) => e?.toString() ?? '').toList();
        }
      });
    }
    return WheelConfig(
      activeMode: WheelModeX.fromId(map['activeMode'] as String?),
      removeOnPick: map['removeOnPick'] == true,
      sets: sets,
    );
  }
}
