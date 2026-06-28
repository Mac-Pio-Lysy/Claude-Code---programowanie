import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../config/public_urls.dart';
import '../../models/schedule_event.dart';
import '../../models/wedding_data.dart';
import '../../services/schedule_service.dart';
import '../../widgets/public_link_card.dart';

/// Podzakładka „Dla gości" — podgląd harmonogramu widzianego przez gości
/// na stronie /harmonogram oraz sterowanie widocznością wydarzeń.
class GuestScheduleTab extends StatelessWidget {
  const GuestScheduleTab({super.key, required this.data, required this.service});

  final WeddingData? data;
  final ScheduleService service;

  List<ScheduleEvent> get _events {
    final list = [
      for (final e in data?.scheduleEvents ?? const [])
        if (e is Map) ScheduleEvent(Map<String, dynamic>.from(e)),
    ];
    list.sort((a, b) => a.sortKey.compareTo(b.sortKey));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final events = _events;
    final visible = events.where((e) => !e.private && e.name.isNotEmpty).toList();
    final base = PublicPages.baseUrl(data?.raw);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        PublicLinkCard(
          label: '📅 Harmonogram dnia ślubu',
          url: PublicPages.harmonogram(base),
        ),
        const SizedBox(height: 16),
        _previewCard(visible),
        const SizedBox(height: 16),
        _visibilityCard(events),
      ],
    );
  }

  Widget _previewCard(List<ScheduleEvent> visible) {
    return _card(
      'Podgląd dla gości (${visible.length})',
      visible.isEmpty
          ? Text('Żadne wydarzenie nie jest oznaczone jako widoczne dla gości.',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tak goście widzą harmonogram na stronie /harmonogram:',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textLight)),
                const SizedBox(height: 10),
                for (final e in visible) _previewRow(e),
              ],
            ),
    );
  }

  Widget _previewRow(ScheduleEvent e) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 46,
            child: Text(e.timeLabel,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent)),
          ),
          const SizedBox(width: 8),
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(shape: BoxShape.circle, color: e.cat.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${e.cat.icon} ${e.name}',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text)),
                if (e.location.isNotEmpty)
                  Text('📍 ${e.location}',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _visibilityCard(List<ScheduleEvent> events) {
    return _card(
      'Widoczność wydarzeń',
      events.isEmpty
          ? Text('Brak wydarzeń. Dodaj je w zakładce „Plan dnia".',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Zaznacz, które wydarzenia widzą goście.',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textLight)),
                const SizedBox(height: 4),
                for (final e in events)
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeThumbColor: AppColors.accent,
                    value: !e.private,
                    onChanged: (v) => service.setEventVisibility(e.id ?? 0, v),
                    title: Text(
                        '${e.timeLabel}  ${e.name.isEmpty ? '(bez nazwy)' : e.name}',
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text(!e.private ? 'Widoczne dla gości' : 'Ukryte',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: !e.private
                                ? const Color(0xFF059669)
                                : AppColors.textLight)),
                  ),
              ],
            ),
    );
  }

  Widget _card(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
