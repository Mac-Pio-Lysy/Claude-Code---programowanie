import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/ad_banner_placeholder.dart';
import '../../../../core/widgets/top_level_page_scaffold.dart';
import '../../../monetization/presentation/cubit/monetization_cubit.dart';
import '../../../receipt_scanner/data/services/mock_ocr_engine.dart';
import '../../../receipt_scanner/presentation/bloc/receipt_scanner_bloc.dart';
import '../../../receipt_scanner/presentation/views/receipt_scanner_view.dart';
import '../../../workspace/presentation/cubit/active_workspace_cubit.dart';
import '../../../workspace/presentation/pages/workspace_page.dart' show workspaceNavDestinations;
import '../bloc/budget_sheet_bloc.dart';

/// AB-5: scan a receipt (mocked OCR) and import the recognized line items
/// straight into the currently active budget's sheet — see
/// architecture.c4's ocrScanner -> sheetEngine flow.
class OcrScannerPage extends StatelessWidget {
  const OcrScannerPage({
    super.key,
    required this.selectedBottomIndex,
    required this.onBottomDestinationSelected,
  });

  final int selectedBottomIndex;
  final ValueChanged<int> onBottomDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final shouldShowAds = context.watch<MonetizationCubit>().shouldShowAds;
    final activeBudgetId = context.watch<ActiveWorkspaceCubit>().state;

    return BlocProvider(
      create: (context) => ReceiptScannerBloc(
        scannerService: const MockOcrEngine(),
        budgetSheetBloc: context.read<BudgetSheetBloc>(),
      ),
      child: TopLevelPageScaffold(
        title: 'Skaner paragonów',
        destinations: workspaceNavDestinations,
        selectedIndex: selectedBottomIndex,
        onDestinationSelected: onBottomDestinationSelected,
        adBanner: shouldShowAds ? const AdBannerPlaceholder() : null,
        body: ReceiptScannerView(targetBudgetId: activeBudgetId),
      ),
    );
  }
}
