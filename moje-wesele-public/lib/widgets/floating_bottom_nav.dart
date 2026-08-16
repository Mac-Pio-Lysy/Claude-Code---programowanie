import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';
import '../navigation/app_sections.dart';
import '../l10n/app_text.dart';

/// Dolny pasek nawigacji w kolorach aplikacji (jasnoniebieski/indygo).
/// Dashboard to pływający okrąg na środku (stały, zarezerwowany — nic innego
/// nie może tam trafić), lekko wystający ponad pasek, otoczony subtelnymi
/// ornamentami. Sekcje z [bar] są dzielone POŁOWA-NA-POŁOWĘ (pierwsza połowa
/// na lewo, reszta na prawo) — a „Więcej" zawsze skrajnie po prawej stronie
/// (przy prawej krawędzi ekranu). Dzięki temu, gdy `bar.length` jest
/// nieparzyste (tak skonfigurowane przez `NavConfigService` — patrz
/// `_BarEditSheet`, dozwolone są tylko 3 lub 5 skrótów), obie strony mają
/// ZAWSZE tyle samo ikon (2+2 albo 3+3) i pływający Dashboard trafia
/// dokładnie w środek przerwy między nimi — bez tego przy nieparzystej
/// (asymetrycznej) liczbie skrótów Dashboard „wjeżdżał" na inne ikony.
/// Na wąskich ekranach etykiety tekstowe automatycznie ustępują miejsca
/// samym (nieco większym) ikonom.
class FloatingBottomNav extends StatelessWidget {
  const FloatingBottomNav({
    super.key,
    required this.barKey,
    required this.dashboardKey,
    required this.moreKey,
    required this.itemKeys,
    required this.bar,
    required this.current,
    required this.dashboardIcon,
    required this.onSelect,
    required this.onMore,
    required this.onLongPress,
  });

  final GlobalKey barKey;
  final GlobalKey dashboardKey;
  final GlobalKey moreKey;
  final List<GlobalKey> itemKeys;
  final List<AppSection> bar;
  final AppSection current;
  final Widget dashboardIcon;
  final ValueChanged<AppSection> onSelect;
  final VoidCallback onMore;
  final VoidCallback onLongPress;

  static const double _barHeight = 62;
  static const double _fabSize = 62;
  static const double _fabOverlap = 20;

  @override
  Widget build(BuildContext context) {
    // Podział połowa-na-połowę (nie „zawsze 3 z lewej"!) — to jedyny sposób,
    // by przy nieparzystej długości paska (3 albo 5 skrótów) obie strony
    // wyszły równe (2+2 albo 3+3) i pływający Dashboard trafiał dokładnie
    // w środek przerwy, a nie „na" jedną z ikon.
    final leftCount = (bar.length / 2).ceil();
    final left = bar.take(leftCount).toList();
    final leftKeys = itemKeys.take(leftCount).toList();
    final right = bar.skip(leftCount).toList();
    final rightKeys = itemKeys.skip(leftCount).toList();

    // Wysokość systemowego paska nawigacji Androida (gesty/przyciski) —
    // na urządzeniach edge-to-edge system rysuje go NAD treścią aplikacji,
    // więc trzeba ręcznie zarezerwować dla niego miejsce pod naszym paskiem
    // (stałej wysokości), inaczej przyciski zostaną nim zasłonięte.
    final systemBottomInset = MediaQuery.paddingOf(context).bottom;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _barHeight + _fabOverlap,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              GestureDetector(
                key: barKey,
                onLongPress: onLongPress,
                child: Container(
                  height: _barHeight,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: AppColors.navBarGradient,
                      // Biel tylko wąskim pasem u góry (przy pływającym
                      // przycisku), reszta indygo — ikony w bieli czytelne.
                      stops: [0.0, 0.5, 1.0],
                    ),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(26)),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Ile miejsca wypada na jedną ikonę (bez środkowej
                      // przerwy na Dashboard) — poniżej progu chowamy etykiety
                      // tekstowe i zostawiamy same ikony, żeby nic się nie
                      // nakładało na wąskich ekranach.
                      final totalIcons = left.length + right.length + 1;
                      final availableForIcons =
                          constraints.maxWidth - (_fabSize + 6);
                      final perItem = totalIcons > 0
                          ? availableForIcons / totalIcons
                          : double.infinity;
                      final compact = perItem < 52;

                      return CustomPaint(
                        painter: _NavOrnamentPainter(),
                        child: Row(
                        children: [
                          for (var i = 0; i < left.length; i++)
                            Expanded(
                              child: _NavItem(
                                key: leftKeys[i],
                                section: left[i],
                                selected: current == left[i],
                                compact: compact,
                                onTap: () => onSelect(left[i]),
                              ),
                            ),
                          SizedBox(width: _fabSize + 6),
                          for (var i = 0; i < right.length; i++)
                            Expanded(
                              child: _NavItem(
                                key: rightKeys[i],
                                section: right[i],
                                selected: current == right[i],
                                compact: compact,
                                onTap: () => onSelect(right[i]),
                              ),
                            ),
                          Expanded(
                            child: _NavItem(
                              key: moreKey,
                              icon: Icons.more_horiz,
                              label: AppText.t.w_more,
                              selected: false,
                              compact: compact,
                              onTap: onMore,
                            ),
                          ),
                        ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 0,
                child: _DashboardFab(
                  key: dashboardKey,
                  size: _fabSize,
                  icon: dashboardIcon,
                  onTap: () => onSelect(AppSection.dashboard),
                ),
              ),
            ],
          ),
        ),
        // Pasek koloru paska, rozciągnięty za system bar — bez tego pod
        // paskiem widać białe tło strony, a przyciski (w tym pływający
        // Dashboard) byłyby częściowo zasłonięte przez system.
        if (systemBottomInset > 0)
          Container(
            height: systemBottomInset,
            color: AppColors.navBarGradient.last,
          ),
      ],
    );
  }
}

