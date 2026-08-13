import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification.dart';
import '../models/notification_snapshot.dart';
import '../models/wedding_data.dart';

/// Centrum powiadomień (etap 1a) — trwałość odcisku i stanu przeczytania.
///
/// Zapis jest LOKALNY (`SharedPreferences`), per użytkownik i per wesele —
/// tak jak `OnboardingService` i preferencja układu. Konsekwencja przyjęta
/// świadomie: „nieprzeczytane" liczy się osobno na każdym urządzeniu. Push
/// z serwera to etap 2.
class NotificationService {
  NotificationService({required this.uid, required this.weddingId});

  final String uid;
  final String weddingId;

  /// Ile identyfikatorów przeczytanych trzymamy. Starsze wypadają — bez tego
  /// lista rosłaby w nieskończoność przez cały okres planowania wesela.
  static const int maxReadIds = 500;

  String get _snapshotKey => 'notif_seen_${uid}_$weddingId';
  String get _readKey => 'notif_read_${uid}_$weddingId';

  /// Odcisk stanu, który użytkownik już widział.
  Future<NotificationSnapshot> loadSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationSnapshot.fromStringList(
        prefs.getStringList(_snapshotKey));
  }

  Future<void> saveSnapshot(NotificationSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_snapshotKey, snapshot.toStringList());
  }

  /// Identyfikatory powiadomień oznaczonych jako przeczytane.
  Future<Set<String>> loadReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_readKey) ?? const []).toSet();
  }

  Future<void> markRead(Iterable<String> ids) async {
    if (ids.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_readKey) ?? const <String>[]).toList()
      ..addAll(ids);
    // Duplikaty odpadają, a przycinamy od początku — najstarsze wpisy są
    // najmniej potrzebne, bo dotyczą zdarzeń dawno zniknięcych z listy.
    final unique = current.toSet().toList();
    final trimmed = unique.length <= maxReadIds
        ? unique
        : unique.sublist(unique.length - maxReadIds);
    await prefs.setStringList(_readKey, trimmed);
  }

  /// Czyści stan (np. przy „Oznacz wszystkie jako przeczytane" po wylogowaniu
  /// albo w narzędziach deweloperskich).
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_snapshotKey);
    await prefs.remove(_readKey);
  }

  /// Pełny cykl: wczytaj odcisk → porównaj → zapisz nowy odcisk.
  ///
  /// Zwraca WYŁĄCZNIE powiadomienia jeszcze nieprzeczytane. Odcisk zapisujemy
  /// zawsze, także przy pierwszym uruchomieniu — wtedy po cichu, bez
  /// powiadomień (patrz [NotificationDetector.detect]).
  Future<List<AppNotification>> refresh(WeddingData? data,
      {DateTime? now}) async {
    final previous = await loadSnapshot();
    final diff = NotificationDetector.detect(
      previous: previous,
      data: data,
      now: now,
    );
    await saveSnapshot(diff.snapshot);

    if (diff.notifications.isEmpty) return const [];
    final read = await loadReadIds();
    return [
      for (final n in diff.notifications)
        if (!read.contains(n.id)) n,
    ];
  }
}

/// Lista powiadomień utrzymywana w pamięci między odświeżeniami danych.
///
/// Detektor zwraca tylko RÓŻNICĘ względem ostatniego odcisku, więc kolejny
/// snapshot z Firestore nie powtórzy poprzednich zmian. Bez takiego bufora
/// powiadomienie zniknęłoby z dzwoneczka przy najbliższym odświeżeniu danych.
class NotificationInbox {
  NotificationInbox({this.maxItems = 100});

  final int maxItems;
  final List<AppNotification> _items = [];
  final Set<String> _read = {};

  List<AppNotification> get all => List.unmodifiable(_items);

  List<AppNotification> get unread =>
      [for (final n in _items) if (!_read.contains(n.id)) n];

  int get unreadCount => unread.length;

  List<NotifGroup> get unreadGroups => NotifGroup.from(unread);

  /// Dokłada nowe powiadomienia, pomijając te, które już są na liście.
  void add(Iterable<AppNotification> items) {
    final known = {for (final n in _items) n.id};
    for (final n in items) {
      if (known.contains(n.id)) continue;
      _items.insert(0, n); // najnowsze na górze
      known.add(n.id);
    }
    if (_items.length > maxItems) _items.removeRange(maxItems, _items.length);
  }

  /// Przywraca zapisany stan przeczytania (po starcie aplikacji).
  void restoreRead(Iterable<String> ids) => _read.addAll(ids);

  void markRead(String id) => _read.add(id);

  void markAllRead() => _read.addAll([for (final n in _items) n.id]);

  bool isRead(String id) => _read.contains(id);

  /// Identyfikatory do zapisania w [NotificationService.markRead].
  Set<String> get readIds => Set.unmodifiable(_read);
}
