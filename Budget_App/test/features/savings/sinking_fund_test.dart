import 'package:budget_app/features/savings/domain/models/sinking_fund.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SinkingFund — monthly provision pacing', () {
    test('divides the remaining amount by whole months left until the due date', () {
      final now = DateTime.now();
      final fund = SinkingFund(
        id: 'f1',
        title: 'Ubezpieczenie OC/AC',
        targetAmount: 1200,
        currentAccumulated: 0,
        targetDate: DateTime(now.year, now.month + 6, now.day),
      );

      expect(fund.remainingAmount, 1200.0);
      expect(fund.monthlyProvision, 200.0); // 1200 / 6
    });

    test('accounts for what has already been accumulated', () {
      final now = DateTime.now();
      final fund = SinkingFund(
        id: 'f2',
        title: 'Podatek od nieruchomości',
        targetAmount: 2000,
        currentAccumulated: 500,
        targetDate: DateTime(now.year, now.month + 3, now.day),
      );

      expect(fund.remainingAmount, 1500.0);
      expect(fund.monthlyProvision, 500.0); // 1500 / 3
    });

    test('a fund that has already reached its target requires no further provision', () {
      final fund = SinkingFund(
        id: 'f3',
        title: 'Cel osiągnięty',
        targetAmount: 500,
        currentAccumulated: 800,
        targetDate: DateTime.now().add(const Duration(days: 90)),
      );

      expect(fund.remainingAmount, 0.0);
      expect(fund.monthlyProvision, 0.0);
    });

    test('a due date that has already passed requires the full remaining amount at once', () {
      final fund = SinkingFund(
        id: 'f4',
        title: 'Święta',
        targetAmount: 1000,
        currentAccumulated: 400,
        targetDate: DateTime.now().subtract(const Duration(days: 5)),
      );

      expect(fund.monthlyProvision, 600.0);
    });
  });
}
