import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/wedding_summary.dart';
import 'membership_service.dart';

/// Zarządzanie weselami (kolekcja `weddings`) i ich powiązaniem z użytkownikiem.
///
/// Odpowiada za:
///   • utworzenie nowego wesela (auto-ID + domyślna konfiguracja + członkostwo
///     `owner` dla twórcy),
///   • listę wesel dostępnych użytkownikowi (przez jego członkostwa).
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

    await ref.set(_defaultWeddingData(
      ownerId: userId,
      name: name,
      persons: persons,
      date: date,
    ));

    await _memberships.create(
      userId: userId,
      weddingId: weddingId,
      role: 'owner',
    );

    return weddingId;
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
    String? date,
  }) {
    final coupleNames = _splitPersons(persons);
    return {
      'ownerId': ownerId,
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
}
