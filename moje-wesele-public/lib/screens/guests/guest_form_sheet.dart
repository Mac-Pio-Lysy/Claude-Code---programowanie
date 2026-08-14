import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/couple.dart';
import '../../models/guest.dart';
import '../../services/guest_service.dart';

/// Modalny formularz dodawania / edycji gościa.
///
/// Zwraca [GuestDraft] przez `Navigator.pop`, gdy użytkownik zapisze formularz,
/// albo `null` po anulowaniu.
class GuestFormSheet extends StatefulWidget {
  const GuestFormSheet({
    super.key,
    this.existing,
    required this.menuOptions,
    this.coupleTaken = 0,
  });

  /// Edytowany gość (null = dodawanie nowego).
  final Guest? existing;

  /// Opcje menu/diety z konfiguracji.
  final List<String> menuOptions;

  /// Ile miejsc w kategorii Pary Młodej jest już zajętych (bez edytowanego
  /// gościa). Przy komplecie kategoria jest niedostępna w liście (#13).
  final int coupleTaken;

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

  /// Czy gość jest dzieckiem (#6).
  bool _isChild = false;

  /// Czy osoba towarzysząca jest dzieckiem — gość przychodzi z dzieckiem.
  bool _companionIsChild = false;

  /// Typ relacji osoby towarzyszącej (#3).
  String _companionRelation = CompanionRelation.unknown;

  /// „Imienia jeszcze nie znam" (#5) — rekord powstaje z nazwą zastępczą.
  bool _companionNamePending = false;

  /// Kategoria osoby towarzyszącej. `null` = dziedzicz po zapraszającym
  /// (z podpowiedzią wynikającą z typu relacji).
  String? _companionCategory;

  bool get _isEdit => widget.existing != null;

  /// Czy ten gość należy do Pary Młodej — wtedy nie ma osoby towarzyszącej
  /// (#12), bo drugą połowę pary dodaje się jako osobny wpis.
  bool get _isCouple => _category == CoupleLabels.coupleCategoryValue;

  /// Czy kategoria Pary Młodej jest jeszcze wolna (#13).
  bool get _coupleSlotFree =>
      widget.coupleTaken < CoupleLabels.maxCouple;

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
    _isChild = g?.isChild ?? false;

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

