import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_colors.dart';
import '../../models/vendor.dart';
import '../../models/wedding_data.dart';
import '../../services/firestore_service.dart';
import '../../services/vendor_service.dart';
import '../../utils/format.dart';
import '../budget/budget_fields.dart';
import 'vendor_form_sheet.dart';

/// Sekcja „Dostawcy" — lista z Firestore, powiązanie z budżetem, raty.
class VendorsScreen extends StatefulWidget {
  VendorsScreen({
    super.key,
    required this.data,
    required FirestoreService firestore,
  }) : service = VendorService(firestore: firestore);

  final WeddingData? data;
  final VendorService service;

  @override
  State<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends State<VendorsScreen> {
  String _categoryFilter = 'all';
  String _statusFilter = 'all';
  String _sort = 'none'; // none | name | status

  List<Vendor> get _vendors {
    final v = widget.data?.raw['vendors'];
    if (v is! List) return [];
    return v
        .whereType<Map>()
        .map((e) => Vendor(Map<String, dynamic>.from(e)))
        .toList();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _add() async {
    final draft = await showModalBottomSheet<VendorDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const VendorFormSheet(),
    );
    if (draft == null) return;
    await widget.service.addVendor(draft);
    _toast('Dodano dostawcę');
  }

  Future<void> _edit(Vendor vendor) async {
    final draft = await showModalBottomSheet<VendorDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VendorFormSheet(existing: vendor),
    );
    if (draft == null || vendor.id == null) return;
    await widget.service.updateVendor(vendor.id!, draft);
    _toast('Zapisano zmiany');
  }

