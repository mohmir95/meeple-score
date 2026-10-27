import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'finger_picker.dart';

/// The Treasure Hunt: every finger plants a flag on a treasure map, and
/// dotted trails race to the chest. The first to arrive wins the treasure.
class TreasurePainter extends CustomPainter {
  const TreasurePainter({required this.picker, required this.now});

  final FingerPicker picker;
  final Duration now;

  static const _ink = Color(0xFF5B3A1E);
  static const _parchment = Color(0xFFF1DDB0);
  static const _parchmentDark = Color(0xFFD9B97A);
  static const _wood = Color(0xFF8B5A2B);
  static const _woodDark = Color(0xFF5A3517);
  static const _gold = Color(0xFFFFC83D);
  static const _goldDark = Color(0xFFB8860B);

  /// How long the map shakes when the race starts.
  static const _quake = Duration(milliseconds: 450);

  double get _t => now.inMicroseconds / 1e6;

  bool get _picked =>
      picker.phase == FingerPhase.picked && picker.winner != null;

  /// How far through the race we are, from 0 to 1 (1 once picked).
  double get _race {
    if (_picked) {
      return 1;
    }
    if (picker.phase != FingerPhase.deciding) {
      return 0;
    }
    return ((now - picker.decidingAt).inMicroseconds /
            picker.decideTime.inMicroseconds)
        .clamp(0.0, 1.0);
  }

  /// The trail that wins: drawn secretly when the race starts.
  int? get _racer => picker.chosen?.pointer ?? picker.winner?.pointer;

  /// How much of its own trail a path has covered, as a share of its own
  /// length, so a flag planted close to the chest gets no head start.
  ///
  /// Every trail keeps its own steady pace for the whole race: the chosen
  /// one is fastest from the start and arrives just as the race ends, while
  /// the others, each a little slower, are still on their way.
  double _covered(FingerTouch touch) {
    final race = _race;
    final seed = picker.decidingAt.inMilliseconds;
    final pace = touch.pointer == _racer
        ? 1.0
        : 0.72 + 0.18 * ((_hash(touch.pointer, seed) % 1000) / 1000);
    // A steady pace from the first moment, so the leader shows early, with a
    // small drift so no trail looks robotic. The drift is zero at both ends
    // and too small to let anyone overtake.
    final drift =
        0.03 * math.sin(race * math.pi * 3 + touch.pointer) * race * (1 - race);
    return (pace * race + drift).clamp(0.0, 1.0);
  }

  static int _hash(int pointer, int seed) =>
      ((pointer + 31) * 2654435761 + seed * 40503) & 0x7fffffff;

  @override
  void paint(Canvas canvas, Size size) {
    final chest = Offset(size.width / 2, size.height * 0.47);
    final c = (math.min(size.width, size.height) * 0.09).clamp(30.0, 52.0);

    // The ground shakes as the race begins.
    if (picker.phase == FingerPhase.deciding) {
      final quake = 1 -
          ((now - picker.decidingAt).inMicroseconds / _quake.inMicroseconds)
              .clamp(0.0, 1.0);
      if (quake > 0) {
        canvas.translate(
          math.sin(_t * 70) * 6 * quake,
          math.cos(_t * 63) * 4 * quake,
        );
      }
    }

    _paintMap(canvas, size);

    final winner = picker.winner;
    final open = _picked
        ? ((now - picker.pickedAt!).inMilliseconds / 450).clamp(0.0, 1.0)
        : 0.0;

    final fingers = picker.touches.values.toList();
    final all = [
      ...fingers,
      if (_picked && !picker.touches.containsKey(winner!.pointer)) winner,
    ];

    // Trails first, so flags and the chest sit on top of them.
    if (_race > 0) {
      for (final touch in all) {
        final isRacer = touch.pointer == _racer;
        _paintTrail(
          canvas,
          touch,
          chest,
          c,
          covered: _covered(touch),
          fade: _picked && !isRacer ? 1 - open * 0.7 : 1,
          glow: isRacer && _picked,
        );
      }
    }

    _paintCountdown(canvas, chest, c);
    _paintChest(
      canvas,
      chest,
      c,
      open: open,
      glow: _picked ? fingerPalette[winner!.colorIndex] : null,
    );

    for (final touch in all) {
      final isWinner = _picked && touch.pointer == winner!.pointer;
      _paintFlag(canvas, touch, dim: _picked && !isWinner, winner: isWinner);
    }

    if (_picked) {
      _paintCoins(canvas, chest, c);
    }
  }

