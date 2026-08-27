/// Three-tier expense classification used to break the budget down into
/// Wymagane/Stałe, Użytkowe and Zachcianki.
enum ExpenseCategoryType {
  /// Required/fixed: housing, rent, electricity, gas, loan installments.
  mandatory,

  /// Utility: education, tutoring, self-development, commuting.
  utility,

  /// Wants: going out, streaming subscriptions (Netflix/HBO), hobbies.
  wants,
}
