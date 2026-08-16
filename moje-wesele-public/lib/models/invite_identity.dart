import 'join_code.dart';

/// Publiczny dokument kodu paczki (`inviteCodes/{KOD}`) — tak, jak widzi go
/// gość skanujący zaproszenie.
///
/// Zawiera WYŁĄCZNIE to, co jest potrzebne, żeby gość rozpoznał siebie:
/// wesele, token strefy gości i imiona z paczki. Żadnych telefonów, diet,
/// kategorii ani przypisania do stołu — patrz `InvitePackage.members`.
class InviteCodeDoc {
  const InviteCodeDoc({
    required this.code,
    required this.weddingId,
    required this.guestToken,
    required this.packageId,
    required this.members,
    required this.revoked,
  });

  final String code;
  final String weddingId;

  /// Token strefy gości — kod paczki prowadzi do TEJ SAMEJ strefy co wspólny
  /// link. Indywidualny kod jest bramką tożsamości, nie osobnym miejscem.
  final String guestToken;

  final int packageId;
  final List<InviteMember> members;

  /// Kod unieważniony przez organizatora — gość dostaje zrozumiały komunikat,
  /// a nie „nieprawidłowy link".
  final bool revoked;

  /// Czy dokument nadaje się do wpuszczenia gościa do strefy.
  bool get usable => !revoked && guestToken.isNotEmpty;

  /// Osoby z podanym imieniem — to one trafiają na kafelki wyboru.
  List<InviteMember> get named =>
      members.where((m) => !m.namePending && m.name.isNotEmpty).toList();

  /// Czy w paczce jest ktoś bez uzupełnionego imienia.
  ///
  /// Wtedy pokazujemy dodatkową drogę „jestem osobą towarzyszącą" z polem na
  /// imię — para wiedziała, że ktoś przyjdzie, ale nie wiedziała kto.
  bool get hasPending => members.any((m) => m.namePending);

  static InviteCodeDoc? fromMap(String code, Map<String, dynamic>? m) {
    if (m == null) return null;
    final raw = m['members'];
    return InviteCodeDoc(
      code: code,
      weddingId: (m['weddingId'] as String?) ?? '',
      guestToken: (m['guestToken'] as String?)?.trim() ?? '',
      packageId: (m['packageId'] as num?)?.toInt() ?? -1,
      revoked: m['revoked'] == true,
      members: [
        for (final e in (raw is List ? raw : const []))
          if (e is Map) InviteMember.fromMap(Map<String, dynamic>.from(e)),
      ],
    );
  }
}

/// Jedna osoba z paczki — kafelek na ekranie „Kim jesteś?".
class InviteMember {
  const InviteMember({
    required this.guestId,
    required this.name,
    required this.isMain,
    required this.namePending,
  });

  final int guestId;
  final String name;
  final bool isMain;
  final bool namePending;

  factory InviteMember.fromMap(Map<String, dynamic> m) => InviteMember(
        guestId: (m['guestId'] as num?)?.toInt() ?? -1,
        name: (m['name'] as String?)?.trim() ?? '',
        isMain: m['kind'] == 'main',
        namePending: m['namePending'] == true,
      );
}

/// Tożsamość gościa w paczce — „ta przeglądarka to Anna z zaproszenia X".
///
/// ⚠️ TO ROZPOZNANIE, NIE UWIERZYTELNIENIE. Kod jedzie wydrukowany na
/// zaproszeniu, więc każdy, kto go zobaczy, może wybrać dowolną osobę z tej
/// paczki. Organizator ma traktować wynik jako „prawdopodobnie Anna" —
/// mówi mu o tym wprost ekran zaproszeń.
class PackageIdentity {
  const PackageIdentity({
    required this.code,
    required this.guestId,
    required this.displayName,
    required this.source,
  });

  final String code;

  /// `id` rekordu gościa albo `null` przy „nie wiem" / „to nie moje
  /// zaproszenie" — takie tożsamości trafiają do sekcji „do przypisania"
  /// (etap 5).
  final int? guestId;

  final String displayName;

  /// `picked` — gość wskazał siebie na liście; `typed` — wpisał imię sam.
  final String source;

  static const String sourcePicked = 'picked';
  static const String sourceTyped = 'typed';

  /// Czy tożsamość wskazuje na konkretny rekord gościa.
  bool get isAssigned => guestId != null;

  /// Identyfikator dokumentu w `identities`.
  ///
  /// Dwa kształty, oba weryfikowane regułą:
  ///  • `{KOD}__{guestId}` — wskazana osoba z paczki. Jedno miejsce na osobę,
  ///    więc paczka dwuosobowa daje najwyżej dwie tożsamości (decyzja 0.4).
  ///  • `{KOD}__x{uid}` — „nie wiem, kim jestem". Zakres własnego `uid`,
  ///    żeby takie zgłoszenia nie zajmowały imiennych miejsc ani się nie
  ///    nadpisywały między gośćmi.
  String docId(String uid) =>
      isAssigned ? '${code}__$guestId' : '${code}__x$uid';

  Map<String, dynamic> toMap(String uid) => {
        'uid': uid,
        'code': code,
        'guestId': guestId,
        'displayName': displayName,
        'source': source,
      };

  /// Zapis lokalny (pamięć przeglądarki) — bez `uid`, bo ten bierze się
  /// z bieżącej sesji.
  Map<String, dynamic> toLocal() => {
        'code': code,
        'guestId': guestId,
        'displayName': displayName,
        'source': source,
      };

  static PackageIdentity? fromLocal(Map<String, dynamic>? m) {
    if (m == null) return null;
    final code = (m['code'] as String?)?.trim() ?? '';
    final name = (m['displayName'] as String?)?.trim() ?? '';
    if (code.isEmpty || name.isEmpty) return null;
    return PackageIdentity(
      code: code,
      guestId: (m['guestId'] as num?)?.toInt(),
      displayName: name,
      source: (m['source'] as String?) ?? sourceTyped,
    );
  }

  /// Klucz w pamięci lokalnej — per kod, żeby jedna przeglądarka mogła
  /// obsłużyć dwa różne zaproszenia (np. rodzic skanujący też kod dziecka).
  static String localKey(String code) =>
      'invite_identity_${JoinCode.normalize(code)}';
}
