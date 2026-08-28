import 'package:equatable/equatable.dart';

import '../../domain/models/bank_profile.dart';
import '../../domain/models/bank_transaction.dart';

enum BankImportStatus {
  /// Step 1: choosing a bank profile and a file.
  pickingFile,
  parsing,

  /// Step 2: reviewing the recognized transactions.
  reviewing,
  importing,

  /// Step 3 done.
  imported,
  failure,
}

class BankImportState extends Equatable {
  const BankImportState({
    required this.status,
    this.selectedProfile,
    this.transactions = const [],
    this.errorMessage,
    this.importedCount = 0,
    this.importedTotal = 0,
  });

  factory BankImportState.initial() =>
      const BankImportState(status: BankImportStatus.pickingFile);

  final BankImportStatus status;
  final BankProfile? selectedProfile;
  final List<BankTransaction> transactions;
  final String? errorMessage;
  final int importedCount;
  final double importedTotal;

  /// Sum of amounts across only the checked-off transactions — what would
  /// actually be imported right now.
  double get selectedTotal => transactions
      .where((t) => t.isSelected)
      .fold(0.0, (sum, t) => sum + t.amount);

  int get selectedCount => transactions.where((t) => t.isSelected).length;

  BankImportState copyWith({
    BankImportStatus? status,
    BankProfile? selectedProfile,
    List<BankTransaction>? transactions,
    String? errorMessage,
    int? importedCount,
    double? importedTotal,
  }) {
    return BankImportState(
      status: status ?? this.status,
      selectedProfile: selectedProfile ?? this.selectedProfile,
      transactions: transactions ?? this.transactions,
      errorMessage: errorMessage,
      importedCount: importedCount ?? this.importedCount,
      importedTotal: importedTotal ?? this.importedTotal,
    );
  }

  @override
  List<Object?> get props => [
        status,
        selectedProfile,
        transactions,
        errorMessage,
        importedCount,
        importedTotal,
      ];
}
