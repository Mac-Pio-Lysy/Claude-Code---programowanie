import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_colors.dart';
import '../config/feature_flags.dart';
import '../l10n/app_text.dart';

/// Karta z kodem QR i klikalnym linkiem do publicznej strony dla gości
/// (kopiowanie i otwieranie w przeglądarce).
class PublicLinkCard extends StatelessWidget {
  const PublicLinkCard({
    super.key,
    required this.label,
    required this.url,
    this.qrSize = 160,
    this.onShare,
  });

  final String label;
  final String url;
  final double qrSize;

  /// Gdy podane — pokazuje przycisk „Pobierz / udostępnij" (np. eksport QR
  /// do PDF z możliwością zapisu, wydruku lub udostępnienia).
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    // Strony przeglądowe dla gości (galeria, harmonogram, RSVP itd.) są
    // tymczasowo ukryte — patrz FeatureFlags. NIE dotyczy to kodów
    // indywidualnych (`?i=KOD`), które generuje osobny widget gdzie indziej
    // i które zostają aktywne niezależnie od tej flagi.
    if (!FeatureFlags.showWebsiteLinks) {
      return _comingSoonCard();
    }
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
          Text(AppText.t.w_guestPage,
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
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                        SnackBar(content: Text(AppText.t.w_linkCopied)));
                },
                icon: const Icon(Icons.copy, size: 16),
                label: Text(AppText.t.common_copy),
              ),
              TextButton.icon(
                onPressed: () => _open(url),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(AppText.t.common_open),
              ),
              if (onShare != null)
                TextButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.download, size: 16),
                  label: Text(AppText.t.w_download),
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

  Widget _comingSoonCard() {
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
          const SizedBox(height: 12),
          const Icon(Icons.hourglass_top, size: 32, color: AppColors.textLight),
          const SizedBox(height: 10),
          Text(AppText.t.w_comingSoon,
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.inter(fontSize: 12.5, color: AppColors.textLight)),
        ],
      ),
    );
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
              child: Text(AppText.t.common_close),
            ),
          ],
        ),
      ),
    ),
  );
}
