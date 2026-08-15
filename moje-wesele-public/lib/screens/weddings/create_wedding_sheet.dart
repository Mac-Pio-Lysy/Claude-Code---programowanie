import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../layout/responsive.dart';
import '../../models/couple.dart';
import '../../utils/app_format.dart';
import '../../l10n/app_text.dart';

/// Dane wprowadzone przy tworzeniu nowego wesela.
class NewWeddingDraft {
  NewWeddingDraft({
    required this.name,
    required this.persons,
    this.date,
    this.coupleType = CoupleType.mixed,
    this.person1 = '',
    this.person2 = '',
    this.withChildren = false,
    this.childrenCount = 0,
  });

  /// Nazwa wesela (`appConfig.eventName`).
  final String name;

  /// Osoby (`appConfig.displayNames`), np. „Ania i Piotr".
  final String persons;

  /// Data ślubu w formacie "YYYY-MM-DD" lub `null` (do uzupełnienia później).
  final String? date;

  /// Typ uroczystości — decyduje o etykietach pary i płci zakładanych rekordów.
  final CoupleType coupleType;

  /// Imiona Pary Młodej. Opcjonalne: puste = nie zakładamy rekordów gości.
  final String person1;
  final String person2;

  /// Czy na weselu będą dzieci (`budgetData.withChildren`).
  final bool withChildren;

  /// Orientacyjna liczba dzieci. 0 = nie podano — wtedy wesele liczy dzieci
  /// z listy gości (tryb `auto`).
  final int childrenCount;
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
  final _person1Ctrl = TextEditingController();
  final _person2Ctrl = TextEditingController();
  final _childrenCtrl = TextEditingController();
  DateTime? _date;
  CoupleType _coupleType = CoupleType.mixed;
  bool _withChildren = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _personsCtrl.dispose();
    _person1Ctrl.dispose();
    _person2Ctrl.dispose();
    _childrenCtrl.dispose();
    super.dispose();
  }

  /// Etykiety pól imion biorą się z typu uroczystości — te same, które potem
  /// widać w całej aplikacji.
  CoupleLabels get _labels => CoupleLabels(type: _coupleType);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime(now.year + 1, now.month, now.day),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      helpText: AppText.t.settings_weddingDate,
      cancelText: AppText.t.common_cancel,
      confirmText: AppText.t.common_select,
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final person1 = _person1Ctrl.text.trim();
    final person2 = _person2Ctrl.text.trim();

    // „Osoby" UZUPEŁNIAMY z imion tylko wtedy, gdy pole zostało puste — nigdy
    // nie nadpisujemy tego, co para wpisała sama. Ta wartość idzie do
    // `displayNames`, którego używa weryfikacja gościa i publiczny mirror.
    final typed = _personsCtrl.text.trim();
    final persons =
        typed.isNotEmpty ? typed : CoupleLabels.joinNames(person1, person2);

    final date = _date == null
        ? null
        : '${_date!.year.toString().padLeft(4, '0')}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}';
    Navigator.of(context).pop(
      NewWeddingDraft(
        name: name.isEmpty ? AppText.t.cw_defaultName : name,
        persons: persons,
        date: date,
        coupleType: _coupleType,
        person1: person1,
        person2: person2,
        withChildren: _withChildren,
        childrenCount: _withChildren
            ? (int.tryParse(_childrenCtrl.text.trim()) ?? 0)
            : 0,
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
                  AppText.t.cw_title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppText.t.cw_intro,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 20),
                _label(AppText.t.cw_name),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _decoration(AppText.t.cw_nameHint),
                ),
                const SizedBox(height: 16),
                _label(AppText.t.settings_coupleType),
                const SizedBox(height: 6),
                DropdownButtonFormField<CoupleType>(
                  initialValue: _coupleType,
                  isExpanded: true,
                  decoration: _decoration(''),
                  items: [
                    for (final t in CoupleType.values)
                      DropdownMenuItem(value: t, child: Text(t.label)),
                  ],
                  onChanged: (v) =>
                      setState(() => _coupleType = v ?? CoupleType.mixed),
                ),
                const SizedBox(height: 6),
                Text(
                  AppText.t.cw_coupleTypeHint(_coupleType.hint),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 16),
                _label(AppText.t.cw_names),
                const SizedBox(height: 6),
                Text(
                  AppText.t.cw_namesHint(_labels.coupleCategoryLabel),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _personField(_labels.person1, _person1Ctrl),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _personField(_labels.person2, _person2Ctrl),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _label(AppText.t.settings_persons),
                const SizedBox(height: 6),
                TextField(
                  controller: _personsCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoration(
                    CoupleLabels.joinNames(
                      _person1Ctrl.text,
                      _person2Ctrl.text,
                    ).isEmpty
                        ? AppText.t.cw_personsHint
                        : CoupleLabels.joinNames(
                            _person1Ctrl.text, _person2Ctrl.text),
                  ),
                ),
                const SizedBox(height: 16),
                _label(AppText.t.cw_dateOptional),
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
                              ? AppText.t.cw_pickDateLater
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
                const SizedBox(height: 8),
                // Dzieci na weselu (#8). Trafia do `budgetData.withChildren` —
                // tych samych pól używa Budżet → Sala, więc nic nie dublujemy.
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.accent,
                  title: Text(AppText.t.cw_children,
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    AppText.t.cw_childrenHint,
                    style: GoogleFonts.inter(
                        fontSize: 12, height: 1.4, color: AppColors.textLight),
                  ),
                  value: _withChildren,
                  onChanged: (v) => setState(() => _withChildren = v),
                ),
                if (_withChildren) ...[
                  const SizedBox(height: 8),
                  _label(AppText.t.cw_childrenCount),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _childrenCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _decoration(AppText.t.cw_childrenCountHint),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _childrenCtrl.text.trim().isEmpty
                        ? AppText.t.cw_childrenAuto
                        : AppText.t.cw_childrenManual,
                    style: GoogleFonts.inter(
                        fontSize: 12, height: 1.4, color: AppColors.textLight),
                  ),
                ],
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
                        child: Text(AppText.t.common_cancel),
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
                          AppText.t.cw_create,
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

  /// Pole imienia jednej z osób. `onChanged` odświeża podpowiedź w „Osoby",
  /// która składa się z obu imion.
  Widget _personField(String label, TextEditingController controller) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            decoration: _decoration(AppText.t.cw_firstName),
            onChanged: (_) => setState(() {}),
          ),
        ],
      );

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

  static String _dateLabel(DateTime date) =>
      AppFormat.dateLong(date);
}
