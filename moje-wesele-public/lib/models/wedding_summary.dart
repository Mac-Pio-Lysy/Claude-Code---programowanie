import '../l10n/app_text.dart';
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
    this.guestToken,
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

  /// Token strefy gości — wypełniany TYLKO gdy podsumowanie powstało z
  /// `weddings/{id}/guestView/main` (rola guest). Dla organizatorów `null`,
  /// bo czytają dokument wesela i token biorą stamtąd.
  ///
  /// Etap 3 go jeszcze nie używa; potrzebuje go etap 4, w którym ekran gościa
  /// renderuje stronę gościa po tokenie zamiast czytać dokument wesela.
  final String? guestToken;

  /// Etykieta roli po polsku.
  String get roleLabel => switch (role) {
        'owner' => AppText.t.wsum_owner,
        'planner' => 'Planer',
        'collaborator' => AppText.t.wsum_collab,
        'guest' => AppText.t.role_guest,
        _ => role,
      };

  /// Czy bieżący użytkownik jest w tym weselu gościem (ograniczony dostęp).
  bool get isGuest => role == 'guest';

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
          : AppText.t.cw_defaultName,
      persons: (persons ?? '').trim(),
      date: _parseDate(data['weddingDate']),
      role: role,
    );
  }

  /// Buduje podsumowanie z `weddings/{id}/guestView/main` — dokumentu, który
  /// czyta rola `guest` (D1). W przeciwieństwie do dokumentu wesela pola są
  /// PŁASKIE (bez `appConfig`), bo to wyliczany wyciąg, a nie kopia.
  factory WeddingSummary.fromGuestView(
    String id,
    Map<String, dynamic> data,
    String role,
  ) {
    final name = (data['eventName'] as String?)?.trim() ?? '';
    final token = (data['guestToken'] as String?)?.trim();
    return WeddingSummary(
      id: id,
      name: name.isNotEmpty ? name : AppText.t.cw_defaultName,
      persons: (data['displayNames'] as String?)?.trim() ?? '',
      date: _parseDate(data['weddingDate']),
      role: role,
      guestToken: (token != null && token.isNotEmpty) ? token : null,
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
