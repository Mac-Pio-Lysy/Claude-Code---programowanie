import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/couple.dart';
import '../../models/guest.dart';
import '../../models/wedding_data.dart';
import '../../models/wheel.dart';
import '../../services/firestore_service.dart';
import '../../services/wheel_service.dart';
import '../budget/budget_fields.dart';
import '../../l10n/app_text.dart';

/// Podzakładka „Koło fortuny" (w sekcji „Ślubne gry").
///
/// Narzędzie dla organizatora na sali: animowane koło losujące spośród gości
/// lub własnych pól. Konfiguracja zapisywana w Firestore; usuwanie z puli przy
/// losowaniu jest tylko stanem sesji (NIE kasuje gości ani zapisanych pól).
class WheelScreen extends StatelessWidget {
  WheelScreen({super.key, required this.data, required FirestoreService firestore})
      : service = WheelService(firestore: firestore);

  final WeddingData? data;
  final WheelService service;

  List<String> _guestPool() {
    final out = <String>[];
    for (final e in data?.guests ?? const []) {
      if (e is! Map) continue;
      final g = Guest(Map<String, dynamic>.from(e));
      if (g.category == CoupleLabels.coupleCategoryValue) continue;
      final n = g.fullName.trim();
      if (n.isNotEmpty) out.add(n);
    }
    return out;
  }

  List<String> _basePool(WheelConfig cfg, WheelMode mode) {
    if (mode.guestBased) return _guestPool();
    return cfg
        .itemsFor(mode)
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = WheelConfig.from(data?.raw);
    final mode = cfg.activeMode;
    final pool = _basePool(cfg, mode);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        _modeSelector(cfg),
        const SizedBox(height: 14),
        if (mode.guestBased)
          _guestPoolInfo(pool.length)
        else
          _fieldsEditor(cfg, mode),
        const SizedBox(height: 8),
        _optionsCard(context, cfg, mode, pool),
        const SizedBox(height: 16),
        WheelView(
          key: ValueKey('inline-${mode.id}'),
          pool: pool,
          removeOnPick: cfg.removeOnPick,
          title: mode.label,
          emoji: mode.emoji,
        ),
      ],
    );
  }

  // ── Wybór trybu ──
  Widget _modeSelector(WheelConfig cfg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppText.t.wheel_mode,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textLight)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in WheelMode.values)
              ChoiceChip(
                label: Text('${m.emoji} ${m.label}'),
                selected: cfg.activeMode == m,
                onSelected: (_) => service.setActiveMode(m.id),
                showCheckmark: false,
                labelStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      cfg.activeMode == m ? Colors.white : AppColors.textLight,
                ),
                selectedColor: AppColors.accent,
                backgroundColor: Colors.white,
                side: BorderSide(
                    color: cfg.activeMode == m
                        ? AppColors.accent
                        : const Color(0xFFDCE4F2)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _guestPoolInfo(int count) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCFE0FB)),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_outline, size: 18, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppText.t.wheel_poolInfo(
                  count, CoupleLabels.current.coupleCategoryLabel),
              style: GoogleFonts.inter(
                  fontSize: 13, height: 1.4, color: AppColors.text),
            ),
          ),
        ],
      ),
    );
  }

  // ── Edytor własnych pól ──
  Widget _fieldsEditor(WheelConfig cfg, WheelMode mode) {
    final setKey = mode.setKey!;
    final items = cfg.itemsFor(mode);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(AppText.t.wheel_fields(items.length),
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text)),
              ),
              IconButton(
                onPressed: () =>
                    service.setItems(setKey, [...items, '']),
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.accent,
                tooltip: AppText.t.wheel_addField,
              ),
            ],
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(AppText.t.wheel_addHint,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textLight)),
            )
          else
            for (var i = 0; i < items.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: BudgetTextField(
                        key: ValueKey('$setKey-$i'),
                        initial: items[i],
                        hint: AppText.t.wheel_fieldN(i + 1),
                        onSaved: (v) {
                          final list = [...items];
                          list[i] = v;
                          service.setItems(setKey, list);
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        final list = [...items]..removeAt(i);
                        service.setItems(setKey, list);
                      },
                      icon: const Icon(Icons.close, size: 18),
                      color: const Color(0xFFC0392B),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  // ── Opcje: usuwanie z puli + pełny ekran ──
  Widget _optionsCard(BuildContext context, WheelConfig cfg, WheelMode mode,
      List<String> pool) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Column(
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.accent,
            value: cfg.removeOnPick,
            onChanged: (v) => service.setRemoveOnPick(v),
            title: Text(AppText.t.wheel_removeOnPick,
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text(
              cfg.removeOnPick
                  ? AppText.t.wheel_removeOnPickOn
                  : AppText.t.wheel_removeOnPickOff,
              style:
                  GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.fullscreen, color: AppColors.accent),
            title: Text(AppText.t.wheel_fullscreen,
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text(AppText.t.wheel_fullscreenHint,
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.textLight)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => _WheelFullscreenPage(
                pool: pool,
                removeOnPick: cfg.removeOnPick,
                title: mode.label,
                emoji: mode.emoji,
              ),
            )),
          ),
        ],
      ),
    );
  }

}

