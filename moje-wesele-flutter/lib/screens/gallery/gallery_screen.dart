import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_colors.dart';
import '../../config/public_urls.dart';
import '../../models/gallery_item.dart';
import '../../models/schedule_event.dart';
import '../../models/wedding_data.dart';
import '../../services/firestore_service.dart';
import '../../services/gallery_service.dart';
import '../../services/pdf_service.dart';
import '../../widgets/guest_page_tab.dart';

/// Sekcja „Galeria & QR" (panel organizatora).
class GalleryScreen extends StatefulWidget {
  GalleryScreen({
    super.key,
    required this.data,
    required this.firestore,
  }) : gallery = GalleryService();

  final WeddingData? data;
  final FirestoreService firestore;
  final GalleryService gallery;

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  static const int _limitBytes = 25 * 1024 * 1024 * 1024; // 25 GB

  String _personFilter = 'all';
  String _typeFilter = 'all'; // all | image | video
  String _sort = 'newest';
  String _pdfFormat = 'A4';

  List<ScheduleEvent> get _events {
    final list = [
      for (final e in widget.data?.raw['scheduleEvents'] ?? const [])
        if (e is Map) ScheduleEvent(Map<String, dynamic>.from(e)),
    ];
    list.sort((a, b) => a.sortKey.compareTo(b.sortKey));
    return list;
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  String _fmtSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(2)} GB';
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = PublicPages.baseUrl(widget.data?.raw);

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text('Galeria & QR',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text)),
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
              Tab(text: 'Galeria'),
              Tab(text: 'Strona dla gości'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  children: [
                    StreamBuilder<List<GalleryItem>>(
                      stream: widget.gallery.watch(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return _card('Galeria',
                              Text('Błąd odczytu galerii: ${snapshot.error}',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFFC0392B))));
                        }
                        if (!snapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return _galleryBlock(snapshot.data!);
                      },
                    ),
                    const SizedBox(height: 16),
                    _pdfSection(baseUrl),
                  ],
                ),
                GuestPageTab(
                  links: [
                    ('📸 Galeria zdjęć i filmów', PublicPages.galeria(baseUrl)),
                    ('🎵 Wybór muzyki', PublicPages.muzyka(baseUrl)),
                  ],
                  intro:
                      'Strona dla gości: wspólna galeria zdjęć i filmów oraz '
                      'możliwość zaproponowania muzyki. Pokaż kod QR lub wyślij '
                      'link.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _galleryBlock(List<GalleryItem> items) {
    final totalBytes = items.fold<int>(0, (s, it) => s + it.fileSize);
    final pct = (totalBytes / _limitBytes).clamp(0.0, 1.0);

    final persons = <String>{for (final it in items) it.uploadedBy}.toList()
      ..sort();

    var filtered = items.where((it) {
      if (_personFilter != 'all' && it.uploadedBy != _personFilter) {
        return false;
      }
      if (_typeFilter == 'image' && it.isVideo) return false;
      if (_typeFilter == 'video' && !it.isVideo) return false;
      return true;
    }).toList();
    filtered.sort((a, b) => _sort == 'newest'
        ? b.timestampMs.compareTo(a.timestampMs)
        : a.timestampMs.compareTo(b.timestampMs));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Licznik miejsca
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2EAF7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Wykorzystano: ${_fmtSize(totalBytes)} / 25 GB',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE5EBF5),
                  valueColor: AlwaysStoppedAnimation(
                      pct >= 0.85 ? const Color(0xFFC0392B) : AppColors.accent),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Filtry
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue:
                    persons.contains(_personFilter) ? _personFilter : 'all',
                isExpanded: true,
                decoration: _miniDec('Osoba'),
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('Wszyscy')),
                  for (final p in persons)
                    DropdownMenuItem(value: p, child: Text(p)),
                ],
                onChanged: (v) => setState(() => _personFilter = v ?? 'all'),
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _sort,
              items: const [
                DropdownMenuItem(value: 'newest', child: Text('Najnowsze')),
                DropdownMenuItem(value: 'oldest', child: Text('Najstarsze')),
              ],
              onChanged: (v) => setState(() => _sort = v ?? 'newest'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _typeChip('Wszystko', 'all'),
            const SizedBox(width: 6),
            _typeChip('📷 Zdjęcia', 'image'),
            const SizedBox(width: 6),
            _typeChip('▶ Filmy', 'video'),
          ],
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          Text('Brak plików w galerii.',
              style:
                  GoogleFonts.inter(fontSize: 13, color: AppColors.textLight))
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 170,
              mainAxisExtent: 200,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, i) => _tile(filtered[i]),
          ),
      ],
    );
  }

  Widget _tile(GalleryItem it) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (it.isVideo)
                  Container(
                    color: const Color(0xFFEEF3FF),
                    child: const Icon(Icons.videocam,
                        size: 36, color: AppColors.accent),
                  )
                else
                  Image.network(
                    it.thumbUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: const Color(0xFFEEF3FF),
                      child: const Icon(Icons.image_outlined,
                          color: AppColors.accent),
                    ),
                  ),
                if (it.isVideo)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('▶ film',
                          style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text('📷 ${it.uploadedBy}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          Row(
            children: [
              Expanded(
                child: IconButton(
                  tooltip: 'Pobierz',
                  onPressed: () => _open(it.downloadUrl),
                  icon: const Icon(Icons.download, size: 18),
                  color: AppColors.accent,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              Expanded(
                child: IconButton(
                  tooltip: 'Usuń',
                  onPressed: () => _confirmDelete(it),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: const Color(0xFFC0392B),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pdfSection(String baseUrl) {
    final format = pdfFormatFromLabel(_pdfFormat);
    return _card(
      'Wydruki PDF',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Format:', style: GoogleFonts.inter(fontSize: 13)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _pdfFormat,
                items: const [
                  DropdownMenuItem(value: 'A4', child: Text('A4')),
                  DropdownMenuItem(value: 'A5', child: Text('A5')),
                ],
                onChanged: (v) => setState(() => _pdfFormat = v ?? 'A4'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pdfBtn('Galeria (QR)', () async {
                final bytes = await PdfService.gallery(
                    galleryUrl: PublicPages.galeria(baseUrl), format: format);
                await PdfService.preview(bytes, 'galeria.pdf');
              }),
              _pdfBtn('Harmonogram', () async {
                final bytes = await PdfService.schedule(
                    events: _events, format: format);
                await PdfService.preview(bytes, 'harmonogram.pdf');
              }),
              _pdfBtn('Połączony', () async {
                final bytes = await PdfService.combined(
                    galleryUrl: PublicPages.galeria(baseUrl),
                    events: _events,
                    format: format);
                await PdfService.preview(bytes, 'galeria-harmonogram.pdf');
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pdfBtn(String label, Future<void> Function() onTap) {
    return OutlinedButton.icon(
      onPressed: () async {
        try {
          await onTap();
        } catch (e) {
          _toast('Błąd PDF: $e');
        }
      },
      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accent,
        side: const BorderSide(color: AppColors.accent),
      ),
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _confirmDelete(GalleryItem it) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć plik z galerii?'),
        content: const Text(
            'Zniknie z galerii gości. Oryginał pozostaje w Cloudinary.'),
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
    if (ok == true) {
      try {
        await widget.gallery.delete(it.id);
        _toast('Usunięto plik');
      } catch (e) {
        _toast('Błąd usuwania: $e');
      }
    }
  }

  Widget _typeChip(String label, String value) {
    final selected = _typeFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _typeFilter = value),
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

  InputDecoration _miniDec(String label) => InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDCE4F2)),
        ),
      );

}
