import 'package:budget_app/features/monetization/domain/models/subscription_tier.dart';
import 'package:budget_app/features/monetization/presentation/cubit/monetization_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MonetizationCubit — Free tier', () {
    test('starts on the Free tier', () {
      final cubit = MonetizationCubit();
      expect(cubit.state, SubscriptionTier.free);
      expect(cubit.isPremium, isFalse);
      cubit.close();
    });

    test('can create a first budget but not a second', () {
      final cubit = MonetizationCubit();
      expect(cubit.canCreateBudget(0), isTrue);
      expect(cubit.canCreateBudget(1), isFalse);
      expect(cubit.canCreateBudget(2), isFalse);
      cubit.close();
    });

    test('cannot share budgets', () {
      final cubit = MonetizationCubit();
      expect(cubit.canShareBudgets, isFalse);
      cubit.close();
    });

    test('shows ads', () {
      final cubit = MonetizationCubit();
      expect(cubit.shouldShowAds, isTrue);
      cubit.close();
    });
  });

  group('MonetizationCubit — activatePremium', () {
    test('switches the tier to Premium', () {
      final cubit = MonetizationCubit();
      cubit.activatePremium();
      expect(cubit.state, SubscriptionTier.premium);
      expect(cubit.isPremium, isTrue);
      cubit.close();
    });

    test('Premium can always create another budget, regardless of count', () {
      final cubit = MonetizationCubit()..activatePremium();
      expect(cubit.canCreateBudget(0), isTrue);
      expect(cubit.canCreateBudget(1), isTrue);
      expect(cubit.canCreateBudget(50), isTrue);
      cubit.close();
    });

    test('Premium can share budgets and has no ads', () {
      final cubit = MonetizationCubit()..activatePremium();
      expect(cubit.canShareBudgets, isTrue);
      expect(cubit.shouldShowAds, isFalse);
      cubit.close();
    });
  });
}
