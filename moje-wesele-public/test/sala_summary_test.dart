// Weryfikuje obliczenia podzakładki „Sala" — catering, obsługa, dekoracje —
// z JEDNĄ wspólną efektywną liczbą gości (`GuestBasis`, patrz
// guest_basis_test.dart), bez osobnych przełączników „licz nieprzypisanych"/
// „licz wirtualnych" (usunięte — dublowały ludzi już policzonych).

import 'package:flutter_test/flutter_test.dart';
import 'package:moje_wesele/models/children.dart';
import 'package:moje_wesele/models/sala_summary.dart';
import 'package:moje_wesele/models/wedding_data.dart';

void main() {
  test(
      'SalaSummary liczy catering przez efektywną liczbę gości (MAX), dodatki i dekoracje',
      () {
    final data = WeddingData.fromMap({
      'guests': [
        {'id': 1, 'tableId': 1},
        {'id': 2, 'tableId': 1},
        {'id': 3, 'tableId': null},
      ],
      'tables': [
        {'id': 1, 'isHonorTable': true},
        {'id': 2}, // zwykły
        {'id': 3}, // zwykły
      ],
      'budgetData': {
        'pricePerPerson': 200,
        'venueMinGuests': 5, // góruje nad 3 zaproszonymi → effective = 5
        'menuAddons': [
          {'id': 1, 'name': 'Tort', 'pricePerPerson': 10},
        ],
        'tableDeco': {
          'honorAddons': [
            {'id': 1, 'name': 'Kwiaty PM', 'price': 300},
          ],
          'regularAddons': [
            {'id': 2, 'name': 'Świece', 'pricePerTable': 50},
          ],
        },
      },
    });

    final s = SalaSummary.from(data);

    expect(s.guestCount, 3);
    expect(s.assignedCount, 2); // informacyjne
    expect(s.unassignedCount, 1); // informacyjne, zero wpływu na koszt
    expect(s.effectiveGuestCount, 5); // MAX(3 zaproszeni, 5 minimum, 0 planowani)
    expect(s.guestCost, 1000); // 200 * 5
    expect(s.virtualGuests, 2); // 5 - 3, WYŁĄCZNIE informacyjne
    expect(s.virtualCost, 400); // 2 * 200, informacyjne — NIE dolicza się osobno
    expect(s.addonsPersonCount, 5); // effective(5) + obsługa(0, brak wpisów)
    expect(s.menuAddonsTotal, 50); // 10 * 5
    expect(s.regularTableCount, 2); // 2 zwykłe stoły
    expect(s.honorDecoTotal, 300);
    expect(s.regularDecoTotal, 100); // 50 * 2
    expect(s.tableDecoTotal, 400);
    // catering = guestCost(1000) + staff(0) + dodatki(50) + honor(300) + regular(100)
    // BEZ osobnego +virtualCost — dopłata do minimum jest już wliczona w guestCost.
    expect(s.cateringTotal, 1450);
  });

  test('nieprzypisani do stołów NIE dublują się w koszcie (dawny bug)', () {
    // 100 zaproszonych (92 przypisanych + 8 bez stołu) i minimum sali 80 —
    // dawny mechanizm dawałby 108 (100 + 8 dodane ponownie na wierzch).
    final guests = [
      for (var i = 0; i < 92; i++) {'id': i, 'tableId': 1},
      for (var i = 92; i < 100; i++) {'id': i, 'tableId': null},
    ];
    final s = SalaSummary.from(WeddingData.fromMap({
      'guests': guests,
      'tables': [
        {'id': 1}
      ],
      'budgetData': {'pricePerPerson': 100, 'venueMinGuests': 80},
    }));

    expect(s.guestCount, 100);
    expect(s.assignedCount, 92);
    expect(s.unassignedCount, 8);
    expect(s.effectiveGuestCount, 100); // NIE 108
    expect(s.guestCost, 10000); // 100 * 100, nie 10800
  });

  test('osoby planowane górują, gdy zaproszonych jeszcze mało (wczesny etap)',
      () {
    final s = SalaSummary.from(WeddingData.fromMap({
      'guests': const [],
      'budgetData': {
        'pricePerPerson': 150,
        'venueMinGuests': 40,
        'plannedGuests': 120,
      },
    }));

    expect(s.effectiveGuestCount, 120);
    expect(s.guestCost, 18000); // 150 * 120
  });

  group('obsługa — tryby liczenia (StaffCalcMode)', () {
    Map<String, dynamic> weddingBase(Map<String, dynamic> extras) => {
          'guests': [
            {'id': 1, 'tableId': 1},
            {'id': 2, 'tableId': 1},
          ],
          'tables': [
            {'id': 1}
          ],
          'staffTables': [
            {'id': 1, 'persons': 3, 'includeInCost': true},
          ],
          'budgetData': {
            'pricePerPerson': 200,
            'includeStaffInCalc': true,
            ...extras,
          },
        };

    test('headcount (domyślny) — suma osób z listy × stawka', () {
      final s = SalaSummary.from(
          WeddingData.fromMap(weddingBase({'staffPricePerPerson': 50})));

      expect(s.staffCalcMode, StaffCalcMode.headcount);
      expect(s.staffPersonCount, 3);
      expect(s.staffCostPersonCount, 3);
      expect(s.staffCost, 150); // 3 * 50
    });

    test(
        'headcount z pustą stawką → fallback do ceny za gościa (zgodność wsteczna)',
        () {
      final s = SalaSummary.from(WeddingData.fromMap(weddingBase({})));

      expect(s.staffRate, 200); // fallback = pricePerPerson
      expect(s.staffCost, 600); // 3 * 200
    });

    test('perGuest — efektywna liczba gości × stawka, bez fallbacku', () {
      final s = SalaSummary.from(WeddingData.fromMap(weddingBase({
        'staffCalcMode': StaffCalcMode.perGuest,
        'staffPricePerPerson': 30,
        'venueMinGuests': 10,
      })));

      expect(s.effectiveGuestCount, 10); // MAX(2 zaproszeni, 10 minimum)
      expect(s.staffCost, 300); // 10 * 30
    });

    test('perGuest z pustą stawką → 0, BEZ fallbacku (tryb jawny)', () {
      final s = SalaSummary.from(WeddingData.fromMap(weddingBase({
        'staffCalcMode': StaffCalcMode.perGuest,
      })));

      expect(s.staffCost, 0);
    });

    test('manual — kwota wpisana wprost, zero mnożenia', () {
      final s = SalaSummary.from(WeddingData.fromMap(weddingBase({
        'staffCalcMode': StaffCalcMode.manual,
        'staffManualAmount': 777,
      })));

      expect(s.staffCost, 777);
    });

    test('includeStaff = false → koszt obsługi zero niezależnie od trybu', () {
      final s = SalaSummary.from(WeddingData.fromMap(weddingBase({
        'includeStaffInCalc': false,
        'staffCalcMode': StaffCalcMode.manual,
        'staffManualAmount': 777,
      })));

      expect(s.staffCost, 0);
    });
  });

  group('wesele z dziećmi — źródło liczby dzieci', () {
    /// Trzech gości, dwoje oznaczonych jako dzieci; wszyscy przy stołach.
    Map<String, dynamic> weddingWith(Map<String, dynamic> budgetExtras) => {
          'guests': [
            {'id': 1, 'tableId': 1, 'isChild': true},
            {'id': 2, 'tableId': 1, 'isChild': true},
            {'id': 3, 'tableId': 1},
          ],
          'tables': [
            {'id': 1}
          ],
          'budgetData': {
            'pricePerPerson': 200,
            'withChildren': true,
            'childMenuSeparate': true,
            'childMenuPricePerPerson': 50,
            ...budgetExtras,
          },
        };

    test('tryb auto bierze liczbę z listy gości', () {
      final s = SalaSummary.from(WeddingData.fromMap(
          weddingWith({ChildrenSettings.modeKey: 'auto'})));

      expect(s.children.auto, isTrue);
      expect(s.childrenCount, 2); // z flag isChild
      expect(s.childBilledCount, 2);
      // 1 dorosły * 200 + 2 dzieci * 50 = 300
      expect(s.guestCost, 300);
      expect(s.childMenuTotal, 100);
    });

    test('tryb auto ignoruje ręcznie wpisaną liczbę', () {
      final s = SalaSummary.from(WeddingData.fromMap(weddingWith(
          {ChildrenSettings.modeKey: 'auto', 'childrenCount': 99})));

      expect(s.childrenCount, 2);
    });

    test('brak trybu = ręczny (stare wesela zachowują swoją liczbę)', () {
      final s = SalaSummary.from(
          WeddingData.fromMap(weddingWith({'childrenCount': 3})));

      expect(s.children.auto, isFalse);
      expect(s.childrenCount, 3);
    });

    test('tryb ręczny bez wpisanej liczby → zero, mimo oznaczonych gości', () {
      final s = SalaSummary.from(WeddingData.fromMap(
          weddingWith({ChildrenSettings.modeKey: 'manual'})));

      expect(s.childrenCount, 0);
      // Wszyscy po cenie dorosłej: 3 * 200.
      expect(s.guestCost, 600);
      // …ale UI ma o rozjeździe ostrzec.
      expect(s.children.manualMismatch, isTrue);
      expect(s.children.fromGuests, 2);
    });

    test('wyłączone „wesele z dziećmi" zeruje liczbę mimo flag u gości', () {
      final s = SalaSummary.from(WeddingData.fromMap({
        'guests': [
          {'id': 1, 'tableId': 1, 'isChild': true},
        ],
        'tables': [
          {'id': 1}
        ],
        'budgetData': {
          'pricePerPerson': 200,
          'withChildren': false,
          ChildrenSettings.modeKey: 'auto',
        },
      }));

      expect(s.childrenCount, 0);
      expect(s.guestCost, 200);
    });

    test('dzieci nie przekraczają liczby gości liczonych do sali', () {
      final s = SalaSummary.from(WeddingData.fromMap({
        'guests': [
          {'id': 1, 'tableId': 1, 'isChild': true},
        ],
        'tables': [
          {'id': 1}
        ],
        'budgetData': {
          'pricePerPerson': 200,
          'withChildren': true,
          'childrenCount': 10, // ręcznie zawyżone
          'childMenuSeparate': true,
          'childMenuPricePerPerson': 50,
        },
      }));

      expect(s.childBilledCount, 1); // przycięte do efektywnej liczby gości
      expect(s.guestCost, 50);
    });
  });
}
