import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/guest.dart' show CompanionRelation;
import 'firestore_service.dart';

/// Dane z formularza dodawania/edycji gościa.
class GuestDraft {
  GuestDraft({
    required this.firstName,
    required this.lastName,
    required this.invitedBy,
    required this.category,
    required this.gender,
    required this.witness,
    required this.menuChoice,
    required this.hasCompanion,
    required this.companionFirstName,
    required this.companionLastName,
    required this.needsAccommodation,
    this.companionRelation,
    this.companionNamePending = false,
    this.companionCategory,
  });

  final String firstName;
  final String lastName;
  final String? invitedBy; // null | 'groom' | 'bride'
  final String category;
  final String gender; // 'K' | 'M' | 'N'
  final String? witness; // null | 'witness_groom' | 'witness_bride'
  final String menuChoice;
  final bool hasCompanion;
  final String companionFirstName;
  final String companionLastName;
  final bool needsAccommodation;

  /// Typ relacji osoby towarzyszącej — patrz [CompanionRelation].
  final String? companionRelation;

  /// Imię osoby towarzyszącej jeszcze nieznane („do potwierdzenia").
  final bool companionNamePending;

  /// Kategoria osoby towarzyszącej. `null` = dziedzicz po zapraszającym
  /// (z podpowiedzią wg typu relacji).
  final String? companionCategory;

  /// Czy osoba towarzysząca ma podane dane osobowe.
  bool get hasNamedCompanion =>
      hasCompanion &&
      (companionFirstName.isNotEmpty || companionLastName.isNotEmpty);
}

