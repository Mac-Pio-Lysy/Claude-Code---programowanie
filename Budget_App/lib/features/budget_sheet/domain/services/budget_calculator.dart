import '../../../../core/utils/currency_math.dart';
import '../models/budget_summary.dart';
import '../models/expense_category_type.dart';
import '../models/expense_entry.dart';
import '../models/income_entry.dart';

/// Pure calculation engine turning raw income/expense entries into a
/// [BudgetSummary]. Holds no state and performs no I/O.
class BudgetCalculator {
  const BudgetCalculator();

  BudgetSummary calculateSummary({
    required List<IncomeEntry> incomes,
    required List<ExpenseEntry> expenses,
    double allocatedToSavings = 0.0,
  }) {
    final totalIncomeNet = _sum(incomes.map((e) => e.netAmount));

    final totalMandatory = _sumByCategory(expenses, ExpenseCategoryType.mandatory);
    final totalUtility = _sumByCategory(expenses, ExpenseCategoryType.utility);
    final totalWants = _sumByCategory(expenses, ExpenseCategoryType.wants);
    final totalExpenses = roundCurrency(totalMandatory + totalUtility + totalWants);

    final remainingBalance = roundCurrency(totalIncomeNet - totalExpenses);

    // Guard against a negative allocation (e.g. a bad manual input upstream)
    // ever inflating freeCash.
    final safeAllocatedToSavings =
        roundCurrency(allocatedToSavings < 0 ? 0.0 : allocatedToSavings);

    final freeCash = roundCurrency(remainingBalance - safeAllocatedToSavings);

    return BudgetSummary(
      totalIncomeNet: totalIncomeNet,
      totalMandatoryExpenses: totalMandatory,
      totalUtilityExpenses: totalUtility,
      totalWantsExpenses: totalWants,
      totalExpenses: totalExpenses,
      remainingBalance: remainingBalance,
      allocatedToSavings: safeAllocatedToSavings,
      freeCash: freeCash,
    );
  }

  double _sumByCategory(List<ExpenseEntry> expenses, ExpenseCategoryType type) {
    return _sum(
      expenses.where((e) => e.categoryType == type).map((e) => e.amount),
    );
  }

  double _sum(Iterable<double> values) {
    if (values.isEmpty) return 0.0;
    return roundCurrency(values.fold(0.0, (total, value) => total + value));
  }
}
