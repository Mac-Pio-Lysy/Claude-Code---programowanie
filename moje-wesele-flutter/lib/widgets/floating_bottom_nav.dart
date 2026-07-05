import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';
import '../navigation/app_sections.dart';

/// Dolny pasek nawigacji w kolorach aplikacji (jasnoniebieski/indygo) z
/// pływającym przyciskiem Dashboard na środku — lekko wystającym ponad pasek,
/// otoczonym subtelnymi ornamentami. Pozostałe sekcje rozłożone są po bokach
/// (w miarę możliwości po połowie), a „Więcej" zamyka pasek z prawej strony.
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
    final leftCount = (bar.length / 2).ceil();
    final left = bar.take(leftCount).toList();
    final leftKeys = itemKeys.take(leftCount).toList();
    final right = bar.skip(leftCount).toList();
    final rightKeys = itemKeys.skip(leftCount).toList();

    return SizedBox(
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
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: SafeArea(
                top: false,
                child: CustomPaint(
                  painter: _NavOrnamentPainter(),
                  child: Row(
                    children: [
                      for (var i = 0; i < left.length; i++)
                        Expanded(
                          child: _NavItem(
                            key: leftKeys[i],
                            section: left[i],
                            selected: current == left[i],
                            onTap: () => onSelect(left[i]),
                          ),
                        ),
                      SizedBox(width: _fabSize + 12),
                      for (var i = 0; i < right.length; i++)
                        Expanded(
                          child: _NavItem(
                            key: rightKeys[i],
                            section: right[i],
                            selected: current == right[i],
                            onTap: () => onSelect(right[i]),
                          ),
                        ),
                      Expanded(
                        child: _NavItem(
                          key: moreKey,
                          icon: Icons.more_horiz,
                          label: 'Więcej',
                          selected: false,
                          onTap: onMore,
                        ),
                      ),
                    ],
                  ),
                ),
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
  });

  final AppSection? section;
  final IconData? icon;
  final String? label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : Colors.white.withValues(alpha: 0.62);
    return InkWell(
      onTap: onTap,
      customBorder: const StadiumBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon ?? section!.icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label ?? section!.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
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
                color: AppColors.accent.withValues(alpha: 0.35),
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

/// Subtelne ornamenty (łuki i kropki) wokół pływającego przycisku Dashboard,
/// rysowane na górnej krawędzi paska nawigacji.
class _NavOrnamentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    const gap = 40.0;

    final arcPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final left = Path()
      ..moveTo(cx - gap, 5)
      ..quadraticBezierTo(cx - gap - 22, 1, cx - gap - 40, 11);
    canvas.drawPath(left, arcPaint);

    final right = Path()
      ..moveTo(cx + gap, 5)
      ..quadraticBezierTo(cx + gap + 22, 1, cx + gap + 40, 11);
    canvas.drawPath(right, arcPaint);

    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.3);
    canvas.drawCircle(Offset(cx - gap - 44, 15), 2, dotPaint);
    canvas.drawCircle(Offset(cx + gap + 44, 15), 2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _NavOrnamentPainter oldDelegate) => false;
}
