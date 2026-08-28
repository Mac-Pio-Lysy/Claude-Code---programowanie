import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A spreadsheet-style cell: shows plain text until tapped, then swaps in a
/// `TextField` for inline editing. Commits on Enter or on losing focus;
/// reverts silently on empty/invalid numeric input.
class EditableCell extends StatefulWidget {
  const EditableCell({
    super.key,
    required this.value,
    required this.onSubmit,
    this.isNumeric = false,
    this.style,
    this.textAlign = TextAlign.start,
  });

  final String value;
  final ValueChanged<String> onSubmit;
  final bool isNumeric;
  final TextStyle? style;
  final TextAlign textAlign;

  @override
  State<EditableCell> createState() => _EditableCellState();
}

class _EditableCellState extends State<EditableCell> {
  bool _editing = false;
  late final _controller = TextEditingController(text: widget.value);
  late final _focusNode = FocusNode()..addListener(_handleFocusChange);

  @override
  void didUpdateWidget(covariant EditableCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.value != widget.value) {
      _controller.text = widget.value;
    }
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus && _editing) _commit();
  }

  void _commit() {
    final newValue = _controller.text.trim();
    setState(() => _editing = false);

    if (newValue.isEmpty) {
      _controller.text = widget.value;
      return;
    }
    if (widget.isNumeric && double.tryParse(newValue.replaceAll(',', '.')) == null) {
      _controller.text = widget.value;
      return;
    }
    if (newValue != widget.value) {
      widget.onSubmit(widget.isNumeric ? newValue.replaceAll(',', '.') : newValue);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_editing) {
      return TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: true,
        textAlign: widget.textAlign,
        style: widget.style,
        keyboardType:
            widget.isNumeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        inputFormatters: widget.isNumeric
            ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))]
            : null,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 4),
        ),
        onSubmitted: (_) => _commit(),
      );
    }

    return InkWell(
      onTap: () => setState(() => _editing = true),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(widget.value, style: widget.style, textAlign: widget.textAlign),
      ),
    );
  }
}
