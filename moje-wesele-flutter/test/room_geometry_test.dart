// Weryfikuje geometrię planu sali względem logiki z wersji web.

import 'package:flutter_test/flutter_test.dart';
import 'package:moje_wesele/models/room_plan.dart';

void main() {
  test('ppm i wysokość kanwy z wymiarów sali', () {
    final geo = RoomGeometry(widthM: 14, lengthM: 10, tableDiameterM: 0);
    // 1400 / 14 = 100 px/m
    expect(geo.ppm, 100);
    // canvasH = max(760, 10*100) = 1000
    expect(geo.canvasH, 1000);
    expect(geo.hasDimensions, true);

    final empty = RoomGeometry(widthM: 0, lengthM: 0, tableDiameterM: 0);
    expect(empty.ppm, 40); // domyślnie 40
    expect(empty.canvasH, RoomGeometry.canvasBaseH);
  });

  test('wymiary stołu prostokątnego z rectWM/rectLM i wrap', () {
    final geo = RoomGeometry(widthM: 14, lengthM: 10, tableDiameterM: 0);
    final table = {'shape': 'rect', 'seats': 8, 'rectWM': 2.0, 'rectLM': 1.0};
    final (tw, th) = geo.tableDims(table);
    expect(tw, 200); // 2m * 100ppm
    expect(th, 100); // 1m * 100ppm
    final (ww, wh) = geo.tableWrap(table);
    expect(ww, 240); // +PAD*2
    expect(wh, 140);
  });

  test('wykrywanie kolizji stołów (AABB na pudełkach)', () {
    final geo = RoomGeometry(widthM: 14, lengthM: 10, tableDiameterM: 0);
    final tables = <Map<String, dynamic>>[
      {'id': 1, 'shape': 'round', 'seats': 8, 'posX': 0, 'posY': 0},
      {'id': 2, 'shape': 'round', 'seats': 8, 'posX': 500, 'posY': 500},
    ];
    // Stół 2 daleko — brak kolizji.
    expect(geo.tableOverlaps(tables, 2, 500, 500), false);
    // Stół 2 nasunięty na stół 1 — kolizja.
    expect(geo.tableOverlaps(tables, 2, 10, 10), true);
  });

  test('clamp pozycji stołu do obrysu sali', () {
    final geo = RoomGeometry(widthM: 14, lengthM: 10, tableDiameterM: 0);
    final table = {'shape': 'round', 'seats': 8, 'posX': 0, 'posY': 0};
    final (x, y) = geo.clampTable(table, 99999, 99999);
    final (w, h) = geo.tableWrap(table);
    expect(x, RoomGeometry.canvasW - w);
    expect(y, geo.canvasH - h);
    final (nx, ny) = geo.clampTable(table, -50, -50);
    expect(nx, 0);
    expect(ny, 0);
  });

  test('geometria elementu z obrotem zamienia wymiary', () {
    final geo = RoomGeometry(widthM: 14, lengthM: 10, tableDiameterM: 0);
    final el = {'wM': 3.0, 'lM': 1.0, 'rotation': 0};
    final g0 = geo.elementGeom(el);
    expect(g0.fpW, 300); // 3m*100
    expect(g0.fpH, 100);
    final g90 = geo.elementGeom({...el, 'rotation': 90});
    expect(g90.swap, true);
    expect(g90.fpW, 100); // zamienione
    expect(g90.fpH, 300);
  });
}
