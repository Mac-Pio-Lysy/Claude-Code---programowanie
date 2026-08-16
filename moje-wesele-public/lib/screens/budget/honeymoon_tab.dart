import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_colors.dart';
import '../../models/couple.dart';
import '../../models/honeymoon_summary.dart';
import '../../models/wedding_data.dart';
import '../../services/budget_service.dart';
import '../../utils/format.dart';
import 'budget_fields.dart';
import '../../l10n/app_text.dart';
import '../../utils/app_format.dart';

/// Podzakładka „Podróż poślubna".
class HoneymoonTab extends StatelessWidget {
  const HoneymoonTab({super.key, required this.data, required this.service});

  final WeddingData? data;
  final BudgetService service;

  @override
  Widget build(BuildContext context) {
    final h = HoneymoonSummary.from(data);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        if (h.hasOptions)
          _variantsCard(context, h)
        else
          _classicCard(context, h),
        const SizedBox(height: 16),
        _paidCard(h),
        const SizedBox(height: 16),
        _installmentsCard(context, h),
      ],
    );
  }

  /// Klasyczny tryb (bez wariantów) — pojedyncza kwota orientacyjna.
  Widget _classicCard(BuildContext context, HoneymoonSummary h) {
    return _card(
      title: AppText.t.budget_honeymoonTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BudgetTextField(
            key: const ValueKey('hm-name'),
            label: AppText.t.budget_honeymoonName,
            initial: h.name,
            onSaved: (v) => service.updateHoneymoon(name: v),
          ),
          const SizedBox(height: 12),
          BudgetTextField(
            key: const ValueKey('hm-link'),
            label: AppText.t.budget_offerLink,
            hint: 'https://…',
            initial: h.link,
            onSaved: (v) => service.updateHoneymoon(link: v),
          ),
          if (h.link.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                onPressed: () => _openLink(context, h.link),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(AppText.t.budget_openOffer),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                ),
              ),
            ),
          const SizedBox(height: 12),
          BudgetNumberField(
            key: const ValueKey('hm-total'),
            label: AppText.t.budget_roughAmount,
            suffix: AppFormat.currency.symbol,
            initial: h.totalAmount,
            onSaved: (v) => service.updateHoneymoon(totalAmount: v),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => service.addHoneymoonOption(),
            icon: const Icon(Icons.add, size: 18),
            label: Text(AppText.t.budget_addVariant),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              AppText.t.budget_variantsHint,
              style:
                  GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
            ),
          ),
        ],
      ),
    );
  }

  /// Tryb wariantów — kilka propozycji, do budżetu wchodzi wybrana (lub
  /// najdroższa, gdy „wlicz droższą wersję").
  Widget _variantsCard(BuildContext context, HoneymoonSummary h) {
    final budgeted = h.budgetedOption;
    return _card(
      title: AppText.t.budget_variantsHeader,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.accent,
            value: h.useHigher,
            onChanged: (v) => service.setHoneymoonUseHigher(v),
            title: Text(AppText.t.budget_includeMoreExpensive,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: Text(AppText.t.budget_includeMoreExpensiveHint,
                style:
                    GoogleFonts.inter(fontSize: 11, color: AppColors.textLight)),
          ),
          const Divider(height: 16),
          for (final o in h.options)
            _OptionRow(
              key: ValueKey('hm-opt-${o.id}'),
              option: o,
              selected: budgeted?.id == o.id,
              selectable: !h.useHigher,
              service: service,
              onOpen: () => _openLink(context, o.link),
            ),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: () => service.addHoneymoonOption(),
            icon: const Icon(Icons.add, size: 18),
            label: Text(AppText.t.budget_addVariantShort),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCFE0FB)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 18, color: AppColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${AppText.t.budget_variantBudgeted(budgeted != null && budgeted.name.isNotEmpty ? budgeted.name : AppText.t.budget_variantNone)} · ${formatPlnZl(budgeted?.amount ?? 0)}',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paidCard(HoneymoonSummary h) {
    return _card(
      title: AppText.t.budget_payments,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _sum(AppText.t.budget_toBudget, formatPlnZl(h.effective),
                const Color(0xFF1D4ED8)),
            _sum(AppText.t.budget_alreadyPaid, formatPlnZl(h.paid), const Color(0xFF059669)),
            _sum(AppText.t.budget_left, formatPlnZl(h.remaining),
                const Color(0xFFEA580C)),
          ],
        ),
      ),
    );
  }

  Widget _installmentsCard(BuildContext context, HoneymoonSummary h) {
    return _card(
      title: AppText.t.budget_installments,
      trailing: IconButton(
        onPressed: () => service.addHoneymoonInstallment(),
        icon: const Icon(Icons.add_circle_outline),
        color: AppColors.accent,
        tooltip: AppText.t.budget_addInstallment,
      ),
      child: h.installments.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(AppText.t.budget_noInstallments,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textLight)),
            )
          : Column(
              children: [
                for (final inst in h.installments)
                  _InstallmentRow(
                    key: ValueKey('hm-inst-${inst.id}'),
                    inst: inst,
                    service: service,
                  ),
              ],
            ),
    );
  }

  Future<void> _openLink(BuildContext context, String link) async {
    var url = link.trim();
    if (!url.startsWith('http')) url = 'https://$url';
    final uri = Uri.tryParse(url);
    final ok = uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppText.t.budget_linkFailed)),
      );
    }
  }

  Widget _sum(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style:
                  GoogleFonts.inter(fontSize: 11, color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _card({required String title, Widget? trailing, required Widget child}) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Wiersz wariantu podróży poślubnej (nazwa, kwota, link, wybór do budżetu).
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    super.key,
    required this.option,
    required this.selected,
    required this.selectable,
    required this.service,
    required this.onOpen,
  });

  final HoneymoonOption option;
  final bool selected;
  final bool selectable;
  final BudgetService service;
  final VoidCallback onOpen;

  int get _id => option.id ?? 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: selected ? AppColors.accent : const Color(0xFFE2EAF7)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap:
                    selectable ? () => service.selectHoneymoonOption(_id) : null,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: selected ? AppColors.accent : AppColors.textLight,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: BudgetTextField(
                  initial: option.name,
                  hint: AppText.t.hm_variantName,
                  onSaved: (v) => service.updateHoneymoonOption(_id, name: v),
                ),
              ),
              IconButton(
                onPressed: () => service.deleteHoneymoonOption(_id),
                icon: const Icon(Icons.close, size: 18),
                color: const Color(0xFFC0392B),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: BudgetNumberField(
                  suffix: AppFormat.currency.symbol,
                  compact: true,
                  initial: option.amount,
                  onSaved: (v) =>
                      service.updateHoneymoonOption(_id, amount: v),
                ),
              ),
              if (option.link.isNotEmpty)
                IconButton(
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  color: AppColors.accent,
                  tooltip: AppText.t.budget_openOffer,
                ),
            ],
          ),
          const SizedBox(height: 6),
          BudgetTextField(
            initial: option.link,
            hint: AppText.t.hm_offerLink,
            onSaved: (v) => service.updateHoneymoonOption(_id, link: v),
          ),
        ],
      ),
    );
  }
}

