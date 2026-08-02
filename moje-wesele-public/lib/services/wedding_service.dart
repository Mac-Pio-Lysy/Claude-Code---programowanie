import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/wedding_summary.dart';
import 'membership_service.dart';

/// Wynik próby dołączenia do wesela jako gość.
enum JoinOutcome {
  /// Dołączono (utworzono członkostwo gościa).
  success,

  /// Użytkownik już należał do tego wesela (bez zmian).
  alreadyMember,

  /// Dane (kod/data/nazwisko) nie zgadzają się z żadnym weselem.
  invalid,

  /// Błąd techniczny (np. brak sieci).
  error,
}

/// Rezultat dołączania: wynik + ID wesela (gdy powodzenie) + rola.
class JoinResult {
  const JoinResult(this.outcome, {this.weddingId, this.role});
  final JoinOutcome outcome;
  final String? weddingId;
  final String? role;
}

/// Zarządzanie weselami (kolekcja `weddings`) i ich powiązaniem z użytkownikiem.
///
/// Odpowiada za:
///   • utworzenie nowego wesela (auto-ID + domyślna konfiguracja + kod
///     dołączenia + członkostwo `owner` dla twórcy),
///   • listę wesel dostępnych użytkownikowi (przez jego członkostwa),
///   • dołączanie gościa po potrójnej weryfikacji (kod + data + nazwisko).
class WeddingService {
  WeddingService({FirebaseFirestore? db, MembershipService? memberships})
      : _db = db ?? FirebaseFirestore.instance,
        _memberships = memberships ?? MembershipService(db: db);

  final FirebaseFirestore _db;
  final MembershipService _memberships;

  static const String collectionName = 'weddings';

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(collectionName);

  /// Tworzy nowe wesele i nadaje twórcy rolę `owner`.
  ///
  /// Zwraca wygenerowane `weddingId`. `date` w formacie "YYYY-MM-DD" lub `null`
  /// (można uzupełnić później w Ustawieniach).
  Future<String> createWedding({
    required String userId,
    required String name,
    required String persons,
    String? date,
  }) async {
    final ref = _col.doc(); // auto-generowane, unikalne weddingId
    final weddingId = ref.id;
    final joinCode = await _uniqueJoinCode();

    await ref.set(_defaultWeddingData(
      ownerId: userId,
      name: name,
      persons: persons,
      date: date,
      joinCode: joinCode,
    ));

    await _memberships.create(
      userId: userId,
      weddingId: weddingId,
      role: 'owner',
    );

    return weddingId;
  }

  /// Zwraca kod dołączenia wesela; jeśli go nie ma (starsze wesele) — generuje
  /// nowy, unikalny i zapisuje. Używane w panelu właściciela.
  Future<String> ensureJoinCode(String weddingId) async {
    final ref = _col.doc(weddingId);
    final snap = await ref.get();
    final existing = (snap.data()?['joinCode'] as String?)?.trim();
    if (existing != null && existing.isNotEmpty) return existing;
    final code = await _uniqueJoinCode();
    await ref.set({'joinCode': code}, SetOptions(merge: true));
    return code;
  }

  /// Dołącza użytkownika jako GOŚĆ po potrójnej weryfikacji: kod + data ślubu
  /// + nazwisko/nazwa Państwa Młodych. Wszystkie trzy muszą się zgadzać.
  ///
  /// [date] w formacie "YYYY-MM-DD". [surname] porównywane z `displayNames`
  /// (a zapasowo z `eventName`) po normalizacji (bez wielkości liter/znaków
  /// diakrytycznych).
  Future<JoinResult> joinAsGuest({
    required String userId,
    required String code,
    required String date,
    required String surname,
  }) async {
    try {
      final normCode = code.trim().toUpperCase();
      if (normCode.isEmpty || date.trim().isEmpty || surname.trim().isEmpty) {
        return const JoinResult(JoinOutcome.invalid);
      }

      final query =
          await _col.where('joinCode', isEqualTo: normCode).limit(1).get();
      if (query.docs.isEmpty) return const JoinResult(JoinOutcome.invalid);

      final doc = query.docs.first;
      final data = doc.data();

      // 1) Data ślubu musi się zgadzać (i musi być ustawiona).
      final wDate = (data['weddingDate'] as String?)?.trim() ?? '';
      if (wDate.isEmpty || wDate != date.trim()) {
        return const JoinResult(JoinOutcome.invalid);
      }

      // 2) Nazwisko/nazwa Państwa Młodych.
      final cfg = data['appConfig'];
      final display =
          (cfg is Map ? cfg['displayNames'] as String? : null) ?? '';
      final event = (cfg is Map ? cfg['eventName'] as String? : null) ?? '';
      if (!_surnameMatches(surname, display, event)) {
        return const JoinResult(JoinOutcome.invalid);
      }

      // Weryfikacja OK → dodaj gościa (jeśli jeszcze nie należy).
      final weddingId = doc.id;
      final existing = await _memberships.findFor(userId, weddingId);
      if (existing != null) {
        return JoinResult(JoinOutcome.alreadyMember,
            weddingId: weddingId, role: existing.role);
      }
      await _memberships.create(
          userId: userId, weddingId: weddingId, role: 'guest');
      return JoinResult(JoinOutcome.success, weddingId: weddingId, role: 'guest');
    } catch (_) {
      return const JoinResult(JoinOutcome.error);
    }
  }

