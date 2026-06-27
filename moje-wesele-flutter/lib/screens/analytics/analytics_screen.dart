import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/budget_summary.dart';
import '../../models/guest.dart';
import '../../models/guest_summary.dart';
import '../../models/wedding_data.dart';
import '../../utils/format.dart';

/// Sekcja „Analityka" — wykresy budżetu i gości (fl_chart).
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key, required this.data});

  final WeddingData? data;

  static const _palette = [
    Color(0xFF1A56DB),
    Color(0xFF059669),
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
    Color(0xFFEA580C),
    Color(0xFF0891B2),
    Color(0xFFCA8A04),
    Color(0xFF4F46E5),
    Color(0xFF16A34A),
    Color(0xFFBE123C),
  ];

  List<Guest> get _guests => [
        for (final e in data?.guests ?? const [])
          if (e is Map) Guest(Map<String, dynamic>.from(e)),
      ];

  @override
  Widget build(BuildContext context) {
    final summary = BudgetSummary.from(data);
    final guests = _guests;
    final guestCount = guests.length;
    final costPerGuest =
        guestCount > 0 ? summary.planForCalc / guestCount : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Text('Analityka',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text)),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            children: [
              _forecastCard(summary, costPerGuest),
              const SizedBox(height: 12),
              _chartCard(context, 'Budżet: plan vs przewidywany vs opłacono',
                  _budgetBars(summary)),
              const SizedBox(height: 12),
              _chartCard(context, 'Rozkład wydatków (kategorie)',
                  _expensePie()),
              const SizedBox(height: 12),
              _chartCard(context, 'Postęp płatności w czasie',
                  _paymentLine()),
              const SizedBox(height: 12),
              _chartCard(context, 'Potwierdzenia gości', _rsvpPie(guests)),
              const SizedBox(height: 12),
              _chartCard(context, 'Rozkład menu / diet', _menuBars(guests)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Prognoza ──
  Widget _forecastCard(BudgetSummary s, double costPerGuest) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppColors.accent, AppColors.accent2]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Prognoza końcowego budżetu',
              style: GoogleFonts.inter(
                  fontSize: 13, color: Colors.white.withValues(alpha: 0.85))),
          const SizedBox(height: 4),
          Text(formatPlnZl(s.planForCalc),
              style: GoogleFonts.playfairDisplay(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Row(
            children: [
              _miniStat('Koszt / gość', formatPlnZl(costPerGuest)),
              _miniStat('Budżet', formatPlnZl(s.budget)),
              _miniStat(
                  s.diff >= 0 ? 'Zapas' : 'Przekroczenie',
                  '${s.diff >= 0 ? '+' : ''}${formatPlnZl(s.diff)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.85))),
        ],
      ),
    );
  }

  // ── Wykresy ──
  Widget _budgetBars(BudgetSummary s) {
    final values = [
      ('Potwierdz.', s.totalConfirmed, const Color(0xFF1D4ED8)),
      ('Przewidyw.', s.totalEffective, const Color(0xFFB45309)),
      ('Opłacono', s.totalPaid, const Color(0xFF059669)),
      ('Budżet', s.budget, const Color(0xFF7C3AED)),
    ];
    final maxY = values.map((v) => v.$2).fold<double>(1, (m, v) => v > m ? v : m);
    return BarChart(
      BarChartData(
        maxY: maxY * 1.15,
        barTouchData: BarTouchData(enabled: true),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= values.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(values[i].$1,
                      style: GoogleFonts.inter(fontSize: 9)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < values.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: values[i].$2,
                color: values[i].$3,
                width: 26,
                borderRadius: BorderRadius.circular(4),
              ),
            ]),
        ],
      ),
    );
  }

  Map<String, double> _expenseByCategory() {
    final bd = data?.raw['budgetData'];
    final expenses = (bd is Map) ? bd['expenses'] : null;
    final map = <String, double>{};
    if (expenses is List) {
      for (final e in expenses) {
        if (e is! Map) continue;
        final planned = (e['planned'] as num?)?.toDouble() ?? 0;
        final est = (e['estimatedAmount'] as num?)?.toDouble() ?? 0;
        final eff = planned > 0 ? planned : est;
        if (eff <= 0) continue;
        final cat = (e['category'] as String?) ?? 'Inne';
        map[cat] = (map[cat] ?? 0) + eff;
      }
    }
    return map;
  }

  Widget _expensePie() {
    final map = _expenseByCategory();
    if (map.isEmpty) return _empty('Brak wydatków.');
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<double>(0, (s, e) => s + e.value);
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 36,
              sectionsSpace: 2,
              sections: [
                for (var i = 0; i < entries.length; i++)
                  PieChartSectionData(
                    value: entries[i].value,
                    color: _palette[i % _palette.length],
                    title:
                        '${(entries[i].value / total * 100).round()}%',
                    radius: 50,
                    titleStyle: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 4,
          children: [
            for (var i = 0; i < entries.length; i++)
              _legend(_palette[i % _palette.length],
                  '${entries[i].key} (${formatPlnZl(entries[i].value)})'),
          ],
        ),
      ],
    );
  }

  Widget _paymentLine() {
    final bd = data?.raw['budgetData'];
    final expenses = (bd is Map) ? bd['expenses'] : null;
    final points = <(DateTime, double)>[];
    if (expenses is List) {
      for (final e in expenses) {
        if (e is! Map) continue;
        final paid = (e['paid'] as num?)?.toDouble() ?? 0;
        final date = DateTime.tryParse((e['paymentDate'] as String?) ?? '');
        if (paid > 0 && date != null) points.add((date, paid));
      }
    }
    if (points.isEmpty) return _empty('Brak danych o płatnościach z datą.');
    points.sort((a, b) => a.$1.compareTo(b.$1));
    var cum = 0.0;
    final spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      cum += points[i].$2;
      spots.add(FlSpot(i.toDouble(), cum));
    }
    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(
            leftTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.accent,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.accent.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rsvpPie(List<Guest> guests) {
    final rsvp = (data?.raw['rsvpEntries'] is List)
        ? data!.raw['rsvpEntries'] as List
        : const [];
    var att = 0, not = 0, none = 0;
    for (final g in guests) {
      if (g.category == 'Państwo Młodzi') continue;
      final st = GuestSummary.rsvpStatus(g.id, rsvp);
      if (st == 'attending') {
        att++;
      } else if (st == 'not_attending') {
        not++;
      } else {
        none++;
      }
    }
    if (att + not + none == 0) return _empty('Brak gości.');
    final items = [
      ('Przyjdą', att, const Color(0xFF059669)),
      ('Nie przyjdą', not, const Color(0xFFC0392B)),
      ('Brak odpowiedzi', none, const Color(0xFFB45309)),
    ];
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 36,
              sectionsSpace: 2,
              sections: [
                for (final (_, n, c) in items)
                  if (n > 0)
                    PieChartSectionData(
                      value: n.toDouble(),
                      color: c,
                      title: '$n',
                      radius: 50,
                      titleStyle: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: [for (final (label, n, c) in items) _legend(c, '$label: $n')],
        ),
      ],
    );
  }

  Widget _menuBars(List<Guest> guests) {
    final map = <String, int>{};
    var noMenu = 0;
    for (final g in guests) {
      final m = g.menuChoice.trim();
      if (m.isEmpty) {
        noMenu++;
      } else {
        map[m] = (map[m] ?? 0) + 1;
      }
    }
    final entries = [
      ...map.entries.map((e) => (e.key, e.value)),
      if (noMenu > 0) ('Bez menu', noMenu),
    ];
    if (entries.isEmpty) return _empty('Brak danych o menu.');
    final maxY =
        entries.map((e) => e.$2).fold<int>(1, (m, v) => v > m ? v : m);
    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.2,
          barTouchData: BarTouchData(enabled: true),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= entries.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: SizedBox(
                      width: 56,
                      child: Text(entries[i].$1,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 8)),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < entries.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: entries[i].$2.toDouble(),
                  color: _palette[i % _palette.length],
                  width: 24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ]),
          ],
        ),
      ),
    );
  }

  // ── Wspólne ──
  Widget _chartCard(BuildContext context, String title, Widget chart) {
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                SizedBox(height: 320, child: chart),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Zamknij'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
                Expanded(
                  child: Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text)),
                ),
                const Icon(Icons.zoom_out_map,
                    size: 16, color: AppColors.textLight),
              ],
            ),
            const SizedBox(height: 12),
            chart,
          ],
        ),
      ),
    );
  }

  Widget _legend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(text,
            style: GoogleFonts.inter(fontSize: 10, color: AppColors.textLight)),
      ],
    );
  }

  Widget _empty(String text) => SizedBox(
        height: 100,
        child: Center(
          child: Text(text,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textLight)),
        ),
      );
}
