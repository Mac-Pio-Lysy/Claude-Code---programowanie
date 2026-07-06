import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../config/public_urls.dart';
import '../../models/wedding_data.dart';
import '../../navigation/app_sections.dart';
import '../../onboarding/tour_tab_sync.dart';
import '../../services/firestore_service.dart';
import '../../services/schedule_service.dart';
import '../../widgets/public_link_card.dart';
import 'checklist_tab.dart';
import 'guest_schedule_tab.dart';
import 'timeline_tab.dart';

/// Sekcja „Harmonogram" — oś czasu dnia ślubu + checklista.
class ScheduleScreen extends StatelessWidget {
  ScheduleScreen({
    super.key,
    required this.data,
    required FirestoreService firestore,
  }) : service = ScheduleService(firestore: firestore);

  final WeddingData? data;
  final ScheduleService service;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: TourTabSync(
        section: AppSection.schedule,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Harmonogram',
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
                IconButton(
                  tooltip: 'Kod QR dla gości',
                  onPressed: () {
                    final base = PublicPages.baseUrl(data?.raw);
                    showPublicLinkDialog(context, '📅 Harmonogram dnia ślubu',
                        PublicPages.harmonogram(base));
                  },
                  icon: const Icon(Icons.qr_code_2, color: AppColors.accent),
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
              Tab(text: 'Plan dnia'),
              Tab(text: 'Checklista'),
              Tab(text: 'Dla gości'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                TimelineTab(data: data, service: service),
                ChecklistTab(data: data, service: service),
                GuestScheduleTab(data: data, service: service),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}
