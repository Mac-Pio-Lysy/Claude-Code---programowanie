import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/photo_contest.dart';
import 'firestore_service.dart';
import 'guest_space_service.dart';

/// Konfiguracja konkursów fotograficznych (organizator) — w
/// `weddings/{id}.photoContests`, MAPA `{contestId: config}`.
///
/// Zgłoszenia zdjęć i głosy gości (3-2-1) są w OSOBNYCH podkolekcjach
/// `guestSpaces/{token}/contestSubmissions` / `contestVotes` — obsługuje je
/// `GuestSpaceService`, tak jak dziś galerię/foto-wyzwania. Tu jest tylko
/// konfiguracja, którą pisze wyłącznie organizator (`fullAccess`, istniejąca
/// reguła `weddings/{w}` — zero zmian w regułach dla tego serwisu).
class PhotoContestService {
  PhotoContestService({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  final FirestoreService _firestore;

  Future<Map<String, dynamic>> _read() async =>
      await _firestore.readData() ?? <String, dynamic>{};

  Future<Map<int, PhotoContest>> readContests() async =>
      PhotoContest.mapFromRaw((await _read())['photoContests']);

  Future<void> _save(Map<int, PhotoContest> contests) => _firestore.setAndSync(
        {
          'photoContests': {
            for (final c in contests.values) '${c.id}': c.toMap(),
          },
        },
        SetOptions(merge: true),
      );

  Future<int> createContest({
    required String name,
    required List<String> subcategoryLabels,
    int rankingSize = 10,
    String revealMode = ContestRevealMode.manual,
    String? revealDate,
  }) async {
    final data = await _read();
    final contests = PhotoContest.mapFromRaw(data['photoContests']);
    final nextId = _nextId(data['nextPhotoContestId'], contests.keys);
    var nextSubId = 1;
    final subs = [
      for (final label in subcategoryLabels)
        if (label.trim().isNotEmpty) ContestSubcategory(id: nextSubId++, label: label.trim()),
    ];
    contests[nextId] = PhotoContest(
      id: nextId,
      name: name.trim(),
      subcategories: subs,
      rankingSize: rankingSize,
      revealMode: revealMode,
      revealDate: revealDate,
      nextSubcategoryId: nextSubId,
    );
    await _firestore.setAndSync(
      {
        'photoContests': {
          for (final c in contests.values) '${c.id}': c.toMap(),
        },
        'nextPhotoContestId': nextId + 1,
      },
      SetOptions(merge: true),
    );
    return nextId;
  }

  Future<void> updateContest(
    int id, {
    String? name,
    int? rankingSize,
    String? revealMode,
    String? revealDate,
    bool clearRevealDate = false,
    bool? active,
  }) async {
    final contests = await readContests();
    final c = contests[id];
    if (c == null) return;
    contests[id] = c.copyWith(
      name: name,
      rankingSize: rankingSize,
      revealMode: revealMode,
      revealDate: revealDate,
      clearRevealDate: clearRevealDate,
      active: active,
    );
    await _save(contests);
  }

  Future<void> deleteContest(int id) async {
    final contests = await readContests()..remove(id);
    await _save(contests);
  }

  /// Dodaje podkategorię do istniejącego konkursu.
  Future<void> addSubcategory(int contestId, String label) async {
    final t = label.trim();
    if (t.isEmpty) return;
    final contests = await readContests();
    final c = contests[contestId];
    if (c == null) return;
    final subs = [...c.subcategories, ContestSubcategory(id: c.nextSubcategoryId, label: t)];
    contests[contestId] =
        c.copyWith(subcategories: subs, nextSubcategoryId: c.nextSubcategoryId + 1);
    await _save(contests);
  }

  Future<void> renameSubcategory(int contestId, int subId, String label) async {
    final t = label.trim();
    if (t.isEmpty) return;
    final contests = await readContests();
    final c = contests[contestId];
    if (c == null) return;
    final subs = [
      for (final s in c.subcategories) s.id == subId ? ContestSubcategory(id: s.id, label: t) : s,
    ];
    contests[contestId] = c.copyWith(subcategories: subs);
    await _save(contests);
  }

  Future<void> deleteSubcategory(int contestId, int subId) async {
    final contests = await readContests();
    final c = contests[contestId];
    if (c == null) return;
    final subs = [
      for (final s in c.subcategories) if (s.id != subId) s,
    ];
    contests[contestId] = c.copyWith(subcategories: subs);
    await _save(contests);
  }

  // ── Etapy 4/5/6: ujawnienie wyników + werdykt Pary Młodej ────────────────

  /// Liczy ranking podkategorii i zapisuje go razem z (opcjonalnym) werdyktem
  /// Pary Młodej — JEDNA akcja „Ujawnij", zgodnie z ustaleniem. Odczyt głosów
  /// (`GuestSpaceService.watchContestVotes`, `list: orgOf`) i zgłoszeń dzieje
  /// się TU, jednorazowo (`.first` na strumieniu) — sama agregacja jest
  /// czysto kliencka, patrz komentarz przy `computeContestRanking`.
  ///
  /// Wywoływana zarówno z przycisku „Ujawnij teraz" (ręcznie, etap 4/5), jak
  /// i z automatycznego sprawdzenia po dacie (etap 6) — jedno miejsce, żeby
  /// oba tryby liczyły ranking dokładnie tak samo.
  Future<void> revealSubcategory({
    required GuestSpaceService guestSpace,
    required int contestId,
    required int subcategoryId,
    required int rankingSize,
    Map<String, dynamic>? coupleChoice,
  }) async {
    final submissions =
        await guestSpace.watchContestSubmissions(contestId, subcategoryId).first;
    final votes = await guestSpace.watchContestVotes(contestId, subcategoryId).first;
    final ranking = computeContestRanking(
      submissions: submissions,
      votes: votes,
      rankingSize: rankingSize,
    );
    await publishResults(
      contestId: contestId,
      subcategoryId: subcategoryId,
      ranking: ranking,
      coupleChoice: coupleChoice,
    );
  }

  /// Zapisuje policzony ranking (+ opcjonalnie werdykt Pary Młodej) do
  /// konfiguracji konkursu. Zwykły zapis `weddings/{id}` (`fullAccess`) —
  /// zero zmian w regułach. Mirror gościa (`_guestMirror`) skopiuje to przy
  /// najbliższej synchronizacji (wywołaj `WeddingService().ensureGuestToken`
  /// po tej metodzie, jak przy każdej zmianie konfiguracji konkursów).
  Future<void> publishResults({
    required int contestId,
    required int subcategoryId,
    required List<Map<String, dynamic>> ranking,
    Map<String, dynamic>? coupleChoice,
  }) async {
    final contests = await readContests();
    final c = contests[contestId];
    if (c == null) return;
    final results = Map<String, dynamic>.from(c.results);
    results['$subcategoryId'] = {
      'revealedAt': DateTime.now().millisecondsSinceEpoch,
      'ranking': ranking,
    };
    final coupleMap = Map<String, dynamic>.from(c.coupleChoice);
    if (coupleChoice != null) {
      coupleMap['$subcategoryId'] = coupleChoice;
    }
    contests[contestId] = c.copyWith(results: results, coupleChoice: coupleMap);
    await _save(contests);
  }

  int _nextId(dynamic stored, Iterable<int> existingIds) {
    final s = (stored as num?)?.toInt() ?? 1;
    var maxId = 0;
    for (final id in existingIds) {
      if (id > maxId) maxId = id;
    }
    return max(s, maxId + 1);
  }
}
