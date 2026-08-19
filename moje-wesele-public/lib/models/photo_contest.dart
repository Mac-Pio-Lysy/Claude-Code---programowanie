/// Podkategoria konkursu (np. „Pan Młody" / „Panna Młoda" / „Razem").
///
/// `id` jest LICZBĄ CAŁKOWITĄ, unikalną w obrębie jednego konkursu — nigdy
/// tekstem wpisywanym przez organizatora. ID dokumentów głosów ma postać
/// `{uid}__{contestId}__{subcategoryId}`; gdyby `id` mogło zawierać `__`,
/// groziłoby to kolizją z separatorem. `label` (dowolny tekst) jest osobnym
/// polem wyłącznie do wyświetlania.
class ContestSubcategory {
  ContestSubcategory({required this.id, required this.label});

  final int id;
  final String label;

  factory ContestSubcategory.fromMap(Map<String, dynamic> m) =>
      ContestSubcategory(
        id: (m['id'] as num?)?.toInt() ?? 0,
        label: (m['label'] as String?)?.trim() ?? '',
      );

  Map<String, dynamic> toMap() => {'id': id, 'label': label};
}

/// Tryb ujawnienia wyników konkursu.
class ContestRevealMode {
  static const String manual = 'manual';
  static const String auto = 'auto';
}

/// Konkurs fotograficzny z głosowaniem gości (system 3-2-1) + osobnym
/// werdyktem Pary Młodej.
///
/// Zapisywany w `weddings/{id}.photoContests` jako MAPA `{contestId:
/// config}` (nie lista) — `contestId` jest liczbą całkowitą (jak
/// [ContestSubcategory.id], z tego samego powodu: separator `__` w ID
/// dokumentów zgłoszeń/głosów w `guestSpaces/{token}/contestSubmissions`
/// i `contestVotes`).
///
/// `results`/`coupleChoice` istnieją w dokumencie DOPIERO po ujawnieniu —
/// przed tym momentem organizator po prostu ich jeszcze nie zapisał, więc
/// mirror gościa (`guestSpaces/{token}`) nie ma czego ukrywać osobną regułą.
class PhotoContest {
  PhotoContest({
    required this.id,
    required this.name,
    required this.subcategories,
    required this.rankingSize,
    required this.revealMode,
    this.revealDate,
    this.active = true,
    this.nextSubcategoryId = 1,
    this.results = const {},
    this.coupleChoice = const {},
  });

  final int id;
  final String name;
  final List<ContestSubcategory> subcategories;

  /// Rozmiar rankingu widocznego dla gości: 10 / 15 / 20.
  final int rankingSize;

  /// [ContestRevealMode.manual] lub [ContestRevealMode.auto].
  final String revealMode;

  /// Data ujawnienia ("YYYY-MM-DD"), tylko gdy [revealMode] == auto.
  final String? revealDate;

  final bool active;

  /// Licznik do generowania kolejnego [ContestSubcategory.id] tego konkursu.
  final int nextSubcategoryId;

  /// `{subcategoryId (jako string): {revealedAt, ranking: [...]}}`.
  /// Puste = jeszcze nieujawnione.
  final Map<String, dynamic> results;

  /// `{subcategoryId (jako string): {first, second, third, honorable: [...]}}`.
  final Map<String, dynamic> coupleChoice;

  bool get isRevealed => results.isNotEmpty;

  ContestSubcategory? subcategory(int subId) {
    for (final s in subcategories) {
      if (s.id == subId) return s;
    }
    return null;
  }

  /// Parsuje `weddings/{id}.photoContests` (mapa `{contestId: config}`) w
  /// jednym miejscu — używane zarówno przez [PhotoContestService], jak i
  /// bezpośrednio przez ekran organizatora czytający żywy `WeddingData.raw`.
  static Map<int, PhotoContest> mapFromRaw(dynamic raw) {
    final result = <int, PhotoContest>{};
    if (raw is Map) {
      for (final entry in raw.entries) {
        final id = int.tryParse(entry.key.toString());
        if (id == null || entry.value is! Map) continue;
        result[id] =
            PhotoContest.fromMap(id, Map<String, dynamic>.from(entry.value as Map));
      }
    }
    return result;
  }

