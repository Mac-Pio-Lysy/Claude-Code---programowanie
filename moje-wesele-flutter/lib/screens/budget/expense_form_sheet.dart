import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/expense.dart';
import '../../services/budget_service.dart';
import '../../utils/format.dart';

/// Modalny formularz dodawania / edycji wydatku. Zwraca [ExpenseDraft].
class ExpenseFormSheet extends StatefulWidget {
  const ExpenseFormSheet({
    super.key,
    this.existing,
    required this.categories,
    required this.coupleNames,
  });

  final Expense? existing;
  final List<String> categories;
  final List<String> coupleNames;

  @override
  State<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<ExpenseFormSheet> {
  late final TextEditingController _customName;
  late final TextEditingController _planned;
  late final TextEditingController _estimated;
  late final TextEditingController _paid;
  late final TextEditingController _splitP1;
  late final TextEditingController _splitP2;
  late final TextEditingController _note;

  late String _category;
  String _paymentDate = '';

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _category = e?.category ?? 'Inne';
    if (!widget.categories.contains(_category)) {
      _category = widget.categories.contains('Inne')
          ? 'Inne'
          : widget.categories.first;
    }
    _customName = TextEditingController(text: e?.customName ?? '');
    _planned = TextEditingController(text: _amt(e?.planned));
    _estimated = TextEditingController(text: _amt(e?.estimatedAmount));
    _paid = TextEditingController(text: _amt(e?.paid));
    _splitP1 = TextEditingController(text: _amt(e?.splitP1));
    _splitP2 = TextEditingController(text: _amt(e?.splitP2));
    _note = TextEditingController(text: e?.note ?? '');
    _paymentDate = e?.paymentDate ?? '';
  }

  @override
  void dispose() {
    _customName.dispose();
    _planned.dispose();
    _estimated.dispose();
    _paid.dispose();
    _splitP1.dispose();
    _splitP2.dispose();
    _note.dispose();
    super.dispose();
  }

  String _amt(double? v) {
    if (v == null || v == 0) return '';
    return v == v.roundToDouble()
        ? v.toInt().toString()
        : v.toString().replaceAll('.', ',');
  }

  num _parse(TextEditingController c) => parsePln(c.text) ?? 0;

  Future<void> _pickDate() async {
    DateTime initial = DateTime.now();
    final parts = _paymentDate.split('-');
    if (parts.length == 3) {
      initial = DateTime.tryParse(_paymentDate) ?? DateTime.now();
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _paymentDate =
            '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  void _submit() {
    Navigator.of(context).pop(
      ExpenseDraft(
        category: _category,
        customName: _category == 'Inne' ? _customName.text.trim() : '',
        planned: _parse(_planned),
        estimatedAmount: _parse(_estimated),
        paid: _parse(_paid),
        paymentDate: _paymentDate,
        note: _note.text.trim(),
        splitP1: _parse(_splitP1),
        splitP2: _parse(_splitP2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final n1 = widget.coupleNames.isNotEmpty ? widget.coupleNames[0] : 'Osoba 1';
    final n2 =
        widget.coupleNames.length > 1 ? widget.coupleNames[1] : 'Osoba 2';

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
                      _isEdit ? 'Edytuj wydatek' : 'Dodaj wydatek',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ),
                Expanded(
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
                            for (final c in widget.categories)
                              DropdownMenuItem(
                                value: c,
                                child: Text('${ExpenseCategories.iconFor(c)} $c'),
                              ),
                          ],
                          onChanged: (v) =>
                              setState(() => _category = v ?? _category),
                        ),
                      ),
                      if (_category == 'Inne')
                        _field(
                          'Własna nazwa',
                          TextField(
                            controller: _customName,
                            decoration: _dec(hint: 'np. Atrakcje dla dzieci'),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: _field('Kwota ostateczna',
                                _numField(_planned, 'zł')),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field('Kwota przewidywana',
                                _numField(_estimated, 'zł')),
                          ),
                        ],
                      ),
                      _field('Opłacono', _numField(_paid, 'zł')),
                      _field(
                        'Data płatności',
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(10),
                          child: InputDecorator(
                            decoration: _dec(),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined,
                                    size: 18, color: AppColors.textLight),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _paymentDate.isEmpty
                                        ? 'Wybierz datę'
                                        : _paymentDate,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: _paymentDate.isEmpty
                                          ? AppColors.textLight
                                          : AppColors.text,
                                    ),
                                  ),
                                ),
                                if (_paymentDate.isNotEmpty)
                                  GestureDetector(
                                    onTap: () =>
                                        setState(() => _paymentDate = ''),
                                    child: const Icon(Icons.close,
                                        size: 18, color: AppColors.textLight),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Text(
                        'Podział kosztów',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(child: _field(n1, _numField(_splitP1, 'zł'))),
                          const SizedBox(width: 12),
                          Expanded(child: _field(n2, _numField(_splitP2, 'zł'))),
                        ],
                      ),
                      _field(
                        'Notatka',
                        TextField(
                          controller: _note,
                          maxLines: 2,
                          decoration: _dec(hint: 'Opcjonalnie…'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textLight,
                                side:
                                    const BorderSide(color: Color(0xFFD7DEEC)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(_isEdit ? 'Zapisz' : 'Dodaj'),
                            ),
                          ),
                        ],
                      ),
                    ],
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
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _numField(TextEditingController c, String suffix) => TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: _dec(hint: '0', suffix: suffix),
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