  void _paintMap(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = const Color(0xFF3E2A18));
    final paper = RRect.fromRectAndRadius(
      rect.deflate(6),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      paper,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.1),
          radius: 0.95,
          colors: [_parchment, _parchment, _parchmentDark, Color(0xFFA8783C)],
          stops: [0, 0.5, 0.85, 1],
        ).createShader(rect),
    );
    // Faint map grid.
    final grid = Paint()
      ..color = _ink.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    for (var x = 40.0; x < size.width; x += 56) {
      canvas.drawLine(Offset(x, 6), Offset(x, size.height - 6), grid);
    }
    for (var y = 40.0; y < size.height; y += 56) {
      canvas.drawLine(Offset(6, y), Offset(size.width - 6, y), grid);
    }

    final ink = Paint()
      ..color = _ink.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    // Mountains.
    for (final (fx, fy, s) in const [
      (0.18, 0.3, 1.0),
      (0.26, 0.27, 0.8),
      (0.8, 0.68, 1.1),
    ]) {
      final at = Offset(size.width * fx, size.height * fy);
      canvas.drawPath(
        Path()
          ..moveTo(at.dx - 16 * s, at.dy)
          ..lineTo(at.dx, at.dy - 20 * s)
          ..lineTo(at.dx + 16 * s, at.dy)
          ..moveTo(at.dx - 4 * s, at.dy - 15 * s)
          ..lineTo(at.dx, at.dy - 11 * s)
          ..lineTo(at.dx + 4 * s, at.dy - 15 * s),
        ink,
      );
    }
    // Little trees.
    for (final (fx, fy) in const [
      (0.72, 0.22),
      (0.76, 0.25),
      (0.68, 0.26),
      (0.22, 0.72),
      (0.27, 0.75),
    ]) {
      final at = Offset(size.width * fx, size.height * fy);
      canvas.drawCircle(at, 6, ink);
      canvas.drawLine(at + const Offset(0, 6), at + const Offset(0, 12), ink);
    }
    // Waves along the bottom.
    for (var i = 0; i < 5; i++) {
      final at = Offset(size.width * (0.12 + i * 0.19), size.height * 0.88);
      canvas.drawPath(
        Path()
          ..moveTo(at.dx - 12, at.dy)
          ..quadraticBezierTo(at.dx - 6, at.dy - 6, at.dx, at.dy)
          ..quadraticBezierTo(at.dx + 6, at.dy - 6, at.dx + 12, at.dy),
        ink,
      );
    }
    _paintCompass(canvas, Offset(size.width - 46, 52));
  }

  void _paintCompass(Canvas canvas, Offset at) {
    final ink = Paint()..color = _ink.withValues(alpha: 0.45);
    canvas.drawCircle(
      at,
      26,
      Paint()
        ..color = _ink.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    for (var i = 0; i < 4; i++) {
      final angle = -math.pi / 2 + i * math.pi / 2;
      final dir = Offset(math.cos(angle), math.sin(angle));
      final side = Offset(-dir.dy, dir.dx);
      canvas.drawPath(
        Path()
          ..moveTo(at.dx + dir.dx * 24, at.dy + dir.dy * 24)
          ..lineTo(at.dx + side.dx * 5, at.dy + side.dy * 5)
          ..lineTo(at.dx - side.dx * 5, at.dy - side.dy * 5)
          ..close(),
        i == 0 ? (Paint()..color = const Color(0xFFA33B2A)) : ink,
      );
    }
  }

  /// Point [s] (0 to 1) along a finger's trail to the chest. Trails bend a
  /// little, like hand-drawn routes.
  Offset _trailPoint(FingerTouch touch, Offset chest, double c, double s) {
    final line = chest - touch.position;
    final length = line.distance;
    if (length < 1) {
      return chest;
    }
    final dir = line / length;
    final end = chest - dir * c * 1.15;
    final normal = Offset(-dir.dy, dir.dx);
    final bend = normal * length * 0.18 * (touch.pointer.isEven ? 1 : -1);
    final control = Offset.lerp(touch.position, end, 0.5)! + bend;
    final u = 1 - s;
    return touch.position * (u * u) + control * (2 * u * s) + end * (s * s);
  }

  void _paintTrail(
    Canvas canvas,
    FingerTouch touch,
    Offset chest,
    double c, {
    required double covered,
    required double fade,
    required bool glow,
  }) {
    if (covered <= 0) {
      return;
    }
    final color = fingerPalette[touch.colorIndex];
    final dash = Paint()
      ..color = Color.lerp(color, _ink, 0.35)!.withValues(alpha: fade)
      ..strokeWidth = glow ? 5 : 4
      ..strokeCap = StrokeCap.round;
    if (glow) {
      final path = Path();
      for (var i = 0; i <= 40; i++) {
        final p = _trailPoint(touch, chest, c, i / 40);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    // Dashes, like a pirate's dotted route.
    // Fixed 8px dashes and gaps, whatever the trail's length.
    dash.strokeCap = StrokeCap.butt;
    const steps = 160;
    final end = covered.clamp(0.0, 1.0);
    var travelled = 0.0;
    var previous = _trailPoint(touch, chest, c, 0);
    for (var i = 1; i <= steps && i / steps <= end; i++) {
      final point = _trailPoint(touch, chest, c, i / steps);
      final step = (point - previous).distance;
      if ((travelled % 16) < 8) {
        canvas.drawLine(previous, point, dash);
      }
      travelled += step;
      previous = point;
    }
    // Footsteps at the head of the trail.
    final head = _trailPoint(touch, chest, c, covered.clamp(0.0, 1.0));
    canvas.drawCircle(
      head,
      6,
      Paint()..color = color.withValues(alpha: fade),
    );
    canvas.drawCircle(
      head,
      6,
      Paint()
        ..color = _ink.withValues(alpha: fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _paintCountdown(Canvas canvas, Offset chest, double c) {
    final progress = picker.armProgress(now);
    if (picker.phase != FingerPhase.arming || progress <= 0) {
      return;
    }
    final rect = Rect.fromCircle(center: chest, radius: c * 1.7);
    const dashes = 24;
    final paint = Paint()
      ..color = const Color(0xFFA33B2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < (dashes * progress).floor(); i++) {
      canvas.drawArc(
        rect,
        -math.pi / 2 + i * math.pi * 2 / dashes,
        math.pi / dashes,
        false,
        paint,
      );
    }
  }

  /// The treasure chest. [open] lifts the lid (0 to 1).
  void _paintChest(
    Canvas canvas,
    Offset at,
    double c, {
    required double open,
    Color? glow,
  }) {
    final w = c * 2;
    final h = c * 1.2;
    final bodyTop = at.dy - h * 0.15;
    // A red X under the chest.
    final x = Paint()
      ..color = const Color(0xFFA33B2A).withValues(alpha: 0.55)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      at + Offset(-c * 1.3, h * 0.2),
      at + Offset(c * 1.3, h * 1.0),
      x,
    );
    canvas.drawLine(
      at + Offset(c * 1.3, h * 0.2),
      at + Offset(-c * 1.3, h * 1.0),
      x,
    );
    if (glow != null) {
      canvas.drawCircle(
        at,
        c * 2.6 * (0.9 + 0.1 * math.sin(_t * 4)),
        Paint()
          ..color = glow.withValues(alpha: 0.45 * open)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
      );
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(at.dx, bodyTop + h * 0.9),
        width: w * 1.2,
        height: h * 0.3,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    final body = Rect.fromLTWH(at.dx - w / 2, bodyTop, w, h * 0.8);
    if (open > 0) {
      // Treasure shining from inside.
      canvas.drawRect(
        Rect.fromLTWH(body.left + 4, bodyTop - 6, w - 8, 12),
        Paint()..color = _gold,
      );
      canvas.drawCircle(
        Offset(at.dx, bodyTop),
        c * 0.9 * open,
        Paint()
          ..color = _gold.withValues(alpha: 0.7 * open)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(4)),
      Paint()..color = _wood,
    );
    // Planks and gold bands.
    final plank = Paint()
      ..color = _woodDark
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(body.left, body.center.dy),
      Offset(body.right, body.center.dy),
      plank,
    );
    for (final fx in const [0.18, 0.82]) {
      canvas.drawRect(
        Rect.fromLTWH(body.left + w * fx - 4, bodyTop, 8, body.height),
        Paint()..color = _goldDark,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(4)),
      Paint()
        ..color = _woodDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // The lid hinges open at the back.
    canvas.save();
    canvas.translate(at.dx, bodyTop);
    canvas.transform(
      (Matrix4.identity()..scaleByDouble(1, 1 - 1.7 * open, 1, 1)).storage,
    );
    final lid = Path()
      ..moveTo(-w / 2, 0)
      ..lineTo(-w / 2, -h * 0.3)
      ..quadraticBezierTo(0, -h * 0.75, w / 2, -h * 0.3)
      ..lineTo(w / 2, 0)
      ..close();
    canvas.drawPath(lid, Paint()..color = Color.lerp(_wood, Colors.white, 0.08)!);
    for (final fx in const [-0.32, 0.32]) {
      canvas.drawRect(
        Rect.fromLTWH(w * fx - 4, -h * 0.55, 8, h * 0.55),
        Paint()..color = _goldDark,
      );
    }
    canvas.drawPath(
      lid,
      Paint()
        ..color = _woodDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.restore();
    // The lock.
    if (open < 0.3) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(at.dx, bodyTop + 4),
            width: 12,
            height: 14,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = _gold,
      );
    }
  }

  void _paintFlag(
    Canvas canvas,
    FingerTouch touch, {
    required bool dim,
    required bool winner,
  }) {
    final color = fingerPalette[touch.colorIndex];
    canvas.drawCircle(
      touch.position,
      28 * (1 + 0.05 * math.sin(_t * 5 + touch.pointer)),
      Paint()
        ..color = color.withValues(alpha: dim ? 0.3 : 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = winner ? 6 : 4,
    );
    final pop = Curves.elasticOut.transform(
      ((now - touch.since).inMilliseconds / 500).clamp(0.0, 1.0),
    );
    if (pop <= 0.01) {
      return;
    }
    // Planted just above the finger so it stays visible.
    final base = touch.position - const Offset(0, 26);
    final pole = 44 * pop;
    canvas.drawLine(
      base,
      base - Offset(0, pole),
      Paint()
        ..color = _ink.withValues(alpha: dim ? 0.5 : 1)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    final top = base - Offset(0, pole);
    final wave = math.sin(_t * 6 + touch.pointer) * 3;
    final cloth = Path()
      ..moveTo(top.dx, top.dy)
      ..quadraticBezierTo(top.dx + 12, top.dy + wave, top.dx + 26 * pop, top.dy + 8)
      ..quadraticBezierTo(
        top.dx + 12,
        top.dy + 14 - wave,
        top.dx,
        top.dy + 18,
      )
      ..close();
    canvas.drawPath(
      cloth,
      Paint()..color = color.withValues(alpha: dim ? 0.45 : 1),
    );
    canvas.drawPath(
      cloth,
      Paint()
        ..color = _ink.withValues(alpha: dim ? 0.3 : 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    canvas.drawOval(
      Rect.fromCenter(center: base, width: 14, height: 5),
      Paint()..color = _ink.withValues(alpha: 0.35),
    );
  }

  /// Gold coins bursting from the open chest.
  void _paintCoins(Canvas canvas, Offset chest, double c) {
    final tau = (now - picker.pickedAt!).inMicroseconds / 1e6 - 0.2;
    if (tau < 0 || tau > 2) {
      return;
    }
    final origin = chest - Offset(0, c * 0.3);
    final gravity = c * 14;
    for (var i = 0; i < 22; i++) {
      final angle = -math.pi / 2 + (i / 22 - 0.5) * math.pi * 1.2;
      final speed = c * (4 + (i % 4) * 1.2);
      final at =
          origin +
          Offset(math.cos(angle), math.sin(angle)) * speed * tau +
          Offset(0, gravity * tau * tau / 2);
      final alpha = (1 - tau / 2).clamp(0.0, 1.0);
      // Spinning coins look like squashed ovals.
      final spin = math.cos(tau * 12 + i).abs();
      canvas.drawOval(
        Rect.fromCenter(center: at, width: 14 * spin + 2, height: 14),
        Paint()..color = _gold.withValues(alpha: alpha),
      );
      canvas.drawOval(
        Rect.fromCenter(center: at, width: 14 * spin + 2, height: 14),
        Paint()
          ..color = _goldDark.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TreasurePainter oldDelegate) => true;
}
