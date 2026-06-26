import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_service.dart';

/// Dane hotelu z formularza.
class HotelDraft {
  HotelDraft({
    required this.name,
    required this.address,
    required this.phone,
    required this.pricePerNight,
    required this.personsPerRoom,
    required this.bookingLink,
    required this.notes,
    required this.inComplex,
  });

  final String name;
  final String address;
  final String phone;
  final num pricePerNight;
  final int personsPerRoom;
  final String bookingLink;
  final String notes;
  final bool inComplex;

  Map<String, dynamic> toFields() => {
        'name': name,
        'address': address,
        'phone': phone,
        'pricePerNight': pricePerNight,
        'personsPerRoom': personsPerRoom,
        'bookingLink': bookingLink,
        'notes': notes,
        'inComplex': inComplex,
      };
}

/// Operacje na noclegach (`hotels`) i przypisaniach gości
/// (`guest.hotelId`, `guest.accommodationStatus`).
class AccommodationService {
  AccommodationService({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  final FirestoreService _firestore;

  Future<void> addHotel(HotelDraft draft) async {
    final data = await _read();
    final hotels = _mapList(data['hotels']);
    final nextId = _nextId(data['nextHotelId'], hotels);
    hotels.add({'id': nextId, ...draft.toFields()});
    await _firestore.mainDoc.set(
      {'hotels': hotels, 'nextHotelId': nextId + 1},
      SetOptions(merge: true),
    );
  }

  Future<void> updateHotel(int id, HotelDraft draft) async {
    final data = await _read();
    final hotels = _mapList(data['hotels']);
    final h = _find(hotels, id);
    if (h == null) return;
    h.addAll(draft.toFields());
    await _firestore.mainDoc.set({'hotels': hotels}, SetOptions(merge: true));
  }

  Future<void> deleteHotel(int id) async {
    final data = await _read();
    final hotels = _mapList(data['hotels']);
    final guests = _mapList(data['guests']);
    hotels.removeWhere((h) => _idOf(h) == id);
    for (final g in guests) {
      if ((g['hotelId'] as num?)?.toInt() == id) {
        g['hotelId'] = null;
        g['accommodationStatus'] = null;
      }
    }
    await _firestore.mainDoc
        .set({'hotels': hotels, 'guests': guests}, SetOptions(merge: true));
  }

  /// Aktualizuje przypisanie noclegu gościa.
  Future<void> updateGuestAccommodation(int guestId,
      {int? hotelId, bool clearHotel = false, String? status}) async {
    final data = await _read();
    final guests = _mapList(data['guests']);
    final g = _find(guests, guestId);
    if (g == null) return;
    if (clearHotel) {
      g['hotelId'] = null;
    } else if (hotelId != null) {
      g['hotelId'] = hotelId;
    }
    if (status != null) {
      g['accommodationStatus'] = status.isEmpty ? null : status;
    }
    await _firestore.mainDoc.set({'guests': guests}, SetOptions(merge: true));
  }

  // ── Pomocnicze ──
  Future<Map<String, dynamic>> _read() async =>
      await _firestore.readData() ?? <String, dynamic>{};

  List<Map<String, dynamic>> _mapList(dynamic value) => value is List
      ? value.map((e) => Map<String, dynamic>.from(e as Map)).toList()
      : <Map<String, dynamic>>[];

  int _nextId(dynamic stored, List<Map<String, dynamic>> list) {
    final s = (stored as num?)?.toInt() ?? 1;
    var maxId = 0;
    for (final m in list) {
      final i = _idOf(m) ?? 0;
      if (i > maxId) maxId = i;
    }
    return max(s, maxId + 1);
  }

  Map<String, dynamic>? _find(List<Map<String, dynamic>> list, int id) {
    for (final m in list) {
      if (_idOf(m) == id) return m;
    }
    return null;
  }

  int? _idOf(Map<String, dynamic> m) => (m['id'] as num?)?.toInt();
}
