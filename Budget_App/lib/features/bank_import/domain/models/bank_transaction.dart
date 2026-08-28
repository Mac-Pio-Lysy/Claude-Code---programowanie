import 'package:equatable/equatable.dart';

import '../../../budget_sheet/domain/models/expense_category_type.dart';

/// Which side of the budget a [BankTransaction] lands on — derived from the
/// sign of [BankTransaction.amount] (positive = income, negative = expense).
enum BankTransactionType { income, expense }

/// One row recognized in an imported bank statement CSV, pending the user's
/// review before import into the budget sheet — the bank-import analogue of
/// receipt_scanner's `ReceiptItem`.
class BankTransaction extends Equatable {
  const BankTransaction({
    required this.id,
    required this.bookingDate,
    required this.counterparty,
    required this.title,
    required this.amount,
    required this.matchedType,
    required this.suggestedSubCategory,
    this.rawCategory,
    this.suggestedCategory,
    this.isImported = false,
    this.isSelected = true,
  });

  final String id;
  final DateTime bookingDate;

  /// The other party on the statement line (odbiorca/nadawca).
  final String counterparty;

  /// The transfer/operation title (tytuł przelewu).
  final String title;

  /// Positive for incoming money, negative for outgoing.
  final double amount;

  /// Category as reported by the bank itself, when the export includes one
  /// (e.g. mBank's "Kategoria" column) — kept for reference, not used for
  /// budgeting directly.
  final String? rawCategory;

  final BankTransactionType matchedType;

  /// Only meaningful for [BankTransactionType.expense] — income entries in
  /// this app aren't classified into mandatory/utility/wants.
  final ExpenseCategoryType? suggestedCategory;

  /// e.g. "Zakupy spożywcze", "Rachunki", "Paliwo", "Wynagrodzenie".
  final String suggestedSubCategory;

  /// Whether this row has already been sent to BudgetSheetBloc.
  final bool isImported;

  /// Whether the user has checked this row for import.
  final bool isSelected;

  static const _unset = Object();

  BankTransaction copyWith({
    Object? suggestedCategory = _unset,
    String? suggestedSubCategory,
    bool? isImported,
    bool? isSelected,
  }) {
    return BankTransaction(
      id: id,
      bookingDate: bookingDate,
      counterparty: counterparty,
      title: title,
      amount: amount,
      rawCategory: rawCategory,
      matchedType: matchedType,
      suggestedCategory: identical(suggestedCategory, _unset)
          ? this.suggestedCategory
          : suggestedCategory as ExpenseCategoryType?,
      suggestedSubCategory: suggestedSubCategory ?? this.suggestedSubCategory,
      isImported: isImported ?? this.isImported,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  List<Object?> get props => [
        id,
        bookingDate,
        counterparty,
        title,
        amount,
        rawCategory,
        matchedType,
        suggestedCategory,
        suggestedSubCategory,
        isImported,
        isSelected,
      ];
}
