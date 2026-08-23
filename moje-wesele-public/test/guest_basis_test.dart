// Weryfikuje `GuestBasis` — jedyne miejsce liczące efektywną liczbę gości
// dla całego budżetu (catering, obsługa, sala, napoje, prezenty).

import 'package:flutter_test/flutter_test.dart';
import 'package:moje_wesele/models/guest_basis.dart';
import 'package:moje_wesele/models/wedding_data.dart';

void main() {
  test('brak danych (null) → wszystko zero', () {
    final b = GuestBasis.from(null);
    expect(b.invited, 0);
    expect(b.assigned, 0);
    expect(b.unassigned, 0);
    expect(b.venueMinGuests, 0);
    expect(b.plannedGuests, 0);
    expect(b.effective, 0);
    expect(b.paddingOverInvited, 0);
  });

  test('zaproszeni górują nad minimum i planowanymi → effective = zaproszeni', () {
    final data = WeddingData.fromMap({
      'guests': [
        {'id': 1, 'tableId': 1},
        {'id': 2, 'tableId': 1},
        {'id': 3, 'tableId': null},
      ],
      'budgetData': {'venueMinGuests': 2, 'plannedGuests': 2},
    });
    final b = GuestBasis.from(data);
    expect(b.invited, 3);
    expect(b.assigned, 2);
    expect(b.unassigned, 1);
    expect(b.effective, 3);
    expect(b.paddingOverInvited, 0);
  });

  test('minimum sali góruje nad zaproszonymi i planowanymi → effective = minimum', () {
    final data = WeddingData.fromMap({
      'guests': [
        {'id': 1, 'tableId': 1},
      ],
      'budgetData': {'venueMinGuests': 80, 'plannedGuests': 10},
    });
    final b = GuestBasis.from(data);
    expect(b.invited, 1);
    expect(b.effective, 80);
    expect(b.paddingOverInvited, 79);
  });

  test('osoby planowane górują (wczesny etap, lista gości jeszcze pusta)', () {
    final data = WeddingData.fromMap({
      'guests': const [],
      'budgetData': {'venueMinGuests': 40, 'plannedGuests': 120},
    });
    final b = GuestBasis.from(data);
    expect(b.invited, 0);
    expect(b.effective, 120);
    expect(b.paddingOverInvited, 120);
  });

  test('wszystko zero → effective = 0, bez wyjątków', () {
    final data = WeddingData.fromMap({
      'guests': const [],
      'budgetData': <String, dynamic>{},
    });
    final b = GuestBasis.from(data);
    expect(b.invited, 0);
    expect(b.venueMinGuests, 0);
    expect(b.plannedGuests, 0);
    expect(b.effective, 0);
  });

  test('nieprzypisani do stołów NIE dublują się w effective (dawny bug)', () {
    // 100 zaproszonych, z czego 8 bez stołu — nieprzypisani są PODZBIOREM
    // zaproszonych, więc effective ma zostać równe 100, nie 108.
    final guests = [
      for (var i = 0; i < 92; i++) {'id': i, 'tableId': 1},
      for (var i = 92; i < 100; i++) {'id': i, 'tableId': null},
    ];
    final data = WeddingData.fromMap({
      'guests': guests,
      'budgetData': {'venueMinGuests': 80, 'plannedGuests': 0},
    });
    final b = GuestBasis.from(data);
    expect(b.invited, 100);
    expect(b.assigned, 92);
    expect(b.unassigned, 8);
    expect(b.effective, 100);
  });

  test('brak pola plannedGuests u starych wesel → traktowane jak 0, nie psuje MAX', () {
    final data = WeddingData.fromMap({
      'guests': [
        {'id': 1, 'tableId': 1},
      ],
      'budgetData': {'venueMinGuests': 50},
    });
    final b = GuestBasis.from(data);
    expect(b.plannedGuests, 0);
    expect(b.effective, 50);
  });
}
