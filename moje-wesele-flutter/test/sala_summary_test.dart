// Weryfikuje obliczenia podzakładki „Sala" względem logiki z wersji web.

import 'package:flutter_test/flutter_test.dart';
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
    expect(s.seated, 2); // 2 gości z tableId
    expect(s.cateringBase, 600); // 200 * 3
    expect(s.virtualGuests, 3); // max(0, 5 - 2)
    expect(s.virtualCost, 600); // 3 * 200
    // effectiveGuestCount = seated(2) + virtual(3) = 5
    expect(s.effectiveGuestCount, 5);
    expect(s.menuAddonsTotal, 50); // 10 * 5
    expect(s.regularTableCount, 2); // 2 zwykłe stoły
    expect(s.honorDecoTotal, 300);
    expect(s.regularDecoTotal, 100); // 50 * 2
    expect(s.tableDecoTotal, 400);
    // catering = 600 + 600 + 0(staff) + 50 + 300 + 100 = 1650
    expect(s.cateringTotal, 1650);
  });
}
