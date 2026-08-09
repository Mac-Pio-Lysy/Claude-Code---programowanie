import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../layout/responsive.dart';

/// Dane wprowadzone przy tworzeniu nowego wesela.
class NewWeddingDraft {
  NewWeddingDraft({required this.name, required this.persons, this.date});

  /// Nazwa wesela (`appConfig.eventName`).
  final String name;

  /// Osoby (`appConfig.displayNames`), np. „Ania i Piotr".
  final String persons;

  /// Data ślubu w formacie "YYYY-MM-DD" lub `null` (do uzupełnienia później).
  final String? date;
}

/// Otwiera arkusz tworzenia wesela. Zwraca [NewWeddingDraft] lub `null`
/// (gdy anulowano).
Future<NewWeddingDraft?> showCreateWeddingSheet(BuildContext context) {
  return showModalBottomSheet<NewWeddingDraft>(
    context: context,
    constraints: const BoxConstraints(maxWidth: kSheetMaxWidth),
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (context) => const _CreateWeddingSheet(),
  );
}

class _CreateWeddingSheet extends StatefulWidget {
  const _CreateWeddingSheet();

  @override
  State<_CreateWeddingSheet> createState() => _CreateWeddingSheetState();
}

class _CreateWeddingSheetState extends State<_CreateWeddingSheet> {
  final _nameCtrl = TextEditingController();
  final _personsCtrl = TextEditingController();
  DateTime? _date;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _personsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime(now.year + 1, now.month, now.day),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      helpText: 'Data ślubu',
      cancelText: 'Anuluj',
      confirmText: 'Wybierz',
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final persons = _personsCtrl.text.trim();
    final date = _date == null
        ? null
        : '${_date!.year.toString().padLeft(4, '0')}-'
            '${_date!.month.toString().padLeft(2, '0')}-'
            '${_date!.day.toString().padLeft(2, '0')}';
    Navigator.of(context).pop(
      NewWeddingDraft(
        name: name.isEmpty ? 'Nasze Wesele' : name,
        persons: persons,
        date: date,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCE4F2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Nowe wesele',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Podaj podstawowe informacje — resztę uzupełnisz później '
                  'w Ustawieniach.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 20),
                _label('Nazwa wesela'),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _decoration('np. Nasze Wesele'),
                ),
                const SizedBox(height: 16),
                _label('Osoby'),
                const SizedBox(height: 6),
                TextField(
                  controller: _personsCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoration('np. Ania i Piotr'),
                ),
                const SizedBox(height: 16),
                _label('Data ślubu (opcjonalnie)'),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: _decoration(''),
                    child: Row(
                      children: [
                        const Icon(Icons.event,
                            size: 20, color: AppColors.accent),
                        const SizedBox(width: 10),
                        Text(
                          _date == null
                              ? 'Wybierz datę (możesz później)'
                              : _dateLabel(_date!),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: _date == null
                                ? AppColors.textLight
                                : AppColors.text,
                          ),
                        ),
                        const Spacer(),
                        if (_date != null)
                          IconButton(
                            onPressed: () => setState(() => _date = null),
                            icon: const Icon(Icons.clear, size: 18),
                            color: AppColors.textLight,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textLight,
                          side: const BorderSide(color: Color(0xFFD7DEEC)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                        ),
                        child: Text(
                          'Utwórz wesele',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
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

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
      );

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: AppColors.textLight, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF8FAFF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDCE4F2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      );

  static String _dateLabel(DateTime date) {
    const months = [
      'stycznia', 'lutego', 'marca', 'kwietnia', 'maja', 'czerwca',
      'lipca', 'sierpnia', 'września', 'października', 'listopada', 'grudnia'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