  /// Lista wesel dostępnych użytkownikowi (z jego członkostw). Wesela usunięte
  /// (brak dokumentu) są pomijane. Sortowanie: najbliższa data pierwsza,
  /// wesela bez daty na końcu.
  Future<List<WeddingSummary>> listForUser(String userId) async {
    final memberships = await _memberships.forUser(userId);
    final result = <WeddingSummary>[];
    for (final m in memberships) {
      final snap = await _col.doc(m.weddingId).get();
      final data = snap.data();
      if (data == null) continue; // wesele nie istnieje / zostało usunięte
      result.add(WeddingSummary.fromWeddingDoc(m.weddingId, data, m.role));
    }
    result.sort((a, b) {
      if (a.date == null && b.date == null) return a.name.compareTo(b.name);
      if (a.date == null) return 1;
      if (b.date == null) return -1;
      return a.date!.compareTo(b.date!);
    });
    return result;
  }

  /// Domyślna, „pusta" konfiguracja nowego wesela. Struktura zgodna z modelem
  /// [WeddingData] i serwisami sekcji — puste listy są bezpieczne (modele mają
  /// wbudowane wartości domyślne, np. kategorie wydatków i opcje menu).
  Map<String, dynamic> _defaultWeddingData({
    required String ownerId,
    required String name,
    required String persons,
    required String joinCode,
    String? date,
  }) {
    final coupleNames = _splitPersons(persons);
    return {
      'ownerId': ownerId,
      'joinCode': joinCode,
      'appConfig': {
        'eventName': name.trim().isEmpty ? 'Nasze Wesele' : name.trim(),
        'displayNames': persons.trim(),
        'ceremonyPlace': '',
        'receptionPlace': '',
        'menuOptions': <String>[],
        'expenseCategories': <String>[],
        'witnessCount': 2,
      },
      'weddingDate': (date != null && date.isNotEmpty) ? date : null,
      'weddingTime': '16:00',
      'budgetData': {
        'coupleNames': coupleNames,
        'total': 0,
      },
      'guests': <dynamic>[],
      'tables': <dynamic>[],
      'tasks': <dynamic>[],
      'vendors': <dynamic>[],
      'scheduleEvents': <dynamic>[],
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Rozdziela „Imię1 i Imię2" na dwie osoby budżetu. Bez separatora — druga
  /// osoba pozostaje pusta (uzupełni się w Ustawieniach).
  List<String> _splitPersons(String persons) {
    final p = persons.trim();
    if (p.isEmpty) return ['Osoba 1', 'Osoba 2'];
    final parts = p.split(RegExp(r'\s+i\s+', caseSensitive: false));
    final a = parts.isNotEmpty ? parts[0].trim() : '';
    final b = parts.length > 1 ? parts[1].trim() : '';
    return [
      a.isEmpty ? 'Osoba 1' : a,
      b.isEmpty ? 'Osoba 2' : b,
    ];
  }

  // ── Kod dołączenia ───────────────────────────────────────────────────────

  /// Alfabet kodu — bez znaków mylących (0/O, 1/I/L), same wielkie litery/cyfry.
  static const String _codeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  /// Generuje 6-znakowy kod dołączenia.
  String _generateCode() {
    final rnd = Random.secure();
    return List.generate(
      6,
      (_) => _codeAlphabet[rnd.nextInt(_codeAlphabet.length)],
    ).join();
  }

  /// Generuje kod i sprawdza, czy nie jest już zajęty (kilka prób).
  Future<String> _uniqueJoinCode() async {
    for (var i = 0; i < 6; i++) {
      final code = _generateCode();
      final taken =
          await _col.where('joinCode', isEqualTo: code).limit(1).get();
      if (taken.docs.isEmpty) return code;
    }
    // Skrajnie mało prawdopodobne — dokładamy przyrostek z czasu.
    return '${_generateCode()}${DateTime.now().millisecondsSinceEpoch % 100}';
  }

  /// Czy podane nazwisko/nazwa pasuje do danych Państwa Młodych (po normalizacji
  /// pojawia się w `displayNames` lub `eventName`).
  bool _surnameMatches(String input, String displayNames, String eventName) {
    final needle = _normalize(input);
    if (needle.length < 2) return false;
    final hay = '${_normalize(displayNames)} ${_normalize(eventName)}';
    return hay.contains(needle);
  }

  /// Normalizacja: małe litery, bez polskich znaków diakrytycznych, pojedyncze
  /// spacje. Pozwala na tolerancyjne porównanie nazwiska.
  String _normalize(String s) {
    var t = s.toLowerCase().trim();
    const map = {
      'ą': 'a', 'ć': 'c', 'ę': 'e', 'ł': 'l', 'ń': 'n',
      'ó': 'o', 'ś': 's', 'ż': 'z', 'ź': 'z',
    };
    map.forEach((k, v) => t = t.replaceAll(k, v));
    return t.replaceAll(RegExp(r'\s+'), ' ');
  }
}
