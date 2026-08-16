import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';
import '../models/wedding_countdown.dart';
import '../l10n/app_text.dart';

/// Licznik odliczający do wesela (#24).
///
/// Sam odświeża się co minutę, więc w ostatniej dobie widać realny upływ
/// czasu. Gdy data nie jest ustawiona, widget znika — nie zajmuje miejsca
/// komunikatem o braku daty.
class WeddingCountdownCard extends StatefulWidget {
  const WeddingCountdownCard({
    super.key,
    required this.weddingDate,
    this.weddingTime,
    this.compact = false,
  });

  /// Data w formacie „YYYY-MM-DD" (jak w konfiguracji wesela).
  final String? weddingDate;

  /// Godzina „HH:mm"; bez niej przyjmujemy 16:00, czyli wartość domyślną.
  final String? weddingTime;

  /// Wariant o mniejszej wysokości (np. na liście harmonogramu).
  final bool compact;

  @override
  State<WeddingCountdownCard> createState() => _WeddingCountdownCardState();
}

class _WeddingCountdownCardState extends State<WeddingCountdownCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Minuta wystarczy — najmniejsza pokazywana jednostka.
    _ticker = Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = WeddingCountdown.from(widget.weddingDate,
        time: widget.weddingTime);
    if (c == null || c.isPast) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          vertical: widget.compact ? 14 : 20, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.14),
            AppColors.accent2.withValues(alpha: 0.07),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD6E4FB)),
      ),
      child: c.hasStarted ? _today() : _counting(c),
    );
  }

  Widget _today() => Column(
        children: [
          Text(AppText.t.w_weddingToday,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                  fontSize: widget.compact ? 22 : 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent)),
          const SizedBox(height: 4),
          Text(AppText.t.w_seeYouAtWedding,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textLight)),
        ],
      );

  Widget _counting(WeddingCountdown c) {
    final detail = c.detail;
    return Column(
      children: [
        Text(AppText.t.w_timeToWedding,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: AppColors.textLight)),
        SizedBox(height: widget.compact ? 4 : 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('${c.headlineValue}',
                style: GoogleFonts.playfairDisplay(
                    fontSize: widget.compact ? 34 : 46,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                    color: AppColors.accent)),
            const SizedBox(width: 8),
            Text(c.headlineLabel,
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text)),
          ],
        ),
        if (detail != null) ...[
          const SizedBox(height: 2),
          Text(detail,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textLight)),
        ],
      ],
    );
  }
}
