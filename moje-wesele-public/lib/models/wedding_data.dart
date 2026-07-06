/// Odczytany stan wesela z dokumentu `weddingPlanner/main`.
///
/// Struktura odpowiada obiektowi zapisywanemu przez aplikację webową
/// (`_serializeState()` w zrodlo-web/script.js). Na tym etapie wyciągamy
/// tylko pola potrzebne do ekranu testowego — pełny obiekt jest dostępny
/// w [raw], więc kolejne sekcje można dodawać stopniowo.
class WeddingData {
  WeddingData({
    required this.guests,
    required this.tables,
    required this.tasks,
    required this.vendors,
    required this.scheduleEvents,
    required this.eventName,
    required this.displayNames,
    required this.weddingDate,
    required this.budgetTotal,
    required this.raw,
  });

  /// Lista gości (klucz `guests`).
  final List<dynamic> guests;

  /// Lista stołów (klucz `tables`).
  final List<dynamic> tables;

  /// Lista zadań (klucz `tasks`).
  final List<dynamic> tasks;

  /// Lista dostawców (klucz `vendors`).
  final List<dynamic> vendors;

  /// Harmonogram dnia (klucz `scheduleEvents`).
  final List<dynamic> scheduleEvents;

  /// Nazwa wydarzenia — zagnieżdżona w `appConfig.eventName`.
  final String? eventName;

  /// Osoby (wyświetlane pod nazwą) — `appConfig.displayNames`.
  final String? displayNames;

  /// Data ślubu (z pola `weddingDate`, format "YYYY-MM-DD").
  final DateTime? weddingDate;

  /// Limit budżetu (`budgetData.total`) w złotych.
  final num budgetTotal;

  /// Surowy dokument — pełny zestaw danych z Firestore.
  final Map<String, dynamic> raw;

  int get guestCount => guests.length;
  int get tableCount => tables.length;
  int get taskCount => tasks.length;
  int get vendorCount => vendors.length;
  int get scheduleCount => scheduleEvents.length;

  /// Liczba pełnych dni do ślubu (0, jeśli data minęła; null, gdy brak daty).
  int? get daysUntilWedding {
    final wd = weddingDate;
    if (wd == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(wd.year, wd.month, wd.day);
    final diff = target.difference(today).inDays;
    return diff < 0 ? 0 : diff;
  }

  factory WeddingData.fromMap(Map<String, dynamic> map) {
    final appConfig = map['appConfig'];
    final eventName = (appConfig is Map) ? appConfig['eventName'] as String? : null;
    final displayNames =
        (appConfig is Map) ? appConfig['displayNames'] as String? : null;

    final budgetData = map['budgetData'];
    final total = (budgetData is Map) ? budgetData['total'] : null;

    return WeddingData(
      guests: _asList(map['guests']),
      tables: _asList(map['tables']),
      tasks: _asList(map['tasks']),
      vendors: _asList(map['vendors']),
      scheduleEvents: _asList(map['scheduleEvents']),
      eventName: eventName,
      displayNames: displayNames,
      weddingDate: _parseDate(map['weddingDate']),
      budgetTotal: total is num ? total : 0,
      raw: map,
    );
  }

  /// Bezpieczne rzutowanie na listę — Firestore może zwrócić null lub inny typ.
  static List<dynamic> _asList(dynamic value) =>
      value is List ? value : const [];

  /// Parsowanie daty ślubu z formatu "YYYY-MM-DD".
  static DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(value);
      if (m != null) {
        return DateTime(
          int.parse(m.group(1)!),
          int.parse(m.group(2)!),
          int.parse(m.group(3)!),
        );
      }
    }
    return null;
  }
}
