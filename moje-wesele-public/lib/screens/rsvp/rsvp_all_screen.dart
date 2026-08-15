import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../config/public_urls.dart';
import '../../models/guest.dart';
import '../../models/rsvp_entry.dart';
import '../../models/wedding_data.dart';
import '../../services/firestore_service.dart';
import '../../services/pdf_service.dart';
import '../../services/rsvp_service.dart';
import '../../widgets/public_link_card.dart';
import '../../l10n/app_text.dart';

/// Sekcja „Wszystkie RSVP" (dostępna pod „Więcej") — pełna lista WSZYSTKICH
/// wpisów potwierdzeń w jednym miejscu (z formularza i ręcznych), z nazwą
/// gościa, statusem, osobą towarzyszącą, wiadomością i źródłem.
class RsvpAllScreen extends StatelessWidget {
  RsvpAllScreen({
    super.key,
    required this.data,
    required FirestoreService firestore,
  }) : service = RsvpService(firestore: firestore);

  final WeddingData? data;
  final RsvpService service;

  List<RsvpEntry> get _entries => [
        for (final e in data?.raw['rsvpEntries'] ?? const [])
          if (e is Map) RsvpEntry(Map<String, dynamic>.from(e)),
      ];

  Map<int, Guest> get _guestById {
    final map = <int, Guest>{};
    for (final e in data?.guests ?? const []) {
      if (e is Map) {
        final g = Guest(Map<String, dynamic>.from(e));
        if (g.id != null) map[g.id!] = g;
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final guestById = _guestById;
    final entries = _entries;
    // Najnowsze na górze (po znaczniku czasu, jeśli jest).
    entries.sort((a, b) {
      final ta = (a.raw['timestamp'] as String?) ?? '';
      final tb = (b.raw['timestamp'] as String?) ?? '';
      return tb.compareTo(ta);
    });

    final attending = entries.where((e) => e.isAttending).length;
    final notAtt = entries.where((e) => e.isNotAttending).length;
    final unmatched = entries.where((e) => e.isUnmatched).length;

    final base = PublicPages.baseUrl(data?.raw);

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
                Text(AppText.t.rsvp_allTitle,
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
                const SizedBox(height: 4),
                Text(
                  AppText.t.rsvp_allHint,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textLight),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
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
              Tab(text: 'Wpisy RSVP'),
              Tab(text: 'Kody QR i linki'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  children: [
                    _summary(entries.length, attending, notAtt, unmatched),
                    const SizedBox(height: 14),
                    if (entries.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFCD34D)),
                        ),
                        child: Text(
                          AppText.t.rsvp_txt1,
                          style: GoogleFonts.inter(
                              fontSize: 13, color: const Color(0xFF92400E)),
                        ),
                      )
                    else
                      for (final e in entries)
                        _entryCard(context, e, guestById),
                  ],
                ),
                _qrCenterTab(context, base),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Zbiorcze centrum kodów QR i linków do wszystkich stron dla gości.
  Widget _qrCenterTab(BuildContext context, String base) {
    final links = <(String, String)>[
      ('📋 Potwierdzenia (RSVP)', PublicPages.rsvp(base)),
      ('📸 Galeria', PublicPages.galeria(base)),
      ('📅 Harmonogram', PublicPages.harmonogram(base)),
      ('🎵 Muzyka', PublicPages.muzyka(base)),
      ('🎲 Ślubne Bingo', PublicPages.bingo(base)),
      ('💝 Księga gości', PublicPages.ksiega(base)),
      ('🧠 Quiz o Parze Młodej', PublicPages.quiz(base)),
      ('💌 Rady dla Pary Młodej', PublicPages.rady(base)),
      ('🤔 Prawda czy Fałsz', PublicPages.prawdaFalsz(base)),
      ('📸 Zgadnij zdjęcie', PublicPages.zgadnijZdjecie(base)),
      ('⏳ Kapsuła czasu', PublicPages.kapsula(base)),
      ('🗺️ Mapa gości', PublicPages.mapa(base)),
      ('📷 Foto-wyzwania', PublicPages.fotoWyzwania(base)),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFCFE0FB)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.qr_code_2, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppText.t.rsvp_txt2,
                  style: GoogleFonts.inter(
                      fontSize: 13, height: 1.45, color: AppColors.text),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final (label, url) in links) ...[
          PublicLinkCard(
            label: label,
            url: url,
            onShare: () => _shareQr(context, label, url),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Future<void> _shareQr(BuildContext context, String label, String url) async {
    try {
      // Usuwamy emoji z tytułu PDF, zachowujemy czytelny opis.
      final title = label.replaceAll(RegExp(r'[^\p{L}\p{N}\s()&-]', unicode: true), '').trim();
      final bytes = await PdfService.qrCode(
        title: title.isEmpty ? 'Strona dla gości' : title,
        url: url,
      );
      await PdfService.preview(bytes, 'qr.pdf');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(AppText.t.rsvp_qrError('$e'))));
      }
    }
  }

