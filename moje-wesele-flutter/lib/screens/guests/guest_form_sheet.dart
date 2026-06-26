import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/guest.dart';
import '../../services/guest_service.dart';

/// Modalny formularz dodawania / edycji gościa.
///
/// Zwraca [GuestDraft] przez `Navigator.pop`, gdy użytkownik zapisze formularz,
/// albo `null` po anulowaniu.
class GuestFormSheet extends StatefulWidget {
  const GuestFormSheet({super.key, this.existing, required this.menuOptions});

  /// Edytowany gość (null = dodawanie nowego).
  final Guest? existing;

  /// Opcje menu/diety z konfiguracji.
  final List<String> menuOptions;

  @override
  State<GuestFormSheet> createState() => _GuestFormSheetState();
}

class _GuestFormSheetState extends State<GuestFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _companionFirst;
  late final TextEditingController _companionLast;

  String? _invitedBy;
  late String _category;
  late String _gender;
  String? _witness;
  String _menuChoice = '';
  bool _hasCompanion = false;
  bool _needsAccommodation = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    _firstName = TextEditingController(text: g?.firstName ?? '');
    _lastName = TextEditingController(text: g?.lastName ?? '');
    _invitedBy = g?.invitedBy;
    _category = g?.category.isNotEmpty == true ? g!.category : 'Rodzina';
    if (!GuestOptions.categories.contains(_category)) _category = 'Rodzina';
    _gender = g?.gender ?? 'K';
    _witness = g?.witness;
    _menuChoice = g?.menuChoice ?? '';
    _hasCompanion = g?.hasCompanion ?? false;
    _needsAccommodation = g?.needsAccommodation ?? false;

    // Rozbij istniejące „imię nazwisko" osoby towarzyszącej na dwa pola.
    final comp = g?.companionName ?? '';
    final spaceIdx = comp.indexOf(' ');
    _companionFirst = TextEditingController(
      text: spaceIdx == -1 ? comp : comp.substring(0, spaceIdx),
    );
    _companionLast = TextEditingController(
      text: spaceIdx == -1 ? '' : comp.substring(spaceIdx + 1),
    );
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _companionFirst.dispose();
    _companionLast.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final draft = GuestDraft(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      invitedBy: _invitedBy,
      category: _category,
      gender: _gender,
      witness: _witness,
      menuChoice: _menuChoice,
      hasCompanion: _hasCompanion,
      companionFirstName: _companionFirst.text.trim(),
      companionLastName: _companionLast.text.trim(),
      needsAccommodation: _needsAccommodation,
    );
    Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    final menus = widget.menuOptions.isNotEmpty
        ? widget.menuOptions
        : GuestOptions.defaultMenuOptions;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
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
                      _isEdit ? 'Edytuj gościa' : 'Dodaj gościa',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
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
                          label: 'Imię *',
                          child: TextFormField(
                            controller: _firstName,
                            textCapitalization: TextCapitalization.words,
                            decoration: _inputDecoration('np. Anna'),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Podaj imię gościa'
                                : null,
                          ),
                        ),
                        _field(
                          label: 'Nazwisko',
                          child: TextFormField(
                            controller: _lastName,
                            textCapitalization: TextCapitalization.words,
                            decoration: _inputDecoration('np. Kowalska'),
                          ),
                        ),
                        _field(
                          label: 'Zaproszony przez',
                          child: DropdownButtonFormField<String?>(
                            initialValue: _invitedBy,
                            decoration: _inputDecoration(null),
                            items: const [
                              DropdownMenuItem(value: null, child: Text('— wybierz —')),
                              DropdownMenuItem(value: 'groom', child: Text('🤵 Pan Młody')),
                              DropdownMenuItem(value: 'bride', child: Text('👰 Panna Młoda')),
                            ],
                            onChanged: (v) => setState(() => _invitedBy = v),
                          ),
                        ),
                        _field(
                          label: 'Kategoria',
                          child: DropdownButtonFormField<String>(
                            initialValue: _category,
                            decoration: _inputDecoration(null),
                            items: [
                              for (final c in GuestOptions.categories)
                                DropdownMenuItem(value: c, child: Text(c)),
                            ],
                            onChanged: (v) =>
                                setState(() => _category = v ?? _category),
                          ),
                        ),
                        _field(
                          label: 'Płeć',
                          child: DropdownButtonFormField<String>(
                            initialValue: _gender,
                            decoration: _inputDecoration(null),
                            items: const [
                              DropdownMenuItem(value: 'K', child: Text('♀ Kobieta')),
                              DropdownMenuItem(value: 'M', child: Text('♂ Mężczyzna')),
                              DropdownMenuItem(value: 'N', child: Text('⚧ Niebinarna')),
                            ],
                            onChanged: (v) => setState(() => _gender = v ?? _gender),
                          ),
                        ),
                        _field(
                          label: 'Rola',
                          child: DropdownButtonFormField<String?>(
                            initialValue: _witness,
                            decoration: _inputDecoration(null),
                            items: const [
                              DropdownMenuItem(value: null, child: Text('Brak roli')),
                              DropdownMenuItem(
                                  value: 'witness_groom', child: Text('Świadek')),
                              DropdownMenuItem(
                                  value: 'witness_bride', child: Text('Świadkowa')),
                            ],
                            onChanged: (v) => setState(() => _witness = v),
                          ),
                        ),
                        _field(
                          label: 'Dieta / menu',
                          child: DropdownButtonFormField<String>(
                            initialValue:
                                menus.contains(_menuChoice) ? _menuChoice : '',
                            decoration: _inputDecoration(null),
                            items: [
                              const DropdownMenuItem(value: '', child: Text('— brak —')),
                              for (final m in menus)
                                DropdownMenuItem(value: m, child: Text(m)),
                            ],
                            onChanged: (v) => setState(() => _menuChoice = v ?? ''),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: AppColors.accent,
                          title: Text('👥 Z osobą towarzyszącą?',
                              style: GoogleFonts.inter(fontSize: 14)),
                          value: _hasCompanion,
                          onChanged: (v) => setState(() => _hasCompanion = v),
                        ),
                        if (_hasCompanion) ...[
                          _field(
                            label: 'Imię os. towarzyszącej',
                            child: TextFormField(
                              controller: _companionFirst,
                              textCapitalization: TextCapitalization.words,
                              decoration: _inputDecoration('Imię'),
                            ),
                          ),
                          _field(
                            label: 'Nazwisko os. towarzyszącej',
                            child: TextFormField(
                              controller: _companionLast,
                              textCapitalization: TextCapitalization.words,
                              decoration: _inputDecoration('Nazwisko'),
                            ),
                          ),
                          if (!_isEdit)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Po podaniu danych osoba towarzysząca zostanie dodana '
                                'jako osobny gość (jak w wersji web).',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ),
                        ],
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: AppColors.accent,
                          title: Text('🏨 Potrzebuje noclegu',
                              style: GoogleFonts.inter(fontSize: 14)),
                          value: _needsAccommodation,
                          onChanged: (v) =>
                              setState(() => _needsAccommodation = v),
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

  Widget _field({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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

  InputDecoration _inputDecoration(String? hint) => InputDecoration(
        hintText: hint,
        isDense: true,
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
      );
}
