import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../config/public_urls.dart';
import '../../models/guestbook_entry.dart';
import '../../models/wedding_data.dart';
import '../../services/guestbook_service.dart';
import '../../services/pdf_service.dart';
import '../../widgets/filter_toggle_button.dart';
import '../../widgets/guest_page_tab.dart';
import '../../l10n/app_text.dart';

/// Podzakładka „Księga gości" (w sekcji „Ślubne pamiątki").
///
/// Dwie wewnętrzne zakładki: „Wpisy" (panel organizatora — lista życzeń,
/// licznik, sortowanie, usuwanie, eksport PDF) oraz „Strona dla gości"
/// (kod QR i link do publicznej strony `ksiega.html`).
class GuestbookScreen extends StatefulWidget {
  const GuestbookScreen({super.key, required this.data});

  final WeddingData? data;

  @override
  State<GuestbookScreen> createState() => _GuestbookScreenState();
}

class _GuestbookScreenState extends State<GuestbookScreen> {
  final GuestbookService _service = GuestbookService();
  late final Stream<List<GuestbookEntry>> _entriesStream =
      _service.watchEntries();
  bool _newestFirst = true;
  bool _filtersVisible = false;

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
            tabs: [
              Tab(text: 'Wpisy'),
              Tab(text: AppText.t.gp_guestPage),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _entriesTab(),
                GuestPageTab(
                  links: [(AppText.t.guestbook_headerTitle, PublicPages.ksiega(base))],
                  intro:
                      AppText.t.guestbook_txt1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _entriesTab() {
    return StreamBuilder<List<GuestbookEntry>>(
      stream: _entriesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _info(
              AppText.t.guestbook_loadError);
        }
        final entries = [...?snapshot.data];
        entries.sort((a, b) =>
            _newestFirst ? b.timestamp.compareTo(a.timestamp) : a.timestamp.compareTo(b.timestamp));

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _toolbar(entries),
            const SizedBox(height: 14),
            if (entries.isEmpty)
              _info(AppText.t.guestbook_txt2)
            else
              for (final e in entries) _entryCard(e),
          ],
        );
      },
    );
  }

  Widget _toolbar(List<GuestbookEntry> entries) {
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
              const Text('💝', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${entries.length}',
                        style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accent)),
                    Text(
                      AppText.t.guestbook_wishCount(entries.length),
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed:
                    entries.isEmpty ? null : () => _exportPdf(entries),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: Text(AppText.t.common_exportPdf),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: Text('Sortowanie',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textLight)),
              ),
              FilterToggleButton(
                expanded: _filtersVisible,
                onTap: () => setState(() => _filtersVisible = !_filtersVisible),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            curve: Curves.easeInOut,
            child: _filtersVisible
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        _sortChip('Najnowsze', true),
                        const SizedBox(width: 8),
                        _sortChip('Najstarsze', false),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _sortChip(String label, bool newest) {
    final selected = _newestFirst == newest;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _newestFirst = newest),
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

  Widget _entryCard(GuestbookEntry e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF7)),
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
                    Text(e.name.isEmpty ? AppText.t.role_guest : e.name,
                        style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text)),
                    if (_dateLabel(e) != null)
                      Text(_dateLabel(e)!,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.textLight)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _confirmDelete(e),
                icon: const Icon(Icons.delete_outline, size: 20),
                color: const Color(0xFFC0392B),
                visualDensity: VisualDensity.compact,
                tooltip: AppText.t.guestbook_deleteEntry,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(e.message,
              style: GoogleFonts.inter(
                  fontSize: 14, height: 1.5, color: AppColors.text)),
          if (e.hasPhoto) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _viewPhoto(e.photoUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  e.photoUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) =>
                      progress == null
                          ? child
                          : Container(
                              height: 160,
                              alignment: Alignment.center,
                              color: const Color(0xFFEEF3FF),
                              child: const CircularProgressIndicator(),
                            ),
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

  String? _dateLabel(GuestbookEntry e) {
    final d = e.dateTime;
    if (d == null) return null;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}, ${two(d.hour)}:${two(d.minute)}';
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

  Future<void> _confirmDelete(GuestbookEntry e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppText.t.guestbook_deleteTitle),
        content: Text(
            AppText.t.guestbook_deleteBodyNamed(
                e.name.isEmpty ? AppText.t.guests_unknownGuest : e.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppText.t.common_cancel),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: const Color(0xFFC0392B)),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppText.t.common_delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.deleteEntry(e.id);
      _toast(AppText.t.guestbook_deleted);
    } catch (err) {
      _toast(AppText.t.common_deleteErrorToast('$err'));
    }
  }

  Future<void> _exportPdf(List<GuestbookEntry> entries) async {
    try {
      final cfg = widget.data?.raw['appConfig'];
      final eventName = (cfg is Map) ? cfg['eventName'] as String? : null;
      final bytes = await PdfService.guestbook(
        entries: entries,
        title: (eventName != null && eventName.trim().isNotEmpty)
            ? AppText.t.guestbook_pdfTitleNamed(eventName.trim())
            : AppText.t.pdf_guestbookTitle,
      );
      await PdfService.preview(bytes, 'ksiega-gosci.pdf');
    } catch (e) {
      _toast(AppText.t.common_pdfError('$e'));
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
