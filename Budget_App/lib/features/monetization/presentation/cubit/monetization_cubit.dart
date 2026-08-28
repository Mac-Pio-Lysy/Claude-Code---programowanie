import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/subscription_tier.dart';

/// The app's single feature-gating source of truth (AB-1). A single
/// app-lifetime instance is provided above the router so the tier survives
/// navigation.
class MonetizationCubit extends Cubit<SubscriptionTier> {
  MonetizationCubit() : super(SubscriptionTier.free);

  /// Free is capped at 1 budget; Premium is unlimited.
  static const int freeBudgetLimit = 1;

  /// Mock upgrade — a real IAP/subscription flow would replace this call.
  void activatePremium() => emit(SubscriptionTier.premium);

  bool get isPremium => state == SubscriptionTier.premium;

  /// Whether the user may create one more budget, given how many they
  /// already have.
  bool canCreateBudget(int currentBudgetCount) {
    if (state == SubscriptionTier.premium) return true;
    return currentBudgetCount < freeBudgetLimit;
  }

  /// Free users can't mark a budget as shared or invite collaborators.
  bool get canShareBudgets => state == SubscriptionTier.premium;

  /// Free shows the banner; Premium is ad-free.
  bool get shouldShowAds => state == SubscriptionTier.free;
}
