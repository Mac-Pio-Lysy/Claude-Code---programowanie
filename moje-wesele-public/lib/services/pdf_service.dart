import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../config/public_urls.dart';
import '../models/advice.dart';
import '../models/guestbook_entry.dart';
import '../models/join_code.dart';
import '../models/schedule_event.dart';
import '../models/time_capsule_message.dart';
import '../l10n/app_text.dart';

/// Generowanie wydruków PDF (galeria/QR, harmonogram, połączony, bingo).
/// Używa czcionki Roboto (Google Fonts) obsługującej polskie znaki.
class PdfService {
  PdfService._();

  static Future<pw.ThemeData> _theme() async => pw.ThemeData.withFont(
        base: await PdfGoogleFonts.robotoRegular(),
        bold: await PdfGoogleFonts.robotoBold(),
      );

  /// Pokazuje podgląd/drukowanie/zapis wygenerowanego PDF (cross-platform).
  static Future<void> preview(Uint8List bytes, String name) =>
      Printing.layoutPdf(onLayout: (_) async => bytes, name: name);

  // ── GALERIA / QR ─────────────────────────────────────────────────────

  /// Pojedyncza strona PDF z kodem QR do strony dla gości — do pobrania,
  /// wydruku lub udostępnienia (przez okno [preview] → Printing).
  static Future<Uint8List> qrCode({
    required String title,
    required String url,
    String? subtitle,
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    // Domyślna wartość parametru musi być stałą kompilacji, a tłumaczenie
    // nią nie jest — dlatego rozwiązujemy je dopiero tutaj.
    final subtitle_ = subtitle ?? AppText.t.pdf_qrHint;
    final doc = pw.Document(theme: await _theme());
    doc.addPage(pw.Page(
      pageFormat: format,
      build: (ctx) => _qrPage(title: title, subtitle: subtitle_, url: url),
    ));
    return doc.save();
  }

  // ── ZAPROSZENIE Z DANYMI DOSTĘPU ─────────────────────────────────────

  /// Karta do wydruku i dołączenia do zaproszenia: kod QR, trzy dane potrzebne
  /// gościowi (kod, data, nazwisko) i instrukcja krok po kroku.
  ///
  /// Te same dane, które organizator widzi w Ustawieniach → „Zaproszenie dla
  /// gości" — tu ułożone tak, żeby dało się je wydrukować i włożyć do koperty.
  ///
  /// [format] domyślnie A5: karta wielkości połowy kartki wchodzi do typowej
  /// koperty na zaproszenie. A4 nadaje się na wydruk do powieszenia, A6 —
  /// na wkładkę wielkości pocztówki.
  static Future<Uint8List> guestInvitation({
    required String code,
    required String qrData,
    required String eventName,
    required String persons,
    required String weddingDate,
    required String surname,
    PdfPageFormat format = PdfPageFormat.a5,
  }) async {
    final doc = pw.Document(theme: await _theme());
    doc.addPage(pw.Page(
      pageFormat: format,
      margin: const pw.EdgeInsets.all(28),
      build: (ctx) => _invitationCard(
        code: code,
        qrData: qrData,
        eventName: eventName,
        persons: persons,
        weddingDate: weddingDate,
        surname: surname,
      ),
    ));
    return doc.save();
  }

  /// Kolor akcentu wydruków — ten sam granat co w aplikacji.
  static const PdfColor _ink = PdfColor.fromInt(0xFF1A2744);
  static const PdfColor _accent = PdfColor.fromInt(0xFF1040B0);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6B7A90);

