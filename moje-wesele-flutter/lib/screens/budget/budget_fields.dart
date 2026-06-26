import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../utils/format.dart';

/// Pole liczbowe zapisywane przy utracie fokusu / zatwierdzeniu.
/// Aktualizuje się ze zdalnych danych tylko, gdy użytkownik nie edytuje.
class BudgetNumberField extends StatefulWidget {
  const BudgetNumberField({
    super.key,
    required this.initial,
    required this.onSaved,
    this.label,
    this.suffix,
    this.integer = false,
    this.compact = false,
  });

  final double initial;
  final ValueChanged<num> onSaved;
  final String? label;
  final String? suffix;
  final bool integer;
  final bool compact;

  @override
  State<BudgetNumberField> createState() => _BudgetNumberFieldState();
}

class _BudgetNumberFieldState extends State<BudgetNumberField> {
  late final TextEditingController _ctrl;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _text(widget.initial));
    _focus.addListener(() {
      if (!_focus.hasFocus) _save();
    });
  }

  @override
  void didUpdateWidget(covariant BudgetNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focus.hasFocus && widget.initial != oldWidget.initial) {
      _ctrl.text = _text(widget.initial);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  String _text(double v) {
    if (v == 0) return '';
    if (widget.integer || v == v.roundToDouble()) return v.toInt().toString();
    return v.toString().replaceAll('.', ',');
  }

  void _save() {
    final parsed = parsePln(_ctrl.text) ?? 0;
    if (parsed != widget.initial) widget.onSaved(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: _ctrl,
      focusNode: _focus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _save(),
      style: GoogleFonts.inter(
        fontSize: widget.compact ? 14 : 16,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
      decoration: _decoration(hint: '0', suffix: widget.suffix),
    );

    if (widget.label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2),
          child: Text(
            widget.label!,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ),
        field,
      ],
    );
  }
}

/// Pole tekstowe zapisywane przy utracie fokusu / zatwierdzeniu.
class BudgetTextField extends StatefulWidget {
  const BudgetTextField({
    super.key,
    required this.initial,
    required this.onSaved,
    this.hint,
    this.label,
  });

  final String initial;
  final ValueChanged<String> onSaved;
  final String? hint;
  final String? label;

  @override
  State<BudgetTextField> createState() => _BudgetTextFieldState();
}

class _BudgetTextFieldState extends State<BudgetTextField> {
  late final TextEditingController _ctrl;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
    _focus.addListener(() {
      if (!_focus.hasFocus) _save();
    });
  }

  @override
  void didUpdateWidget(covariant BudgetTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focus.hasFocus && widget.initial != oldWidget.initial) {
      _ctrl.text = widget.initial;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _save() {
    if (_ctrl.text != widget.initial) widget.onSaved(_ctrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: _ctrl,
      focusNode: _focus,
      textCapitalization: TextCapitalization.sentences,
      onSubmitted: (_) => _save(),
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.text),
      decoration: _decoration(hint: widget.hint),
    );

    if (widget.label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2),
          child: Text(
            widget.label!,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ),
        field,
      ],
    );
  }
}

InputDecoration _decoration({String? hint, String? suffix}) => InputDecoration(
      hintText: hint,
      suffixText: suffix,
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFF8FAFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
