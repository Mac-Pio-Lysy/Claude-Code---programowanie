import 'app_notification.dart';
import 'guest.dart';
import 'wedding_data.dart';
import '../l10n/app_text.dart';

/// „Odcisk" stanu wesela — to, co użytkownik już widział.
///
/// Zamiast kopiować cały dokument, trzymamy zbiór lekkich znaczników: jeden
/// na każdy element, którego pojawienie się lub zmiana ma dać powiadomienie.
/// Znacznik zawiera identyfikator ORAZ istotne wartości, więc zmiana godziny
/// punktu harmonogramu daje inny znacznik niż wersja sprzed zmiany.
///
/// Odcisk jest listą krótkich ciągów, dzięki czemu zapisuje się go wprost
/// do `SharedPreferences` bez własnego serializatora.
class NotificationSnapshot {
  const NotificationSnapshot(this.marks);

  /// Znaczniki w formacie `typ:id[:wartości]`.
  final Set<String> marks;

  static const NotificationSnapshot empty = NotificationSnapshot({});

  bool get isEmpty => marks.isEmpty;

  List<String> toStringList() => marks.toList()..sort();

  static NotificationSnapshot fromStringList(List<String>? saved) =>
      NotificationSnapshot(saved == null ? const {} : saved.toSet());

  /// Buduje odcisk z bieżących danych wesela.
  factory NotificationSnapshot.of(WeddingData? data) {
    if (data == null) return empty;
    final marks = <String>{};

    // Goście — sam fakt istnienia rekordu.
    for (final g in data.guests) {
      final id = _idOf(g);
      if (id != null) marks.add('guest:$id');
    }

    // RSVP — status wchodzi do znacznika, więc zmiana decyzji to nowe
    // zdarzenie („jednak nie przyjdę").
    for (final e in _list(data.raw['rsvpEntries'])) {
      final id = _idOf(e);
      if (id == null) continue;
      final status = (e['status'] as String?) ?? '';
      marks.add('rsvp:$id:$status');
    }

    // Zadania — sam fakt dodania.
    for (final t in data.tasks) {
      final id = _idOf(t);
      if (id != null) marks.add('task:$id');
    }

    // Harmonogram — godzina i nazwa, bo ich zmiana jest istotna dla wszystkich.
    for (final s in data.scheduleEvents) {
      final mark = scheduleMark(s);
      if (mark != null) marks.add(mark);
    }

    return NotificationSnapshot(marks);
  }

  /// Znacznik punktu harmonogramu — wspólny dla panelu organizatora i strefy
  /// gościa, żeby obie ścieżki wykrywały dokładnie te same zmiany.
  static String? scheduleMark(dynamic e) {
    final id = _idOf(e);
    if (id == null) return null;
    final map = e as Map;
    final h = (map['hour'] as num?)?.toInt() ?? 0;
    final m = (map['minute'] as num?)?.toInt() ?? 0;
    final name = (map['name'] as String?)?.trim() ?? '';
    return 'sched:$id:${_hhmm(h, m)}|$name';
  }

  static int? _idOf(dynamic e) =>
      e is Map ? (e['id'] as num?)?.toInt() : null;

  static List<Map<dynamic, dynamic>> _list(dynamic v) => v is List
      ? [
          for (final e in v)
            if (e is Map) e
        ]
      : const [];

