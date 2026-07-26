/// Skrócone dane wesela do listy „Twoje wesela".
///
/// Budowane z dokumentu `weddings/{id}` + roli z odpowiedniego członkostwa.
/// Nie zawiera pełnych danych sekcji — służy tylko do wyświetlenia karty na
/// liście i wyboru aktywnego wesela.
class WeddingSummary {
  WeddingSummary({
    required this.id,
    required this.name,
    required this.persons,
    required this.date,
    required this.role,
  });

  final String id;

  /// Nazwa wesela (`appConfig.eventName`).
  final String name;

  /// Osoby (`appConfig.displayNames`).
  final String persons;

  /// Data ślubu ("YYYY-MM-DD") lub `null`, gdy jeszcze nie ustawiono.
  final DateTime? date;

  /// Rola bieżącego użytkownika w tym weselu ('owner'/'planner'/'collaborator').
  final String role;

  /// Etykieta roli po polsku.
  String get roleLabel => switch (role) {
        'owner' => 'Właściciel',
        'planner' => 'Planer',
        'collaborator' => 'Współpraca',
        _ => role,
      };

  factory WeddingSummary.fromWeddingDoc(
    String id,
    Map<String, dynamic> data,
    String role,
  ) {
    final appConfig = data['appConfig'];
    final name = (appConfig is Map ? appConfig['eventName'] as String? : null);
    final persons =
        (appConfig is Map ? appConfig['displayNames'] as String? : null);
    return WeddingSummary(
      id: id,
      name: (name != null && name.trim().isNotEmpty)
          ? name.trim()
          : 'Nasze Wesele',
      persons: (persons ?? '').trim(),
      date: _parseDate(data['weddingDate']),
      role: role,
    );
  }

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
