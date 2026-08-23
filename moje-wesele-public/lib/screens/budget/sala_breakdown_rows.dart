import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/sala_summary.dart';
import '../../utils/format.dart';
import '../../l10n/app_text.dart';

/// Rozbicie kosztu Sali na składniki (goście, obsługa, dodatki, dekoracje,
/// catering oddzielny) — WSPÓLNE dla podzakładki „Sala" (`sala_tab.dart`)
/// i podsumowania budżetu (`budget_summary_tab.dart`), żeby ta sama lista
/// wierszy nie żyła w dwóch miejscach osobno.
class SalaBreakdownRows extends StatelessWidget {
  const SalaBreakdownRows({
    super.key,
    required this.s,
    this.showTotal = true,
    this.compact = false,
  });

  final SalaSummary s;

  /// Czy pokazać wiersz z sumą całkowitą na dole (z dzielnikiem nad nim).
  /// W podsumowaniu budżetu suma jest już pokazana osobno wyżej jako
  /// „z tego Sala" — tam wyłączamy, żeby nie dublować.
  final bool showTotal;

  /// Mniejsza czcionka — do osadzenia jako wcięty podpunkt (np. pod wierszem
  /// „z tego Sala" w podsumowaniu budżetu).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row(AppText.t.budget_guestsCostCount(s.effectiveGuestCount.round()),
            formatPlnZl(s.guestCost)),
        if (s.childMenuSeparate && s.childBilledCount > 0)
          _row('w tym menu dzieci (${s.childBilledCount.round()} os.)',
              formatPlnZl(s.childMenuTotal)),
        if (s.virtualGuests > 0)
          _row(AppText.t.budget_virtualCostCount(s.virtualGuests.round()),
              formatPlnZl(s.virtualCost)),
        _row(
            s.staffCalcMode != StaffCalcMode.headcount
                ? AppText.t.budget_staffCost
                : s.includeStaff
                    ? AppText.t.budget_staffCostCount(
                        s.staffCostPersonCount.round())
                    : AppText.t.budget_staffCostCountExcluded(
                        s.staffCostPersonCount.round()),
            formatPlnZl(s.staffCost)),
        _row(AppText.t.sala_menuExtras, formatPlnZl(s.menuAddonsTotal)),
        _row(AppText.t.budget_tableDecorTotal, formatPlnZl(s.tableDecoTotal)),
        if (s.cateringSeparate)
          _row(AppText.t.sala_separateCatering,
              formatPlnZl(s.cateringSeparateTotal)),
        if (showTotal) ...[
          const Divider(height: 20),
          _row(AppText.t.sala_venueTotal, formatPlnZl(s.cateringTotal),
              bold: true, big: true),
        ],
      ],
    );
  }

  Widget _row(String label, String value, {bool bold = false, bool big = false}) {
    final baseLabelSize = big ? 14.0 : 13.0;
    final baseValueSize = big ? 17.0 : 14.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: compact ? baseLabelSize - 1.5 : baseLabelSize,
                color: bold ? AppColors.text : AppColors.textLight,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: compact ? baseValueSize - 2 : baseValueSize,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: bold ? AppColors.accent : AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
