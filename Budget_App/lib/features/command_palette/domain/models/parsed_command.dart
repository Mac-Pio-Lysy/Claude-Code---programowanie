import 'package:equatable/equatable.dart';

import '../../../budget_sheet/domain/models/expense_category_type.dart';

/// Where a [NavigateCommand] should take the user.
enum PaletteDestination {
  /// The active budget's sheet (`/budget/:id`, or `/workspace` if none is
  /// active yet).
  budgetSheet,
  savings,
  ocrScanner,
  bankImport,
}

/// What the Command Palette should do with a parsed query — produced by
/// [parseCommand], acted on by the palette's UI (which alone has the
/// BuildContext needed to actually navigate/open dialogs/dispatch to
/// blocs).
sealed class ParsedCommand extends Equatable {
  const ParsedCommand();

  @override
  List<Object?> get props => [];
}

class NavigateCommand extends ParsedCommand {
  const NavigateCommand(this.destination);

  final PaletteDestination destination;

  @override
  List<Object?> get props => [destination];
}

/// "podział" — opens FairShareSplitDialog rather than pushing a route.
class OpenFairShareDialogCommand extends ParsedCommand {
  const OpenFairShareDialogCommand();
}

class AddExpenseParsedCommand extends ParsedCommand {
  const AddExpenseParsedCommand({
    required this.name,
    required this.amount,
    required this.currency,
    required this.categoryType,
    required this.subCategory,
  });

  final String name;

  /// In [currency] — not yet converted to PLN.
  final double amount;

  /// ISO 4217 code, e.g. 'PLN', 'EUR'.
  final String currency;
  final ExpenseCategoryType categoryType;
  final String subCategory;

  @override
  List<Object?> get props => [name, amount, currency, categoryType, subCategory];
}

class AddIncomeParsedCommand extends ParsedCommand {
  const AddIncomeParsedCommand({
    required this.title,
    required this.amount,
    required this.currency,
  });

  final String title;

  /// In [currency] — not yet converted to PLN.
  final double amount;

  /// ISO 4217 code, e.g. 'PLN', 'EUR'.
  final String currency;

  @override
  List<Object?> get props => [title, amount, currency];
}

/// The query is empty, or didn't match any navigation keyword or
/// `<name> <amount> [currency] [category]` quick-add shape.
class UnknownCommand extends ParsedCommand {
  const UnknownCommand(this.rawInput);

  final String rawInput;

  @override
  List<Object?> get props => [rawInput];
}
