import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/hotel.dart';
import '../../services/accommodation_service.dart';
import '../../utils/format.dart';

/// Modalny formularz dodawania / edycji hotelu.
class HotelFormSheet extends StatefulWidget {
  const HotelFormSheet({super.key, this.existing});

  final Hotel? existing;

  @override
  State<HotelFormSheet> createState() => _HotelFormSheetState();
}

class _HotelFormSheetState extends State<HotelFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _price;
  late final TextEditingController _bookingLink;
  late final TextEditingController _notes;

  late int _persons;
  bool _inComplex = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final h = widget.existing;
    _name = TextEditingController(text: h?.name ?? '');
    _address = TextEditingController(text: h?.address ?? '');
    _phone = TextEditingController(text: h?.phone ?? '');
    _price = TextEditingController(
        text: (h == null || h.pricePerNight == 0) ? '' : _amt(h.pricePerNight));
    _bookingLink = TextEditingController(text: h?.bookingLink ?? '');
    _notes = TextEditingController(text: h?.notes ?? '');
    _persons = h?.personsPerRoom ?? 2;
    _inComplex = h?.inComplex ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    _price.dispose();
    _bookingLink.dispose();
    _notes.dispose();
    super.dispose();
  }

  String _amt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      HotelDraft(
        name: _name.text.trim(),
        address: _address.text.trim(),
        phone: _phone.text.trim(),
        pricePerNight: parsePln(_price.text) ?? 0,
        personsPerRoom: _persons,
        bookingLink: _bookingLink.text.trim(),
        notes: _notes.text.trim(),
        inComplex: _inComplex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7DEEC),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(_isEdit ? 'Edytuj hotel' : 'Dodaj hotel',
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text)),
                  const SizedBox(height: 16),
                  _label('Nazwa hotelu *'),
                  TextFormField(
                    controller: _name,
                    decoration: _dec(hint: 'np. Hotel Pod Różą'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Podaj nazwę hotelu'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _label('Adres'),
                  TextField(
                      controller: _address, decoration: _dec(hint: 'Ulica, miasto')),
                  const SizedBox(height: 14),
                  _label('Telefon'),
                  TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: _dec(hint: 'np. 600 100 200')),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Cena za os./noc'),
                            TextField(
                              controller: _price,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              decoration: _dec(hint: '0', suffix: 'zł'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Osób w pokoju'),
                            Row(
                              children: [
                                _stepper(Icons.remove, () {
                                  if (_persons > 1) setState(() => _persons--);
                                }),
                                Expanded(
                                  child: Text('$_persons',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.text)),
                                ),
                                _stepper(Icons.add, () {
                                  if (_persons < 20) setState(() => _persons++);
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _label('Link do rezerwacji'),
                  TextField(
                      controller: _bookingLink,
                      keyboardType: TextInputType.url,
                      decoration: _dec(hint: 'https://…')),
                  const SizedBox(height: 14),
                  _label('Notatki'),
                  TextField(
                      controller: _notes,
                      maxLines: 2,
                      decoration: _dec(hint: 'Opcjonalnie…')),
                  const SizedBox(height: 4),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppColors.accent,
                    title: Text('🏰 Hotel w kompleksie wesela',
                        style: GoogleFonts.inter(fontSize: 14)),
                    value: _inComplex,
                    onChanged: (v) => setState(() => _inComplex = v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textLight,
                            side: const BorderSide(color: Color(0xFFD7DEEC)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 2),
        child: Text(text,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text)),
      );

  Widget _stepper(IconData icon, VoidCallback onTap) => Material(
        color: const Color(0xFFEEF3FF),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: AppColors.accent, size: 20),
          ),
        ),
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
