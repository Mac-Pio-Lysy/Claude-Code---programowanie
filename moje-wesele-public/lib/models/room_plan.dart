import 'dart:math';

/// Geometria planu sali — odwzorowana z logiki w zrodlo-web/script.js
/// (roomPxPerMeter, rtTableDims, rtSeatPositions, _tableWrapSize, _elGeom,
/// kolizje i clamp). Współrzędne posX/posY są w pikselach kanwy (logicznych).
class RoomGeometry {
  RoomGeometry({
    required this.widthM,
    required this.lengthM,
    required this.tableDiameterM,
  });

  factory RoomGeometry.fromMeta(Map<dynamic, dynamic>? meta) {
    double d(dynamic v) => v is num ? v.toDouble() : 0;
    return RoomGeometry(
      widthM: d(meta?['widthM']),
      lengthM: d(meta?['lengthM']),
      tableDiameterM: d(meta?['tableDiameterM']),
    );
  }

  final double widthM;
  final double lengthM;
  final double tableDiameterM;

  static const double canvasW = 1400;
  static const double canvasBaseH = 760;
  static const double tablePad = 20;
  static const double elPad = 6;
  static const double zoomMin = 0.4;
  static const double zoomMax = 5;
  static const double zoomStep = 1.25;

  double get ppm => widthM > 0 ? canvasW / widthM : 40;

  double get canvasH => (widthM > 0 && lengthM > 0)
      ? max(canvasBaseH, (lengthM * ppm).roundToDouble())
      : canvasBaseH;

  bool get hasDimensions => widthM > 0 && lengthM > 0;

  // ── STOŁY ──────────────────────────────────────────────────────────────

  /// Wewnętrzne wymiary blatu (tw × th).
  (double, double) tableDims(Map<dynamic, dynamic> t) {
    final p = ppm;
    final seats = (t['seats'] as num?)?.toInt() ?? 0;
    final shape = (t['shape'] as String?) ?? 'round';
    if (shape == 'round') {
      final diamM = (t['diamM'] as num?)?.toDouble() ?? 0;
      if (diamM > 0) {
        final dd = (diamM * p).clamp(50.0, 500.0);
        return (dd, dd);
      }
      if (tableDiameterM > 0 && widthM > 0) {
        final dd = (tableDiameterM * p).clamp(50.0, 400.0);
        return (dd, dd);
      }
      final dd = max(86.0, 58 + seats * 5.0);
      return (dd, dd);
    }
    final rectWM = (t['rectWM'] as num?)?.toDouble() ?? 0;
    final rectLM = (t['rectLM'] as num?)?.toDouble() ?? 0;
    if (rectWM > 0 && rectLM > 0) {
      return ((rectWM * p).clamp(60.0, 700.0), (rectLM * p).clamp(40.0, 500.0));
    }
    return (max(118.0, 68 + seats * 9.0), 76.0);
  }

  /// Rozmiar „pudełka" stołu (z marginesem na miejsca) — do kolizji i clamp.
  (double, double) tableWrap(Map<dynamic, dynamic> t) {
    final (tw, th) = tableDims(t);
    final honor = t['isHonorTable'] == true;
    return (tw + tablePad * 2, th + tablePad * 2 + (honor ? 10 : 0));
  }

  /// Pozycje miejsc wokół stołu (względem wrap-a, środek w PAD+tw/2).
  List<Offset2> seatPositions(Map<dynamic, dynamic> t) {
    final (tw, th) = tableDims(t);
    final n = (t['seats'] as num?)?.toInt() ?? 0;
    if (n <= 0) return const [];
    final cx = tablePad + tw / 2;
    final cy = tablePad + th / 2;
    final shape = (t['shape'] as String?) ?? 'round';
    final honor = t['isHonorTable'] == true;

    if (shape == 'round') {
      final r = tw / 2 + 14;
      return [
        for (var i = 0; i < n; i++)
          Offset2(cx + r * cos(i * 2 * pi / n - pi / 2),
              cy + r * sin(i * 2 * pi / n - pi / 2)),
      ];
    }
    if (honor) {
      const pad = 10.0;
      final xStart = cx - tw / 2 + pad;
      final xEnd = cx + tw / 2 - pad;
      final y = cy + th / 2 + 15;
      return [
        for (var i = 0; i < n; i++)
          Offset2(xStart + (n > 1 ? i / (n - 1) : 0.5) * (xEnd - xStart), y),
      ];
    }
    final perimeter = 2 * (tw + th);
    const gap = 15.0;
    final out = <Offset2>[];
    for (var i = 0; i < n; i++) {
      final dd = i * perimeter / n;
      double x, y;
      if (dd < tw) {
        x = cx - tw / 2 + dd;
        y = cy - th / 2 - gap;
      } else if (dd < tw + th) {
        x = cx + tw / 2 + gap;
        y = cy - th / 2 + (dd - tw);
      } else if (dd < 2 * tw + th) {
        x = cx + tw / 2 - (dd - tw - th);
        y = cy + th / 2 + gap;
      } else {
        x = cx - tw / 2 - gap;
        y = cy + th / 2 - (dd - 2 * tw - th);
      }
      out.add(Offset2(x, y));
    }
    return out;
  }

