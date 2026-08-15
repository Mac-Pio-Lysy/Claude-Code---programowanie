import '../l10n/app_text.dart';
import 'couple.dart';

/// Stan członkostwa niezależny od języka — do kolorowania i porównań.
enum MembershipStatusKind { active, blocked, pending, expired }

/// Powiązanie użytkownik ↔ wesele (kolekcja `memberships`).
///
/// Jeden użytkownik może mieć dostęp do wielu wesel, a jedno wesele może mieć
/// wielu użytkowników. Rola określa poziom dostępu:
///   • `owner`        — Para Młoda / założyciel: ZAWSZE nadrzędny, nieusuwalny,
///   • `planner`      — planer: pełny panel, ale z DATĄ WAŻNOŚCI (`expiresAt`),
///   • `collaborator` — współorganizator (świadek, mama): pełny panel bez daty,
///   • `guest`        — gość: ograniczony dostęp (patrz etap 4b).
///
/// Status kontroluje owner: `active` (dostęp), `blocked` (odcięty), `pending`
/// (zaproszenie kodem, jeszcze nieodebrane — brak `userId`).
///
/// UWAGA: reguły bezpieczeństwa NIE są jeszcze wdrożone — egzekwowanie ról jest
/// na poziomie INTERFEJSU (krok izolacji doda reguły Firestore).
class Membership {
  Membership({
    required this.id,
    required this.userId,
    required this.weddingId,
    required this.role,
    this.status = 'active',
    this.expiresAt,
    this.email = '',
    this.displayName = '',
    this.inviteCode,
  });

  /// ID dokumentu członkostwa.
  final String id;

  /// UID użytkownika (pusty dla nieodebranego zaproszenia kodem — `pending`).
  final String userId;
  final String weddingId;

  /// 'owner' | 'planner' | 'collaborator' | 'guest'.
  final String role;

  /// 'active' | 'blocked' | 'pending'.
  final String status;

  /// Data ważności dostępu ("YYYY-MM-DD") — tylko dla planera; null = bez końca.
  final String? expiresAt;

  /// E-mail osoby (do wyświetlenia na liście osób).
  final String email;

  /// Nazwa/imię osoby (jeśli znane).
  final String displayName;

  /// Kod zaproszenia (tylko dla `pending` — do odebrania roli przez osobę).
  final String? inviteCode;

  bool get isOwner => role == 'owner';
  bool get isBlocked => status == 'blocked';
  bool get isPending => status == 'pending';

  /// Czy dostęp planera wygasł względem [today] (data w Warszawie).
  bool isExpiredOn(DateTime today) {
    if (role != 'planner') return false;
    final exp = _parse(expiresAt);
    if (exp == null) return false;
    final d = DateTime(today.year, today.month, today.day);
    return d.isAfter(exp); // po dacie ważności (włącznie z dniem = jeszcze OK)
  }

  /// Czy członkostwo daje dostęp DZIŚ (aktywne, nie zablokowane, nie wygasłe).
  bool isEffectiveOn(DateTime today) =>
      status == 'active' && !isExpiredOn(today);

  /// Etykieta roli na ekranie — TŁUMACZONA. W bazie zostaje [role]
  /// (`owner`/`planner`/…), więc zmiana języka nie rusza uprawnień.
  String get roleLabel => switch (role) {
        // Właściciel opisany jak wszędzie indziej — z uwzględnieniem typu
        // uroczystości (para jednopłciowa nie zobaczy „Pary Młodej").
        'owner' => CoupleLabels.current.coupleCategoryLabel,
        'planner' => AppText.t.role_planner,
        'collaborator' => AppText.t.role_collaborator,
        'guest' => AppText.t.role_guest,
        _ => role,
      };

  /// Etykieta statusu na ekranie (uwzględnia wygaśnięcie planera).
  ///
  /// Do KOLOROWANIA i logiki służy [statusKindOn], nie ta etykieta — inaczej
  /// po przełączeniu języka porównania tekstu przestałyby trafiać.
  String statusLabelOn(DateTime today) => switch (statusKindOn(today)) {
        MembershipStatusKind.blocked => AppText.t.status_blocked,
        MembershipStatusKind.pending => AppText.t.status_pending,
        MembershipStatusKind.expired => AppText.t.status_expired,
        MembershipStatusKind.active => AppText.t.status_active,
      };

  /// Status w formie nadającej się do porównań (niezależnej od języka).
  MembershipStatusKind statusKindOn(DateTime today) {
    if (status == 'blocked') return MembershipStatusKind.blocked;
    if (status == 'pending') return MembershipStatusKind.pending;
    if (isExpiredOn(today)) return MembershipStatusKind.expired;
    return MembershipStatusKind.active;
  }

  factory Membership.fromMap(String id, Map<String, dynamic> m) => Membership(
        id: id,
        userId: (m['userId'] as String?) ?? '',
        weddingId: (m['weddingId'] as String?) ?? '',
        role: (m['role'] as String?) ?? 'collaborator',
        status: (m['status'] as String?) ?? 'active',
        expiresAt: _cleanDate(m['expiresAt']),
        email: (m['email'] as String?) ?? '',
        displayName: (m['displayName'] as String?) ?? '',
        inviteCode: (m['inviteCode'] as String?),
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'weddingId': weddingId,
        'role': role,
        'status': status,
        'expiresAt': expiresAt,
        'email': email,
        'displayName': displayName,
        if (inviteCode != null) 'inviteCode': inviteCode,
      };

  static String? _cleanDate(dynamic v) =>
      (v is String && v.trim().isNotEmpty) ? v.trim() : null;

  static DateTime? _parse(String? s) {
    if (s == null) return null;
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(s);
    if (m == null) return null;
    return DateTime(
        int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));
  }
}
