import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/vehicle.dart';
import '../../services/transport_service.dart';
import '../../utils/format.dart';

/// Modalny formularz dodawania / edycji pojazdu.
class VehicleFormSheet extends StatefulWidget {
  const VehicleFormSheet({super.key, this.existing});

  final Vehicle? existing;

  @override
  State<VehicleFormSheet> createState() => _VehicleFormSheetState();
}

class _VehicleFormSheetState extends State<VehicleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _type;
  late final TextEditingController _driver;
  late final TextEditingController _route;
  late final TextEditingController _cost;

  late int _seats;
  String _departureTime = '';

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final v = widget.existing;
    _type = TextEditingController(text: v?.type ?? '');
    _driver = TextEditingController(text: v?.driver ?? '');
    _route = TextEditingController(text: v?.route ?? '');
    _cost = TextEditingController(
        text: (v == null || v.cost == 0) ? '' : _amt(v.cost));
    _seats = v?.seats ?? 4;
    _departureTime = v?.departureTime ?? '';
  }

  @override
  void dispose() {
    _type.dispose();
    _driver.dispose();
    _route.dispose();
    _cost.dispose();
    super.dispose();
  }

  String _amt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  Future<void> _pickTime() async {
    TimeOfDay initial = const TimeOfDay(hour: 12, minute: 0);
    final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(_departureTime);
    if (m != null) {
      initial = TimeOfDay(
          hour: int.parse(m.group(1)!), minute: int.parse(m.group(2)!));
    }
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        _departureTime =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      VehicleDraft(
        type: _type.text.trim(),
        description: '',
        driver: _driver.text.trim(),
        seats: _seats,
        route: _route.text.trim(),
        departureTime: _departureTime,
        cost: parsePln(_cost.text) ?? 0,
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
                  Text(_isEdit ? 'Edytuj pojazd' : 'Dodaj pojazd',
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text)),
                  const SizedBox(height: 16),
                  _label('Typ / nazwa pojazdu *'),
                  TextFormField(
                    controller: _type,
                    decoration: _dec(hint: 'np. Pojazd Kuby, Bus wynajęty'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Podaj typ/nazwę'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final t in kVehicleTypes)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text(t,
                                  style: GoogleFonts.inter(fontSize: 11)),
                              onPressed: () {
                                _type.text = t;
                                setState(() {});
                              },
                              backgroundColor: const Color(0xFFF1F5F9),
                              side: BorderSide.none,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _label('Kierowca'),
                  TextField(
                      controller: _driver,
                      decoration: _dec(hint: 'Imię kierowcy')),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Liczba miejsc'),
                            Row(
                              children: [
                                _stepper(Icons.remove, () {
                                  if (_seats > 1) setState(() => _seats--);
                                }),
                                Expanded(
                                  child: Text('$_seats',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.text)),
                                ),
                                _stepper(Icons.add, () {
                                  if (_seats < 60) setState(() => _seats++);
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Godzina odjazdu'),
                            InkWell(
                              onTap: _pickTime,
                              child: InputDecorator(
                                decoration: _dec(),
                                child: Row(
                                  children: [
                                    const Icon(Icons.schedule,
                                        size: 16, color: AppColors.textLight),
                                    const SizedBox(width: 8),
                                    Text(
                                        _departureTime.isEmpty
                                            ? 'Wybierz'
                                            : _departureTime,
                                        style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: _departureTime.isEmpty
                                                ? AppColors.textLight
                                                : AppColors.text)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _label('Trasa'),
                  TextField(
                      controller: _route,
                      decoration: _dec(hint: 'np. Kościół → Sala')),
                  const SizedBox(height: 14),
                  _label('Koszt (zł)'),
                  TextField(
                    controller: _cost,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: _dec(hint: '0', suffix: 'zł'),
                  ),
                  const SizedBox(height: 16),
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
