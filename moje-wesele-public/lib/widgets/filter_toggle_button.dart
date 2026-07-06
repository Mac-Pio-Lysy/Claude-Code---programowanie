import 'package:flutter/material.dart';

import '../app_colors.dart';

/// Mała strzałka/przycisk do chowania i pokazywania opcji filtrowania
/// i sortowania (ikona filtra + obracający się chevron).
class FilterToggleButton extends StatelessWidget {
  const FilterToggleButton({
    super.key,
    required this.expanded,
    required this.onTap,
  });

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: expanded ? 'Ukryj filtry' : 'Pokaż filtry',
      child: Material(
        color: expanded ? const Color(0xFFEEF3FF) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDCE4F2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.filter_list, size: 18, color: AppColors.accent),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.expand_more,
                      size: 18, color: AppColors.accent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
