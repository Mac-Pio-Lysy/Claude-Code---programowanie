import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_service.dart';

/// Operacje na prezentach: otrzymane (`gifts`), upominki dla gości
/// (`giftsForGuests`) oraz propozycje / lista życzeń (`giftProposals`).
class GiftService {
  GiftService({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  final FirestoreService _firestore;

  // ── PREZENTY OTRZYMANE ───────────────────────────────────────────────

  Future<void> addGift() async {
    final data = await _read();
    final list = _mapList(data['gifts']);
    final nextId = _nextId(data['nextGiftId'], list);
    list.add({
      'id': nextId,
      'from': '',
      'description': '',
      'value': null,
      'thanked': false,
    });
    await _firestore.mainDoc
        .set({'gifts': list, 'nextGiftId': nextId + 1}, SetOptions(merge: true));
  }

  Future<void> updateGift(int id,
      {String? from, String? description, num? value, bool? clearValue, bool? thanked}) async {
    final data = await _read();
    final list = _mapList(data['gifts']);
    final item = _find(list, id);
    if (item == null) return;
    if (from != null) item['from'] = from;
    if (description != null) item['description'] = description;
    if (clearValue == true) {
      item['value'] = null;
    } else if (value != null) {
      item['value'] = value;
    }
    if (thanked != null) item['thanked'] = thanked;
    await _firestore.mainDoc.set({'gifts': list}, SetOptions(merge: true));
  }

  Future<void> deleteGift(int id) async {
    final data = await _read();
    final list = _mapList(data['gifts'])..removeWhere((m) => _idOf(m) == id);
    await _firestore.mainDoc.set({'gifts': list}, SetOptions(merge: true));
  }

  // ── UPOMINKI DLA GOŚCI ───────────────────────────────────────────────

  Future<void> addGiftForGuest(String category) async {
    final data = await _read();
    final list = _mapList(data['giftsForGuests']);
    final nextId = _nextId(data['nextGiftForId'], list);
    list.add({
      'id': nextId,
      'category': category,
      'name': '',
      'qty': 1,
      'cost': 0,
      'guestIds': <dynamic>[],
    });
    await _firestore.mainDoc.set(
      {'giftsForGuests': list, 'nextGiftForId': nextId + 1},
      SetOptions(merge: true),
    );
  }

  Future<void> updateGiftForGuest(int id,
      {String? name, num? qty, num? cost}) async {
    final data = await _read();
    final list = _mapList(data['giftsForGuests']);
    final item = _find(list, id);
    if (item == null) return;
    if (name != null) item['name'] = name;
    if (qty != null) item['qty'] = qty;
    if (cost != null) item['cost'] = cost;
    await _firestore.mainDoc
        .set({'giftsForGuests': list}, SetOptions(merge: true));
  }

  Future<void> deleteGiftForGuest(int id) async {
    final data = await _read();
    final list = _mapList(data['giftsForGuests'])
      ..removeWhere((m) => _idOf(m) == id);
    await _firestore.mainDoc
        .set({'giftsForGuests': list}, SetOptions(merge: true));
  }

  Future<void> addDistinctionGuest(int id, int guestId) async {
    final data = await _read();
    final list = _mapList(data['giftsForGuests']);
    final item = _find(list, id);
    if (item == null) return;
    final ids = _intList(item['guestIds']);
    if (!ids.contains(guestId)) ids.add(guestId);
    item['guestIds'] = ids;
    await _firestore.mainDoc
        .set({'giftsForGuests': list}, SetOptions(merge: true));
  }

  Future<void> removeDistinctionGuest(int id, int guestId) async {
    final data = await _read();
    final list = _mapList(data['giftsForGuests']);
    final item = _find(list, id);
    if (item == null) return;
    item['guestIds'] = _intList(item['guestIds'])..remove(guestId);
    await _firestore.mainDoc
        .set({'giftsForGuests': list}, SetOptions(merge: true));
  }

  /// Ustawia podstawę przeliczania upominków (jak `setGiftForGuestsBasis`).
  Future<void> setGiftForGuestsBasis(String which, bool checked) async {
    final data = await _read();
    final current = (data['giftForGuestsBasis'] as String?) ?? '';
    final next = checked ? which : (current == which ? '' : current);
    await _firestore.mainDoc
        .set({'giftForGuestsBasis': next}, SetOptions(merge: true));
  }

  // ── PROPOZYCJE / LISTA ŻYCZEŃ ────────────────────────────────────────

  Future<void> addProposal() async {
    final data = await _read();
    final list = _mapList(data['giftProposals']);
    final nextId = _nextId(data['nextProposalId'], list);
    list.add({
      'id': nextId,
      'title': '',
      'desc': '',
      'link': '',
      'showToGuests': false,
    });
    await _firestore.mainDoc.set(
      {'giftProposals': list, 'nextProposalId': nextId + 1},
      SetOptions(merge: true),
    );
  }

  Future<void> updateProposal(int id,
      {String? title, String? desc, String? link, bool? showToGuests}) async {
    final data = await _read();
    final list = _mapList(data['giftProposals']);
    final item = _find(list, id);
    if (item == null) return;
    if (title != null) item['title'] = title;
    if (desc != null) item['desc'] = desc;
    if (link != null) item['link'] = link;
    if (showToGuests != null) item['showToGuests'] = showToGuests;
    await _firestore.mainDoc
        .set({'giftProposals': list}, SetOptions(merge: true));
  }

  Future<void> deleteProposal(int id) async {
    final data = await _read();
    final list = _mapList(data['giftProposals'])
      ..removeWhere((m) => _idOf(m) == id);
    await _firestore.mainDoc
        .set({'giftProposals': list}, SetOptions(merge: true));
  }

  // ── Pomocnicze ──
  Future<Map<String, dynamic>> _read() async =>
      await _firestore.readData() ?? <String, dynamic>{};

  List<Map<String, dynamic>> _mapList(dynamic value) => value is List
      ? value.map((e) => Map<String, dynamic>.from(e as Map)).toList()
      : <Map<String, dynamic>>[];

  List<int> _intList(dynamic value) => value is List
      ? value.map((e) => (e as num?)?.toInt()).whereType<int>().toList()
      : <int>[];

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
