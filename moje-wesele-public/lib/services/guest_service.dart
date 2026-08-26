import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/couple.dart';
import '../models/guest.dart' show CompanionRelation;
import 'firestore_service.dart';
import '../l10n/app_text.dart';

/// Błąd reguły biznesowej listy gości — komunikat jest gotowy do pokazania
/// użytkownikowi (UI wyświetla go w SnackBarze).
class GuestRuleException implements Exception {
  const GuestRuleException(this.message);

  final String message;

  @override
  String toString() => message;
}

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
    this.isChild = false,
    this.companionIsChild = false,
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

  /// Czy gość jest dzieckiem (#6).
  final bool isChild;

  /// Czy osoba towarzysząca jest dzieckiem — częsty przypadek: gość przychodzi
  /// z własnym dzieckiem.
  final bool companionIsChild;

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
  ///
  /// Rzuca [GuestRuleException], gdy wpis łamie reguły Pary Młodej.
  Future<void> addGuest(GuestDraft draft) async {
    final data = await _firestore.readData() ?? <String, dynamic>{};
    final guests = _mapList(data['guests']);
    var nextId = _nextGuestId(data, guests);

    checkCoupleRules(
      guests,
      category: draft.category,
      hasCompanion: draft.hasCompanion,
    );

    // Ustawienie z sekcji Transport: nowo dodani goście dostają od razu
    // transport własny. Czytane z TEGO SAMEGO odczytu — zero dodatkowego
    // zapytania. Dotyczy WYŁĄCZNIE tworzenia — `updateGuest` tego nie rusza,
    // więc nie nadpisuje transportu ustawionego już ręcznie przy edycji.
    final autoOwnTransport = data['transportAutoOwn'] == true;

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
        'isChild': draft.isChild,
        if (autoOwnTransport) 'ownTransport': true,
      });
    guests.add(main);

    // Osoba towarzysząca → ZAWSZE osobny rekord, powiązany z zapraszającym.
    // Także wtedy, gdy imię nie jest jeszcze znane: dzięki temu ma miejsce przy
    // stole i liczy się do cateringu, a dane uzupełnia się później.
    if (draft.hasCompanion) {
      final companion = buildCompanionRecord(
        id: nextId++,
        draft: draft,
        inviterId: mainId,
        inviterLastName: draft.lastName,
        inviterCategory: draft.category,
        inviterInvitedBy: draft.invitedBy,
      );
      if (autoOwnTransport) companion['ownTransport'] = true;
      guests.add(companion);
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
        (inviterCategory == CoupleLabels.coupleCategoryValue
            ? 'Znajomi'
            : inviterCategory);

    return _baseGuest(id)
      ..addAll({
        'firstName': pending
            ? CompanionRelation.placeholderFirstName
            : draft.companionFirstName,
        'lastName': pending ? inviterLastName : draft.companionLastName,
        'category':
            category == CoupleLabels.coupleCategoryValue ? 'Znajomi' : category,
        'invitedBy': inviterInvitedBy,
        'companionOfId': inviterId,
        'relationType': draft.companionRelation ?? CompanionRelation.unknown,
        'namePending': pending,
        'isChild': draft.companionIsChild,
      });
  }

  // ── Para Młoda ────────────────────────────────────────────────────────────

  /// Ilu gości ma kategorię Pary Młodej. [exceptId] pomija jeden rekord —
  /// przy edycji gość nie może blokować sam siebie.
  static int coupleCount(List<Map<String, dynamic>> guests, {int? exceptId}) =>
      guests
          .where((g) =>
              g['category'] == CoupleLabels.coupleCategoryValue &&
              (exceptId == null || (g['id'] as num?)?.toInt() != exceptId))
          .length;

  /// Sprawdza reguły Pary Młodej przed zapisem. Rzuca [GuestRuleException]
  /// z gotowym komunikatem.
  ///
  /// Dwie reguły, obie wynikające ze zgłoszeń:
  ///  • najwyżej dwie osoby w tej kategorii (#13),
  ///  • Para Młoda nie ma osoby towarzyszącej — jest nią dla siebie (#12).
  ///
  /// Walidacja siedzi w serwisie, a nie tylko w UI, bo przez `updateGuest`
  /// można zmienić kategorię istniejącego gościa z pominięciem formularza
  /// dodawania.
  static void checkCoupleRules(
    List<Map<String, dynamic>> guests, {
    required String category,
    required bool hasCompanion,
    int? exceptId,
  }) {
    if (category != CoupleLabels.coupleCategoryValue) return;

    if (coupleCount(guests, exceptId: exceptId) >= CoupleLabels.maxCouple) {
      throw GuestRuleException(
        AppText.t.guestSvc_coupleLimit(CoupleLabels.current.coupleCategoryLabel, CoupleLabels.maxCouple),
      );
    }
    if (hasCompanion) {
      throw GuestRuleException(
        AppText.t.guestSvc_coupleNoCompanion,
      );
    }
  }

  /// Rekordy Pary Młodej zakładane razem z weselem (zgłoszenie #9).
  ///
  /// Puste imię = brak rekordu, więc wesele bez podanych imion powstaje
  /// dokładnie jak dotąd. Wpis „Ania Kowalska" rozdzielamy na imię i nazwisko
  /// po pierwszej spacji — samo „Ania" zostawia nazwisko puste.
  ///
  /// CZYSTA (bez zapisu), żeby dało się ją przetestować bez atrapy Firestore'a.
  static List<Map<String, dynamic>> buildCoupleRecords({
    required int startId,
    required CoupleType type,
    required String person1,
    required String person2,
  }) {
    final records = <Map<String, dynamic>>[];
    var id = startId;

    for (final (index, raw) in [person1, person2].indexed) {
      final name = raw.trim();
      if (name.isEmpty) continue;

      final space = name.indexOf(' ');
      final first = space == -1 ? name : name.substring(0, space).trim();
      final last = space == -1 ? '' : name.substring(space + 1).trim();

      records.add(_baseGuest(id++)
        ..addAll({
          'firstName': first,
          'lastName': last,
          'category': CoupleLabels.coupleCategoryValue,
          'gender': type.genderFor(index + 1),
          // Para Młoda nikogo nie „zaprasza" — to gospodarze wesela.
          'invitedBy': null,
          'witness': null,
          'hasCompanion': false,
        }));
    }
    return records;
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
    // Ta sama reguła co przy dodawaniu: Para Młoda nie dostaje towarzyszącej,
    // nawet ścieżką naprawy starych danych (#12).
    checkCoupleRules(
      guests,
      category: (inviter['category'] as String?) ?? '',
      hasCompanion: true,
      exceptId: guestId,
    );
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

  /// Tworzy osobę towarzyszącą [inviterId] i zwraca jej nowe `id`.
  ///
  /// Wariant [createCompanionFor] do użycia tam, gdzie wołający MUSI od razu
  /// znać nowe `id` (np. żeby powiązać je z tożsamością z paczki, etap 5) —
  /// [createCompanionFor] tego nie zwraca i dodatkowo pomija zapis, gdy
  /// zapraszający ma już powiązaną osobę towarzyszącą (naprawa starych
  /// danych), co tutaj byłoby błędne: „do przypisania" może dokładać KOLEJNE
  /// osoby do tej samej paczki.
  Future<int> createCompanionWithId(
    int inviterId, {
    required String firstName,
    required String lastName,
  }) async {
    final data = await _firestore.readData() ?? <String, dynamic>{};
    final guests = _mapList(data['guests']);
    final idx = guests.indexWhere((g) => _idOf(g) == inviterId);
    if (idx == -1) {
      throw GuestRuleException(AppText.t.unassigned_inviterMissing);
    }
    final inviter = guests[idx];

    checkCoupleRules(
      guests,
      category: (inviter['category'] as String?) ?? '',
      hasCompanion: true,
      exceptId: inviterId,
    );

    var nextId = _nextGuestId(data, guests);
    final newId = nextId++;

    final draft = GuestDraft(
      firstName: '',
      lastName: '',
      invitedBy: inviter['invitedBy'] as String?,
      category: (inviter['category'] as String?) ?? '',
      gender: 'N',
      witness: null,
      menuChoice: '',
      hasCompanion: true,
      companionFirstName: firstName,
      companionLastName: lastName,
      needsAccommodation: false,
    );

    guests.add(buildCompanionRecord(
      id: newId,
      draft: draft,
      inviterId: inviterId,
      inviterLastName: (inviter['lastName'] as String?) ?? '',
      inviterCategory: (inviter['category'] as String?) ?? '',
      inviterInvitedBy: inviter['invitedBy'] as String?,
    ));

    await _firestore.mainDoc.set(
      {'guests': guests, 'nextGuestId': nextId},
      SetOptions(merge: true),
    );
    return newId;
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

    // Reguły Pary Młodej obowiązują też przy edycji — kategorię można tu
    // zmienić z pominięciem formularza dodawania. Istniejący rekord osoby
    // towarzyszącej liczy się tak samo jak zaznaczony „+1".
    checkCoupleRules(
      guests,
      category: draft.category,
      hasCompanion: draft.hasCompanion || linked,
      exceptId: id,
    );

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
      'isChild': draft.isChild,
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

  /// Trwałe usunięcie oznaczeń „dziecko" ze WSZYSTKICH gości oraz wyzerowanie
  /// pól budżetowych dzieci (`childrenCount`, `childMenuSeparate`,
  /// `childMenuPricePerPerson`). NIEODWRACALNE — wołane wyłącznie po wyraźnym
  /// potwierdzeniu w UI (Ustawienia → Wesele).
  ///
  /// Samo wyłączenie „wesele z dziećmi" (`BudgetService.setWithChildren`)
  /// NIE kasuje danych — tylko przestaje je liczyć do budżetu. Ta metoda jest
  /// jedynym miejscem faktycznego, trwałego usunięcia.
  Future<void> clearChildrenData() async {
    final data = await _firestore.readData() ?? <String, dynamic>{};
    final guests = _mapList(data['guests']);
    for (var i = 0; i < guests.length; i++) {
      if (guests[i]['isChild'] == true) {
        guests[i] = {...guests[i], 'isChild': false};
      }
    }
    await _firestore.mainDoc.set({
      'guests': guests,
      'budgetData': {
        'childrenCount': 0,
        'childMenuSeparate': false,
        'childMenuPricePerPerson': 0,
      },
    }, SetOptions(merge: true));
  }

  /// Czyści całą listę gości oraz WSZYSTKIE odwołania do nich w innych
  /// strukturach dokumentu (Ustawienia → Pomoc i zaawansowane → Strefa
  /// zagrożenia, „Wyczyść gości i powiązania"). NIEODWRACALNE — wołane
  /// wyłącznie po dwustopniowym potwierdzeniu w UI.
  ///
  /// Zachowuje same OBIEKTY (stoły, pojazdy, hotele, pozycje prezentów) —
  /// czyści tylko odwołania do ID gościa (`seatsData`/`guestIds`) w nich.
  /// Budżet NIE jest ruszany — `GuestBasis` przeliczy efektywną liczbę gości
  /// z `plannedGuests`/`venueMinGuests`, tak jak przy braku wpisanych gości.
  ///
  /// Mirror gości (`guestSpaces` i podkolekcje: RSVP, księga gości, zdjęcia,
  /// głosy) NIE jest ruszany — będzie osobną operacją.
  ///
  /// ⚠️ UWAGA NA PRZYSZŁOŚĆ: każde nowe pole odwołujące się do ID gościa
  /// (`guestId`/`guestIds`) trzeba dopisać tutaj — tak jak przy
  /// `deleteGuest()`, z którym ta metoda dzieli listę odwołań.
  Future<void> clearAllGuests() async {
    final data = await _firestore.readData() ?? <String, dynamic>{};

    final tables = _mapList(data['tables']);
    for (final t in tables) {
      final seats = t['seatsData'];
      if (seats is List) {
        t['seatsData'] = List<dynamic>.filled(seats.length, null);
      }
    }

    final vehicles = _mapList(data['vehicles']);
    for (final v in vehicles) {
      if (v['guestIds'] is List) v['guestIds'] = <dynamic>[];
    }

    final gifts = _mapList(data['giftsForGuests']);
    for (final g in gifts) {
      if (g['guestIds'] is List) g['guestIds'] = <dynamic>[];
    }

    await _firestore.mainDoc.set({
      'guests': <dynamic>[],
      'tables': tables,
      'vehicles': vehicles,
      'giftsForGuests': gifts,
      'pairs': <dynamic>[],
      'rsvpEntries': <dynamic>[],
      'nextGuestId': 1,
    }, SetOptions(merge: true));
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
        'isChild': false,
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