  static String _hhmm(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

/// Wynik porównania: powiadomienia + odcisk do zapisania.
class NotificationDiff {
  const NotificationDiff({required this.notifications, required this.snapshot});

  final List<AppNotification> notifications;
  final NotificationSnapshot snapshot;
}

/// Wykrywanie zmian przez porównanie odcisków (etap 1a).
///
/// Bez Cloud Functions i bez dziennika zdarzeń w bazie: pracujemy na danych,
/// które aplikacja i tak już czyta.
class NotificationDetector {
  const NotificationDetector._();

  /// Porównuje stan poprzedni z bieżącym.
  ///
  /// ⚠️ PIERWSZE URUCHOMIENIE: gdy [previous] jest pusty, zwracamy odcisk BEZ
  /// powiadomień. Inaczej wesele z dwustoma gośćmi wygenerowałoby dwieście
  /// powiadomień „dodano gościa" przy pierwszym otwarciu panelu.
  static NotificationDiff detect({
    required NotificationSnapshot previous,
    required WeddingData? data,
    DateTime? now,
  }) {
    final current = NotificationSnapshot.of(data);
    if (previous.isEmpty) {
      return NotificationDiff(
          notifications: const [], snapshot: current);
    }

    final at = now ?? DateTime.now();
    final fresh = current.marks.difference(previous.marks);
    if (fresh.isEmpty || data == null) {
      return NotificationDiff(notifications: const [], snapshot: current);
    }

    final byId = _guestsById(data);
    final out = <AppNotification>[];

    for (final mark in fresh) {
      final n = _describe(mark, data, byId, at);
      if (n != null) out.add(n);
    }

    // Najnowsze rodzaje najpierw — kolejność w obrębie odświeżenia jest
    // umowna, więc sortujemy stabilnie po treści znacznika.
    out.sort((a, b) => a.id.compareTo(b.id));
    return NotificationDiff(notifications: out, snapshot: current);
  }

  /// Zamienia znacznik na powiadomienie z tekstem dla użytkownika.
  static AppNotification? _describe(String mark, WeddingData data,
      Map<int, Guest> guestsById, DateTime at) {
    final parts = mark.split(':');
    if (parts.length < 2) return null;
    final type = parts[0];
    final id = int.tryParse(parts[1]);
    if (id == null) return null;

    switch (type) {
      case 'guest':
        final g = guestsById[id];
        final name = _guestName(g);
        return AppNotification(
          id: mark,
          kind: NotifKind.guestAdded,
          text: AppText.t.notif_guestAdded(name),
          at: at,
        );

      case 'rsvp':
        final entry = _findById(data.raw['rsvpEntries'], id);
        if (entry == null) return null;
        final status = (entry['status'] as String?) ?? '';
        final guestId = (entry['guestId'] as num?)?.toInt();
        final rawName = (entry['rawName'] as String?)?.trim() ?? '';
        final name = guestId != null && guestsById[guestId] != null
            ? _guestName(guestsById[guestId])
            : (rawName.isNotEmpty ? rawName : AppText.t.role_guest);
        return AppNotification(
          id: mark,
          kind: NotifKind.rsvp,
          text: switch (status) {
            'attending' => AppText.t.notif_guestAttending(name),
            'not_attending' => AppText.t.notif_guestNotAttending(name),
            _ => AppText.t.notif_guestChanged(name),
          },
          at: at,
        );

      case 'task':
        final t = _findById(data.tasks, id);
        final name = (t?['name'] as String?)?.trim() ?? '';
        return AppNotification(
          id: mark,
          kind: NotifKind.taskAdded,
          text: name.isEmpty
              ? AppText.t.notif_taskAdded
              : AppText.t.notif_taskAddedNamed(name),
          at: at,
        );

      case 'sched':
        final s = _findById(data.scheduleEvents, id);
        if (s == null) return null;
        final h = (s['hour'] as num?)?.toInt() ?? 0;
        final m = (s['minute'] as num?)?.toInt() ?? 0;
        final name = (s['name'] as String?)?.trim() ?? '';
        final time = NotificationSnapshot._hhmm(h, m);
        final label = name.isEmpty ? AppText.t.notif_programmeItem : name;
        // Nie odróżniamy „dodano" od „zmieniono" — dla odbiorcy liczy się
        // aktualna treść punktu, a nie historia edycji.
        return AppNotification(
          id: mark,
          kind: NotifKind.schedule,
          text: AppText.t.notif_scheduleAdded(label, time),
          at: at,
        );
    }
    return null;
  }

  static Map<int, Guest> _guestsById(WeddingData data) {
    final out = <int, Guest>{};
    for (final e in data.guests) {
      if (e is! Map) continue;
      final g = Guest(Map<String, dynamic>.from(e));
      if (g.id != null) out[g.id!] = g;
    }
    return out;
  }

  static String _guestName(Guest? g) {
    if (g == null) return AppText.t.role_guest;
    final full = g.fullName.trim();
    return full.isEmpty ? AppText.t.notif_guestNoName : full;
  }

  /// Ten sam mechanizm dla STREFY GOŚCIA, ale wąski: wyłącznie harmonogram.
  ///
  /// Gość widzi tylko publiczny mirror (`guestSpaces/{token}`), więc pracujemy
  /// na jego `scheduleEvents`, a nie na dokumencie wesela. Żaden inny rodzaj
  /// powiadomień do gościa nie trafia — to celowe zawężenie, nie filtr na
  /// pełnej liście, żeby przez pomyłkę nic mu nie wyciekło.
  static NotificationSnapshot guestSnapshot(dynamic scheduleEvents) {
    final marks = <String>{};
    if (scheduleEvents is List) {
      for (final e in scheduleEvents) {
        final mark = NotificationSnapshot.scheduleMark(e);
        if (mark != null) marks.add(mark);
      }
    }
    return NotificationSnapshot(marks);
  }

  /// Wykrywanie zmian harmonogramu dla gościa.
  ///
  /// ⚠️ Jak u organizatora: pusty [previous] = pierwsze uruchomienie, więc
  /// zapisujemy odcisk BEZ powiadomień.
  static NotificationDiff detectGuest({
    required NotificationSnapshot previous,
    required dynamic scheduleEvents,
    DateTime? now,
  }) {
    final current = guestSnapshot(scheduleEvents);
    if (previous.isEmpty) {
      return NotificationDiff(notifications: const [], snapshot: current);
    }

    final at = now ?? DateTime.now();
    final fresh = current.marks.difference(previous.marks);
    final out = <AppNotification>[];

    for (final mark in fresh) {
      final id = int.tryParse(mark.split(':').elementAtOrNull(1) ?? '');
      if (id == null) continue;
      final e = _findById(scheduleEvents, id);
      if (e == null) continue;

      final h = (e['hour'] as num?)?.toInt() ?? 0;
      final m = (e['minute'] as num?)?.toInt() ?? 0;
      final name = (e['name'] as String?)?.trim() ?? '';
      final label = name.isEmpty ? AppText.t.notif_programmeItem : name;

      out.add(AppNotification(
        id: mark,
        kind: NotifKind.schedule,
        text: 'Zmieniono w harmonogramie: $label ${NotificationSnapshot._hhmm(h, m)}',
        at: at,
      ));
    }

    out.sort((a, b) => a.id.compareTo(b.id));
    return NotificationDiff(notifications: out, snapshot: current);
  }

  static Map<dynamic, dynamic>? _findById(dynamic list, int id) {
    if (list is! List) return null;
    for (final e in list) {
      if (e is Map && (e['id'] as num?)?.toInt() == id) return e;
    }
    return null;
  }
}