  /// Clamp pozycji stołu do obrysu sali.
  (double, double) clampTable(Map<dynamic, dynamic> t, double x, double y) {
    final (w, h) = tableWrap(t);
    final maxX = max(0.0, canvasW - w);
    final maxY = max(0.0, canvasH - h);
    return (x.clamp(0.0, maxX), y.clamp(0.0, maxY));
  }

  /// Czy stół [id] na (x,y) nachodziłby na inny stół?
  bool tableOverlaps(
      List<Map<dynamic, dynamic>> tables, int id, double x, double y) {
    final mt = tables.where((t) => (t['id'] as num?)?.toInt() == id).firstOrNull;
    if (mt == null) return false;
    final (mw, mh) = tableWrap(mt);
    for (final o in tables) {
      if ((o['id'] as num?)?.toInt() == id) continue;
      final ox = (o['posX'] as num?)?.toDouble() ?? 0;
      final oy = (o['posY'] as num?)?.toDouble() ?? 0;
      final (ow, oh) = tableWrap(o);
      if (x < ox + ow && x + mw > ox && y < oy + oh && y + mh > oy) {
        return true;
      }
    }
    return false;
  }

  // ── ELEMENTY ──────────────────────────────────────────────────────────

  /// Geometria elementu z uwzględnieniem obrotu (fpW/fpH po obrocie).
  ElementGeom elementGeom(Map<dynamic, dynamic> el) {
    final p = ppm;
    final tw = max(46.0, ((el['wM'] as num?)?.toDouble() ?? 1) * p);
    final th = max(36.0, ((el['lM'] as num?)?.toDouble() ?? 1) * p);
    final rot = ((((el['rotation'] as num?)?.toInt() ?? 0) % 360) + 360) % 360;
    final swap = rot == 90 || rot == 270;
    return ElementGeom(
      tw: tw,
      th: th,
      rotation: rot,
      swap: swap,
      fpW: swap ? th : tw,
      fpH: swap ? tw : th,
    );
  }

  (double, double) clampElement(Map<dynamic, dynamic> el, double x, double y) {
    final g = elementGeom(el);
    final wrapW = g.fpW + elPad * 2;
    final wrapH = g.fpH + elPad * 2;
    return (x.clamp(0.0, max(0.0, canvasW - wrapW)),
        y.clamp(0.0, max(0.0, canvasH - wrapH)));
  }
}

class Offset2 {
  const Offset2(this.x, this.y);
  final double x;
  final double y;
}

class ElementGeom {
  const ElementGeom({
    required this.tw,
    required this.th,
    required this.rotation,
    required this.swap,
    required this.fpW,
    required this.fpH,
  });
  final double tw;
  final double th;
  final int rotation;
  final bool swap;
  final double fpW;
  final double fpH;
}

/// Typy elementów sali (z `_elementType`) — ikona i etykieta.
class RoomElementType {
  const RoomElementType(this.id, this.label, this.icon);
  final String id;
  final String label;
  final String icon;

  static const options = [
    RoomElementType('orkiestra', 'Orkiestra', '🎻'),
    RoomElementType('dj', 'DJ', '🎧'),
    RoomElementType('parkiet', 'Parkiet', '💃'),
    RoomElementType('bar', 'Bar', '🍸'),
    RoomElementType('scena', 'Scena', '🎭'),
    RoomElementType('custom', 'Inne', '➕'),
  ];

  static String typeOf(String name) {
    final n = name.toLowerCase();
    if (n.contains('parkiet')) return 'parkiet';
    if (n.contains('orkiestra')) return 'orkiestra';
    if (n.contains('dj')) return 'dj';
    if (n.contains('bar')) return 'bar';
    if (n.contains('scen')) return 'scena';
    return 'custom';
  }

  static String iconOf(String type) =>
      options.where((o) => o.id == type).map((o) => o.icon).firstOrNull ?? '📦';
}
