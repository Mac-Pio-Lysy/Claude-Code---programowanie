import 'package:equatable/equatable.dart';

import '../../domain/models/scanned_receipt_result.dart';

sealed class ReceiptScannerState extends Equatable {
  const ReceiptScannerState();

  @override
  List<Object?> get props => [];
}

class ReceiptScannerInitial extends ReceiptScannerState {
  const ReceiptScannerInitial();
}

class ReceiptScanningInProgress extends ReceiptScannerState {
  const ReceiptScanningInProgress();
}

class ReceiptScanSuccess extends ReceiptScannerState {
  const ReceiptScanSuccess(this.result);

  final ScannedReceiptResult result;

  @override
  List<Object?> get props => [result];
}

class ReceiptImportedSuccessfully extends ReceiptScannerState {
  const ReceiptImportedSuccessfully({required this.importedCount, required this.totalImported});

  final int importedCount;
  final double totalImported;

  @override
  List<Object?> get props => [importedCount, totalImported];
}

class ReceiptScannerFailure extends ReceiptScannerState {
  const ReceiptScannerFailure(this.error);

  final String error;

  @override
  List<Object?> get props => [error];
}
