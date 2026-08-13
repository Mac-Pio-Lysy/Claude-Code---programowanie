import '../navigation/app_sections.dart';

/// Rodzaj powiadomienia — decyduje o ikonie i grupowaniu w centrum.
enum NotifKind {
  /// Gość potwierdził albo odwołał obecność.
  rsvp,

  /// Nowy gość na liście.
  guestAdded,

  /// Nowe zadanie.
  taskAdded,

  /// Nowy albo zmieniony punkt harmonogramu.
  schedule;

  /// Sekcja, do której prowadzi kliknięcie.
  AppSection get section => switch (this) {
        NotifKind.rsvp => AppSection.rsvp,
        NotifKind.guestAdded => AppSection.guests,
        NotifKind.taskAdded => AppSection.tasks,
        NotifKind.schedule => AppSection.schedule,
      };

  /// Podzakładka docelowa (`null` = sekcja główna).
  int? get subTab => switch (this) {
        NotifKind.guestAdded => 0, // „Lista"
        NotifKind.schedule => 0, // „Plan dnia"
        _ => null,
      };

  /// Nagłówek grupy w centrum powiadomień.
  String get groupLabel => switch (this) {
        NotifKind.rsvp => 'Potwierdzenia',
        NotifKind.guestAdded => 'Goście',
        NotifKind.taskAdded => 'Zadania',
        NotifKind.schedule => 'Harmonogram',
      };

  String get emoji => switch (this) {
        NotifKind.rsvp => '✉',
        NotifKind.guestAdded => '👤',
        NotifKind.taskAdded => '✅',
        NotifKind.schedule => '🕒',
      };
}

/// Pojedyncze powiadomienie w centrum (dzwoneczek).
///
/// ⚠️ [id] MUSI być deterministyczne — to samo zdarzenie ma zawsze ten sam
/// identyfikator. Na tym opiera się stan przeczytania: raz odhaczone
/// powiadomienie nie wraca przy kolejnym odświeżeniu danych.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.text,
    required this.at,
  });

  /// Deterministyczny identyfikator zdarzenia, np. `rsvp:12:attending`.
  final String id;

  final NotifKind kind;

  /// Gotowy tekst dla użytkownika („Jan Kowalski potwierdził obecność").
  final String text;

  /// Kiedy zmiana została wykryta (czas lokalny urządzenia).
  final DateTime at;

  AppSection get section => kind.section;
  int? get subTab => kind.subTab;

  @override
  String toString() => '$id: $text';
}

/// Grupa powiadomień jednego rodzaju — „Potwierdzenia: 3 nowe".
class NotifGroup {
  const NotifGroup({required this.kind, required this.items});

  final NotifKind kind;
  final List<AppNotification> items;

  int get count => items.length;
  String get label => kind.groupLabel;

  /// Podsumowanie liczbowe z poprawną odmianą.
  String get summary => switch (count) {
        1 => '1 nowe',
        _ when count % 10 >= 2 &&
                count % 10 <= 4 &&
                (count % 100 < 12 || count % 100 > 14) =>
          '$count nowe',
        _ => '$count nowych',
      };

  /// Grupuje powiadomienia wg rodzaju, zachowując kolejność [NotifKind.values].
  static List<NotifGroup> from(List<AppNotification> items) {
    final groups = <NotifGroup>[];
    for (final kind in NotifKind.values) {
      final of = items.where((n) => n.kind == kind).toList();
      if (of.isNotEmpty) groups.add(NotifGroup(kind: kind, items: of));
    }
    return groups;
  }
}
