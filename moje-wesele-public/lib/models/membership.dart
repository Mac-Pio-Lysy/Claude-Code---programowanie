/// Powiązanie użytkownik ↔ wesele (kolekcja `memberships`).
///
/// Jeden użytkownik może mieć dostęp do wielu wesel, a jedno wesele może mieć
/// wielu użytkowników. Rola określa poziom dostępu:
///   • `owner`        — właściciel (Para Młoda / założyciel wesela),
///   • `planner`      — planer/organizator z dostępem do wesela,
///   • `collaborator` — współpracownik zaproszony do pomocy.
///
/// UWAGA: reguły bezpieczeństwa NIE są jeszcze wdrożone — role są tu tylko
/// jako struktura danych (zgodnie z zakresem tego kroku).
class Membership {
  Membership({
    required this.id,
    required this.userId,
    required this.weddingId,
    required this.role,
  });

  /// ID dokumentu członkostwa.
  final String id;
  final String userId;
  final String weddingId;

  /// 'owner' | 'planner' | 'collaborator'.
  final String role;

  factory Membership.fromMap(String id, Map<String, dynamic> m) => Membership(
        id: id,
        userId: (m['userId'] as String?) ?? '',
        weddingId: (m['weddingId'] as String?) ?? '',
        role: (m['role'] as String?) ?? 'collaborator',
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'weddingId': weddingId,
        'role': role,
      };
}
