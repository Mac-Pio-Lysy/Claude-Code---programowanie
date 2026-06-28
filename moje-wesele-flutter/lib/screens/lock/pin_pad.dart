import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';

/// Klawiatura numeryczna z kropkami stanu — do wpisywania/weryfikacji PIN-u.
///
/// Komponent bezstanowy logicznie: rodzic przekazuje aktualny [value] i reaguje
/// na [onChanged]/[onCompleted]. Estetyka jasnoniebieska, spójna z aplikacją.
class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onCompleted,
    this.length = 4,
    this.error = false,
  });

  final String value;
  final int length;
  final bool error;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onCompleted;

  void _press(String digit) {
    if (value.length >= length) return;
    final next = value + digit;
    onChanged(next);
    if (next.length == length) onCompleted(next);
  }

  void _backspace() {
    if (value.isEmpty) return;
    onChanged(value.substring(0, value.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Kropki stanu
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                margin: const EdgeInsets.symmetric(horizontal: 9),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < value.length
                      ? (error ? const Color(0xFFC0392B) : AppColors.accent)
                      : Colors.transparent,
                  border: Border.all(
                    color: error
                        ? const Color(0xFFE9A8A8)
                        : (i < value.length
                            ? AppColors.accent
                            : const Color(0xFFC3D2EC)),
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 28),
        // Klawiatura
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [for (final d in row) _key(d)],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _spacer(),
              _key('0'),
              _key(null, icon: Icons.backspace_outlined, onTap: _backspace),
            ],
          ),
        ),
      ],
    );
  }

  Widget _spacer() => const SizedBox(width: 76, height: 76);

  Widget _key(String? digit, {IconData? icon, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.selectionClick();
            if (onTap != null) {
              onTap();
            } else if (digit != null) {
              _press(digit);
            }
          },
          child: Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFDCE4F2), width: 1.5),
            ),
            child: icon != null
                ? Icon(icon, color: AppColors.accent, size: 24)
                : Text(
                    digit!,
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
