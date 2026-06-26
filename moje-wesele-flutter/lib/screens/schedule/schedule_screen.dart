import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/wedding_data.dart';
import '../../services/firestore_service.dart';
import '../../services/schedule_service.dart';
import 'checklist_tab.dart';
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
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
          const SizedBox(height: 8),
          TabBar(
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textLight,
            indicatorColor: AppColors.accent,
            dividerColor: const Color(0xFFE2EAF7),
            labelStyle:
                GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'Plan dnia'),
              Tab(text: 'Checklista'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                TimelineTab(data: data, service: service),
                ChecklistTab(data: data, service: service),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
