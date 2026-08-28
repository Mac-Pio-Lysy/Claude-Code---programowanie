import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../budget_sheet/domain/models/expense_category_type.dart';
import '../../../budget_sheet/presentation/widgets/editable_cell.dart';
import '../../../budget_sheet/presentation/widgets/expense_category_label.dart';
import '../../domain/models/receipt_item.dart';
import '../../domain/models/scanned_receipt_result.dart';
import '../bloc/receipt_scanner_bloc.dart';
import '../bloc/receipt_scanner_event.dart';
import '../bloc/receipt_scanner_state.dart';

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

/// AB-5: pick/take a receipt photo, review the OCR-recognized line items,
/// then import the checked ones straight into the active budget's sheet.
class ReceiptScannerView extends StatelessWidget {
  const ReceiptScannerView({super.key, required this.targetBudgetId});

  /// The budget ConfirmImportToBudget should attribute the import to. Null
  /// means no budget is currently active (e.g. reached without one open).
  final String? targetBudgetId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReceiptScannerBloc, ReceiptScannerState>(
      builder: (context, state) {
        return switch (state) {
          ReceiptScannerInitial() => const _CenteredScrollable(child: _SourcePicker()),
          ReceiptScanningInProgress() => const _ScanningIndicator(),
          ReceiptScanSuccess() => _ReceiptReview(result: state.result, targetBudgetId: targetBudgetId),
          ReceiptImportedSuccessfully() => _ImportSuccess(state: state),
          ReceiptScannerFailure() => _ScanError(message: state.error),
        };
      },
    );
  }
}

/// The bare "pick a source" content — deliberately not scrollable/centered
/// on its own, since it's reused inline within [_ScanError] and
/// [_ImportSuccess], which provide the single outer scroll view themselves
/// to avoid nesting one scrollable inside another's unbounded height.
class _SourcePicker extends StatelessWidget {
  const _SourcePicker();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // A decorative crop-frame placeholder — no live camera preview in
        // this mock flow, just a visual cue of where the receipt would be
        // framed.
        DottedFrame(
          child: SizedBox(
            width: 220,
            height: 280,
            child: Center(
              child: Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Zeskanuj paragon, aby dodać wydatki', style: textTheme.titleMedium),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () =>
              context.read<ReceiptScannerBloc>().add(const PickReceiptImage(ImageSource.camera)),
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('Zrób zdjęcie paragonu'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () =>
              context.read<ReceiptScannerBloc>().add(const PickReceiptImage(ImageSource.gallery)),
          icon: const Icon(Icons.upload_file_outlined),
          label: const Text('Wgraj plik ze zdjęciem/PDF'),
        ),
      ],
    );
  }
}

/// Centers [child] when it fits, scrolls it when it doesn't — the shared
/// wrapper for every step's content in this view.
class _CenteredScrollable extends StatelessWidget {
  const _CenteredScrollable({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: Center(child: child),
          ),
        );
      },
    );
  }
}

/// A dashed-border framing box, reused as the "crop frame" visual.
class DottedFrame extends StatelessWidget {
  const DottedFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.4), width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }
}

class _ScanningIndicator extends StatelessWidget {
  const _ScanningIndicator();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Skanowanie paragonu…', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ScanError extends StatelessWidget {
  const _ScanError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _CenteredScrollable(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.negative, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          const _SourcePicker(),
        ],
      ),
    );
  }
}

class _ImportSuccess extends StatelessWidget {
  const _ImportSuccess({required this.state});

  final ReceiptImportedSuccessfully state;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _CenteredScrollable(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.positive, size: 56),
          const SizedBox(height: 16),
          Text(
            'Zaimportowano ${state.importedCount} '
            '${state.importedCount == 1 ? 'pozycję' : 'pozycji'} na kwotę '
            '${CurrencyFormatter.format(state.totalImported)}',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          const _SourcePicker(),
        ],
      ),
    );
  }
}

class _ReceiptReview extends StatelessWidget {
  const _ReceiptReview({required this.result, required this.targetBudgetId});

  final ScannedReceiptResult result;
  final String? targetBudgetId;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bloc = context.read<ReceiptScannerBloc>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.merchantName, style: textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  _formatDate(result.transactionDate),
                  style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Suma paragonu: ${CurrencyFormatter.format(result.totalAmount)}',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final item in result.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ReceiptItemTile(item: item),
            ),
          const SizedBox(height: 8),
          GlassCard(
            child: Row(
              children: [
                Text('Do importu:', style: textTheme.titleSmall),
                const Spacer(),
                Text(
                  CurrencyFormatter.format(result.selectedTotal),
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: targetBudgetId == null
                ? null
                : () => bloc.add(ConfirmImportToBudget(targetBudgetId!)),
            icon: const Icon(Icons.playlist_add_check_outlined),
            label: const Text('Dodaj zaznaczone wydatki do bieżącego budżetu'),
          ),
          if (targetBudgetId == null) ...[
            const SizedBox(height: 8),
            Text(
              'Brak aktywnego budżetu — otwórz najpierw budżet z listy.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReceiptItemTile extends StatelessWidget {
  const _ReceiptItemTile({required this.item});

  final ReceiptItem item;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ReceiptScannerBloc>();

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Checkbox(
            value: item.isSelected,
            onChanged: (_) => bloc.add(ToggleItemSelection(item.id)),
          ),
          Expanded(
            flex: 3,
            child: EditableCell(
              value: item.name,
              onSubmit: (v) => bloc.add(UpdateItemDetails(itemId: item.id, name: v)),
            ),
          ),
          Expanded(
            flex: 2,
            child: EditableCell(
              value: item.price.toStringAsFixed(2),
              isNumeric: true,
              textAlign: TextAlign.end,
              onSubmit: (v) =>
                  bloc.add(UpdateItemDetails(itemId: item.id, price: double.parse(v))),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<ExpenseCategoryType>(
            value: item.suggestedCategory,
            underline: const SizedBox.shrink(),
            items: [
              for (final type in ExpenseCategoryType.values)
                DropdownMenuItem(value: type, child: Text(expenseCategoryTypeLabel(type))),
            ],
            onChanged: (value) {
              if (value == null) return;
              bloc.add(
                UpdateItemCategory(
                  itemId: item.id,
                  category: value,
                  subCategory: item.suggestedSubCategory,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
