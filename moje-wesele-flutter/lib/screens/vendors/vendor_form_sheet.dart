import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/vendor.dart';
import '../../services/vendor_service.dart';
import '../../utils/format.dart';

/// Modalny formularz dodawania / edycji dostawcy.
class VendorFormSheet extends StatefulWidget {
  const VendorFormSheet({super.key, this.existing});

  final Vendor? existing;

  @override
  State<VendorFormSheet> createState() => _VendorFormSheetState();
}

class _VendorFormSheetState extends State<VendorFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _customCategory;
  late final TextEditingController _companyName;
  late final TextEditingController _contactName;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _price;
  late final TextEditingController _mapUrl;
  late final TextEditingController _notes;
  late final TextEditingController _contractAmount;

  late String _category;
  late String _paymentStatus;
  late String _budgetCategory;
  bool _isBudgetLinked = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final v = widget.existing;
    _category = v?.category ?? 'Fotograf';
    if (!kVendorCategories.contains(_category)) _category = 'Inne';
    _customCategory = TextEditingController(text: v?.customCategory ?? '');
    _companyName = TextEditingController(text: v?.companyName ?? '');
    _contactName = TextEditingController(text: v?.contactName ?? '');
    _phone = TextEditingController(text: v?.phone ?? '');
    _email = TextEditingController(text: v?.email ?? '');
    _price = TextEditingController(text: _amt(v?.price));
    _mapUrl = TextEditingController(text: v?.mapUrl ?? '');
    _notes = TextEditingController(text: v?.notes ?? '');
    _paymentStatus = v?.paymentStatus ?? 'contacted';
    if (!VendorStatus.all.any((s) => s.value == _paymentStatus)) {
      _paymentStatus = 'contacted';
    }
    _isBudgetLinked = v?.isBudgetLinked ?? false;
    // domyślnie kwota umowy = cena, jeśli nie ustawiono (jak w web)
    final cAmount = (v != null && v.contractAmount > 0)
        ? v.contractAmount
        : (v?.price ?? 0);
    _contractAmount = TextEditingController(text: _amt(cAmount));
    _budgetCategory = v?.budgetCategory.isNotEmpty == true
        ? v!.budgetCategory
        : 'Sala';
    if (!kVendorBudgetCategories.contains(_budgetCategory)) {
      _budgetCategory = 'Sala';
    }
  }

  @override
  void dispose() {
    _customCategory.dispose();
    _companyName.dispose();
    _contactName.dispose();
    _phone.dispose();
    _email.dispose();
    _price.dispose();
    _mapUrl.dispose();
    _notes.dispose();
    _contractAmount.dispose();
    super.dispose();
  }

  String _amt(double? v) {
    if (v == null || v == 0) return '';
    return v == v.roundToDouble()
        ? v.toInt().toString()
        : v.toString().replaceAll('.', ',');
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      VendorDraft(
        category: _category,
        customCategory:
            _category == 'Inne' ? _customCategory.text.trim() : '',
        companyName: _companyName.text.trim(),
        contactName: _contactName.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        price: parsePln(_price.text) ?? 0,
        paymentStatus: _paymentStatus,
        mapUrl: _mapUrl.text.trim(),
        notes: _notes.text.trim(),
        isBudgetLinked: _isBudgetLinked,
        contractAmount: parsePln(_contractAmount.text) ?? 0,
        budgetCategory: _budgetCategory,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7DEEC),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _isEdit ? 'Edytuj dostawcę' : 'Dodaj dostawcę',
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text),
                    ),
                  ),
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      children: [
                        _field(
                          'Kategoria',
                          DropdownButtonFormField<String>(
                            initialValue: _category,
                            isExpanded: true,
                            decoration: _dec(),
                            items: [
                              for (final c in kVendorCategories)
                                DropdownMenuItem(value: c, child: Text(c)),
                            ],
                            onChanged: (v) =>
                                setState(() => _category = v ?? _category),
                          ),
                        ),
                        if (_category == 'Inne')
                          _field(
                            'Własna kategoria',
                            TextField(
                              controller: _customCategory,
                              decoration: _dec(hint: 'np. Animator'),
                            ),
                          ),
                        _field(
                          'Nazwa firmy *',
                          TextFormField(
                            controller: _companyName,
                            decoration: _dec(hint: 'np. Studio Foto'),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Podaj nazwę firmy'
                                : null,
                          ),
                        ),
                        _field(
                          'Osoba kontaktowa',
                          TextField(
                            controller: _contactName,
                            decoration: _dec(hint: 'Imię i nazwisko'),
                          ),
                        ),
                        _field(
                          'Telefon',
                          TextField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: _dec(hint: 'np. 600 100 200'),
                          ),
                        ),
                        _field(
                          'Email',
                          TextField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _dec(hint: 'kontakt@firma.pl'),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _field('Cena (zł)',
                                  _numField(_price)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _field(
                                'Status płatności',
                                DropdownButtonFormField<String>(
                                  initialValue: _paymentStatus,
                                  isExpanded: true,
                                  decoration: _dec(),
                                  items: [
                                    for (final s in VendorStatus.all)
                                      DropdownMenuItem(
                                          value: s.value, child: Text(s.label)),
                                  ],
                                  onChanged: (v) => setState(
                                      () => _paymentStatus = v ?? 'contacted'),
                                ),
                              ),
                            ),
                          ],
                        ),
                        _field(
                          'Link do Google Maps',
                          TextField(
                            controller: _mapUrl,
                            keyboardType: TextInputType.url,
                            decoration: _dec(hint: 'https://maps…'),
                          ),
                        ),
                        _field(
                          'Notatki',
                          TextField(
                            controller: _notes,
                            maxLines: 2,
                            decoration: _dec(hint: 'Opcjonalnie…'),
                          ),
                        ),
                        const Divider(height: 24),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: AppColors.accent,
                          title: Text('💰 Powiąż z budżetem',
                              style: GoogleFonts.inter(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            'Tworzy/aktualizuje powiązany wpis w budżecie (referencja).',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: AppColors.textLight),
                          ),
                          value: _isBudgetLinked,
                          onChanged: (v) => setState(() => _isBudgetLinked = v),
                        ),
                        if (_isBudgetLinked) ...[
                          _field('Kwota umowy / szac. koszt (zł)',
                              _numField(_contractAmount)),
                          _field(
                            'Kategoria budżetowa',
                            DropdownButtonFormField<String>(
                              initialValue: _budgetCategory,
                              isExpanded: true,
                              decoration: _dec(),
                              items: [
                                for (final c in kVendorBudgetCategories)
                                  DropdownMenuItem(value: c, child: Text(c)),
                              ],
                              onChanged: (v) => setState(
                                  () => _budgetCategory = v ?? 'Sala'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textLight,
                                  side: const BorderSide(
                                      color: Color(0xFFD7DEEC)),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Anuluj'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(_isEdit ? 'Zapisz' : 'Dodaj'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _field(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 2),
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text)),
          ),
          child,
        ],
      ),
    );
  }

  Widget _numField(TextEditingController c) => TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: _dec(hint: '0', suffix: 'zł'),
      );

  InputDecoration _dec({String? hint, String? suffix}) => InputDecoration(
        hintText: hint,
        suffixText: suffix,
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF8FAFF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDCE4F2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDCE4F2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
      );
}
