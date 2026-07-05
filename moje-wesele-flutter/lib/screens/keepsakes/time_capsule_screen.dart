import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../config/public_urls.dart';
import '../../models/time_capsule_message.dart';
import '../../models/wedding_data.dart';
import '../../services/pdf_service.dart';
import '../../services/time_capsule_service.dart';
import '../../widgets/guest_page_tab.dart';

/// Podzakładka „Kapsuła czasu" (w sekcji „Ślubne pamiątki").
///
/// Wiadomości zapieczętowane (data otwarcia w przyszłości) mają ukrytą treść —
/// widać tylko autora i datę. Po nadejściu daty odblokowują się. Organizator
/// może podejrzeć wszystko wcześniej („Otwórz wszystko teraz") — to tylko widok,
/// nie zmienia danych.
class TimeCapsuleScreen extends StatefulWidget {
  const TimeCapsuleScreen({super.key, required this.data});

  final WeddingData? data;

  @override
  State<TimeCapsuleScreen> createState() => _TimeCapsuleScreenState();
}

class _TimeCapsuleScreenState extends State<TimeCapsuleScreen> {
  final TimeCapsuleService _service = TimeCapsuleService();
  late final Stream<List<TimeCapsuleMessage>> _stream = _service.watchMessages();

  bool _soonestFirst = true;
  bool _revealAll = false; // tylko podgląd — nie zmienia Firestore

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final base = PublicPages.baseUrl(widget.data?.raw);
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textLight,
            indicatorColor: AppColors.accent,
            dividerColor: const Color(0xFFE2EAF7),
            labelStyle:
                GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'Wiadomości'),
              Tab(text: 'Strona dla gości'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _messagesTab(),
                GuestPageTab(
                  links: [('⏳ Kapsuła czasu', PublicPages.kapsula(base))],
                  intro:
                      'Strona, na której goście zostawią wiadomości do otwarcia '
                      'w przyszłości (np. w rocznicę). Pokaż im kod QR lub '
                      'wyślij link.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _messagesTab() {
    return StreamBuilder<List<TimeCapsuleMessage>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _info('Nie udało się wczytać wiadomości. Sprawdź połączenie.');
        }
        final all = [...?snapshot.data];
        all.sort((a, b) => _soonestFirst
            ? a.openDate.compareTo(b.openDate)
            : b.openDate.compareTo(a.openDate));
        final sealed = all.where((m) => m.isSealed).length;
        final opened = all.length - sealed;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _toolbar(all, sealed, opened),
            const SizedBox(height: 14),
            if (all.isEmpty)
              _info('Brak wiadomości. Udostępnij gościom kod QR z zakładki '
                  '„Strona dla gości".')
            else
              for (final m in all) _messageCard(m),
          ],
        );
      },
    );
  }

  Widget _toolbar(List<TimeCapsuleMessage> all, int sealed, int opened) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _stat('${all.length}', 'Wiadomości', AppColors.accent),
              _stat('$sealed', 'Zapieczętowane', const Color(0xFFB45309)),
              _stat('$opened', 'Otwarte', const Color(0xFF059669)),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              Text('Sortuj:',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textLight)),
              const SizedBox(width: 10),
              _sortChip('Najbliższe', true),
              const SizedBox(width: 8),
              _sortChip('Najdalsze', false),
              const Spacer(),
              IconButton(
                onPressed: opened == 0
                    ? null
                    : () => _exportPdf(
                        all.where((m) => !m.isSealed).toList()),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                color: AppColors.accent,
                tooltip: 'Eksport otwartych do PDF',
              ),
            ],
          ),
          if (sealed > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(_revealAll ? Icons.lock_open : Icons.lock_outline,
                    size: 18,
                    color: _revealAll
                        ? const Color(0xFF059669)
                        : AppColors.textLight),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _revealAll
                        ? 'Podgląd wszystkich włączony (treści widoczne tylko dla Ciebie).'
                        : 'Wiadomości otworzą się automatycznie w swojej dacie.',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textLight),
                  ),
                ),
                TextButton(
                  onPressed: _toggleRevealAll,
                  child: Text(_revealAll ? 'Zapieczętuj' : 'Otwórz wszystko'),
                ),
              ],
            ),
          ],
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

  Widget _sortChip(String label, bool soonest) {
    final selected = _soonestFirst == soonest;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _soonestFirst = soonest),
      showCheckmark: false,
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: selected ? Colors.white : AppColors.textLight,
      ),
      selectedColor: AppColors.accent,
      backgroundColor: Colors.white,
      side: BorderSide(
          color: selected ? AppColors.accent : const Color(0xFFDCE4F2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _messageCard(TimeCapsuleMessage m) {
    final sealed = m.isSealed && !_revealAll;
    if (sealed) return _sealedCard(m);
    return _openCard(m);
  }

  Widget _sealedCard(TimeCapsuleMessage m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE4F2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFEEF3FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline, color: Color(0xFFB45309)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.name.isEmpty ? 'Gość' : m.name,
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
                const SizedBox(height: 2),
                Text('🔒 Zapieczętowane do ${_dateLabel(m.openDateTime)}',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFB45309))),
                if (m.hasPhoto)
                  Text('📷 zawiera zdjęcie',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.textLight)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _confirmDelete(m),
            icon: const Icon(Icons.delete_outline, size: 20),
            color: const Color(0xFFC0392B),
            visualDensity: VisualDensity.compact,
            tooltip: 'Usuń wiadomość',
          ),
        ],
      ),
    );
  }

  Widget _openCard(TimeCapsuleMessage m) {
    final peeked = m.isSealed && _revealAll;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: peeked ? const Color(0xFFFCD34D) : const Color(0xFFE2EAF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.name.isEmpty ? 'Gość' : m.name,
                        style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text)),
                    Text(
                      peeked
                          ? '🔓 Podgląd — otworzy się ${_dateLabel(m.openDateTime)}'
                          : (m.openDate > 0
                              ? '💌 Otwarta ${_dateLabel(m.openDateTime)}'
                              : '💌 Otwarta'),
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: peeked
                              ? const Color(0xFFB45309)
                              : AppColors.textLight),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _confirmDelete(m),
                icon: const Icon(Icons.delete_outline, size: 20),
                color: const Color(0xFFC0392B),
                visualDensity: VisualDensity.compact,
                tooltip: 'Usuń wiadomość',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(m.message,
              style: GoogleFonts.inter(
                  fontSize: 14, height: 1.5, color: AppColors.text)),
          if (m.hasPhoto) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _viewPhoto(m.photoUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  m.photoUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : Container(
                          height: 160,
                          alignment: Alignment.center,
                          color: const Color(0xFFEEF3FF),
                          child: const CircularProgressIndicator()),
                  errorBuilder: (_, _, _) => Container(
                    height: 80,
                    alignment: Alignment.center,
                    color: const Color(0xFFEEF3FF),
                    child: const Icon(Icons.broken_image_outlined,
                        color: AppColors.textLight),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _dateLabel(DateTime? d) {
    if (d == null) return 'później';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}';
  }

  Future<void> _viewPhoto(String url) async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleRevealAll() async {
    if (_revealAll) {
      setState(() => _revealAll = false);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Otworzyć wszystko teraz?'),
        content: const Text(
            'Zobaczysz treść także zapieczętowanych wiadomości, zanim nadejdzie '
            'ich data. To tylko podgląd dla Ciebie — nie zmienia dat otwarcia '
            'ani tego, co widzą inni. Najwięcej radości daje jednak '
            'czekanie 💙'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Otwórz wszystko'),
          ),
        ],
      ),
    );
    if (ok == true) setState(() => _revealAll = true);
  }

  Future<void> _confirmDelete(TimeCapsuleMessage m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć wiadomość?'),
        content: Text(
            'Czy na pewno usunąć wiadomość od „${m.name.isEmpty ? 'Gość' : m.name}"? '
            'Tej operacji nie można cofnąć.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: const Color(0xFFC0392B)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.deleteMessage(m.id);
      _toast('Usunięto wiadomość');
    } catch (e) {
      _toast('Błąd usuwania: $e');
    }
  }

  Future<void> _exportPdf(List<TimeCapsuleMessage> opened) async {
    try {
      final cfg = widget.data?.raw['appConfig'];
      final eventName = (cfg is Map) ? cfg['eventName'] as String? : null;
      final bytes = await PdfService.timeCapsule(
        messages: opened,
        title: (eventName != null && eventName.trim().isNotEmpty)
            ? 'Kapsuła czasu — ${eventName.trim()}'
            : 'Kapsuła czasu',
      );
      await PdfService.preview(bytes, 'kapsula-czasu.pdf');
    } catch (e) {
      _toast('Błąd generowania PDF: $e');
    }
  }

  Widget _info(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Text(text,
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.inter(fontSize: 14, color: AppColors.textLight)),
        ),
      );
}
