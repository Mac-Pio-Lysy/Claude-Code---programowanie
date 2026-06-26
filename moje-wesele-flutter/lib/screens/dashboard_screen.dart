import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';
import '../models/wedding_data.dart';

/// Dashboard — pokazuje prawdziwe dane z Firestore: liczbę gości, stołów,
/// budżet oraz licznik dni do ślubu.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.data,
    required this.isLoading,
  });

  final WeddingData? data;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading && data == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppColors.accent),
        ),
      );
    }

    final d = data;
    final tiles = <Widget>[
      _StatTile(
        icon: Icons.people_outline,
        value: d == null ? '—' : '${d.guestCount}',
        label: 'Goście',
        color: const Color(0xFF1A56DB),
      ),
      _StatTile(
        icon: Icons.table_restaurant_outlined,
        value: d == null ? '—' : '${d.tableCount}',
        label: 'Stoły',
        color: const Color(0xFF059669),
      ),
      _StatTile(
        icon: Icons.account_balance_wallet_outlined,
        value: d == null ? '—' : _formatBudget(d.budgetTotal),
        label: 'Budżet',
        color: const Color(0xFF7C3AED),
      ),
      _StatTile(
        icon: Icons.favorite_outline,
        value: _countdownValue(d),
        label: _countdownLabel(d),
        color: const Color(0xFFDB2777),
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 44,
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: const LinearGradient(colors: AppColors.dividerGradient),
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              // 2 kolumny na telefonie, 4 na szerokim ekranie.
              final columns = constraints.maxWidth >= 640 ? 4 : 2;
              const gap = 16.0;
              final tileWidth =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final tile in tiles)
                    SizedBox(width: tileWidth, child: tile),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static String _countdownValue(WeddingData? d) {
    final days = d?.daysUntilWedding;
    if (days == null) return '—';
    return '$days';
  }

  static String _countdownLabel(WeddingData? d) {
    if (d?.weddingDate == null) return 'Brak daty ślubu';
    final days = d!.daysUntilWedding!;
    if (days == 0) return 'To dziś! 🎉';
    return days == 1 ? 'dzień do ślubu' : 'dni do ślubu';
  }

  /// Formatuje kwotę z separatorem tysięcy i dopiskiem „zł".
  static String _formatBudget(num value) {
    final whole = value.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buf.write(' ');
      buf.write(whole[i]);
    }
    return '$buf zł';
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EAF7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
