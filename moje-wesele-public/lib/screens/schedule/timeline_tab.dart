import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_colors.dart';
import '../../models/schedule_event.dart';
import '../../models/wedding_data.dart';
import '../../services/schedule_service.dart';
import 'event_form_sheet.dart';

/// Oś czasu dnia ślubu — wydarzenia posortowane po godzinie.
class TimelineTab extends StatelessWidget {
  const TimelineTab({super.key, required this.data, required this.service});

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

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _add(BuildContext context) async {
    final draft = await showModalBottomSheet<ScheduleEventDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const EventFormSheet(),
    );
    if (draft == null) return;
    await service.addEvent(draft);
    if (context.mounted) _toast(context, 'Dodano wydarzenie');
  }

  Future<void> _edit(BuildContext context, ScheduleEvent event) async {
    final draft = await showModalBottomSheet<ScheduleEventDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EventFormSheet(existing: event),
    );
    if (draft == null || event.id == null) return;
    await service.updateEvent(event.id!, draft);
    if (context.mounted) _toast(context, 'Zapisano zmiany');
  }

  Future<void> _delete(BuildContext context, ScheduleEvent event) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć wydarzenie?'),
        content: Text('Czy na pewno usunąć „${event.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Anuluj')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC0392B)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (ok != true || event.id == null) return;
    await service.deleteEvent(event.id!);
    if (context.mounted) _toast(context, 'Usunięto wydarzenie');
  }

  @override
  Widget build(BuildContext context) {
    final events = _events;
    return Column(
      children: [
        Expanded(
          child: events.isEmpty
              ? Center(
                  child: Text('Brak wydarzeń. Dodaj pierwsze poniżej.',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.textLight)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  itemCount: events.length,
                  itemBuilder: (context, i) => _EventCard(
                    key: ValueKey(events[i].id),
                    event: events[i],
                    onEdit: () => _edit(context, events[i]),
                    onDelete: () => _delete(context, events[i]),
                  ),
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _add(context),
                icon: const Icon(Icons.add),
                label: const Text('Dodaj wydarzenie'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EventCard extends StatefulWidget {
  const _EventCard({
    super.key,
    required this.event,
    required this.onEdit,
    required this.onDelete,
  });

  final ScheduleEvent event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  bool _expanded = false;

  Future<void> _openLink(String link) async {
    var url = link.trim();
    if (!url.startsWith('http')) url = 'https://$url';
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Oś czasu z kropką
          Column(
            children: [
              Text(e.timeLabel,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text)),
              const SizedBox(height: 4),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: e.cat.color),
              ),
              Expanded(child: Container(width: 2, color: const Color(0xFFE2EAF7))),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border(
                    left: BorderSide(color: e.cat.color, width: 4),
                    top: const BorderSide(color: Color(0xFFE2EAF7)),
                    right: const BorderSide(color: Color(0xFFE2EAF7)),
                    bottom: const BorderSide(color: Color(0xFFE2EAF7)),
                  ),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text('${e.cat.icon} ',
                                          style: const TextStyle(fontSize: 14)),
                                      Flexible(
                                        child: Text(
                                          e.name.isEmpty ? '(bez nazwy)' : e.name,
                                          style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.text),
                                        ),
                                      ),
                                      if (e.private)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 6),
                                          child: Text('🔒',
                                              style: TextStyle(fontSize: 12)),
                                        ),
                                      if (e.showLinkToGuests)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 4),
                                          child: Text('👁',
                                              style: TextStyle(fontSize: 12)),
                                        ),
                                    ],
                                  ),
                                  if (e.location.isNotEmpty ||
                                      e.responsible.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        [
                                          if (e.location.isNotEmpty)
                                            '📍 ${e.location}',
                                          if (e.responsible.isNotEmpty)
                                            '👤 ${e.responsible}',
                                        ].join('  ·  '),
                                        style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppColors.textLight),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            AnimatedRotation(
                              turns: _expanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 180),
                              child: const Icon(Icons.keyboard_arrow_down,
                                  color: AppColors.textLight),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_expanded)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(height: 12),
                            if (e.description.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(e.description,
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppColors.text)),
                              ),
                            if (e.locationUrl.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: OutlinedButton.icon(
                                  onPressed: () => _openLink(e.locationUrl),
                                  icon:
                                      const Icon(Icons.location_on, size: 16),
                                  label: const Text('Otwórz lokalizację'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.accent,
                                    side: const BorderSide(
                                        color: AppColors.accent),
                                  ),
                                ),
                              ),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: widget.onEdit,
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18),
                                    label: const Text('Edytuj'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.accent,
                                      side: const BorderSide(
                                          color: AppColors.accent),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: widget.onDelete,
                                    icon: const Icon(Icons.delete_outline,
                                        size: 18),
                                    label: const Text('Usuń'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFC0392B),
                                      side: const BorderSide(
                                          color: Color(0xFFE9A8A8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
