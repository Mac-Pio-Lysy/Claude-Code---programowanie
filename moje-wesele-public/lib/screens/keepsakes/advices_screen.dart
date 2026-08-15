import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../config/public_urls.dart';
import '../../models/advice.dart';
import '../../models/wedding_data.dart';
import '../../services/advice_service.dart';
import '../../services/pdf_service.dart';
import '../../widgets/filter_toggle_button.dart';
import '../../widgets/guest_page_tab.dart';
import '../../l10n/app_text.dart';

/// Podzakładka „Rady dla Pary Młodej" (w sekcji „Ślubne pamiątki").
///
/// Dwie wewnętrzne zakładki: „Rady" (panel organizatora — lista, filtr po
/// kategorii, licznik, usuwanie, eksport PDF, pokaz slajdów) oraz „Strona dla
/// gości" (kod QR/link do publicznej strony `rady.html`).
class AdvicesScreen extends StatefulWidget {
  const AdvicesScreen({super.key, required this.data});

  final WeddingData? data;

  @override
  State<AdvicesScreen> createState() => _AdvicesScreenState();
}

class _AdvicesScreenState extends State<AdvicesScreen> {
  final AdviceService _service = AdviceService();
  late final Stream<List<Advice>> _stream = _service.watchAdvices();

  /// Klucz filtrowanej kategorii ('' = wszystkie).
  String _filter = '';
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
            tabs: const [
              Tab(text: 'Rady'),
              Tab(text: 'Strona dla gości'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _advicesTab(),
                GuestPageTab(
                  links: [(AppText.t.advices_header, PublicPages.rady(base))],
                  intro:
                      AppText.t.advices_txt1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _advicesTab() {
    return StreamBuilder<List<Advice>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _info('Nie udało się wczytać rad. Sprawdź połączenie.');
        }
        final all = snapshot.data ?? const <Advice>[];
        final filtered = _filter.isEmpty
            ? all
            : all.where((a) => a.categoryKey == _filter).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _toolbar(all, filtered),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(AppText.t.advices_filterByCategory,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text)),
                ),
                FilterToggleButton(
                  expanded: _filtersVisible,
                  onTap: () =>
                      setState(() => _filtersVisible = !_filtersVisible),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              curve: Curves.easeInOut,
              child: _filtersVisible
                  ? _filters(all)
                  : const SizedBox(width: double.infinity),
            ),
            const SizedBox(height: 14),
            if (filtered.isEmpty)
              _info(all.isEmpty
                  ? AppText.t.advices_txt2
                  : 'Brak rad w tej kategorii.')
            else
              for (final a in filtered) _adviceCard(a),
          ],
        );
      },
    );
  }

  Widget _toolbar(List<Advice> all, List<Advice> filtered) {
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
      child: Row(
        children: [
          const Text('💌', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${all.length}',
                    style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent)),
                Text(all.length == 1 ? 'rada' : 'rad',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textLight)),
              ],
            ),
          ),
          IconButton(
            onPressed:
                filtered.isEmpty ? null : () => _startSlideshow(filtered),
            icon: const Icon(Icons.slideshow),
            color: AppColors.accent,
            tooltip: AppText.t.advices_slideshow,
          ),
          OutlinedButton.icon(
            onPressed: filtered.isEmpty ? null : () => _exportPdf(filtered),
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: const Text('PDF'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filters(List<Advice> all) {
    final counts = <String, int>{};
    for (final a in all) {
      counts[a.categoryKey] = (counts[a.categoryKey] ?? 0) + 1;
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip('Wszystkie', '', all.length),
          for (final c in AdviceCategory.all)
            _filterChip('${c.emoji} ${c.label}', c.key, counts[c.key] ?? 0),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String key, int count) {
    final selected = _filter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(AppText.t.advices_labelCount(label, count)),
        selected: selected,
        onSelected: (_) => setState(() => _filter = key),
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
      ),
    );
  }

  Widget _adviceCard(Advice a) {
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
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${a.category.emoji} ${a.category.label}',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent)),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _confirmDelete(a),
                icon: const Icon(Icons.delete_outline, size: 20),
                color: const Color(0xFFC0392B),
                visualDensity: VisualDensity.compact,
                tooltip: AppText.t.advices_delete,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(AppText.t.advices_quoted(a.message),
              style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                  color: AppColors.text)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text('— ${a.name.isEmpty ? 'Gość' : a.name}',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
              ),
              if (_dateLabel(a) != null)
                Text(_dateLabel(a)!,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textLight)),
            ],
          ),
        ],
      ),
    );
  }

  String? _dateLabel(Advice a) {
    final d = a.dateTime;
    if (d == null) return null;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}';
  }

  Future<void> _confirmDelete(Advice a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppText.t.advices_deleteTitle),
        content: Text('Czy na pewno usunąć radę od '
            '„${a.name.isEmpty ? 'Gość' : a.name}"? Tej operacji nie można cofnąć.'),
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
      await _service.deleteAdvice(a.id);
      _toast(AppText.t.advices_deleted);
    } catch (e) {
      _toast(AppText.t.common_deleteErrorToast('$e'));
    }
  }

  Future<void> _exportPdf(List<Advice> advices) async {
    try {
      final cfg = widget.data?.raw['appConfig'];
      final eventName = (cfg is Map) ? cfg['eventName'] as String? : null;
      final bytes = await PdfService.advices(
        advices: advices,
        title: (eventName != null && eventName.trim().isNotEmpty)
            ? 'Rady dla Pary Młodej — ${eventName.trim()}'
            : 'Rady dla Pary Młodej',
      );
      await PdfService.preview(bytes, 'rady-dla-pary-mlodej.pdf');
    } catch (e) {
      _toast(AppText.t.common_pdfError('$e'));
    }
  }

  void _startSlideshow(List<Advice> advices) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _AdviceSlideshowPage(advices: advices),
    ));
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

