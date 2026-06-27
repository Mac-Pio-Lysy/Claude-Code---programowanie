import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../config/public_urls.dart';
import '../../models/guest.dart';
import '../../models/rsvp_entry.dart';
import '../../models/wedding_data.dart';
import '../../services/firestore_service.dart';
import '../../services/rsvp_service.dart';
import '../../widgets/public_link_card.dart';

/// Sekcja „Potwierdzenia" (panel RSVP organizatora).
class RsvpScreen extends StatelessWidget {
  RsvpScreen({
    super.key,
    required this.data,
    required FirestoreService firestore,
  }) : service = RsvpService(firestore: firestore);

  final WeddingData? data;
  final RsvpService service;

  List<Guest> get _guests => [
        for (final e in data?.guests ?? const [])
          if (e is Map) Guest(Map<String, dynamic>.from(e)),
      ];

  List<RsvpEntry> get _entries => [
        for (final e in data?.raw['rsvpEntries'] ?? const [])
          if (e is Map) RsvpEntry(Map<String, dynamic>.from(e)),
      ];

  @override
  Widget build(BuildContext context) {
    final guests = _guests;
    final entries = _entries;
    // Ostatni status per gość.
    final statusByGuest = <int, String>{};
    for (final e in entries) {
      if (e.guestId != null) statusByGuest[e.guestId!] = e.status;
    }
    final unmatched = entries.where((e) => e.isUnmatched).toList();

    final attending =
        entries.where((e) => e.guestId != null && e.isAttending).length;
    final notAtt =
        entries.where((e) => e.guestId != null && e.isNotAttending).length;
    final noReply = guests
        .where((g) =>
            g.category != 'Państwo Młodzi' &&
            !statusByGuest.containsKey(g.id))
        .length;

    final listGuests =
        guests.where((g) => g.category != 'Państwo Młodzi').toList();
    final baseUrl = PublicPages.baseUrl(data?.raw);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: Text('Potwierdzenia',
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
              ),
              IconButton(
                tooltip: 'Wyczyść wszystkie',
                onPressed: () => _confirmClearAll(context),
                icon: const Icon(Icons.delete_sweep_outlined,
                    color: Color(0xFFC0392B)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: [
              _summary(attending, notAtt, noReply),
              const SizedBox(height: 16),
              if (entries.isEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: Text(
                    'Brak potwierdzeń. Udostępnij gościom kod QR (na dole tej '
                    'sekcji) lub link do strony /rsvp, aby zbierać potwierdzenia. '
                    'Możesz też ręcznie ustawić status każdego gościa poniżej.',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: const Color(0xFF92400E)),
                  ),
                ),
              if (unmatched.isNotEmpty) ...[
                Text('Nierozpoznane potwierdzenia (${unmatched.length})',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFB45309))),
                const SizedBox(height: 6),
                for (final e in unmatched)
                  _unmatchedRow(context, e, guests),
                const SizedBox(height: 16),
              ],
              Text('Goście',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text)),
              const SizedBox(height: 6),
              for (final g in listGuests)
                _guestRow(context, g, statusByGuest[g.id]),
              const SizedBox(height: 16),
              _qrCard(context, baseUrl),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summary(int attending, int notAtt, int noReply) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EAF7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _stat('$attending', 'Przyjdą', const Color(0xFF059669)),
          _stat('$notAtt', 'Nie przyjdą', const Color(0xFFC0392B)),
          _stat('$noReply', 'Brak odpowiedzi', const Color(0xFFB45309)),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.inter(fontSize: 11, color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _guestRow(BuildContext context, Guest g, String? status) {
    Color badgeColor;
    String badgeText;
    if (status == 'attending') {
      badgeColor = const Color(0xFF059669);
      badgeText = '✓ Przyjdzie';
    } else if (status == 'not_attending') {
      badgeColor = const Color(0xFFC0392B);
      badgeText = '✗ Nie przyjdzie';
    } else {
      badgeColor = AppColors.textLight;
      badgeText = 'Brak odpowiedzi';
    }
    final gid = g.id ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.accent,
                child: Text(g.initials.toUpperCase(),
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(g.fullName.isEmpty ? '(bez imienia)' : g.fullName,
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(badgeText,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: badgeColor)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _btn('Przyjdzie', const Color(0xFF059669),
                  () => service.setGuestStatus(gid, 'attending')),
              const SizedBox(width: 6),
              _btn('Nie przyjdzie', const Color(0xFFC0392B),
                  () => service.setGuestStatus(gid, 'not_attending')),
              const Spacer(),
              if (status != null)
                TextButton(
                  onPressed: () => service.clearGuestStatus(gid),
                  child: const Text('Wyczyść'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _btn(String label, Color color, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        textStyle:
            GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }

  Widget _unmatchedRow(BuildContext context, RsvpEntry e, List<Guest> guests) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${e.rawName.isEmpty ? '(brak imienia)' : e.rawName} → ${e.isAttending ? 'Przyjdzie' : 'Nie przyjdzie'}',
            style:
                GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          if (e.message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('„${e.message}"',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textLight)),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Przypisz do gościa…'),
                  items: [
                    for (final g in guests)
                      DropdownMenuItem(
                          value: g.id,
                          child: Text(
                              g.fullName.isEmpty ? 'Gość' : g.fullName)),
                  ],
                  onChanged: (v) {
                    if (v != null && e.id != null) {
                      service.assignEntry(e.id!, v);
                    }
                  },
                ),
              ),
              IconButton(
                onPressed: () {
                  if (e.id != null) service.deleteEntry(e.id!);
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                color: const Color(0xFFC0392B),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qrCard(BuildContext context, String baseUrl) {
    return PublicLinkCard(
      label: '✅ Strona potwierdzeń (RSVP)',
      url: PublicPages.rsvp(baseUrl),
    );
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wyczyścić wszystkie potwierdzenia?'),
        content: const Text('Tej operacji nie można cofnąć.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Anuluj')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC0392B)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Wyczyść'),
          ),
        ],
      ),
    );
    if (ok == true) await service.clearAll();
  }
}
