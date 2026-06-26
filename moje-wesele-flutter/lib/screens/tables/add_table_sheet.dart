import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../services/table_service.dart';

/// Modalny formularz dodawania stołu. Zwraca [TableDraft] przez `Navigator.pop`.
class AddTableSheet extends StatefulWidget {
  const AddTableSheet({super.key});

  @override
  State<AddTableSheet> createState() => _AddTableSheetState();
}

class _AddTableSheetState extends State<AddTableSheet> {
  final _name = TextEditingController();
  String _shape = 'round';
  int _seats = 8;
  bool _isHonor = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(
      TableDraft(
        name: _name.text.trim(),
        shape: _shape,
        seats: _seats,
        isHonor: _isHonor,
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
                Text(
                  'Dodaj stół',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 16),
                _label('Nazwa stołu'),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _decoration('np. Stół 1 (opcjonalnie)'),
                ),
                const SizedBox(height: 16),
                _label('Kształt'),
                Row(
                  children: [
                    _shapeOption('round', '⚪ Okrągły'),
                    const SizedBox(width: 10),
                    _shapeOption('rect', '▭ Prostokątny'),
                  ],
                ),
                const SizedBox(height: 16),
                _label('Liczba miejsc'),
                Row(
                  children: [
                    _stepperButton(Icons.remove, () {
                      if (_seats > 1) setState(() => _seats--);
                    }),
                    Expanded(
                      child: Text(
                        '$_seats',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    _stepperButton(Icons.add, () {
                      if (_seats < 99) setState(() => _seats++);
                    }),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.accent,
                  title: Text('⭐ Stół Pary Młodej (honorowy)',
                      style: GoogleFonts.inter(fontSize: 14)),
                  subtitle: _isHonor
                      ? Text('Używa układu prostokątnego',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.textLight))
                      : null,
                  value: _isHonor,
                  onChanged: (v) => setState(() => _isHonor = v),
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Dodaj stół'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 2),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
      );

  Widget _shapeOption(String value, String label) {
    final selected = _shape == value;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _shape = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEEF3FF) : const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.accent : const Color(0xFFDCE4F2),
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.accent : AppColors.textLight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: const Color(0xFFEEF3FF),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: AppColors.accent),
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF8FAFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      );
}