  /// Po oznaczeniu gościa jako dziecko podpowiada menu dziecięce.
  ///
  /// Tylko gdy menu nie jest jeszcze wybrane (nie nadpisujemy decyzji pary)
  /// i gdy taka pozycja w ogóle istnieje w konfiguracji — listę menu można
  /// dowolnie zmienić w Ustawieniach.
  void _suggestChildMenu(List<String> menus) {
    if (_menuChoice.isNotEmpty) return;
    if (!menus.contains(GuestOptions.childMenuOption)) return;
    _menuChoice = GuestOptions.childMenuOption;
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
      // Para Młoda nigdy nie wychodzi z formularza z „+1" (#12).
      hasCompanion: _isCouple ? false : _hasCompanion,
      // Przy „imię do potwierdzenia" nie przekazujemy danych osobowych —
      // serwis nada wtedy nazwę zastępczą.
      companionFirstName:
          _companionNamePending ? '' : _companionFirst.text.trim(),
      companionLastName:
          _companionNamePending ? '' : _companionLast.text.trim(),
      needsAccommodation: _needsAccommodation,
      companionRelation: _companionRelation,
      companionNamePending: _companionNamePending,
      companionCategory: _companionCategory,
      isChild: _isChild,
      companionIsChild: _isCouple ? false : _companionIsChild,
    );
    Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
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
                      _isEdit ? t.guests_formEditTitle : t.guests_formAddTitle,
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
                      padding: EdgeInsets.fromLTRB(
                          20, 8, 20, 20 + MediaQuery.paddingOf(context).bottom),
                      children: [
                        _field(
                          label: t.guests_formFirstName,
                          child: TextFormField(
                            controller: _firstName,
                            textCapitalization: TextCapitalization.words,
                            decoration: _inputDecoration(t.guests_formFirstNameHint),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? t.guests_formFirstNameRequired
                                : null,
                          ),
                        ),
                        _field(
                          label: t.guests_formLastName,
                          child: TextFormField(
                            controller: _lastName,
                            textCapitalization: TextCapitalization.words,
                            decoration: _inputDecoration(t.guests_formLastNameHint),
                          ),
                        ),
                        _field(
                          label: t.guests_formInvitedBy,
                          child: DropdownButtonFormField<String?>(
                            initialValue: _invitedBy,
                            decoration: _inputDecoration(null),
                            items: [
                              DropdownMenuItem(
                                  value: null, child: Text(t.guests_formChoose)),
                              // Kolejność „bride" przed „groom" bez znaczenia;
                              // etykiety idą z typu uroczystości.
                              DropdownMenuItem(
                                  value: 'groom',
                                  child: Text(
                                      GuestOptions.invitedByLabel('groom'))),
                              DropdownMenuItem(
                                  value: 'bride',
                                  child: Text(
                                      GuestOptions.invitedByLabel('bride'))),
                            ],
                            onChanged: (v) => setState(() => _invitedBy = v),
                          ),
                        ),
                        _field(
                          label: t.guests_formCategory,
                          child: DropdownButtonFormField<String>(
                            initialValue: _category,
                            decoration: _inputDecoration(null),
                            items: [
                              for (final c in GuestOptions.categories)
                                DropdownMenuItem(
                                  value: c,
                                  // Komplet Pary Młodej blokuje kategorię, ale
                                  // gość, który już do niej należy, musi móc
                                  // zostać zapisany bez zmiany kategorii.
                                  enabled: c !=
                                          CoupleLabels.coupleCategoryValue ||
                                      _coupleSlotFree ||
                                      _isCouple,
                                  // Wartość zostaje polska, etykieta tłumaczona.
                                  child: Text(GuestOptions.categoryLabel(c)),
                                ),
                            ],
                            onChanged: (v) => setState(() {
                              _category = v ?? _category;
                              // Para Młoda nie ma osoby towarzyszącej —
                              // gasimy przełącznik, żeby zapis nie odbił się
                              // o walidację w serwisie.
                              if (_isCouple) _hasCompanion = false;
                            }),
                          ),
                        ),
                        if (_category == CoupleLabels.coupleCategoryValue &&
                            !_coupleSlotFree &&
                            !_isEdit)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              t.guests_formCoupleLimit(CoupleLabels.maxCouple),
                              style: GoogleFonts.inter(
                                  fontSize: 11.5, color: AppColors.textLight),
                            ),
                          ),
                        _field(
                          label: t.guests_formGender,
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
                          label: t.guests_formRole,
                          child: DropdownButtonFormField<String?>(
                            initialValue: _witness,
                            decoration: _inputDecoration(null),
                            items: [
                              DropdownMenuItem(
                                  value: null, child: Text(t.guests_formNoRole)),
                              DropdownMenuItem(
                                  value: 'witness_groom',
                                  child: Text(
                                      GuestOptions.witnessLabel(
                                          'witness_groom'))),
                              DropdownMenuItem(
                                  value: 'witness_bride',
                                  child: Text(
                                      GuestOptions.witnessLabel(
                                          'witness_bride'))),
                            ],
                            onChanged: (v) => setState(() => _witness = v),
                          ),
                        ),
                        // Dziecko: flaga, nie kategoria — gość zostaje np.
                        // w „Rodzinie" i jednocześnie liczy się jako dziecko.
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: AppColors.accent,
                          title: Text(t.guests_formIsChild,
                              style: GoogleFonts.inter(fontSize: 14)),
                          subtitle: Text(
                            t.guests_formIsChildHint,
                            style: GoogleFonts.inter(
                                fontSize: 11.5, color: AppColors.textLight),
                          ),
                          value: _isChild,
                          onChanged: (v) => setState(() {
                            _isChild = v;
                            if (v) _suggestChildMenu(menus);
                          }),
                        ),
                        const SizedBox(height: 4),
                        _field(
                          label: t.guests_formDiet,
                          child: DropdownButtonFormField<String>(
                            initialValue:
                                menus.contains(_menuChoice) ? _menuChoice : '',
                            decoration: _inputDecoration(null),
                            items: [
                              DropdownMenuItem(
                                  value: '', child: Text(t.guests_formNoMenu)),
                              for (final m in menus)
                                DropdownMenuItem(
                                    value: m,
                                    child: Text(GuestOptions.menuLabel(m))),
                            ],
                            onChanged: (v) => setState(() => _menuChoice = v ?? ''),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Para Młoda nie ma „+1" (#12) — przełącznik zostaje
                        // widoczny, ale nieaktywny, z wyjaśnieniem dlaczego.
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: AppColors.accent,
                          title: Text(t.guests_companionSwitch,
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: _isCouple
                                      ? AppColors.textLight
                                      : AppColors.text)),
                          subtitle: _isCouple
                              ? Text(
                                  t.guests_companionForCouple(
                                      CoupleLabels.current.coupleCategoryLabel),
                                  style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      color: AppColors.textLight),
                                )
                              : null,
                          value: _isCouple ? false : _hasCompanion,
                          onChanged: _isCouple
                              ? null
                              : (v) => setState(() => _hasCompanion = v),
                        ),
                        if (_hasCompanion && !_isCouple) ...[
                          // ── Typ relacji (#3) ──
                          _field(
                            label: t.guests_companionRelation,
                            child: Wrap(
                              spacing: 8,
                              children: [
                                for (final r in CompanionRelation.all)
                                  ChoiceChip(
                                    label: Text(CompanionRelation.label(r)),
                                    selected: _companionRelation == r,
                                    showCheckmark: false,
                                    onSelected: (_) => setState(() {
                                      _companionRelation = r;
                                      // Podpowiedź kategorii — nadpisujemy tylko
                                      // wtedy, gdy użytkownik sam jej jeszcze
                                      // nie wybrał.
                                      final hint =
                                          CompanionRelation.suggestedCategory(r);
                                      if (hint != null &&
                                          _companionCategory == null) {
                                        _companionCategory = hint;
                                      }
                                    }),
                                    labelStyle: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: _companionRelation == r
                                          ? Colors.white
                                          : AppColors.textLight,
                                    ),
                                    selectedColor: AppColors.accent,
                                    backgroundColor: Colors.white,
                                    side: BorderSide(
                                        color: _companionRelation == r
                                            ? AppColors.accent
                                            : const Color(0xFFDCE4F2)),
                                  ),
                              ],
                            ),
                          ),
                          // ── Imię do potwierdzenia (#5) ──
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            activeThumbColor: AppColors.accent,
                            title: Text(t.guests_companionNameUnknown,
                                style: GoogleFonts.inter(fontSize: 14)),
                            subtitle: Text(
                              t.guests_companionNameUnknownHint,
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: AppColors.textLight),
                            ),
                            value: _companionNamePending,
                            onChanged: (v) =>
                                setState(() => _companionNamePending = v),
                          ),
                          if (!_companionNamePending) ...[
                            _field(
                              label: t.guests_companionFirstName,
                              child: TextFormField(
                                controller: _companionFirst,
                                textCapitalization: TextCapitalization.words,
                                decoration: _inputDecoration(t.guests_companionFirstNameHint),
                              ),
                            ),
                            _field(
                              label: t.guests_companionLastName,
                              child: TextFormField(
                                controller: _companionLast,
                                textCapitalization: TextCapitalization.words,
                                decoration: _inputDecoration('Nazwisko'),
                              ),
                            ),
                          ],
                          // ── Kategoria osoby towarzyszącej ──
                          _field(
                            label: t.guests_companionCategory,
                            child: DropdownButtonFormField<String>(
                              initialValue: _companionCategory ?? '',
                              isExpanded: true,
                              decoration: _inputDecoration(''),
                              items: [
                                DropdownMenuItem(
                                  value: '',
                                  child: Text(t.guests_companionInherit(
                                      GuestOptions.categoryLabel(_category))),
                                ),
                                for (final c in GuestOptions.categories)
                                  if (c != CoupleLabels.coupleCategoryValue)
                                    DropdownMenuItem(
                                        value: c,
                                        child:
                                            Text(GuestOptions.categoryLabel(c))),
                              ],
                              onChanged: (v) => setState(() =>
                                  _companionCategory =
                                      (v == null || v.isEmpty) ? null : v),
                            ),
                          ),
                          // Częsty przypadek: gość przychodzi z własnym
                          // dzieckiem. Flaga trafia na tworzony rekord
                          // towarzyszącej — dlatego tylko przy dodawaniu;
                          // przy edycji rekord już istnieje i oznacza się go
                          // wprost, na jego własnym formularzu.
                          if (!_isEdit)
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              activeThumbColor: AppColors.accent,
                              title: Text(t.guests_companionIsChild,
                                  style: GoogleFonts.inter(fontSize: 13)),
                              value: _companionIsChild,
                              onChanged: (v) =>
                                  setState(() => _companionIsChild = v),
                            ),
                          if (!_isEdit)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                t.guests_companionInfo,
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
                          title: Text(t.guests_formAccommodation,
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
                                child: Text(t.common_cancel),
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
