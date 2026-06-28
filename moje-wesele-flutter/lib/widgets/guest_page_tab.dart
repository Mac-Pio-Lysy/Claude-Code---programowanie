import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';
import 'public_link_card.dart';

/// Podzakładka „Strona dla gości" — pokazuje karty z kodem QR i linkiem do
/// publicznych stron dla gości (podgląd + kopiowanie + otwarcie w przeglądarce).
class GuestPageTab extends StatelessWidget {
  const GuestPageTab({super.key, required this.links, this.intro});

  /// Lista (etykieta, adres URL) — każda renderowana jako [PublicLinkCard].
  final List<(String label, String url)> links;

  /// Opcjonalny tekst wprowadzający na górze.
  final String? intro;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        if (intro != null) ...[
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
                const Icon(Icons.info_outline,
                    size: 18, color: AppColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(intro!,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.45,
                          color: AppColors.text)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        for (final (label, url) in links) ...[
          PublicLinkCard(label: label, url: url),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