/// Pełnoekranowy pokaz slajdów rad (do pokazania na sali). Ręczne przewijanie
/// lub automatyczne (co kilka sekund).
class _AdviceSlideshowPage extends StatefulWidget {
  const _AdviceSlideshowPage({required this.advices});
  final List<Advice> advices;

  @override
  State<_AdviceSlideshowPage> createState() => _AdviceSlideshowPageState();
}

class _AdviceSlideshowPageState extends State<_AdviceSlideshowPage> {
  final _controller = PageController();
  int _index = 0;
  bool _auto = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _toggleAuto() {
    setState(() => _auto = !_auto);
    _timer?.cancel();
    if (_auto) {
      _timer = Timer.periodic(const Duration(seconds: 6), (_) => _next());
    }
  }

  void _next() {
    if (widget.advices.isEmpty) return;
    final next = (_index + 1) % widget.advices.length;
    _controller.animateToPage(next,
        duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
  }

  void _prev() {
    if (widget.advices.isEmpty) return;
    final prev =
        (_index - 1 + widget.advices.length) % widget.advices.length;
    _controller.animateToPage(prev,
        duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final advices = widget.advices;
    return Scaffold(
      backgroundColor: const Color(0xFF0B1B3B),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(AppText.t.advices_header,
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                  IconButton(
                    onPressed: _toggleAuto,
                    icon: Icon(_auto ? Icons.pause_circle : Icons.play_circle,
                        color: Colors.white),
                    tooltip: _auto ? 'Zatrzymaj' : 'Auto-pokaz',
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Zamknij',
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: advices.length,
                itemBuilder: (_, i) => _slide(advices[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _prev,
                    icon: const Icon(Icons.chevron_left,
                        color: Colors.white, size: 32),
                  ),
                  Text(AppText.t.advices_position(_index + 1, advices.length),
                      style: GoogleFonts.inter(
                          fontSize: 14, color: Colors.white70)),
                  IconButton(
                    onPressed: _next,
                    icon: const Icon(Icons.chevron_right,
                        color: Colors.white, size: 32),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slide(Advice a) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(a.category.emoji, style: const TextStyle(fontSize: 44)),
              const SizedBox(height: 18),
              Text(AppText.t.advices_quoted(a.message),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
              const SizedBox(height: 24),
              Text('— ${a.name.isEmpty ? 'Gość' : a.name}',
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF8FB6FF))),
              const SizedBox(height: 6),
              Text(a.category.label,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: Colors.white54)),
            ],
          ),
        ),
      ),
    );
  }
}