class _InstallmentRow extends StatelessWidget {
  const _InstallmentRow({
    super.key,
    required this.inst,
    required this.service,
  });

  final HoneymoonInstallment inst;
  final BudgetService service;

  /// Kto płaci ratę. Klucze zapisywane w bazie zostają, etykiety wyliczamy
  /// z typu uroczystości (patrz [CoupleLabels]).
  static Map<String, String> get _paidByLabels => {
        'groom': CoupleLabels.current.person2,
        'bride': CoupleLabels.current.person1,
        'both': 'Oboje',
      };

  int get _id => inst.id ?? 0;

  Future<void> _pickDate(BuildContext context) async {
    final initial = DateTime.tryParse(inst.dueDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final d =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      await service.updateHoneymoonInstallment(_id, dueDate: d);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPaid = inst.isPaid;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isPaid ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isPaid ? const Color(0xFFBBF7D0) : const Color(0xFFE2EAF7)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: BudgetNumberField(
                  suffix: AppFormat.currency.symbol,
                  initial: inst.amount,
                  compact: true,
                  onSaved: (v) =>
                      service.updateHoneymoonInstallment(_id, amount: v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(context),
                  child: InputDecorator(
                    decoration: _dec(),
                    child: Text(
                      inst.dueDate.isEmpty ? 'Termin' : inst.dueDate,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: inst.dueDate.isEmpty
                            ? AppColors.textLight
                            : AppColors.text,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => service.deleteHoneymoonInstallment(_id),
                icon: const Icon(Icons.close, size: 18),
                color: const Color(0xFFC0392B),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _paidByLabels.containsKey(inst.paidBy)
                      ? inst.paidBy
                      : 'both',
                  isExpanded: true,
                  decoration: _dec(),
                  items: [
                    for (final e in _paidByLabels.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: (v) => service.updateHoneymoonInstallment(_id,
                      paidBy: v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: inst.status == 'paid' ? 'paid' : 'pending',
                  isExpanded: true,
                  decoration: _dec(),
                  items: [
                    // Wartości 'paid'/'pending' zostają — to zapis w bazie.
                    DropdownMenuItem(
                        value: 'paid',
                        child: Text(AppText.t.budget_installmentPaid)),
                    DropdownMenuItem(
                        value: 'pending',
                        child: Text(AppText.t.budget_installmentDue)),
                  ],
                  onChanged: (v) => service.updateHoneymoonInstallment(_id,
                      status: v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _dec() => InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDCE4F2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDCE4F2)),
        ),
      );
}
