import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';

/// Pojedyncza podzakładka sekcji: etykieta + jej widok.
typedef SectionTab = ({String label, Widget view});

/// Wielokrotnego użytku szkielet sekcji z podzakładkami (nagłówek + TabBar +
/// TabBarView). Używany przez „Ślubne gry" i „Ślubne pamiątki" — dodanie nowej
/// gry/pamiątki sprowadza się do dopisania wpisu do listy [tabs].
class TabbedSectionScaffold extends StatelessWidget {
  const TabbedSectionScaffold({
    super.key,
    required this.title,
    required this.tabs,
  });

  /// Tytuł sekcji (nagłówek).
  final String title;

  /// Lista podzakładek (etykieta + widok).
  final List<SectionTab> tabs;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 44,
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(
                        colors: AppColors.dividerGradient),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textLight,
            indicatorColor: AppColors.accent,
            dividerColor: const Color(0xFFE2EAF7),
            labelStyle:
                GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle:
                GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
            tabs: [for (final t in tabs) Tab(text: t.label)],
          ),
          Expanded(
            child: TabBarView(
              children: [for (final t in tabs) t.view],
            ),
          ),
        ],
      ),
    );
  }
}
