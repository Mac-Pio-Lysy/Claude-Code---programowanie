import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_colors.dart';

/// Wzór graficzny 3×3 (jak blokada Androida). Użytkownik łączy punkty,
/// a kolejność wybranych węzłów (0–8) tworzy sekret.
///
/// Minimalna długość wzoru to [minNodes]. Po podniesieniu palca wywoływany
/// jest [onCompleted] z listą indeksów; rodzic decyduje o serializacji.
class PatternLock extends StatefulWidget {
  const PatternLock({
    super.key,
    required this.onCompleted,
    this.error = false,
    this.minNodes = 4,
    this.size = 280,
  });

  final ValueChanged<List<int>> onCompleted;
  final bool error;
  final int minNodes;
  final double size;

  /// Serializacja wzoru do postaci przechowywanej/haszowanej.
  static String serialize(List<int> nodes) => nodes.join('-');

  @override
  State<PatternLock> createState() => _PatternLockState();
}

class _PatternLockState extends State<PatternLock> {
  final List<int> _selected = [];
  Offset? _cursor;

  late List<Offset> _nodes;

  static const double _hitRadius = 28;

  void _computeNodes(double size) {
    const margin = 36.0;
    final step = (size - margin * 2) / 2;
    _nodes = [
      for (var r = 0; r < 3; r++)
        for (var c = 0; c < 3; c++)
          Offset(margin + c * step, margin + r * step),
    ];
  }

  int? _nodeAt(Offset p) {
    for (var i = 0; i < _nodes.length; i++) {
      if ((p - _nodes[i]).distance <= _hitRadius) return i;
    }
    return null;
  }

  void _addNode(int i) {
    if (_selected.contains(i)) return;
    // Domknij węzeł pośredni leżący w linii prostej (jak na Androidzie).
    if (_selected.isNotEmpty) {
      final prev = _selected.last;
      final mid = _between(prev, i);
      if (mid != null && !_selected.contains(mid)) _selected.add(mid);
    }
    _selected.add(i);
    HapticFeedback.selectionClick();
  }

  /// Indeks węzła leżącego dokładnie pomiędzy a i b (lub null).
  int? _between(int a, int b) {
    final ar = a ~/ 3, ac = a % 3;
    final br = b ~/ 3, bc = b % 3;
    final dr = br - ar, dc = bc - ac;
    if (dr.abs() == 2 && dc.abs() == 2 || // przekątna
        (dr.abs() == 2 && dc == 0) ||
        (dc.abs() == 2 && dr == 0)) {
      return (ar + dr ~/ 2) * 3 + (ac + dc ~/ 2);
    }
    return null;
  }

  void _start(Offset p) {
    setState(() {
      _selected.clear();
      _cursor = p;
      final i = _nodeAt(p);
      if (i != null) _addNode(i);
    });
  }

  void _update(Offset p) {
    setState(() {
      _cursor = p;
      final i = _nodeAt(p);
      if (i != null) _addNode(i);
    });
  }

  void _end() {
    final result = List<int>.of(_selected);
    _cursor = null;
    _selected.clear();
    if (mounted) setState(() {});
    if (result.length >= widget.minNodes) {
      widget.onCompleted(result);
    } else if (result.isNotEmpty) {
      // Za krótki — sygnalizujemy pustą listą, by rodzic pokazał błąd.
      widget.onCompleted(const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = min(widget.size, MediaQuery.sizeOf(context).width - 64);
    _computeNodes(size);
    return GestureDetector(
      onPanStart: (d) => _start(d.localPosition),
      onPanUpdate: (d) => _update(d.localPosition),
      onPanEnd: (_) => _end(),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _PatternPainter(
            nodes: _nodes,
            selected: _selected,
            cursor: _cursor,
            error: widget.error,
          ),
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  _PatternPainter({
    required this.nodes,
    required this.selected,
    required this.cursor,
    required this.error,
  });

  final List<Offset> nodes;
  final List<int> selected;
  final Offset? cursor;
  final bool error;

  @override
  void paint(Canvas canvas, Size size) {
    final active = error ? const Color(0xFFC0392B) : AppColors.accent;

    // Linie pomiędzy wybranymi węzłami.
    final linePaint = Paint()
      ..color = active.withValues(alpha: 0.55)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < selected.length - 1; i++) {
      canvas.drawLine(nodes[selected[i]], nodes[selected[i + 1]], linePaint);
    }
    if (selected.isNotEmpty && cursor != null) {
      canvas.drawLine(nodes[selected.last], cursor!, linePaint);
    }

    // Węzły.
    for (var i = 0; i < nodes.length; i++) {
      final on = selected.contains(i);
      canvas.drawCircle(
        nodes[i],
        on ? 10 : 8,
        Paint()..color = on ? active : const Color(0xFFC3D2EC),
      );
      canvas.drawCircle(
        nodes[i],
        on ? 22 : 18,
        Paint()
          ..color = on ? active.withValues(alpha: 0.18) : Colors.transparent
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        nodes[i],
        on ? 22 : 18,
        Paint()
          ..color = on ? active : const Color(0xFFD7E0F0)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter old) =>
      old.selected.length != selected.length ||
      old.cursor != cursor ||
      old.error != error;
}
