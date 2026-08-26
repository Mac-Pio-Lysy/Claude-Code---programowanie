import 'package:flutter/material.dart';

/// Kategoria wydarzenia harmonogramu (SCHED_CATS w zrodlo-web/script.js).
class SchedCategory {
  const SchedCategory(this.name, this.color, this.icon);
  final String name;
  final Color color;
  final String icon;

  static const List<SchedCategory> all = [
    SchedCategory('Przygotowania', Color(0xFF3B82F6), '💄'),
    SchedCategory('Ceremonia', Color(0xFF7C3AED), '💒'),
    SchedCategory('Sesja', Color(0xFF059669), '📷'),
    SchedCategory('Wesele', Color(0xFFD97706), '🥂'),
    SchedCategory('Tort', Color(0xFFEC4899), '🎂'),
    SchedCategory('Taniec', Color(0xFFEF4444), '💃'),
    // Harmonogram zabaw/atrakcji — najczęściej z PRZEDZIAŁEM czasu (patrz
    // `hasRange` niżej), np. budka do zdjęć 19:00–23:00, fajerwerki 23:00.
    SchedCategory('Atrakcja', Color(0xFF06B6D4), '🎉'),
    // Godziny pracy dostawcy, np. barman 18:00–02:00, fotograf 14:00–22:00.
    SchedCategory('Dostawca', Color(0xFF92400E), '🧑‍🔧'),
    SchedCategory('Inne', Color(0xFF6B7280), '📌'),
  ];

  static SchedCategory byName(String? name) =>
      all.firstWhere((c) => c.name == name, orElse: () => all.last);

  static List<String> get names => all.map((c) => c.name).toList();
}

/// Wydarzenie harmonogramu dnia ślubu — nakładka na surową mapę.
class ScheduleEvent {
  ScheduleEvent(this.raw);
  final Map<String, dynamic> raw;

  int? get id => (raw['id'] as num?)?.toInt();
  int get hour => (raw['hour'] as num?)?.toInt() ?? 0;
  int get minute => (raw['minute'] as num?)?.toInt() ?? 0;
  String get name => (raw['name'] as String?) ?? '';
  String get description => (raw['description'] as String?) ?? '';
  String get location => (raw['location'] as String?) ?? '';
  String get responsible => (raw['responsible'] as String?) ?? '';
  String get category => (raw['category'] as String?) ?? 'Inne';
  bool get private => raw['private'] == true;
  String get locationUrl => (raw['locationUrl'] as String?) ?? '';
  bool get showLinkToGuests => raw['showLinkToGuests'] == true;

  /// Koniec PRZEDZIAŁU czasu (opcjonalny — np. budka do zdjęć 19:00–23:00,
  /// godziny pracy dostawcy). `null` = wydarzenie punktowe, jak dotąd —
  /// stare, zapisane wydarzenia bez tych pól czytają się bez zmian.
  int? get endHour => (raw['endHour'] as num?)?.toInt();
  int? get endMinute => (raw['endMinute'] as num?)?.toInt();

  /// Czy to wydarzenie ma przedział czasu (OD–DO), a nie pojedynczy moment.
  bool get hasRange => endHour != null && endMinute != null;

  SchedCategory get cat => SchedCategory.byName(category);

  /// Minuty do sortowania osi czasu. Godziny po północy (0–5) traktujemy jako
  /// „następnego dnia" (+24 h), aby zakończenie wesela (np. 01:00, 02:00) było
  /// na końcu, a nie na początku — zgodnie z logiką wersji web (`hour < 6`).
  int get sortKey => (hour < 6 ? hour + 24 : hour) * 60 + minute;

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// Etykieta czasu: „19:00–23:00" gdy przedział, inaczej to samo co
  /// [timeLabel]. Koniec „mniejszy" niż początek (np. 18:00–02:00) jest
  /// prawidłowy — oznacza przejście przez północ, bez żadnego ostrzeżenia
  /// ani specjalnej obsługi: wyświetlamy oba czasy dosłownie tak, jak
  /// wpisał organizator.
  String get timeRangeLabel {
    if (!hasRange) return timeLabel;
    final eh = endHour!.toString().padLeft(2, '0');
    final em = endMinute!.toString().padLeft(2, '0');
    return '$timeLabel–$eh:$em';
  }
}
