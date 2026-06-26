import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/budget_summary.dart';
import '../../models/wedding_data.dart';
import '../../models/beverage.dart';
import '../../services/budget_service.dart';
import '../../services/firestore_service.dart';
import 'beverage_tab.dart';
import 'budget_summary_tab.dart';
import 'expenses_tab.dart';
import 'honeymoon_tab.dart';
import 'payments_tab.dart';
import 'sala_tab.dart';

/// Sekcja „Budżet" z podzakładkami. Na razie pełna jest „Podsumowanie",
/// reszta to placeholdery (kolejne podzakładki w następnych częściach).
class BudgetScreen extends StatelessWidget {
  BudgetScreen({
    super.key,
    required this.data,
    required FirestoreService firestore,
  }) : service = BudgetService(firestore: firestore);

  final WeddingData? data;
  final BudgetService service;

  static const _tabs = [
    'Podsumowanie',
    'Sala',
    'Wydatki',
    'Alkohol',
    'Napoje bezalkoholowe',
    'Podróż poślubna',
    'Płatności',
  ];

  @override
  Widget build(BuildContext context) {
    final summary = BudgetSummary.from(data);

    return DefaultTabController(
      length: _tabs.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Budżet',
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
                    gradient:
                        const LinearGradient(colors: AppColors.dividerGradient),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
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
            tabs: [for (final t in _tabs) Tab(text: t)],
          ),
          Expanded(
            child: TabBarView(
              children: [
                BudgetSummaryTab(summary: summary, service: service),
                SalaTab(data: data, service: service),
                ExpensesTab(data: data, service: service),
                BeverageTab(
                    kind: BeverageKind.alcohol, data: data, service: service),
                BeverageTab(
                    kind: BeverageKind.soft, data: data, service: service),
                HoneymoonTab(data: data, service: service),
                PaymentsTab(data: data),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