/// Pojedyncza pozycja paska (ikona sekcji + etykieta).
class _NavItem extends StatelessWidget {
  const _NavItem({
    super.key,
    this.section,
    this.icon,
    this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final AppSection? section;
  final IconData? icon;
  final String? label;
  final bool selected;
  final VoidCallback onTap;

  /// Tryb wąskiego ekranu — bez etykiety tekstowej, sama (nieco większa)
  /// ikona wyśrodkowana, żeby nic się nie ucinało ani nie nakładało.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // Pasek indygo → białe ikony/etykiety (pełna biel dla zaznaczonej,
    // przygaszona dla pozostałych).
    final color = selected ? Colors.white : Colors.white.withValues(alpha: 0.66);
    return InkWell(
      onTap: onTap,
      customBorder: const StadiumBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon ?? section!.icon, size: compact ? 23 : 20, color: color),
            if (!compact) ...[
              const SizedBox(height: 3),
              Text(
                label ?? section!.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  height: 1,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Środkowy, pływający przycisk Dashboard — okrąg lekko wystający ponad pasek.
class _DashboardFab extends StatelessWidget {
  const _DashboardFab({
    super.key,
    required this.size,
    required this.icon,
    required this.onTap,
  });

  final double size;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFEAF1FF)],
            ),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: icon,
        ),
      ),
    );
  }
}

/// Subtelne, eleganckie ZŁOTE ornamenty na górnej krawędzi paska: cienka
/// złota linia (z przerwą na pływający przycisk), delikatne łuki i kropki
/// po obu stronach Dashboardu. Lekki akcent spójny z designem aplikacji.
class _NavOrnamentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    const gap = 42.0;

    // Cienka złota linia wzdłuż górnej krawędzi — z przerwą na przycisk.
    final linePaint = Paint()
      ..shader = const LinearGradient(colors: AppColors.goldGradient)
          .createShader(Rect.fromLTWH(0, 0, size.width, 2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawLine(const Offset(14, 1.4), Offset(cx - gap - 6, 1.4), linePaint);
    canvas.drawLine(
        Offset(cx + gap + 6, 1.4), Offset(size.width - 14, 1.4), linePaint);

    // Delikatne łuki flankujące przycisk.
    final arcPaint = Paint()
      ..color = AppColors.goldLight.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final leftArc = Path()
      ..moveTo(cx - gap, 6)
      ..quadraticBezierTo(cx - gap - 20, 2, cx - gap - 38, 11);
    canvas.drawPath(leftArc, arcPaint);
    final rightArc = Path()
      ..moveTo(cx + gap, 6)
      ..quadraticBezierTo(cx + gap + 20, 2, cx + gap + 38, 11);
    canvas.drawPath(rightArc, arcPaint);

    // Drobne złote kropki na końcach łuków.
    final dotPaint = Paint()..color = AppColors.gold.withValues(alpha: 0.75);
    canvas.drawCircle(Offset(cx - gap - 42, 14), 1.8, dotPaint);
    canvas.drawCircle(Offset(cx + gap + 42, 14), 1.8, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _NavOrnamentPainter oldDelegate) => false;
}

