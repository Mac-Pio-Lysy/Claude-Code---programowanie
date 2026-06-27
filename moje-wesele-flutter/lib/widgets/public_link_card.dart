import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_colors.dart';

/// Karta z kodem QR i klikalnym linkiem do publicznej strony dla gości
/// (kopiowanie i otwieranie w przeglądarce).
class PublicLinkCard extends StatelessWidget {
  const PublicLinkCard({
    super.key,
    required this.label,
    required this.url,
    this.qrSize = 160,
  });

  final String label;
  final String url;
  final double qrSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Column(
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 4),
          Text('Strona dla gości',
              style:
                  GoogleFonts.inter(fontSize: 11, color: AppColors.textLight)),
          const SizedBox(height: 12),
          QrImageView(
            data: url,
            size: qrSize,
            eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square, color: Color(0xFF1040B0)),
            dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF1040B0)),
          ),
          const SizedBox(height: 10),
          SelectableText(url,
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.inter(fontSize: 11, color: AppColors.textLight)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                        const SnackBar(content: Text('Skopiowano link')));
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Kopiuj'),
              ),
              TextButton.icon(
                onPressed: () => _open(url),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Otwórz'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Pokazuje kartę QR/link w oknie dialogowym.
Future<void> showPublicLinkDialog(
    BuildContext context, String label, String url) {
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PublicLinkCard(label: label, url: url, qrSize: 200),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.textLight),
              child: const Text('Zamknij'),
            ),
          ],
        ),
      ),
    ),
  );
}