/// Operacje na gościach w dokumencie `weddingPlanner/main`.
///
/// Zapisy używają `set(..., merge: true)` na konkretnych polach, więc nie
/// nadpisują reszty dokumentu. Struktura gościa jest identyczna jak w wersji
/// webowej (`_newGuestBase()` + `addGuest()`), dzięki czemu oba systemy
/// współdzielą dane.
class GuestService {
  GuestService({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  final FirestoreService _firestore;

  /// Dodaje gościa (i opcjonalnie osobę towarzyszącą jako osobnego gościa).
  Future<void> addGuest(GuestDraft draft) async {
    final data = await _firestore.readData() ?? <String, dynamic>{};
    final guests = _mapList(data['guests']);
    var nextId = _nextGuestId(data, guests);

    final mainId = nextId++;
    final main = _baseGuest(mainId)
      ..addAll({
        'firstName': draft.firstName,
        'lastName': draft.lastName,
        'category': draft.category,
        'gender': draft.gender,
        'invitedBy': draft.invitedBy,
        'witness': draft.witness,
        // Osoba towarzysząca ma teraz ZAWSZE własny rekord, więc flaga „+1 bez
        // rekordu" zostaje wyłączona — inaczej catering policzyłby ją dwa razy.
        'hasCompanion': false,
        'needsAccommodation': draft.needsAccommodation,
        'menuChoice': draft.menuChoice,
      });
    guests.add(main);

    // Osoba towarzysząca → ZAWSZE osobny rekord, powiązany z zapraszającym.
    // Także wtedy, gdy imię nie jest jeszcze znane: dzięki temu ma miejsce przy
    // stole i liczy się do cateringu, a dane uzupełnia się później.
    if (draft.hasCompanion) {
      guests.add(buildCompanionRecord(
        id: nextId++,
        draft: draft,
        inviterId: mainId,
        inviterLastName: draft.lastName,
        inviterCategory: draft.category,
        inviterInvitedBy: draft.invitedBy,
      ));
    }

    await _firestore.mainDoc.set(
      {'guests': guests, 'nextGuestId': nextId},
      SetOptions(merge: true),
    );
  }

  /// Buduje rekord osoby towarzyszącej powiązanej z [inviterId].
  ///
  /// Gdy imię nie jest znane, wpis dostaje nazwę zastępczą z nazwiskiem
  /// zapraszającego („Osoba towarzysząca Kowalski") — czytelną na liście
  /// gości i na planie sali, a jednocześnie łatwą do odróżnienia od innych
  /// takich wpisów.
  /// Publiczna i CZYSTA (bez zapisu) — dzięki temu da się ją przetestować
  /// bez atrapy Firestore'a.
  static Map<String, dynamic> buildCompanionRecord({
    required int id,
    required GuestDraft draft,
    required int inviterId,
    required String inviterLastName,
    required String inviterCategory,
    required String? inviterInvitedBy,
  }) {
    final hasName = draft.companionFirstName.isNotEmpty ||
        draft.companionLastName.isNotEmpty;
    final pending = draft.companionNamePending || !hasName;

    // Kategoria: jawny wybór → podpowiedź z typu relacji → kategoria
    // zapraszającego. Osoba towarzysząca nigdy nie jest „Państwem Młodymi".
    final category = draft.companionCategory ??
        CompanionRelation.suggestedCategory(draft.companionRelation) ??
        (inviterCategory == 'Państwo Młodzi' ? 'Znajomi' : inviterCategory);

    return _baseGuest(id)
      ..addAll({
        'firstName': pending
            ? CompanionRelation.placeholderFirstName
            : draft.companionFirstName,
        'lastName': pending ? inviterLastName : draft.companionLastName,
        'category': category == 'Państwo Młodzi' ? 'Znajomi' : category,
        'invitedBy': inviterInvitedBy,
        'companionOfId': inviterId,
        'relationType': draft.companionRelation ?? CompanionRelation.unknown,
        'namePending': pending,
      });
  }

  /// Osoby towarzyszące powiązane z danym gościem.
  ///
  /// Używane przed usunięciem zapraszającego — UI pyta wtedy, co z nimi zrobić.
  static List<Map<String, dynamic>> companionsOf(
          List<Map<String, dynamic>> guests, int guestId) =>
      [
        for (final g in guests)
          if ((g['companionOfId'] as num?)?.toInt() == guestId) g,
      ];

  /// Osoby towarzyszące gościa — odczytane prosto z bazy.
  Future<List<Map<String, dynamic>>> loadCompanionsOf(int guestId) async {
    final data = await _firestore.readData() ?? <String, dynamic>{};
    return companionsOf(_mapList(data['guests']), guestId);
  }

  /// Tworzy rekord osoby towarzyszącej dla ISTNIEJĄCEGO gościa.
  ///
  /// Ścieżka dla starych danych: gość ma `hasCompanion: true` i ewentualnie
  /// `companionName`, ale nie ma powiązanego rekordu. Po utworzeniu rekordu
  /// flaga `hasCompanion` jest zerowana, żeby nie liczyć osoby dwa razy.
  ///
  /// ⚠️ Ta operacja PODNOSI liczbę gości o 1, a więc i szacowany koszt
  /// cateringu. To korekta wcześniejszego zaniżenia, nie błąd — UI musi o tym
  /// uprzedzić.
  Future<void> createCompanionFor(
    int guestId, {
    String firstName = '',
    String lastName = '',
    String? relation,
    String? category,
  }) async {
    final data = await _firestore.readData() ?? <String, dynamic>{};
    final guests = _mapList(data['guests']);
    final idx = guests.indexWhere((g) => _idOf(g) == guestId);
    if (idx == -1) return;
    // Nie dublujemy — jeśli powiązany rekord już istnieje, nic nie robimy.
    if (companionsOf(guests, guestId).isNotEmpty) return;

    final inviter = guests[idx];
    var nextId = _nextGuestId(data, guests);

    // Gdy nie podano imienia, korzystamy z zapisanego wcześniej `companionName`.
    final legacy = (inviter['companionName'] as String?)?.trim() ?? '';
    final parts = legacy.split(RegExp(r'\s+'));
    final fallbackFirst = parts.isNotEmpty ? parts.first : '';
    final fallbackLast = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    final draft = GuestDraft(
      firstName: '',
      lastName: '',
      invitedBy: inviter['invitedBy'] as String?,
      category: (inviter['category'] as String?) ?? '',
      gender: 'N',
      witness: null,
      menuChoice: '',
      hasCompanion: true,
      companionFirstName:
          firstName.isNotEmpty ? firstName : fallbackFirst,
      companionLastName: lastName.isNotEmpty ? lastName : fallbackLast,
      needsAccommodation: false,
      companionRelation: relation,
      companionCategory: category,
    );

    guests.add(buildCompanionRecord(
      id: nextId++,
      draft: draft,
      inviterId: guestId,
      inviterLastName: (inviter['lastName'] as String?) ?? '',
      inviterCategory: (inviter['category'] as String?) ?? '',
      inviterInvitedBy: inviter['invitedBy'] as String?,
    ));

    // Rekord istnieje ⇒ flaga „+1 bez rekordu" musi zgasnąć.
    guests[idx] = {...inviter, 'hasCompanion': false, 'companionName': ''};

    await _firestore.mainDoc.set(
      {'guests': guests, 'nextGuestId': nextId},
      SetOptions(merge: true),
    );
  }

  /// Aktualizuje istniejącego gościa, zachowując pozostałe pola.
  Future<void> updateGuest(int id, GuestDraft draft) async {
    final data = await _firestore.readData() ?? <String, dynamic>{};
    final guests = _mapList(data['guests']);
    final idx = guests.indexWhere((g) => _idOf(g) == id);
    if (idx == -1) return;

    final companionName =
        [draft.companionFirstName, draft.companionLastName]
            .where((s) => s.isNotEmpty)
            .join(' ');

    // Czy ten gość ma już POWIĄZANY rekord osoby towarzyszącej.
    final linked = companionsOf(guests, id).isNotEmpty;

    // Gdy edytujemy rekord osoby towarzyszącej „do potwierdzenia" i podano
    // prawdziwe imię — flaga gaśnie. Bez tego wpis zostawałby oznaczony jako
    // niepotwierdzony mimo uzupełnionych danych (#5).
    final isCompanionRecord = guests[idx]['companionOfId'] != null;
    final gotRealName = draft.firstName.isNotEmpty &&
        draft.firstName != CompanionRelation.placeholderFirstName;
    final namePending = isCompanionRecord && !gotRealName
        ? (guests[idx]['namePending'] == true)
        : false;

    guests[idx] = {
      ...guests[idx],
      if (isCompanionRecord) 'namePending': namePending,
      'firstName': draft.firstName,
      'lastName': draft.lastName,
      'category': draft.category,
      'gender': draft.gender,
      'invitedBy': draft.invitedBy,
      'witness': draft.witness,
      'menuChoice': draft.menuChoice,
      'needsAccommodation': draft.needsAccommodation,
      // Gdy istnieje powiązany rekord, flaga „+1 bez rekordu" musi zostać
      // wyłączona — inaczej catering policzyłby tę samą osobę dwa razy.
      // Pola `companionOfId` / `relationType` / `namePending` NIE są tu ruszane:
      // należą do rekordu towarzyszącej, nie do zapraszającego.
      'hasCompanion': linked ? false : draft.hasCompanion,
      'companionName':
          linked ? '' : (draft.hasCompanion ? companionName : ''),
    };

    await _firestore.mainDoc.set({'guests': guests}, SetOptions(merge: true));
  }

  /// Szybka edycja pojedynczego pola gościa (Kartoteka: menuChoice,
  /// preferences, allergies, cardNotes).
  Future<void> setField(int id, String field, dynamic value) async {
    final data = await _firestore.readData() ?? <String, dynamic>{};
    final guests = _mapList(data['guests']);
    final idx = guests.indexWhere((g) => _idOf(g) == id);
    if (idx == -1) return;
    guests[idx] = {...guests[idx], field: value};
    await _firestore.mainDoc.set({'guests': guests}, SetOptions(merge: true));
  }

  /// Usuwa gościa wraz z czyszczeniem powiązań (jak `removeGuest` w wersji web):
  /// zwalnia miejsce przy stole, rozłącza parę oraz usuwa odwołania w pojazdach,
  /// prezentach i potwierdzeniach RSVP.
  /// Usuwa gościa.
  ///
  /// [alsoCompanions] decyduje o losie powiązanych osób towarzyszących:
  ///  • `true`  — usuwane razem z zapraszającym,
  ///  • `false` — zostają jako goście samodzielni (powiązanie jest zrywane).
  ///
  /// Ciche kasowanie dwóch osób jednym kliknięciem byłoby niebezpieczne,
  /// dlatego domyślnie osoba towarzysząca PRZEŻYWA, a UI ma o to zapytać.
  Future<void> deleteGuest(int id, {bool alsoCompanions = false}) async {
    final data = await _firestore.readData() ?? <String, dynamic>{};
    final guests = _mapList(data['guests']);
    final guest = guests.where((g) => _idOf(g) == id).firstOrNull;
    if (guest == null) return;

    final payload = <String, dynamic>{};

    // 0) Osoby towarzyszące: albo usuwamy razem, albo usamodzielniamy.
    final companionIds = <int>[
      for (final c in companionsOf(guests, id))
        if (_idOf(c) != null) _idOf(c)!,
    ];
    if (!alsoCompanions) {
      for (final g in guests) {
        if ((g['companionOfId'] as num?)?.toInt() == id) {
          g['companionOfId'] = null;
          g['relationType'] = null;
        }
      }
    }

    // 1) Zwolnij miejsce przy stole.
    final tableId = (guest['tableId'] as num?)?.toInt();
    final seatIndex = (guest['seatIndex'] as num?)?.toInt();
    if (tableId != null) {
      final tables = _mapList(data['tables']);
      final table = tables.where((t) => _idOf(t) == tableId).firstOrNull;
      if (table != null && seatIndex != null) {
        final seats = List<dynamic>.from(table['seatsData'] as List? ?? const []);
        if (seatIndex >= 0 && seatIndex < seats.length) {
          seats[seatIndex] = null;
          table['seatsData'] = seats;
        }
      }
      payload['tables'] = tables;
    }

    // 2) Rozłącz parę.
    final pairId = (guest['pairId'] as num?)?.toInt();
    if (pairId != null) {
      final pairs = _mapList(data['pairs']);
      final pair = pairs.where((p) => _idOf(p) == pairId).firstOrNull;
      if (pair != null) {
        for (final member in [pair['g1'], pair['g2']]) {
          final memberId = (member as num?)?.toInt();
          final partner =
              guests.where((g) => _idOf(g) == memberId).firstOrNull;
          if (partner != null) partner['pairId'] = null;
        }
      }
      pairs.removeWhere((p) => _idOf(p) == pairId);
      payload['pairs'] = pairs;
    }

    // 3) Usuń odwołania w pojazdach i prezentach.
    if (data['vehicles'] is List) {
      final vehicles = _mapList(data['vehicles']);
      for (final v in vehicles) {
        if (v['guestIds'] is List) {
          v['guestIds'] =
              (v['guestIds'] as List).where((gid) => _toInt(gid) != id).toList();
        }
      }
      payload['vehicles'] = vehicles;
    }
    if (data['giftsForGuests'] is List) {
      final gifts = _mapList(data['giftsForGuests']);
      for (final item in gifts) {
        if (item['guestIds'] is List) {
          item['guestIds'] = (item['guestIds'] as List)
              .where((gid) => _toInt(gid) != id)
              .toList();
        }
      }
      payload['giftsForGuests'] = gifts;
    }

    // 4) Usuń potwierdzenia RSVP gościa.
    if (data['rsvpEntries'] is List) {
      final rsvp = _mapList(data['rsvpEntries']);
      rsvp.removeWhere((e) => (e['guestId'] as num?)?.toInt() == id);
      payload['rsvpEntries'] = rsvp;
    }

    // 5) Usuń samego gościa.
    guests.removeWhere((g) => _idOf(g) == id);
    payload['guests'] = guests;

    await _firestore.mainDoc.set(payload, SetOptions(merge: true));

    // 6) Osoby towarzyszące usuwamy tą samą ścieżką — dzięki temu też im
    // zwalniamy miejsce przy stole i czyścimy RSVP oraz prezenty, zamiast
    // powielać tu całą logikę sprzątania.
    if (alsoCompanions) {
      for (final companionId in companionIds) {
        await deleteGuest(companionId);
      }
    }
  }

  // ── Pomocnicze ─────────────────────────────────────────────────────────

  /// Domyślny szablon gościa — odpowiednik `_newGuestBase()` + stałe pola.
  static Map<String, dynamic> _baseGuest(int id) => {
        'id': id,
        'firstName': '',
        'lastName': '',
        'category': 'Rodzina',
        'gender': 'K',
        'photo': null,
        'invitedBy': null,
        'witness': null,
        'diet': 'standard',
        'dietOther': '',
        'hasCompanion': false,
        'companionName': '',
        'needsAccommodation': false,
        'vehicleId': null,
        'ownTransport': false,
        'hotelId': null,
        'accommodationStatus': null,
        'tableId': null,
        'seatIndex': null,
        'pairId': null,
        'menuChoice': '',
        'preferences': '',
        'allergies': '',
        'cardNotes': '',
      };

  int _nextGuestId(Map<String, dynamic> data, List<Map<String, dynamic>> guests) {
    final stored = (data['nextGuestId'] as num?)?.toInt() ?? 1;
    var maxId = 0;
    for (final g in guests) {
      final i = _idOf(g) ?? 0;
      if (i > maxId) maxId = i;
    }
    return max(stored, maxId + 1);
  }

  List<Map<String, dynamic>> _mapList(dynamic value) => value is List
      ? value.map((e) => Map<String, dynamic>.from(e as Map)).toList()
      : <Map<String, dynamic>>[];

  int? _idOf(Map<String, dynamic> m) => (m['id'] as num?)?.toInt();
  int? _toInt(dynamic v) => (v as num?)?.toInt();
}
