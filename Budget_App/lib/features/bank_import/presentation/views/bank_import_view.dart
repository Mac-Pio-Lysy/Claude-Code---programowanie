import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/models/bank_profile.dart';
import '../bloc/bank_import_bloc.dart';
import '../bloc/bank_import_event.dart';
import '../bloc/bank_import_state.dart';
import '../widgets/bank_profile_ui.dart';
import '../widgets/bank_transaction_tile.dart';

/// AB-6: import a bank statement CSV (one of six recognized Polish-bank
/// profiles, or a universal auto-detected template), review the recognized
/// transactions, then import the checked ones straight into the active
/// budget's sheet.
class BankImportView extends StatelessWidget {
  const BankImportView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BankImportBloc, BankImportState>(
      builder: (context, state) {
        return switch (state.status) {
          BankImportStatus.pickingFile => _CenteredScrollable(
              child: _ProfileAndFilePicker(selectedProfile: state.selectedProfile),
            ),
          BankImportStatus.parsing => const _ParsingIndicator(),
          BankImportStatus.reviewing => _TransactionReview(state: state),
          BankImportStatus.importing => const _ParsingIndicator(),
          BankImportStatus.imported => _ImportSuccess(state: state),
          BankImportStatus.failure => _ImportError(message: state.errorMessage ?? 'Błąd importu.'),
        };
      },
    );
  }
}

/// Centers [child] when it fits, scrolls it when it doesn't.
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

class _ProfileAndFilePicker extends StatelessWidget {
  const _ProfileAndFilePicker({required this.selectedProfile});

  final BankProfile? selectedProfile;

  Future<void> _pickFile(BuildContext context) async {
    final profile = selectedProfile;
    if (profile == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    final bytes = result?.files.single.bytes;
    if (bytes == null || !context.mounted) return;

    context.read<BankImportBloc>().add(LoadBankCsvFile(bytes, profile));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bloc = context.read<BankImportBloc>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Krok 1: wybierz bank', style: textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final profile in BankProfile.values)
              ChoiceChip(
                avatar: Icon(bankProfileIcon(profile), size: 18),
                label: Text(bankProfileLabel(profile)),
                selected: selectedProfile == profile,
                onSelected: (_) => bloc.add(SelectBankProfile(profile)),
              ),
          ],
        ),
        const SizedBox(height: 24),
        DottedFrame(
          child: SizedBox(
            width: 260,
            height: 160,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.upload_file_outlined, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Przeciągnij plik CSV lub wybierz z dysku',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: selectedProfile == null ? null : () => _pickFile(context),
          icon: const Icon(Icons.folder_open_outlined),
          label: const Text('Wybierz plik CSV'),
        ),
      ],
    );
  }
}

/// A dashed-border framing box, reused as the drop-zone visual.
class DottedFrame extends StatelessWidget {
  const DottedFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryIndigo.withValues(alpha: 0.4), width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }
}

class _ParsingIndicator extends StatelessWidget {
  const _ParsingIndicator();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Wczytywanie wyciągu…', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ImportError extends StatelessWidget {
  const _ImportError({required this.message});

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
          _ProfileAndFilePicker(selectedProfile: context.read<BankImportBloc>().state.selectedProfile),
        ],
      ),
    );
  }
}

class _ImportSuccess extends StatelessWidget {
  const _ImportSuccess({required this.state});

  final BankImportState state;

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
            '${state.importedCount == 1 ? 'pozycję' : 'pozycji'} na łączną kwotę '
            '${CurrencyFormatter.format(state.importedTotal)}',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _TransactionReview extends StatelessWidget {
  const _TransactionReview({required this.state});

  final BankImportState state;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bloc = context.read<BankImportBloc>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Krok 2: sprawdź rozpoznane transakcje', style: textTheme.titleMedium),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: state.transactions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                BankTransactionTile(transaction: state.transactions[index]),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GlassCard(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: state.selectedCount == 0
                      ? null
                      : () => bloc.add(const ConfirmImportSelectedTransactions()),
                  icon: const Icon(Icons.playlist_add_check_outlined),
                  label: Text(
                    'Zaimportuj ${state.selectedCount} '
                    '${state.selectedCount == 1 ? 'pozycję' : 'pozycji'} na łączną kwotę '
                    '${CurrencyFormatter.format(state.selectedTotal)} do budżetu',
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
