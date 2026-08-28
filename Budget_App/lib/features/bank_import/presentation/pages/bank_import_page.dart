import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/gradient_background.dart';
import '../../../budget_sheet/presentation/bloc/budget_sheet_bloc.dart';
import '../bloc/bank_import_bloc.dart';
import '../views/bank_import_view.dart';

/// Reached via "Importuj wyciąg CSV" from the workspace top bar (desktop)
/// or the mobile FAB's add-entry chooser — not a top-level nav destination,
/// just a one-off wizard pushed on top of whichever budget is active.
class BankImportPage extends StatelessWidget {
  const BankImportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BankImportBloc(budgetSheetBloc: context.read<BudgetSheetBloc>()),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Import wyciągu bankowego')),
        body: const GradientBackground(child: SafeArea(child: BankImportView())),
      ),
    );
  }
}