  factory PhotoContest.fromMap(int id, Map<String, dynamic> m) => PhotoContest(
        id: id,
        name: (m['name'] as String?)?.trim() ?? '',
        subcategories: [
          for (final e in (m['subcategories'] as List?) ?? const [])
            if (e is Map) ContestSubcategory.fromMap(Map<String, dynamic>.from(e)),
        ],
        rankingSize: (m['rankingSize'] as num?)?.toInt() ?? 10,
        revealMode: m['revealMode'] == ContestRevealMode.auto
            ? ContestRevealMode.auto
            : ContestRevealMode.manual,
        revealDate: (m['revealDate'] as String?)?.trim().isNotEmpty == true
            ? (m['revealDate'] as String).trim()
            : null,
        active: m['active'] != false,
        nextSubcategoryId: (m['nextSubcategoryId'] as num?)?.toInt() ?? 1,
        results: m['results'] is Map
            ? Map<String, dynamic>.from(m['results'] as Map)
            : const {},
        coupleChoice: m['coupleChoice'] is Map
            ? Map<String, dynamic>.from(m['coupleChoice'] as Map)
            : const {},
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'subcategories': [for (final s in subcategories) s.toMap()],
        'rankingSize': rankingSize,
        'revealMode': revealMode,
        'revealDate': revealDate,
        'active': active,
        'nextSubcategoryId': nextSubcategoryId,
        'results': results,
        'coupleChoice': coupleChoice,
      };

  PhotoContest copyWith({
    String? name,
    List<ContestSubcategory>? subcategories,
    int? rankingSize,
    String? revealMode,
    String? revealDate,
    bool clearRevealDate = false,
    bool? active,
    int? nextSubcategoryId,
    Map<String, dynamic>? results,
    Map<String, dynamic>? coupleChoice,
  }) =>
      PhotoContest(
        id: id,
        name: name ?? this.name,
        subcategories: subcategories ?? this.subcategories,
        rankingSize: rankingSize ?? this.rankingSize,
        revealMode: revealMode ?? this.revealMode,
        revealDate: clearRevealDate ? null : (revealDate ?? this.revealDate),
        active: active ?? this.active,
        nextSubcategoryId: nextSubcategoryId ?? this.nextSubcategoryId,
        results: results ?? this.results,
        coupleChoice: coupleChoice ?? this.coupleChoice,
      );
}

/// Zgłoszenie zdjęcia do podkategorii konkursu
/// (`guestSpaces/{token}/contestSubmissions/{autoId}`).
///
/// `contestId`/`subcategoryId` są w Firestore STRINGAMI (zgodnie z regułą
/// `vContestSubmission`, `_s(...)`), mimo że [PhotoContest.id]/
/// [ContestSubcategory.id] to `int` — parsowane tu z powrotem na `int`,
/// żeby dopasowanie do konfiguracji konkursu było proste w kodzie Dart.
class ContestSubmission {
  ContestSubmission({
    required this.id,
    required this.contestId,
    required this.subcategoryId,
    required this.name,
    required this.photoUrl,
    required this.photoPublicId,
    required this.authorUid,
    required this.timestamp,
  });

  final String id;
  final int contestId;
  final int subcategoryId;
  final String name;
  final String photoUrl;
  final String photoPublicId;
  final String authorUid;
  final int timestamp;

  factory ContestSubmission.fromMap(String id, Map<String, dynamic> m) => ContestSubmission(
        id: id,
        contestId: int.tryParse('${m['contestId']}') ?? 0,
        subcategoryId: int.tryParse('${m['subcategoryId']}') ?? 0,
        name: (m['name'] as String?)?.trim() ?? '',
        photoUrl: (m['photoUrl'] as String?)?.trim() ?? '',
        photoPublicId: (m['photoPublicId'] as String?)?.trim() ?? '',
        authorUid: (m['authorUid'] as String?) ?? '',
        timestamp: (m['timestamp'] as num?)?.toInt() ?? 0,
      );
}
