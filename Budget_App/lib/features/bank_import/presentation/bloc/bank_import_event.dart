import 'package:equatable/equatable.dart';

import '../../../budget_sheet/domain/models/expense_category_type.dart';
import '../../domain/models/bank_profile.dart';

sealed class BankImportEvent extends Equatable {
  const BankImportEvent();

  @override
  List<Object?> get props => [];
}

class SelectBankProfile extends BankImportEvent {
  const SelectBankProfile(this.profile);

  final BankProfile profile;

  @override
  List<Object?> get props => [profile];
}

class LoadBankCsvFile extends BankImportEvent {
  const LoadBankCsvFile(this.fileBytes, this.bankProfile);

  final List<int> fileBytes;
  final BankProfile bankProfile;

  @override
  List<Object?> get props => [fileBytes, bankProfile];
}

class ToggleTransactionSelection extends BankImportEvent {
  const ToggleTransactionSelection(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class ChangeTransactionCategory extends BankImportEvent {
  const ChangeTransactionCategory({
    required this.id,
    required this.category,
    required this.subCategory,
  });

  final String id;
  final ExpenseCategoryType category;
  final String subCategory;

  @override
  List<Object?> get props => [id, category, subCategory];
}

class ConfirmImportSelectedTransactions extends BankImportEvent {
  const ConfirmImportSelectedTransactions();
}
