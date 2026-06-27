import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/wedding_data.dart';
import '../../services/firestore_service.dart';
import '../../services/guest_service.dart';
import 'guests_card_tab.dart';
import 'guests_screen.dart';
import 'guests_summary_tab.dart';

/// Sekcja „Goście" z podzakładkami: Lista, Kartoteka, Podsumowanie.
class GuestsSectionScreen extends StatelessWidget {
  GuestsSectionScreen({
    super.key,
    required this.data,
    required this.firestore,
  }) : service = GuestService(firestore: firestore);

  final WeddingData? data;
  final FirestoreService firestore;
  final GuestService service;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Goście',
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
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
                GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'Lista'),
              Tab(text: 'Kartoteka'),
              Tab(text: 'Podsumowanie'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                GuestsScreen(
                    data: data, firestore: firestore, embedded: true),
                GuestsCardTab(data: data, service: service),
                GuestsSummaryTab(data: data),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