  Future<void> _delete(Vendor vendor) async {
    final linked = vendor.isBudgetLinked && vendor.budgetExpenseId != null;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć dostawcę?'),
        content: Text(linked
            ? 'Dostawca „${vendor.label}" jest powiązany z wpisem w budżecie. '
                'Co zrobić z powiązanym wpisem?'
            : 'Czy na pewno usunąć „${vendor.label}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop('cancel'),
              child: const Text('Anuluj')),
          if (linked)
            TextButton(
              onPressed: () => Navigator.of(context).pop('keep'),
              child: const Text('Usuń, zostaw wpis'),
            ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC0392B)),
            onPressed: () => Navigator.of(context).pop('all'),
            child: Text(linked ? 'Usuń oba' : 'Usuń'),
          ),
        ],
      ),
    );
    if (result == null || result == 'cancel' || vendor.id == null) return;
    await widget.service
        .deleteVendor(vendor.id!, deleteLinkedExpense: result == 'all');
    _toast('Usunięto dostawcę');
  }

  @override
  Widget build(BuildContext context) {
    final vendors = _vendors;
    final filtered = vendors.where((v) {
      if (_categoryFilter != 'all' && v.category != _categoryFilter) {
        return false;
      }
      if (_statusFilter != 'all' && v.paymentStatus != _statusFilter) {
        return false;
      }
      return true;
    }).toList();
    if (_sort == 'name') {
      filtered.sort(
          (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    } else if (_sort == 'status') {
      int rank(Vendor v) =>
          VendorStatus.all.indexWhere((s) => s.value == v.paymentStatus);
      filtered.sort((a, b) => rank(a).compareTo(rank(b)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dostawcy',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text)),
              const SizedBox(height: 4),
              Container(
                width: 44,
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient:
                      const LinearGradient(colors: AppColors.dividerGradient),
                ),
              ),
              const SizedBox(height: 12),
              _filtersBar(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text('Brak dostawców.',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.textLight)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => _VendorCard(
                    key: ValueKey(filtered[i].id),
                    vendor: filtered[i],
                    service: widget.service,
                    onEdit: () => _edit(filtered[i]),
                    onDelete: () => _delete(filtered[i]),
                  ),
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _add,
                icon: const Icon(Icons.add),
                label: const Text('Dodaj dostawcę'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _filtersBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _chipRow([
          _chip('Wszyscy', _categoryFilter == 'all',
              () => setState(() => _categoryFilter = 'all')),
          for (final c in kVendorCategories)
            _chip(c, _categoryFilter == c,
                () => setState(() => _categoryFilter = c)),
        ]),
        const SizedBox(height: 8),
        _chipRow([
          _chip('Każdy status', _statusFilter == 'all',
              () => setState(() => _statusFilter = 'all')),
          for (final s in VendorStatus.all)
            _chip(s.label, _statusFilter == s.value,
                () => setState(() => _statusFilter = s.value)),
        ]),
        const SizedBox(height: 8),
        _chipRow([
          _chip('Bez sortowania', _sort == 'none',
              () => setState(() => _sort = 'none')),
          _chip('Wg nazwy (A–Z)', _sort == 'name',
              () => setState(() => _sort = 'name')),
          _chip('Wg statusu', _sort == 'status',
              () => setState(() => _sort = 'status')),
        ]),
      ],
    );
  }

  Widget _chipRow(List<Widget> chips) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final c in chips)
            Padding(padding: const EdgeInsets.only(right: 8), child: c),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: selected ? Colors.white : AppColors.textLight,
      ),
      selectedColor: AppColors.accent,
      backgroundColor: Colors.white,
      side: BorderSide(
          color: selected ? AppColors.accent : const Color(0xFFDCE4F2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

class _VendorCard extends StatefulWidget {
  const _VendorCard({
    super.key,
    required this.vendor,
    required this.service,
    required this.onEdit,
    required this.onDelete,
  });

  final Vendor vendor;
  final VendorService service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_VendorCard> createState() => _VendorCardState();
}

class _VendorCardState extends State<_VendorCard> {
  bool _expanded = false;

  Future<void> _launch(String scheme, String value) async {
    if (value.trim().isEmpty) return;
    final uri = scheme == 'url'
        ? Uri.tryParse(value.startsWith('http') ? value : 'https://$value')
        : Uri(scheme: scheme, path: value.replaceAll(' ', ''));
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vendor;
    final st = v.status;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _badge('🏢 Dostawca', const Color(0xFFEEF3FF),
                          AppColors.accent),
                      _badge(v.displayCategory, const Color(0xFFF1F5F9),
                          AppColors.textLight),
                      _badge(st.label, st.color.withValues(alpha: 0.15),
                          st.color),
                      if (v.isBudgetLinked)
                        _badge('💰 ${formatPlnZl(v.contractAmount)}',
                            const Color(0xFFF5F3FF), const Color(0xFF7C3AED)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.label,
                              style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text),
                            ),
                            if (v.contactName.isNotEmpty)
                              Text('👤 ${v.contactName}',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.textLight)),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: const Icon(Icons.keyboard_arrow_down,
                            color: AppColors.textLight),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) _details(v),
        ],
      ),
    );
  }

  Widget _details(Vendor v) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (v.phone.isNotEmpty)
                _actionChip(Icons.phone, v.phone,
                    () => _launch('tel', v.phone)),
              if (v.email.isNotEmpty)
                _actionChip(Icons.email_outlined, v.email,
                    () => _launch('mailto', v.email)),
              if (v.mapUrl.isNotEmpty)
                _actionChip(Icons.location_on_outlined, 'Mapa',
                    () => _launch('url', v.mapUrl)),
            ],
          ),
          if (v.price > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Cena: ${formatPlnZl(v.price)}',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          if (v.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(v.notes,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.text)),
            ),
          const SizedBox(height: 12),
          _installmentsSection(v),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edytuj'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Usuń'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC0392B),
                    side: const BorderSide(color: Color(0xFFE9A8A8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _installmentsSection(Vendor v) {
    final sums = v.installmentSums;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('💵 Raty / płatności',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
              ),
              TextButton.icon(
                onPressed: () =>
                    widget.service.addInstallment(v.id ?? 0),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Rata'),
                style: TextButton.styleFrom(foregroundColor: AppColors.accent),
              ),
            ],
          ),
          if (v.installments.isEmpty)
            Text('Brak rat.',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textLight))
          else
            for (final inst in v.installments)
              _InstallmentRow(
                key: ValueKey('vinst-${v.id}-${inst.id}'),
                vendorId: v.id ?? 0,
                inst: inst,
                service: widget.service,
              ),
          if (v.installments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Zapłacono: ${formatPlnZl(sums.paid)} · Pozostało: ${formatPlnZl(sums.remaining)} · Suma: ${formatPlnZl(sums.total)}',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF059669)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionChip(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF3FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.accent),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent)),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class _InstallmentRow extends StatelessWidget {
  const _InstallmentRow({
    super.key,
    required this.vendorId,
    required this.inst,
    required this.service,
  });

  final int vendorId;
  final VendorInstallment inst;
  final VendorService service;

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
      await service.updateInstallment(vendorId, _id, dueDate: d);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: BudgetTextField(
                  initial: inst.label,
                  hint: 'np. Zadatek',
                  onSaved: (v) =>
                      service.updateInstallment(vendorId, _id, label: v),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: BudgetNumberField(
                  suffix: 'zł',
                  compact: true,
                  initial: inst.amount,
                  onSaved: (v) =>
                      service.updateInstallment(vendorId, _id, amount: v),
                ),
              ),
              IconButton(
                onPressed: () => service.deleteInstallment(vendorId, _id),
                icon: const Icon(Icons.close, size: 18),
                color: const Color(0xFFC0392B),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(context),
                  child: InputDecorator(
                    decoration: _dec(),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 14, color: AppColors.textLight),
                        const SizedBox(width: 6),
                        Text(inst.dueDate.isEmpty ? 'Termin' : inst.dueDate,
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: inst.dueDate.isEmpty
                                    ? AppColors.textLight
                                    : AppColors.text)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: inst.isPaid ? 'paid' : 'due',
                  isExpanded: true,
                  decoration: _dec(),
                  items: const [
                    DropdownMenuItem(value: 'due', child: Text('Do zapłaty')),
                    DropdownMenuItem(value: 'paid', child: Text('Zapłacona')),
                  ],
                  onChanged: (v) =>
                      service.updateInstallment(vendorId, _id, status: v),
                ),
              ),
            ],
          ),
          const Divider(height: 14),
        ],
      ),
    );
  }

  InputDecoration _dec() => InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
