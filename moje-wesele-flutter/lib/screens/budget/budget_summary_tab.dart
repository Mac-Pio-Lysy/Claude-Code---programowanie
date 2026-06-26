import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/budget_summary.dart';
import '../../services/budget_service.dart';
import '../../utils/format.dart';

/// Podzakładka „Podsumowanie" budżetu.
class BudgetSummaryTab extends StatefulWidget {
  const BudgetSummaryTab({
    super.key,
    required this.summary,
    required this.service,
  });

  final BudgetSummary summary;
  final BudgetService service;

  @override
  State<BudgetSummaryTab> createState() => _BudgetSummaryTabState();
}

class _BudgetSummaryTabState extends State<BudgetSummaryTab> {
  late final TextEditingController _budgetCtrl;
  final FocusNode _budgetFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _budgetCtrl = TextEditingController(text: _budgetText(widget.summary.budget));
  }

  @override
  void didUpdateWidget(covariant BudgetSummaryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Zaktualizuj pole, gdy budżet zmienił się zdalnie, a użytkownik nie edytuje.
    if (!_budgetFocus.hasFocus &&
        widget.summary.budget != oldWidget.summary.budget) {
      _budgetCtrl.text = _budgetText(widget.summary.budget);
    }
  }

  @override
  void dispose() {
    _budgetCtrl.dispose();
    _budgetFocus.dispose();
    super.dispose();
  }

  String _budgetText(double value) => value == 0 ? '' : formatPln(value);

  Future<void> _saveBudget() async {
    final parsed = parsePln(_budgetCtrl.text);
    if (parsed == null) {
      _toast('Nieprawidłowa kwota');
      return;
    }
    _budgetFocus.unfocus();
    try {
      await widget.service.setTotalBudget(parsed);
      _toast('Zapisano budżet');
    } catch (e) {
      _toast('Błąd zapisu: $e');
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _budgetInputCard(),
          const SizedBox(height: 16),
          _progressCard(s),
          const SizedBox(height: 16),
          _valuesCard(s),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EAF7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _budgetInputCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budżet całkowity',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _budgetCtrl,
            focusNode: _budgetFocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveBudget(),
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
            decoration: InputDecoration(
              hintText: '0,00',
              suffixText: 'zł',
              filled: true,
              fillColor: const Color(0xFFF8FAFF),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDCE4F2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDCE4F2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.accent, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _saveBudget,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Zapisz budżet'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressCard(BudgetSummary s) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${s.paidPercentLabel}%',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'opłacono',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ProgressBar(
            confirmedFraction: s.confirmedFraction,
            effectiveFraction: s.effectiveFraction,
            paidFraction: s.paidFraction,
            planFraction: s.planFraction,
            hasEstimates: s.hasEstimates,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _legend(const Color(0xFF93C5FD), 'Plan: ${formatPlnZl(s.planForCalc)}'),
              _legend(const Color(0xFF059669), 'Opłacono: ${formatPlnZl(s.totalPaid)}'),
              _legend(const Color(0xFFCBD5E1), 'Budżet: ${formatPlnZl(s.budget)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
        ),
      ],
    );
  }

  Widget _valuesCard(BudgetSummary s) {
    return _card(
      child: Column(
        children: [
          _valueRow('Potwierdzone', formatPlnZl(s.totalConfirmed),
              const Color(0xFF1D4ED8)),
          if (s.catering > 0)
            _valueRow('w tym sala / catering', formatPlnZl(s.catering),
                AppColors.textLight,
                small: true),
          if (s.hasEstimates) ...[
            const Divider(height: 18),
            _valueRow('Przewidywane', '~ ${formatPlnZl(s.totalEffective)}',
                const Color(0xFFB45309)),
          ],
          if (s.expensesEstimated > 0)
            _valueRow('w tym szacunki wydatków',
                formatPlnZl(s.expensesEstimated), AppColors.textLight,
                small: true),
          const Divider(height: 18),
          _valueRow('Opłacono', formatPlnZl(s.totalPaid),
              const Color(0xFF059669)),
          const Divider(height: 18),
          _valueRow('Pozostało', formatPlnZl(s.remaining),
              const Color(0xFFEA580C)),
          const Divider(height: 18),
          _valueRow(
            'Budżet − plan',
            '${s.diff >= 0 ? '+' : ''}${formatPlnZl(s.diff)}',
            s.diff >= 0 ? const Color(0xFF059669) : const Color(0xFFC0392B),
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _valueRow(String label, String value, Color valueColor,
      {bool bold = false, bool small = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: small ? 2 : 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: small ? 12 : 14,
                color: small ? AppColors.textLight : AppColors.text,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: small ? 12 : 15,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pasek postępu: tło (budżet) → plan potwierdzony + szacunki → opłacono.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.confirmedFraction,
    required this.effectiveFraction,
    required this.paidFraction,
    required this.planFraction,
    required this.hasEstimates,
  });

  final double confirmedFraction;
  final double effectiveFraction;
  final double paidFraction;
  final double planFraction;
  final bool hasEstimates;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return SizedBox(
          height: 22,
          child: Stack(
            children: [
              // Tło (skala = budżet / przewidywane)
              Container(
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5EBF5),
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              // Część potwierdzona (plan)
              _segment(0, confirmedFraction * w, const Color(0xFF93C5FD)),
              // Szacunki (ponad potwierdzone)
              if (hasEstimates)
                _segment(
                  confirmedFraction * w,
                  (effectiveFraction - confirmedFraction) * w,
                  const Color(0xFFFCD34D),
                ),
              // Opłacono — węższy pasek na dole
              Positioned(
                left: 0,
                bottom: 0,
                child: Container(
                  height: 8,
                  width: paidFraction * w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // Znacznik planu
              Positioned(
                left: (planFraction * w).clamp(0, w - 2),
                top: 0,
                bottom: 0,
                child: Container(width: 2, color: const Color(0xFF1E293B)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _segment(double left, double width, Color color) {
    return Positioned(
      left: left,
      top: 0,
      child: Container(
        height: 22,
        width: width < 0 ? 0 : width,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(11),
        ),
      ),
    );
  }
}
