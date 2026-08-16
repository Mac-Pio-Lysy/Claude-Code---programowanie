import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/invite_identity.dart';
import '../models/join_code.dart';
import 'guest_identity.dart';
import 'guest_space_service.dart';
import 'invite_code_service.dart';

/// Obsługa wejścia gościa kodem paczki (`?i=KOD`).
///
/// Trzy zadania: odczytać publiczny dokument kodu, zapamiętać wybór gościa
/// lokalnie i zgłosić tożsamość do `guestSpaces/{token}/identities`.
class InviteIdentityService {
  InviteIdentityService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Podkolekcja tożsamości przy strefie gości.
  static const String collectionName = 'identities';

  /// Czyta publiczny dokument kodu paczki.
  ///
  /// Zwraca `null`, gdy kodu nie ma — wtedy gość dostaje komunikat
  /// o nieprawidłowym zaproszeniu. Kod unieważniony ZWRACAMY normalnie,
  /// ze znacznikiem [InviteCodeDoc.revoked], żeby dało się pokazać
  /// zrozumiały powód zamiast „nieprawidłowy link".
  Future<InviteCodeDoc?> load(String rawCode) async {
    final code = JoinCode.normalize(rawCode);
    if (code.isEmpty) return null;
    final snap =
        await _db.collection(InviteCodeService.collectionName).doc(code).get();
    if (!snap.exists) return null;
    return InviteCodeDoc.fromMap(code, snap.data());
  }

  /// Zapisuje tożsamość gościa w strefie wesela.
  ///
  /// Zapis jest „best effort": gdy się nie uda (brak sieci, reguły jeszcze
  /// niewdrożone), gość i tak wchodzi do strefy z zapamiętanym lokalnie
  /// imieniem. Utrata tego zapisu oznacza tylko tyle, że organizator nie
  /// powiąże wpisów z osobą — a to gorsze niż zablokowanie gościa w dniu
  /// wesela nie jest.
  Future<bool> claim(InviteCodeDoc doc, PackageIdentity identity) async {
    try {
      final uid = await GuestIdentity.ensure();
      await _db
          .collection(GuestSpaceService.collectionName)
          .doc(doc.guestToken)
          .collection(collectionName)
          .doc(identity.docId(uid))
          .set({
        ...identity.toMap(uid),
        'claimedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Pamięć lokalna (przeglądarka gościa) ────────────────────────────────

  /// Zapamiętany wybór dla tego kodu — kolejne wejście pomija ekran wyboru.
  Future<PackageIdentity?> loadLocal(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(PackageIdentity.localKey(code));
    if (raw == null || raw.isEmpty) return null;
    try {
      return PackageIdentity.fromLocal(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLocal(PackageIdentity identity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      PackageIdentity.localKey(identity.code),
      jsonEncode(identity.toLocal()),
    );
  }

  /// Kasuje zapamiętany wybór — „to nie ja" w menu gościa.
  Future<void> clearLocal(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(PackageIdentity.localKey(code));
  }
}
