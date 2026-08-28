import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/currency_math.dart';
import '../../../budget_sheet/domain/models/expense_entry.dart';
import '../../../budget_sheet/presentation/bloc/budget_sheet_bloc.dart';
import '../../../budget_sheet/presentation/bloc/budget_sheet_event.dart';
import '../../domain/services/receipt_scanner_service.dart';
import 'receipt_scanner_event.dart';
import 'receipt_scanner_state.dart';

const _uuid = Uuid();

class ReceiptScannerBloc extends Bloc<ReceiptScannerEvent, ReceiptScannerState> {
  ReceiptScannerBloc({
    required ReceiptScannerService scannerService,
    required this.budgetSheetBloc,
    ImagePicker? imagePicker,
  })  : _service = scannerService,
        _imagePicker = imagePicker ?? ImagePicker(),
        super(const ReceiptScannerInitial()) {
    on<PickReceiptImage>(_onPickImage);
    on<ProcessReceipt>((event, emit) => _processImage(event.imagePath, emit));
    on<ToggleItemSelection>(_onToggleItem);
    on<UpdateItemDetails>(_onUpdateDetails);
    on<UpdateItemCategory>(_onUpdateCategory);
    on<ConfirmImportToBudget>(_onConfirmImport);
  }

  final ReceiptScannerService _service;
  final BudgetSheetBloc budgetSheetBloc;
  final ImagePicker _imagePicker;

  Future<void> _onPickImage(PickReceiptImage event, Emitter<ReceiptScannerState> emit) async {
    final file = await _imagePicker.pickImage(source: event.source);
    if (file == null) return; // user cancelled — leave the current state as-is.
    await _processImage(file.path, emit);
  }

  Future<void> _processImage(String path, Emitter<ReceiptScannerState> emit) async {
    emit(const ReceiptScanningInProgress());
    try {
      final result = await _service.processReceiptImage(path);
      emit(ReceiptScanSuccess(result));
    } catch (_) {
      emit(const ReceiptScannerFailure('Nie udało się rozpoznać paragonu. Spróbuj ponownie.'));
    }
  }

  void _onToggleItem(ToggleItemSelection event, Emitter<ReceiptScannerState> emit) {
    final current = state;
    if (current is! ReceiptScanSuccess) return;

    emit(
      ReceiptScanSuccess(
        current.result.copyWith(
          items: [
            for (final item in current.result.items)
              if (item.id == event.itemId) item.copyWith(isSelected: !item.isSelected) else item,
          ],
        ),
      ),
    );
  }

  void _onUpdateDetails(UpdateItemDetails event, Emitter<ReceiptScannerState> emit) {
    final current = state;
    if (current is! ReceiptScanSuccess) return;

    emit(
      ReceiptScanSuccess(
        current.result.copyWith(
          items: [
            for (final item in current.result.items)
              if (item.id == event.itemId)
                item.copyWith(name: event.name, price: event.price)
              else
                item,
          ],
        ),
      ),
    );
  }

  void _onUpdateCategory(UpdateItemCategory event, Emitter<ReceiptScannerState> emit) {
    final current = state;
    if (current is! ReceiptScanSuccess) return;

    emit(
      ReceiptScanSuccess(
        current.result.copyWith(
          items: [
            for (final item in current.result.items)
              if (item.id == event.itemId)
                item.copyWith(
                  suggestedCategory: event.category,
                  suggestedSubCategory: event.subCategory,
                )
              else
                item,
          ],
        ),
      ),
    );
  }

  void _onConfirmImport(ConfirmImportToBudget event, Emitter<ReceiptScannerState> emit) {
    final current = state;
    if (current is! ReceiptScanSuccess) return;

    final selectedItems = current.result.items.where((item) => item.isSelected);
    var total = 0.0;

    for (final item in selectedItems) {
      final amount = roundCurrency(item.price * item.quantity);
      total += amount;
      budgetSheetBloc.add(
        AddExpenseEntry(
          ExpenseEntry(
            id: _uuid.v4(),
            name: item.name,
            amount: amount,
            categoryType: item.suggestedCategory,
            subCategory: item.suggestedSubCategory,
            date: current.result.transactionDate,
            comment: 'Zaimportowano z paragonu: ${current.result.merchantName}',
          ),
        ),
      );
    }

    emit(
      ReceiptImportedSuccessfully(
        importedCount: selectedItems.length,
        totalImported: roundCurrency(total),
      ),
    );
  }
}
