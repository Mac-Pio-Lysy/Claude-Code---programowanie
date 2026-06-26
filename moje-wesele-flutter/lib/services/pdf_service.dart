import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/schedule_event.dart';

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

  static Future<Uint8List> gallery({
    required String galleryUrl,
    required PdfPageFormat format,
  }) async {
    final doc = pw.Document(theme: await _theme());
    doc.addPage(pw.Page(
      pageFormat: format,
      build: (ctx) => _qrPage(
        title: 'Galeria zdjęć z wesela',
        subtitle:
            'Zeskanuj telefonem, aby dodać i obejrzeć wspólne zdjęcia i filmy.',
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
        title: 'Galeria zdjęć z wesela',
        subtitle: 'Zeskanuj telefonem, aby dodać i obejrzeć wspólne zdjęcia.',
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
        child: pw.Text('Harmonogram dnia ślubu',
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
                      pw.Text('Miejsce: ${e.location}',
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
      if (events.isEmpty) pw.Text('Brak wydarzeń w harmonogramie.'),
    ];
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
        pw.Text('ŚLUBNE BINGO',
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
