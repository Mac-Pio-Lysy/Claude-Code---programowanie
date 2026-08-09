// Weryfikuje obliczenia podzakładki „Sala" względem logiki z wersji web.

import 'package:flutter_test/flutter_test.dart';
import 'package:moje_wesele/models/children.dart';
import 'package:moje_wesele/models/sala_summary.dart';
import 'package:moje_wesele/models/wedding_data.dart';

void main() {
  test('SalaSummary liczy catering, gości wirtualnych, dodatki i dekoracje', () {
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
        'venueMinGuests': 5, // próg 5, przy stołach 2 → 3 wirtualnych
        'includeVirtualInCalc': true,
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
    expect(s.assignedCount, 2); // 2 gości z tableId
    expect(s.unassignedCount, 1);
    // Nieprzypisani liczą się domyślnie → baza cateringu to wszyscy goście.
    expect(s.guestBilledCount, 3);
    expect(s.guestCost, 600); // 200 * 3
    expect(s.virtualGuests, 3); // max(0, 5 - 2), liczone od przypisanych
    expect(s.virtualCost, 600); // 3 * 200
    // effectiveGuestCount = liczeni goście(3) + wirtualni(3) + obsługa(0)
    expect(s.effectiveGuestCount, 6);
    expect(s.menuAddonsTotal, 60); // 10 * 6
    expect(s.regularTableCount, 2); // 2 zwykłe stoły
    expect(s.honorDecoTotal, 300);
    expect(s.regularDecoTotal, 100); // 50 * 2
    expect(s.tableDecoTotal, 400);
    // catering = 600 + 600 + 0(obsługa) + 60 + 300 + 100 = 1660
    expect(s.cateringTotal, 1660);
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

      expect(s.childBilledCount, 1); // przycięte do liczby gości
      expect(s.guestCost, 50);
    });
  });
}
