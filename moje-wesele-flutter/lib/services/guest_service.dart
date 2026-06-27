import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

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

  /// Czy osoba towarzysząca ma podane dane (→ zostaje osobnym gościem).
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

    final named = draft.hasNamedCompanion;

    final main = _baseGuest(nextId++)
      ..addAll({
        'firstName': draft.firstName,
        'lastName': draft.lastName,
        'category': draft.category,
        'gender': draft.gender,
        'invitedBy': draft.invitedBy,
        'witness': draft.witness,
        'hasCompanion': draft.hasCompanion && !named,
        'needsAccommodation': draft.needsAccommodation,
        'menuChoice': draft.menuChoice,
      });
    guests.add(main);

    // Osoba towarzysząca z danymi → osobny gość (jak w addGuest w wersji web).
    if (named) {
      final companion = _baseGuest(nextId++)
        ..addAll({
          'firstName': draft.companionFirstName,
          'lastName': draft.companionLastName,
          // towarzysząca nie może być Parą Młodą
          'category':
              draft.category == 'Państwo Młodzi' ? 'Znajomi' : draft.category,
          'gender': 'K',
          'invitedBy': draft.invitedBy,
        });
      guests.add(companion);
    }

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

    guests[idx] = {
      ...guests[idx],
      'firstName': draft.firstName,
      'lastName': draft.lastName,
      'category': draft.category,
      'gender': draft.gender,
      'invitedBy': draft.invitedBy,
      'witness': draft.witness,
      'menuChoice': draft.menuChoice,
      'needsAccommodation': draft.needsAccommodation,
      'hasCompanion': draft.hasCompanion,
      'companionName': draft.hasCompanion ? companionName : '',
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
  Future<void> deleteGuest(int id) async {
    final data = await _firestore.readData() ?? <String, dynamic>{};
    final guests = _mapList(data['guests']);
    final guest = guests.where((g) => _idOf(g) == id).firstOrNull;
    if (guest == null) return;

    final payload = <String, dynamic>{};

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
  }

  // ── Pomocnicze ─────────────────────────────────────────────────────────

  /// Domyślny szablon gościa — odpowiednik `_newGuestBase()` + stałe pola.
  Map<String, dynamic> _baseGuest(int id) => {
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
