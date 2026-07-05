import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';

/// Klikalna plakietka „Dodano w: [sekcja]" — pokazywana przy rekordzie, który
/// został utworzony w innej sekcji (jedno źródło danych / SSOT) i tu tylko się
/// pokazuje. Kliknięcie prowadzi do sekcji źródłowej.
class AddedInChip extends StatelessWidget {
  const AddedInChip({super.key, required this.section, required this.onTap});

  final String section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 3, 4, 3),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF3FF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCFE0FB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link, size: 13, color: AppColors.accent),
            const SizedBox(width: 4),
            Text('Dodano w: $section',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent)),
            const Icon(Icons.chevron_right, size: 15, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}
