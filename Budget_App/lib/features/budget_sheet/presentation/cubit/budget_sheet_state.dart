import 'package:equatable/equatable.dart';

import '../../domain/entities/sheet_entry.dart';

sealed class BudgetSheetState extends Equatable {
  const BudgetSheetState();

  @override
  List<Object?> get props => [];
}

class BudgetSheetLoading extends BudgetSheetState {
  const BudgetSheetLoading();
}

class BudgetSheetLoaded extends BudgetSheetState {
  const BudgetSheetLoaded(this.entries);

  final List<SheetEntry> entries;

  @override
  List<Object?> get props => [entries];
}