  Widget _summary(int total, int attending, int notAtt, int unmatched) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Row(
        children: [
          _stat('$total', 'Wpisów', AppColors.accent),
          _stat('$attending', 'Przyjdą', const Color(0xFF059669)),
          _stat('$notAtt', 'Nie przyjdą', const Color(0xFFC0392B)),
          _stat('$unmatched', 'Nierozpoznane', const Color(0xFFB45309)),
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
                  fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.inter(fontSize: 11, color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _entryCard(BuildContext context, RsvpEntry e, Map<int, Guest> byId) {
    final guest = e.guestId != null ? byId[e.guestId!] : null;
    final name = guest != null && guest.fullName.isNotEmpty
        ? guest.fullName
        : (e.rawName.isNotEmpty ? e.rawName : '(bez imienia)');

    Color color;
    String label;
    if (e.isAttending) {
      color = const Color(0xFF059669);
      label = '✓ Przyjdzie';
    } else if (e.isNotAttending) {
      color = const Color(0xFFC0392B);
      label = '✗ Nie przyjdzie';
    } else {
      color = AppColors.textLight;
      label = e.status.isEmpty ? 'Brak statusu' : e.status;
    }

    final ts = _fmtTimestamp(e.raw['timestamp'] as String?);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: e.isUnmatched
                ? const Color(0xFFFCD34D)
                : const Color(0xFFE2EAF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name,
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _tag(e.manual ? '✍ Ręczny' : '🌐 Z formularza',
                  const Color(0xFFEEF3FF), AppColors.accent),
              if (e.isUnmatched)
                _tag('Nieprzypisany', const Color(0xFFFEF3C7),
                    const Color(0xFFB45309)),
              if (e.companionName.isNotEmpty)
                _tag('👥 +1 ${e.companionName}', const Color(0xFFF1F5F9),
                    const Color(0xFF475569)),
              if (ts.isNotEmpty)
                _tag('🕗 $ts', const Color(0xFFF1F5F9), AppColors.textLight),
            ],
          ),
          if (e.message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(AppText.t.rsvp_quotedMessage(e.message),
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.text)),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _confirmDelete(context, e),
              icon: const Icon(Icons.delete_outline, size: 16),
              label: Text(AppText.t.rsvp_deleteEntry),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFC0392B),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  String _fmtTimestamp(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.day)}.${two(l.month)}.${l.year} ${two(l.hour)}:${two(l.minute)}';
  }

  Future<void> _confirmDelete(BuildContext context, RsvpEntry e) async {
    if (e.id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppText.t.rsvp_deleteEntryTitle),
        content: Text(AppText.t.common_deleteConfirmBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppText.t.common_cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC0392B)),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppText.t.common_delete),
          ),
        ],
      ),
    );
    if (ok == true) await service.deleteEntry(e.id!);
  }
}
