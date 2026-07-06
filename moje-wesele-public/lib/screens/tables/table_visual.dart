import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app_colors.dart';
import '../../models/guest.dart';

/// Pozycje miejsc wokół stołu (odwzorowane z `getSeatPositions()` w wersji web).
class _SeatLayout {
  _SeatLayout(this.canvas, this.seats);
  final Size canvas;
  final List<Offset> seats;
}

_SeatLayout _computeSeats(String shape, int n, bool isHonor) {
  if (n <= 0) return _SeatLayout(const Size(200, 200), const []);

  if (shape == 'round') {
    const cx = 100.0, cy = 100.0, r = 68.0;
    final seats = [
      for (var i = 0; i < n; i++)
        Offset(
          cx + r * cos(i * 2 * pi / n - pi / 2),
          cy + r * sin(i * 2 * pi / n - pi / 2),
        ),
    ];
    return _SeatLayout(const Size(200, 200), seats);
  }

  // Prostokąt: kontener 260×200, blat 160×100 wyśrodkowany w (130,100).
  const cx = 130.0, cy = 100.0, tw = 160.0, th = 100.0, gap = 28.0;

  if (isHonor) {
    const pad = 18.0;
    const xStart = cx - tw / 2 + pad;
    const xEnd = cx + tw / 2 - pad;
    final seats = [
      for (var i = 0; i < n; i++)
        Offset(
          xStart + (n > 1 ? i / (n - 1) : 0.5) * (xEnd - xStart),
          cy + th / 2 + gap,
        ),
    ];
    return _SeatLayout(const Size(260, 200), seats);
  }

  const perimeter = 2 * (tw + th);
  final seats = <Offset>[];
  for (var i = 0; i < n; i++) {
    final d = i * perimeter / n;
    double x, y;
    if (d < tw) {
      x = cx - tw / 2 + d;
      y = cy - th / 2 - gap;
    } else if (d < tw + th) {
      x = cx + tw / 2 + gap;
      y = cy - th / 2 + (d - tw);
    } else if (d < 2 * tw + th) {
      x = cx + tw / 2 - (d - tw - th);
      y = cy + th / 2 + gap;
    } else {
      x = cx - tw / 2 - gap;
      y = cy + th / 2 - (d - 2 * tw - th);
    }
    seats.add(Offset(x, y));
  }
  return _SeatLayout(const Size(260, 200), seats);
}

/// Graficzny stół: blat (okrągły/prostokątny) z nazwą oraz miejsca wokół.
/// Zajęte miejsca to awatary gości, które można przeciągać (long-press).
class TableVisual extends StatelessWidget {
  const TableVisual({
    super.key,
    required this.table,
    required this.guestById,
    required this.onGuestTap,
  });

  final Map<String, dynamic> table;
  final Map<int, Guest> guestById;
  final void Function(Guest guest) onGuestTap;

  static const double _seatSize = 30;

  @override
  Widget build(BuildContext context) {
    final shape = (table['shape'] as String?) ?? 'round';
    final isRound = shape == 'round';
    final isHonor = table['isHonorTable'] == true;
    final seatsData = (table['seatsData'] as List?) ?? const [];
    final seatCount = seatsData.length;
    final name = (table['name'] as String?) ?? 'Stół';

    final layout = _computeSeats(shape, seatCount, isHonor);

    return SizedBox(
      width: layout.canvas.width,
      height: layout.canvas.height,
      child: Stack(
        children: [
          // Blat stołu
          _tableBody(isRound, isHonor, name),
          // Miejsca
          for (var i = 0; i < layout.seats.length; i++)
            Positioned(
              left: layout.seats[i].dx - _seatSize / 2,
              top: layout.seats[i].dy - _seatSize / 2,
              child: _seat(seatsData.length > i ? seatsData[i] : null),
            ),
        ],
      ),
    );
  }

  Widget _tableBody(bool isRound, bool isHonor, String name) {
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isHonor
          ? const [Color(0xFFB45309), Color(0xFFF59E0B)]
          : const [AppColors.accent, AppColors.accent2],
    );

    if (isRound) {
      return Positioned(
        left: 100 - 46,
        top: 100 - 46,
        child: Container(
          width: 92,
          height: 92,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient),
          child: _bodyLabel(name, isHonor),
        ),
      );
    }
    return Positioned(
      left: 130 - 80,
      top: 100 - 50,
      child: Container(
        width: 160,
        height: 100,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: _bodyLabel(name, isHonor),
      ),
    );
  }

  Widget _bodyLabel(String name, bool isHonor) {
    return Text(
      '${isHonor ? '★ ' : ''}$name',
      textAlign: TextAlign.center,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }

  Widget _seat(dynamic guestIdRaw) {
    final guestId = (guestIdRaw as num?)?.toInt();
    if (guestId == null) return const _EmptySeat();

    final guest = guestById[guestId];
    if (guest == null) return const _EmptySeat();

    final avatar = _SeatAvatar(initials: guest.initials);

    return LongPressDraggable<int>(
      data: guestId,
      feedback: _SeatAvatar(initials: guest.initials, dragging: true),
      childWhenDragging: const _EmptySeat(),
      child: GestureDetector(
        onTap: () => onGuestTap(guest),
        child: Tooltip(message: guest.fullName, child: avatar),
      ),
    );
  }
}

class _EmptySeat extends StatelessWidget {
  const _EmptySeat();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF1F5F9),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: const Icon(Icons.add, size: 14, color: Color(0xFF94A3B8)),
    );
  }
}

class _SeatAvatar extends StatelessWidget {
  const _SeatAvatar({required this.initials, this.dragging = false});
  final String initials;
  final bool dragging;

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: dragging ? 36 : 30,
      height: dragging ? 36 : 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A56DB), Color(0xFF3B82F6)],
        ),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: dragging
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.4),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: Text(
        initials.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
    return dragging ? Material(color: Colors.transparent, child: avatar) : avatar;
  }
}
