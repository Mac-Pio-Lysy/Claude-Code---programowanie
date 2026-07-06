// Weryfikuje, że BudgetSummary liczy tak samo jak renderBudgetOverview() w web.

import 'package:flutter_test/flutter_test.dart';
import 'package:moje_wesele/models/budget_summary.dart';
import 'package:moje_wesele/models/wedding_data.dart';

void main() {
  test('BudgetSummary agreguje koszty z wielu sekcji', () {
    final data = WeddingData.fromMap({
      'guests': [
        {'id': 1, 'tableId': 1},
        {'id': 2, 'tableId': null},
      ],
      'tables': [],
      'budgetData': {
        'total': 20000,
        'pricePerPerson': 200,
        'venueMinGuests': 0,
        'expenses': [
          {'planned': 1000, 'paid': 400, 'estimatedAmount': 0},
          {'planned': 0, 'paid': 100, 'estimatedAmount': 500},
        ],
        'alcoholItems': [
          {'bottles': 10, 'pricePerBottle': 50}, // 500
        ],
        'softItems': [
          {'bottles': 5, 'pricePerBottle': 10}, // 50
        ],
        'honeymoon': {
          'totalAmount': 3000,
          'estimatedAmount': 0,
          'installments': [
            {'amount': 1000, 'status': 'paid'},
            {'amount': 500, 'status': 'pending'},
          ],
        },
      },
      'vendors': [
        {
          'isBudgetLinked': false,
          'price': 2000,
          'installments': [
            {'amount': 800, 'status': 'paid'},
          ],
        },
        {'isBudgetLinked': true, 'price': 9999}, // pominięty (powiązany)
      ],
      'hotels': [
        {'pricePerNight': 300, 'personsPerRoom': 2}, // 600
      ],
      'vehicles': [
        {'cost': 400},
      ],
    });

    final s = BudgetSummary.from(data);

    expect(s.catering, 400); // 200 zł * 2 gości
    expect(s.totalConfirmed, 7950); // 400 + 1550 + 3000 + 3000
    expect(s.totalEffective, 8450); // 400 + 2050 + 3000 + 3000
    expect(s.totalPaid, 2300); // 500 + 1000 + 800
    expect(s.hasEstimates, true);
    expect(s.planForCalc, 8450);
    expect(s.remaining, 6150); // 8450 - 2300
    expect(s.budget, 20000);
    expect(s.diff, 11550); // 20000 - 8450
    expect(s.expensesEstimated, 500);
    expect(s.paidPercentLabel, 27); // round(2300 / 8450 * 100)
  });
}
