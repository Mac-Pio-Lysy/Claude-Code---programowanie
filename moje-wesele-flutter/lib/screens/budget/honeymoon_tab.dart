import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_colors.dart';
import '../../models/honeymoon_summary.dart';
import '../../models/wedding_data.dart';
import '../../services/budget_service.dart';
import '../../utils/format.dart';
import 'budget_fields.dart';

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
        _detailsCard(context, h),
        const SizedBox(height: 16),
        _installmentsCard(context, h),
      ],
    );
  }

  Widget _detailsCard(BuildContext context, HoneymoonSummary h) {
    return _card(
      title: '✈ Podróż poślubna',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BudgetTextField(
            key: const ValueKey('hm-name'),
            label: 'Nazwa / cel podróży',
            initial: h.name,
            onSaved: (v) => service.updateHoneymoon(name: v),
          ),
          const SizedBox(height: 12),
          BudgetTextField(
            key: const ValueKey('hm-link'),
            label: 'Link do oferty',
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
                label: const Text('Otwórz ofertę'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: BudgetNumberField(
                  key: const ValueKey('hm-total'),
                  label: 'Kwota ostateczna',
                  suffix: 'zł',
                  initial: h.totalAmount,
                  onSaved: (v) => service.updateHoneymoon(totalAmount: v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BudgetNumberField(
                  key: const ValueKey('hm-est'),
                  label: '~ Przewidywana',
                  suffix: 'zł',
                  initial: h.estimatedAmount,
                  onSaved: (v) => service.updateHoneymoon(estimatedAmount: v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _sum('Zapłacono', formatPlnZl(h.paid), const Color(0xFF059669)),
                _sum('Pozostało', '${formatPlnZl(h.remaining)}${h.isPredicted ? ' ~' : ''}',
                    const Color(0xFFEA580C)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _installmentsCard(BuildContext context, HoneymoonSummary h) {
    return _card(
      title: 'Harmonogram płatności',
      trailing: IconButton(
        onPressed: () => service.addHoneymoonInstallment(),
        icon: const Icon(Icons.add_circle_outline),
        color: AppColors.accent,
        tooltip: 'Dodaj ratę',
      ),
      child: h.installments.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text('Brak rat — dodaj harmonogram płatności.',
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
        const SnackBar(content: Text('Nie udało się otworzyć linku')),
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

class _InstallmentRow extends StatelessWidget {
  const _InstallmentRow({
    super.key,
    required this.inst,
    required this.service,
  });

  final HoneymoonInstallment inst;
  final BudgetService service;

  static const _paidByLabels = {
    'groom': 'Pan Młody',
    'bride': 'Panna Młoda',
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
                  suffix: 'zł',
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
                  items: const [
                    DropdownMenuItem(value: 'paid', child: Text('✓ Zapłacona')),
                    DropdownMenuItem(
                        value: 'pending', child: Text('○ Do zapłaty')),
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