/// Pełnoekranowy tryb prezentacji koła (do pokazania na sali).
class _WheelFullscreenPage extends StatelessWidget {
  const _WheelFullscreenPage({
    required this.pool,
    required this.removeOnPick,
    required this.title,
    required this.emoji,
  });

  final List<String> pool;
  final bool removeOnPick;
  final String title;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1B3B),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('$emoji  $title',
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Zamknij',
                  ),
                ],
              ),
            ),
            Expanded(
              child: WheelView(
                key: const ValueKey('fullscreen'),
                pool: pool,
                removeOnPick: removeOnPick,
                title: title,
                emoji: emoji,
                fullscreen: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Samowystarczalny widget koła: animacja, losowanie, wynik, historia, reset.
/// Stan puli (usunięci) i historia żyją w pamięci tego widgetu.
class WheelView extends StatefulWidget {
  const WheelView({
    super.key,
    required this.pool,
    required this.removeOnPick,
    required this.title,
    required this.emoji,
    this.fullscreen = false,
  });

  final List<String> pool;
  final bool removeOnPick;
  final String title;
  final String emoji;
  final bool fullscreen;

  @override
  State<WheelView> createState() => _WheelViewState();
}

class _WheelViewState extends State<WheelView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  static const _curve = Curves.easeOutCubic;
  final _rng = Random();

  double _beginRot = 0;
  double _endRot = 0;
  double _restRot = 0;
  bool _spinning = false;

  /// Pola usunięte z puli w tej sesji (gdy „usuń wylosowanego").
  final Set<String> _removed = {};
  final List<String> _history = [];
  String? _result;
  List<String> _spinPool = [];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4200));
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) _onSpinComplete();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<String> get _effectivePool =>
      widget.pool.where((e) => !_removed.contains(e)).toList();

  double get _rotation =>
      _beginRot + (_endRot - _beginRot) * _curve.transform(_ctrl.value);

  void _spin() {
    if (_spinning) return;
    final pool = _effectivePool;
    if (pool.isEmpty) {
      _toast(AppText.t.wheel_poolEmpty);
      return;
    }
    final n = pool.length;
    final winner = _rng.nextInt(n);
    final seg = 2 * pi / n;
    final centerAngle = winner * seg + seg / 2;
    // Pointer na górze (12:00 = 3π/2 zgodnie z ruchem wskazówek, y w dół).
    final desired = (3 * pi / 2) - centerAngle;
    final minTarget = _restRot + 2 * pi * 6; // min. 6 obrotów
    final k = ((minTarget - desired) / (2 * pi)).ceil();
    setState(() {
      _spinPool = pool;
      _spinning = true;
      _result = null;
      _beginRot = _restRot;
      _endRot = desired + 2 * pi * k;
    });
    _ctrl.forward(from: 0);
  }

  void _onSpinComplete() {
    _restRot = _endRot;
    final pool = _spinPool;
    if (pool.isEmpty) {
      setState(() => _spinning = false);
      return;
    }
    // Wskaźnik wskazuje pole, którego środek trafił na górę.
    final n = pool.length;
    final seg = 2 * pi / n;
    // Odtwórz indeks z końcowej rotacji (odporne na zaokrąglenia).
    var idx = (((3 * pi / 2) - _restRot) / seg - 0.5).round() % n;
    idx = (idx % n + n) % n;
    final winner = pool[idx];
    setState(() {
      _spinning = false;
      _result = winner;
      _history.insert(0, winner);
      if (_history.length > 12) _history.removeLast();
      if (widget.removeOnPick) _removed.add(winner);
    });
  }

  void _resetPool() {
    setState(() {
      _removed.clear();
      _result = null;
    });
    _toast(AppText.t.wheel_poolReset);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final displayPool = _spinning ? _spinPool : _effectivePool;
    final size = widget.fullscreen
        ? (min(media.width, media.height) - 64).clamp(240.0, 480.0)
        : (media.width - 80).clamp(220.0, 340.0);
    final onDark = widget.fullscreen;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: size + 24,
          child: Center(
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (displayPool.isEmpty)
                    _emptyWheel(size, onDark)
                  else
                    AnimatedBuilder(
                      animation: _ctrl,
                      builder: (_, _) => Transform.rotate(
                        angle: _rotation,
                        child: CustomPaint(
                          size: Size.square(size),
                          painter: _WheelPainter(displayPool),
                        ),
                      ),
                    ),
                  // Piasta na środku
                  Container(
                    width: size * 0.16,
                    height: size * 0.16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accent, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.celebration,
                        color: AppColors.accent, size: 20),
                  ),
                  // Wskaźnik u góry
                  Positioned(
                    top: -2,
                    child: CustomPaint(
                      size: const Size(34, 28),
                      painter: _PointerPainter(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _resultBox(onDark),
        const SizedBox(height: 12),
        _spinButton(),
        const SizedBox(height: 8),
        _poolBar(displayPool.length, onDark),
        if (_history.isNotEmpty) ...[
          const SizedBox(height: 12),
          _historyCard(onDark),
        ],
      ],
    );
  }

  Widget _emptyWheel(double size, bool onDark) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: onDark ? Colors.white10 : const Color(0xFFEFF3FF),
        border: Border.all(color: const Color(0xFFCFE0FB)),
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(AppText.t.wheel_noFields,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 14,
                color: onDark ? Colors.white70 : AppColors.textLight)),
      ),
    );
  }

  Widget _resultBox(bool onDark) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: (_result == null || _spinning)
          ? SizedBox(
              key: const ValueKey('noresult'),
              height: widget.fullscreen ? 64 : 40,
              child: Center(
                child: Text(
                  _spinning ? AppText.t.wheel_spinning : AppText.t.wheel_pressSpin,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      color: onDark ? Colors.white60 : AppColors.textLight),
                ),
              ),
            )
          : Container(
              key: ValueKey(_result),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.accent, AppColors.accent2]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(AppText.t.wheel_drawn,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70)),
                  const SizedBox(height: 2),
                  Text(_result!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                          fontSize: widget.fullscreen ? 34 : 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ],
              ),
            ),
    );
  }

  Widget _spinButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _spinning ? null : _spin,
        icon: const Icon(Icons.casino, size: 24),
        label: Text(_spinning ? AppText.t.wheel_spinning : AppText.t.wheel_spin,
            style:
                GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white70,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _poolBar(int count, bool onDark) {
    final txtColor = onDark ? Colors.white70 : AppColors.textLight;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(AppText.t.wheel_inPool(count),
            style: GoogleFonts.inter(fontSize: 12, color: txtColor)),
        if (_removed.isNotEmpty) ...[
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: _resetPool,
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(AppText.t.wheel_reset),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
          ),
        ],
      ],
    );
  }

  Widget _historyCard(bool onDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: onDark ? Colors.white24 : const Color(0xFFE2EAF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppText.t.wheel_history,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: onDark ? Colors.white : AppColors.text)),
          const SizedBox(height: 8),
          for (var i = 0; i < _history.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    alignment: Alignment.center,
                    child: Text('${i + 1}',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: onDark ? Colors.white54 : AppColors.textLight)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(_history[i],
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w500,
                            color: onDark ? Colors.white : AppColors.text)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Rysuje segmenty koła z etykietami (naprzemienne odcienie niebieskiego).
class _WheelPainter extends CustomPainter {
  _WheelPainter(this.items);
  final List<String> items;

  static const _palette = [
    Color(0xFF1A56DB),
    Color(0xFF3B82F6),
    Color(0xFF1040B0),
    Color(0xFF60A5FA),
    Color(0xFF2563EB),
    Color(0xFF7AB0FF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final n = items.length;
    final seg = 2 * pi / n;

    final sep = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var i = 0; i < n; i++) {
      final fill = Paint()
        ..style = PaintingStyle.fill
        ..color = _palette[i % _palette.length];
      // Gdy 2 kolejne segmenty miałyby ten sam kolor (parzysta liczba pól),
      // wymuś kontrast między pierwszym i ostatnim.
      canvas.drawArc(rect, i * seg, seg, true, fill);
      canvas.drawArc(rect, i * seg, seg, true, sep);
      _drawLabel(canvas, center, radius, i * seg + seg / 2, items[i], seg);
    }

    // Obwódka koła
    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = Colors.white,
    );
  }

  void _drawLabel(Canvas canvas, Offset center, double radius, double angle,
      String text, double seg) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    var a = angle;
    var alignRight = true;
    // Na lewej połowie obróć tekst, by nie był „do góry nogami".
    if (a > pi / 2 && a < 3 * pi / 2) {
      a += pi;
      alignRight = false;
    }
    canvas.rotate(a);

    final maxWidth = radius * 0.66;
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.05),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
    )..layout(maxWidth: maxWidth);

    // Tekst biegnie promieniowo, kończąc się blisko krawędzi.
    if (alignRight) {
      canvas.translate(radius * 0.93 - tp.width, -tp.height / 2);
    } else {
      canvas.translate(-radius * 0.93, -tp.height / 2);
    }
    tp.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) => old.items != items;
}

/// Wskaźnik (trójkąt) u góry koła, wskazujący w dół.
class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawShadow(path, Colors.black54, 4, false);
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.fill
          ..color = const Color(0xFFEA580C));
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
