import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/guest.dart';

/// Szybki filtr listy gości (jeden aktywny na raz).
enum GuestQuick { all, assigned, unassigned, groom, bride, witnesses }

/// Stan filtrów gości — WSPÓLNY dla podzakładek „Lista" i „Kartoteka",
/// dzięki czemu obie mają dokładnie te same opcje filtrowania/sortowania.
@immutable
class GuestFilter {
  const GuestFilter({
    this.quick = GuestQuick.all,
    this.category,
    this.witnessFirst = false,
  });

  /// Szybki filtr: wszyscy / przypisani / nieprzypisani / od Pana / od Panny /
  /// świadkowie.
  final GuestQuick quick;

  /// Kategoria (null = wszystkie).
  final String? category;

  /// Sortowanie: świadkowie na początku listy.
  final bool witnessFirst;

  GuestFilter copyWith({
    GuestQuick? quick,
    String? category,
    bool clearCategory = false,
    bool? witnessFirst,
  }) =>
      GuestFilter(
        quick: quick ?? this.quick,
        category: clearCategory ? null : (category ?? this.category),
        witnessFirst: witnessFirst ?? this.witnessFirst,
      );

  bool matches(Guest g) {
    switch (quick) {
      case GuestQuick.assigned:
        if (!g.isAssigned) return false;
      case GuestQuick.unassigned:
        if (g.isAssigned) return false;
      case GuestQuick.groom:
        if (g.invitedBy != 'groom') return false;
      case GuestQuick.bride:
        if (g.invitedBy != 'bride') return false;
      case GuestQuick.witnesses:
        if (g.witness == null) return false;
      case GuestQuick.all:
        break;
    }
    if (category != null && g.category != category) return false;
    return true;
  }
}

/// Filtruje i (opcjonalnie) sortuje gości wg [filter].
/// Sortowanie „świadkowie najpierw" jest stabilne — zachowuje pierwotną
/// kolejność w obrębie grup.
List<Guest> filterGuests(List<Guest> guests, GuestFilter filter) {
  final list = guests.where(filter.matches).toList();
  if (!filter.witnessFirst) return list;
  final witnesses = [for (final g in list) if (g.witness != null) g];
  final rest = [for (final g in list) if (g.witness == null) g];
  return [...witnesses, ...rest];
}

/// Wiersze filtrów gości (chipy) — używane w „Liście" i „Kartotece".
class GuestFilterControls extends StatelessWidget {
  const GuestFilterControls({
    super.key,
    required this.filter,
    required this.onChanged,
  });

  final GuestFilter filter;
  final ValueChanged<GuestFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row([
          _chip('Wszyscy', filter.quick == GuestQuick.all,
              () => onChanged(filter.copyWith(quick: GuestQuick.all))),
          _chip('Przypisani', filter.quick == GuestQuick.assigned,
              () => onChanged(filter.copyWith(quick: GuestQuick.assigned))),
          _chip('Nieprzypisani', filter.quick == GuestQuick.unassigned,
              () => onChanged(filter.copyWith(quick: GuestQuick.unassigned))),
          _chip('Od Pana Młodego', filter.quick == GuestQuick.groom,
              () => onChanged(filter.copyWith(quick: GuestQuick.groom))),
          _chip('Od Panny Młodej', filter.quick == GuestQuick.bride,
              () => onChanged(filter.copyWith(quick: GuestQuick.bride))),
          _chip('🤝 Świadkowie', filter.quick == GuestQuick.witnesses,
              () => onChanged(filter.copyWith(quick: GuestQuick.witnesses))),
        ]),
        const SizedBox(height: 8),
        _row([
          _chip('Wszyscy', filter.category == null,
              () => onChanged(filter.copyWith(clearCategory: true))),
          for (final c in const ['Rodzina', 'Znajomi', 'Praca', 'Inne'])
            _chip(c, filter.category == c,
                () => onChanged(filter.copyWith(category: c))),
        ]),
        const SizedBox(height: 8),
        _row([
          _chip('🤝 Świadkowie', filter.witnessFirst,
              () => onChanged(filter.copyWith(witnessFirst: !filter.witnessFirst))),
        ]),
      ],
    );
  }

  Widget _row(List<Widget> chips) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final c in chips)
            Padding(padding: const EdgeInsets.only(right: 8), child: c),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      labelStyle: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: selected ? Colors.white : AppColors.textLight,
      ),
      selectedColor: AppColors.accent,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? AppColors.accent : const Color(0xFFDCE4F2),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
