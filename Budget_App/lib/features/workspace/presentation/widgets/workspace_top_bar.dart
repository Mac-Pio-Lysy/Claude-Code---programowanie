import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/widgets/profile_menu_button.dart';
import '../../../command_palette/presentation/widgets/command_palette_overlay.dart';

/// App logo (hidden on narrow widths to make room), the active budget name,
/// a budget-settings gear, a workspace switcher and the profile menu.
class WorkspaceTopBar extends StatelessWidget {
  const WorkspaceTopBar({
    super.key,
    required this.budgetName,
    this.onViewSwitch,
    this.onBudgetSettingsTap,
    this.onScanReceiptTap,
    this.onImportCsvTap,
    this.onFairSplitTap,
    this.isShared = false,
  });

  final String budgetName;
  final VoidCallback? onViewSwitch;

  /// Gear icon next to the budget name — opens BudgetSettingsDialog.
  final VoidCallback? onBudgetSettingsTap;

  /// Scanner icon — opens the AB-5 receipt scanner (`/ocr`).
  final VoidCallback? onScanReceiptTap;

  /// Import icon — opens the bank statement CSV import wizard (`/bank-import`).
  final VoidCallback? onImportCsvTap;

  /// "Sprawiedliwy podział kosztów" icon — only shown when [isShared].
  final VoidCallback? onFairSplitTap;

  /// Whether the active budget is shared with another partner (AB-7's cost
  /// split only makes sense for a shared budget).
  final bool isShared;

  static const double _logoBreakpoint = 500;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showLogo = constraints.maxWidth >= _logoBreakpoint;

          return Row(
            children: [
              if (showLogo) ...[
                const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primaryIndigo),
                const SizedBox(width: 8),
                Text(AppConstants.appName, style: textTheme.titleMedium),
                const SizedBox(width: 16),
                const _Divider(),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Text(
                  budgetName,
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'Command Palette (⌘K)',
                onPressed: () => showCommandPaletteOverlay(context),
                icon: const Icon(Icons.search),
              ),
              if (showLogo)
                IconButton(
                  tooltip: 'Skanuj paragon',
                  onPressed: onScanReceiptTap,
                  icon: const Icon(Icons.document_scanner_outlined),
                ),
              if (showLogo)
                IconButton(
                  tooltip: 'Importuj wyciąg CSV',
                  onPressed: onImportCsvTap,
                  icon: const Icon(Icons.upload_file_outlined),
                ),
              if (isShared)
                IconButton(
                  tooltip: 'Sprawiedliwy podział kosztów',
                  onPressed: onFairSplitTap,
                  icon: const Icon(Icons.balance_outlined),
                ),
              IconButton(
                tooltip: 'Ustawienia budżetu',
                onPressed: onBudgetSettingsTap,
                icon: const Icon(Icons.settings_outlined),
              ),
              IconButton(
                tooltip: 'Przełącz budżet',
                onPressed: onViewSwitch,
                icon: const Icon(Icons.swap_horiz_rounded),
              ),
              const ProfileMenuButton(),
            ],
          );
        },
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      color: AppColors.indigoSlate.withValues(alpha: 0.12),
    );
  }
}
