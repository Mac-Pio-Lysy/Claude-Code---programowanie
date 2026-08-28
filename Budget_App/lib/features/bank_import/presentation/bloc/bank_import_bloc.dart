import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../budget_sheet/domain/models/expense_category_type.dart';
import '../../../budget_sheet/domain/models/expense_entry.dart';
import '../../../budget_sheet/domain/models/income_entry.dart';
import '../../../budget_sheet/domain/models/income_type.dart';
import '../../../budget_sheet/presentation/bloc/budget_sheet_bloc.dart';
import '../../../budget_sheet/presentation/bloc/budget_sheet_event.dart';
import '../../domain/models/bank_transaction.dart';
import '../../domain/services/bank_csv_parser_service.dart';
import 'bank_import_event.dart';
import 'bank_import_state.dart';

const _uuid = Uuid();

class BankImportBloc extends Bloc<BankImportEvent, BankImportState> {
  BankImportBloc({
    required this.budgetSheetBloc,
    BankCsvParserService? parserService,
  })  : _parser = parserService ?? const BankCsvParserService(),
        super(BankImportState.initial()) {
    on<SelectBankProfile>(_onSelectProfile);
    on<LoadBankCsvFile>(_onLoadFile);
    on<ToggleTransactionSelection>(_onToggleSelection);
    on<ChangeTransactionCategory>(_onChangeCategory);
    on<ConfirmImportSelectedTransactions>(_onConfirmImport);
  }

  final BudgetSheetBloc budgetSheetBloc;
  final BankCsvParserService _parser;

  void _onSelectProfile(SelectBankProfile event, Emitter<BankImportState> emit) {
    emit(state.copyWith(selectedProfile: event.profile));
  }

  Future<void> _onLoadFile(LoadBankCsvFile event, Emitter<BankImportState> emit) async {
    emit(state.copyWith(status: BankImportStatus.parsing, selectedProfile: event.bankProfile));
    try {
      final transactions = _parser.parse(fileBytes: event.fileBytes, profile: event.bankProfile);
      if (transactions.isEmpty) {
        emit(
          state.copyWith(
            status: BankImportStatus.failure,
            errorMessage: 'Nie rozpoznano żadnych transakcji w tym pliku.',
          ),
        );
        return;
      }
      emit(state.copyWith(status: BankImportStatus.reviewing, transactions: transactions));
    } on BankCsvParseException catch (e) {
      emit(state.copyWith(status: BankImportStatus.failure, errorMessage: e.message));
    } catch (_) {
      emit(
        state.copyWith(
          status: BankImportStatus.failure,
          errorMessage: 'Nie udało się odczytać pliku CSV. Sprawdź, czy wybrano właściwy bank.',
        ),
      );
    }
  }

  void _onToggleSelection(ToggleTransactionSelection event, Emitter<BankImportState> emit) {
    emit(
      state.copyWith(
        transactions: [
          for (final t in state.transactions)
            if (t.id == event.id) t.copyWith(isSelected: !t.isSelected) else t,
        ],
      ),
    );
  }

  void _onChangeCategory(ChangeTransactionCategory event, Emitter<BankImportState> emit) {
    emit(
      state.copyWith(
        transactions: [
          for (final t in state.transactions)
            if (t.id == event.id)
              t.copyWith(suggestedCategory: event.category, suggestedSubCategory: event.subCategory)
            else
              t,
        ],
      ),
    );
  }

  void _onConfirmImport(
    ConfirmImportSelectedTransactions event,
    Emitter<BankImportState> emit,
  ) {
    final selected = state.transactions.where((t) => t.isSelected && !t.isImported);
    var total = 0.0;

    for (final transaction in selected) {
      total += transaction.amount;
      if (transaction.matchedType == BankTransactionType.income) {
        budgetSheetBloc.add(
          AddIncomeEntry(
            IncomeEntry(
              id: _uuid.v4(),
              title: transaction.title.isEmpty ? transaction.counterparty : transaction.title,
              type: IncomeType.other,
              grossAmount: transaction.amount,
              netAmount: transaction.amount,
              comment: 'Zaimportowano z wyciągu bankowego',
            ),
          ),
        );
      } else {
        budgetSheetBloc.add(
          AddExpenseEntry(
            ExpenseEntry(
              id: _uuid.v4(),
              name: transaction.title.isEmpty ? transaction.counterparty : transaction.title,
              amount: transaction.amount.abs(),
              categoryType: transaction.suggestedCategory ?? ExpenseCategoryType.mandatory,
              subCategory: transaction.suggestedSubCategory,
              date: transaction.bookingDate,
              comment: 'Zaimportowano z wyciągu bankowego',
            ),
          ),
        );
      }
    }

    emit(
      state.copyWith(
        status: BankImportStatus.imported,
        importedCount: selected.length,
        importedTotal: total,
        transactions: [
          for (final t in state.transactions)
            if (t.isSelected) t.copyWith(isImported: true) else t,
        ],
      ),
    );
  }
}