  static pw.Widget _invitationCard({
    required String code,
    required String qrData,
    required String eventName,
    required String persons,
    required String weddingDate,
    required String surname,
  }) {
    return pw.Container(
      // Podwójna ramka — prosty, „zaproszeniowy" akcent, który dobrze wychodzi
      // na każdej drukarce (bez cieni i przezroczystości).
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _accent, width: 1.4),
      ),
      padding: const pw.EdgeInsets.all(6),
      child: pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _accent, width: 0.5),
        ),
        padding: const pw.EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('❦',
                style: pw.TextStyle(fontSize: 16, color: _accent)),
            pw.SizedBox(height: 8),
            if (eventName.trim().isNotEmpty)
              pw.Text(eventName.trim(),
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                      fontSize: 19,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink)),
            if (persons.trim().isNotEmpty) ...[
              pw.SizedBox(height: 3),
              pw.Text(persons.trim(),
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 12, color: _accent)),
            ],
            pw.SizedBox(height: 12),
            pw.Container(height: 0.7, width: 90, color: _accent),
            pw.SizedBox(height: 14),
            pw.Text(AppText.t.invite_pdfLead,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 10.5, color: _muted)),
            pw.SizedBox(height: 14),
            pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: qrData,
              width: 116,
              height: 116,
              color: _accent,
            ),
            pw.SizedBox(height: 6),
            pw.Text(AppText.t.invite_pdfScanHint,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 8.5, color: _muted)),
            pw.SizedBox(height: 14),
            _inviteDataBox(code, weddingDate, surname),
            pw.SizedBox(height: 12),
            _inviteSteps(),
          ],
        ),
      ),
    );
  }

  /// Ramka z trzema danymi, o które gość zostanie zapytany w aplikacji.
  static pw.Widget _inviteDataBox(
      String code, String weddingDate, String surname) {
    pw.Widget row(String label, String value, {bool mono = false}) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 96,
                child: pw.Text(label,
                    style: const pw.TextStyle(fontSize: 9, color: _muted)),
              ),
              pw.Expanded(
                child: pw.Text(
                  value,
                  style: pw.TextStyle(
                    fontSize: mono ? 13 : 10.5,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: mono ? 1.4 : 0,
                    color: mono ? _accent : _ink,
                  ),
                ),
              ),
            ],
          ),
        );

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF6F8FE),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFD6E0F5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(AppText.t.settings_inviteDataTitle,
              style: pw.TextStyle(
                  fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: _ink)),
          pw.SizedBox(height: 6),
          row(AppText.t.settings_weddingCode, code, mono: true),
          row(AppText.t.settings_weddingDate,
              weddingDate.isEmpty ? AppText.t.settings_notSet : weddingDate),
          row(AppText.t.settings_coupleSurname,
              surname.isEmpty ? AppText.t.settings_notSet : surname),
        ],
      ),
    );
  }

  /// Instrukcja — te same kroki, co na ekranie Ustawień.
  static pw.Widget _inviteSteps() {
    final steps = [
      AppText.t.invite_pdfStep1,
      AppText.t.invite_pdfStep2,
      AppText.t.invite_pdfStep3,
    ];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 14,
                  child: pw.Text('${i + 1}.',
                      style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: _accent)),
                ),
                pw.Expanded(
                  child: pw.Text(steps[i],
                      style: const pw.TextStyle(fontSize: 9, color: _ink)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static Future<Uint8List> gallery({
    required String galleryUrl,
    required PdfPageFormat format,
  }) async {
    final doc = pw.Document(theme: await _theme());
    doc.addPage(pw.Page(
      pageFormat: format,
      build: (ctx) => _qrPage(
        title: AppText.t.pdf_galleryTitle,
        subtitle:
            AppText.t.pdf_galleryHintVideo,
        url: galleryUrl,
      ),
    ));
    return doc.save();
  }

  static Future<Uint8List> schedule({
    required List<ScheduleEvent> events,
    required PdfPageFormat format,
  }) async {
    final doc = pw.Document(theme: await _theme());
    doc.addPage(pw.MultiPage(
      pageFormat: format,
      build: (ctx) => _scheduleContent(events),
    ));
    return doc.save();
  }

  static Future<Uint8List> combined({
    required String galleryUrl,
    required List<ScheduleEvent> events,
    required PdfPageFormat format,
  }) async {
    final doc = pw.Document(theme: await _theme());
    doc.addPage(pw.Page(
      pageFormat: format,
      build: (ctx) => _qrPage(
        title: AppText.t.pdf_galleryTitle,
        subtitle: AppText.t.pdf_galleryHint,
        url: galleryUrl,
      ),
    ));
    doc.addPage(pw.MultiPage(
      pageFormat: format,
      build: (ctx) => _scheduleContent(events),
    ));
    return doc.save();
  }

  static pw.Widget _qrPage({
    required String title,
    required String subtitle,
    required String url,
  }) {
    return pw.Center(
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(title,
              style: pw.TextStyle(
                  fontSize: 26,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF1A2744))),
          pw.SizedBox(height: 8),
          pw.Text(subtitle,
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 13)),
          pw.SizedBox(height: 28),
          pw.BarcodeWidget(
            barcode: pw.Barcode.qrCode(),
            data: url,
            width: 220,
            height: 220,
            color: PdfColor.fromInt(0xFF1040B0),
          ),
          pw.SizedBox(height: 18),
          pw.UrlLink(
            destination: url,
            child: pw.Text(url,
                style: const pw.TextStyle(
                    fontSize: 11, color: PdfColors.blue700)),
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> _scheduleContent(List<ScheduleEvent> events) {
    return [
      pw.Header(
        level: 0,
        child: pw.Text(AppText.t.pdf_scheduleTitle,
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
      ),
      pw.SizedBox(height: 10),
      for (final e in events)
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 50,
                child: pw.Text(e.timeLabel,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(e.name,
                        style: pw.TextStyle(
                            fontSize: 13, fontWeight: pw.FontWeight.bold)),
                    if (e.location.isNotEmpty)
                      pw.Text(AppText.t.pdf_place(e.location),
                          style: const pw.TextStyle(fontSize: 11)),
                    if (e.description.isNotEmpty)
                      pw.Text(e.description,
                          style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ),
      if (events.isEmpty) pw.Text(AppText.t.pdf_scheduleEmpty),
    ];
  }

  // ── INDYWIDUALNE ZAPROSZENIA (etap 6) ────────────────────────────────

  /// Wydruk zaproszeń per paczka — jeden PDF, wiele stron.
  ///
  /// [format] A6/A5 → jedna karta na stronę (pętla `addPage`, jak [bingo]).
  /// [format] A4 z [perPage] 2 lub 4 → siatka kart na arkuszu z liniami
  /// cięcia, żeby dało się je rozciąć po wydruku.
  ///
  /// QR prowadzi na `<baseUrl>/?i=<KOD>` (patrz `PublicPages.inviteEntry`) —
  /// zeskanowanie wpuszcza gościa prosto do wyboru tożsamości, bez ręcznego
  /// wpisywania kodu.
  static Future<Uint8List> individualInvitations({
    required List<({String code, String names})> packages,
    required String baseUrl,
    required String eventName,
    required String persons,
    PdfPageFormat format = PdfPageFormat.a6,
    int perPage = 1,
    void Function(int done, int total)? onProgress,
  }) async {
    final doc = pw.Document(theme: await _theme());
    final total = packages.length;
    var done = 0;

    if (perPage <= 1) {
      for (final p in packages) {
        doc.addPage(pw.Page(
          pageFormat: format,
          margin: const pw.EdgeInsets.all(20),
          build: (ctx) => _individualCard(
            code: p.code,
            names: p.names,
            url: PublicPages.inviteEntry(baseUrl, p.code),
            eventName: eventName,
            persons: persons,
          ),
        ));
        done++;
        onProgress?.call(done, total);
        // Oddaje sterowanie pętli zdarzeń, żeby pasek postępu zdążył się
        // przerysować — bez tego cała pętla (czysto synchroniczna) wykonałaby
        // się między jedną klatką a drugą i pasek „przeskoczyłby" od razu na 100%.
        await Future<void>.delayed(Duration.zero);
      }
    } else {
      for (var i = 0; i < packages.length; i += perPage) {
        final chunk = packages.sublist(
            i, i + perPage > packages.length ? packages.length : i + perPage);
        doc.addPage(pw.Page(
          pageFormat: format,
          margin: const pw.EdgeInsets.all(14),
          build: (ctx) => _invitationGrid(
            chunk,
            perPage: perPage,
            baseUrl: baseUrl,
            eventName: eventName,
            persons: persons,
          ),
        ));
        done += chunk.length;
        onProgress?.call(done, total);
        await Future<void>.delayed(Duration.zero);
      }
    }
    return doc.save();
  }

  /// Karta jednej paczki (A6/A5, cała strona).
  static pw.Widget _individualCard({
    required String code,
    required String names,
    required String url,
    required String eventName,
    required String persons,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(color: _accent, width: 1.4)),
      padding: const pw.EdgeInsets.all(6),
      child: pw.Container(
        decoration: pw.BoxDecoration(border: pw.Border.all(color: _accent, width: 0.5)),
        padding: const pw.EdgeInsets.fromLTRB(18, 20, 18, 18),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text('❦', style: pw.TextStyle(fontSize: 15, color: _accent)),
            pw.SizedBox(height: 6),
            if (eventName.trim().isNotEmpty)
              pw.Text(eventName.trim(),
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold, color: _ink)),
            if (persons.trim().isNotEmpty) ...[
              pw.SizedBox(height: 2),
              pw.Text(persons.trim(),
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 10.5, color: _accent)),
            ],
            pw.SizedBox(height: 10),
            pw.Container(height: 0.7, width: 80, color: _accent),
            pw.SizedBox(height: 10),
            pw.Text(AppText.t.pdf_individualFor(names),
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                    fontSize: 13, fontWeight: pw.FontWeight.bold, color: _ink)),
            pw.SizedBox(height: 12),
            pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: url,
              width: 100,
              height: 100,
              color: _accent,
            ),
            pw.SizedBox(height: 6),
            pw.Text(AppText.t.pdf_individualScanHint,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 8, color: _muted)),
            pw.SizedBox(height: 6),
            pw.Text(JoinCode.format(code),
                style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.2,
                    color: _accent)),
          ],
        ),
      ),
    );
  }

  /// Siatka 2 lub 4 kart na arkuszu A4, z liniami cięcia.
  static pw.Widget _invitationGrid(
    List<({String code, String names})> chunk, {
    required int perPage,
    required String baseUrl,
    required String eventName,
    required String persons,
  }) {
    pw.Widget cell(({String code, String names})? p) => pw.Expanded(
          child: p == null
              ? pw.SizedBox()
              : pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: _individualCard(
                    code: p.code,
                    names: p.names,
                    url: PublicPages.inviteEntry(baseUrl, p.code),
                    eventName: eventName,
                    persons: persons,
                  ),
                ),
        );

    final padded = List<({String code, String names})?>.from(chunk);
    while (padded.length < perPage) {
      padded.add(null);
    }

    pw.Widget row(List<pw.Widget> children) => pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: children,
        );

    if (perPage == 2) {
      return row([cell(padded[0]), _cutLine(vertical: true), cell(padded[1])]);
    }
    // perPage == 4: siatka 2×2.
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Expanded(
          child: row([cell(padded[0]), _cutLine(vertical: true), cell(padded[1])]),
        ),
        _cutLine(vertical: false),
        pw.Expanded(
          child: row([cell(padded[2]), _cutLine(vertical: true), cell(padded[3])]),
        ),
      ],
    );
  }

  /// Cienka linia cięcia między kartami na arkuszu A4.
  ///
  /// Zwykła cienka linia, nie przerywana: `pdf`/`printing` nie mają wbudowanej
  /// przerywanej ramki, a odtworzenie jej z osobnych kresek wymagałoby znać z
  /// góry dostępną wysokość/szerokość (zależy od formatu strony i nie da się
  /// tu jej policzyć). `CrossAxisAlignment.stretch` na rodzicu rozciąga tę
  /// linię dokładnie na całą dostępną przestrzeń niezależnie od formatu.
  static pw.Widget _cutLine({required bool vertical}) => pw.Container(
        width: vertical ? 0.75 : null,
        height: vertical ? null : 0.75,
        color: const PdfColor.fromInt(0xFFB9C3D6),
      );

  // ── KSIĘGA GOŚCI ─────────────────────────────────────────────────────

  /// Pamiątkowy PDF z wpisami z księgi gości (do wydruku).
  static Future<Uint8List> guestbook({
    required List<GuestbookEntry> entries,
    String? title,
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    // Domyślna wartość parametru musi być stałą kompilacji, a tłumaczenie
    // nią nie jest — dlatego rozwiązujemy je dopiero tutaj.
    final title_ = title ?? AppText.t.pdf_guestbookTitle;
    final doc = pw.Document(theme: await _theme());
    doc.addPage(pw.MultiPage(
      pageFormat: format,
      build: (ctx) => _guestbookContent(entries, title_),
    ));
    return doc.save();
  }

  static List<pw.Widget> _guestbookContent(
      List<GuestbookEntry> entries, String title) {
    return [
      pw.Center(
        child: pw.Column(children: [
          pw.Text('💝', style: const pw.TextStyle(fontSize: 30)),
          pw.SizedBox(height: 6),
          pw.Text(title,
              style: pw.TextStyle(
                  fontSize: 26,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF1040B0))),
          pw.SizedBox(height: 4),
          pw.Text(AppText.t.pdf_guestbookSub,
              style: const pw.TextStyle(fontSize: 12)),
        ]),
      ),
      pw.SizedBox(height: 18),
      if (entries.isEmpty)
        pw.Text(AppText.t.pdf_guestbookEmpty)
      else
        for (final e in entries)
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF5F8FF),
              border: pw.Border.all(color: PdfColor.fromInt(0xFFC5D8F6)),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Text(e.name.isEmpty ? AppText.t.role_guest : e.name,
                          style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromInt(0xFF1A2744))),
                    ),
                    if (_dateLabel(e.dateTime).isNotEmpty)
                      pw.Text(_dateLabel(e.dateTime),
                          style: const pw.TextStyle(
                              fontSize: 9, color: PdfColors.grey700)),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Text(e.message, style: const pw.TextStyle(fontSize: 11)),
                if (e.hasPhoto)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 5),
                    child: pw.Text(AppText.t.pdf_hasPhoto,
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey600)),
                  ),
              ],
            ),
          ),
    ];
  }

  static String _dateLabel(DateTime? d) {
    if (d == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  // ── RADY DLA PARY MŁODEJ ─────────────────────────────────────────────

  /// Pamiątkowy PDF z radami dla Pary Młodej (do wydruku / oprawienia).
  static Future<Uint8List> advices({
    required List<Advice> advices,
    String? title,
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    // Domyślna wartość parametru musi być stałą kompilacji, a tłumaczenie
    // nią nie jest — dlatego rozwiązujemy je dopiero tutaj.
    final title_ = title ?? AppText.t.pdf_advicesTitle;
    final doc = pw.Document(theme: await _theme());
    doc.addPage(pw.MultiPage(
      pageFormat: format,
      build: (ctx) => _advicesContent(advices, title_),
    ));
    return doc.save();
  }

  static List<pw.Widget> _advicesContent(List<Advice> advices, String title) {
    return [
      pw.Center(
        child: pw.Column(children: [
          pw.Text('💌', style: const pw.TextStyle(fontSize: 30)),
          pw.SizedBox(height: 6),
          pw.Text(title,
              style: pw.TextStyle(
                  fontSize: 26,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF1040B0))),
          pw.SizedBox(height: 4),
          pw.Text(AppText.t.pdf_advicesSub,
              style: const pw.TextStyle(fontSize: 12)),
        ]),
      ),
      pw.SizedBox(height: 18),
      if (advices.isEmpty)
        pw.Text(AppText.t.pdf_advicesEmpty)
      else
        for (final a in advices)
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF5F8FF),
              border: pw.Border.all(color: PdfColor.fromInt(0xFFC5D8F6)),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(AppText.t.pdf_quoted(a.message),
                    style: pw.TextStyle(
                        fontSize: 13, fontStyle: pw.FontStyle.italic)),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                        '— ${a.name.isEmpty ? AppText.t.role_guest : a.name} · ${a.category.label}',
                        style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromInt(0xFF1A2744))),
                    if (_dateLabel(a.dateTime).isNotEmpty)
                      pw.Text(_dateLabel(a.dateTime),
                          style: const pw.TextStyle(
                              fontSize: 9, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
          ),
    ];
  }

  // ── KAPSUŁA CZASU ────────────────────────────────────────────────────

  /// Pamiątkowy PDF z otwartymi wiadomościami z kapsuły czasu.
  static Future<Uint8List> timeCapsule({
    required List<TimeCapsuleMessage> messages,
    String? title,
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    // Domyślna wartość parametru musi być stałą kompilacji, a tłumaczenie
    // nią nie jest — dlatego rozwiązujemy je dopiero tutaj.
    final title_ = title ?? AppText.t.pdf_capsuleTitle;
    final doc = pw.Document(theme: await _theme());
    doc.addPage(pw.MultiPage(
      pageFormat: format,
      build: (ctx) => _timeCapsuleContent(messages, title_),
    ));
    return doc.save();
  }

  static List<pw.Widget> _timeCapsuleContent(
      List<TimeCapsuleMessage> messages, String title) {
    return [
      pw.Center(
        child: pw.Column(children: [
          pw.Text('⏳', style: const pw.TextStyle(fontSize: 30)),
          pw.SizedBox(height: 6),
          pw.Text(title,
              style: pw.TextStyle(
                  fontSize: 26,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF1040B0))),
          pw.SizedBox(height: 4),
          pw.Text(AppText.t.pdf_capsuleSub,
              style: const pw.TextStyle(fontSize: 12)),
        ]),
      ),
      pw.SizedBox(height: 18),
      if (messages.isEmpty)
        pw.Text(AppText.t.pdf_capsuleEmpty)
      else
        for (final m in messages)
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF5F8FF),
              border: pw.Border.all(color: PdfColor.fromInt(0xFFC5D8F6)),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Text(m.name.isEmpty ? AppText.t.role_guest : m.name,
                          style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromInt(0xFF1A2744))),
                    ),
                    if (_dateLabel(m.openDateTime).isNotEmpty)
                      pw.Text(AppText.t.pdf_openedOn(_dateOnly(m.openDateTime)),
                          style: const pw.TextStyle(
                              fontSize: 9, color: PdfColors.grey700)),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Text(m.message, style: const pw.TextStyle(fontSize: 11)),
                if (m.hasPhoto)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 5),
                    child: pw.Text(AppText.t.pdf_hasPhoto,
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey600)),
                  ),
              ],
            ),
          ),
    ];
  }

  static String _dateOnly(DateTime? d) {
    if (d == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}';
  }

  // ── BINGO ────────────────────────────────────────────────────────────

  static Future<Uint8List> bingo({
    required List<List<String>> boards,
    required String centerLabel,
    required PdfPageFormat format,
  }) async {
    final doc = pw.Document(theme: await _theme());
    for (final board in boards) {
      doc.addPage(pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(16),
        build: (ctx) => _bingoBoard(board, centerLabel),
      ));
    }
    return doc.save();
  }

  static pw.Widget _bingoBoard(List<String> board, String centerLabel) {
    // 24 pól + środek → siatka 5×5.
    final cells = <String>[];
    var k = 0;
    for (var i = 0; i < 25; i++) {
      if (i == 12) {
        cells.add(centerLabel);
      } else {
        cells.add(k < board.length ? board[k] : '');
        k++;
      }
    }
    return pw.Column(
      children: [
        pw.Text(AppText.t.pdf_bingoTitle,
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Expanded(
          child: pw.GridView(
            crossAxisCount: 5,
            childAspectRatio: 1,
            children: [
              for (var i = 0; i < 25; i++)
                pw.Container(
                  margin: const pw.EdgeInsets.all(2),
                  padding: const pw.EdgeInsets.all(4),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                        color: PdfColor.fromInt(0xFF1A56DB), width: 1),
                    color: i == 12
                        ? PdfColor.fromInt(0xFFE8F1FC)
                        : PdfColors.white,
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    cells[i],
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight:
                            i == 12 ? pw.FontWeight.bold : pw.FontWeight.normal),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Format strony PDF (rozmiar).
PdfPageFormat pdfFormatFromLabel(String label) => switch (label) {
      'A4' => PdfPageFormat.a4,
      'A5' => PdfPageFormat.a5,
      'A6' => PdfPageFormat.a6,
      _ => PdfPageFormat.a4,
    };
