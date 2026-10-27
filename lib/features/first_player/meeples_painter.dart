import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'finger_picker.dart';

/// Magnetic Meeples: every finger gets a meeple on a shared tabletop. A
/// magnet drags them together and pulls one onto the first-player pedestal.
class MeeplesPainter extends CustomPainter {
  const MeeplesPainter({required this.picker, required this.now});

  final FingerPicker picker;
  final Duration now;

  static const _gold = Color(0xFFFFC83D);
  static const _goldLight = Color(0xFFFFE9A0);
  static const _goldDark = Color(0xFFB8860B);
  static const _magnet = Color(0xFFD32F2F);
  static const _magnetDark = Color(0xFF8E1B1B);
  static const _steel = Color(0xFFCFD8DC);

  /// How long the winner's jump onto the pedestal takes.
  static const _jump = Duration(milliseconds: 700);

  /// The classic meeple, one unit tall, feet on y = 0.5.
  static final Path _meeple = Path.combine(
    PathOperation.union,
    Path()..addOval(Rect.fromCircle(center: const Offset(0, -0.32), radius: 0.17)),
    Path()
      ..moveTo(-0.11, -0.2)
      ..lineTo(-0.4, -0.1)
      ..quadraticBezierTo(-0.5, -0.05, -0.44, 0.04)
      ..lineTo(-0.17, 0.08)
      ..lineTo(-0.36, 0.46)
      ..quadraticBezierTo(-0.37, 0.5, -0.32, 0.5)
      ..lineTo(-0.07, 0.5)
      ..quadraticBezierTo(0, 0.28, 0.07, 0.5)
      ..lineTo(0.32, 0.5)
      ..quadraticBezierTo(0.37, 0.5, 0.36, 0.46)
      ..lineTo(0.17, 0.08)
      ..lineTo(0.44, 0.04)
      ..quadraticBezierTo(0.5, -0.05, 0.4, -0.1)
      ..lineTo(0.11, -0.2)
      ..close(),
  );

  double get _t => now.inMicroseconds / 1e6;

  static double _ease(double x) =>
      Curves.easeInOutCubic.transform(x.clamp(0.0, 1.0));

  bool get _picked =>
      picker.phase == FingerPhase.picked && picker.winner != null;

  @override
  void paint(Canvas canvas, Size size) {
    final pedestal = Offset(size.width / 2, size.height * 0.48);
    final m = (math.min(size.width, size.height) * 0.13).clamp(44.0, 76.0);

    _paintTable(canvas, size);

    final jump = _picked
        ? (now - picker.pickedAt!).inMicroseconds / _jump.inMicroseconds
        : 0.0;
    final landed = _picked && jump >= 1;
    if (landed) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = fingerPalette[picker.winner!.colorIndex].withValues(
            alpha: 0.14,
          ),
      );
    }

    _paintPedestal(canvas, pedestal, m, glow: landed);
    final magnet = pedestal - Offset(0, m * 2.4 + math.sin(_t * 2) * 4);

    final fingers = picker.touches.values.toList();
    final winner = picker.winner;
    // A winner who lifted their finger still stands on the pedestal.
    final all = [
      ...fingers,
      if (_picked && !picker.touches.containsKey(winner!.pointer)) winner,
    ];

    for (final touch in fingers) {
      final isWinner = _picked && touch.pointer == winner!.pointer;
      _paintRing(canvas, touch, dim: _picked && !isWinner);
    }

    // Where each meeple stands right now (feet position) and how it leans.
    final pulled = _racePositions(all, pedestal, m);
    final settled = _picked
        ? _racePositions(all, pedestal, m, settled: true)
        : const <Offset>[];
    final pieces = <(FingerTouch, Offset, double, double)>[];
    for (var i = 0; i < all.length; i++) {
      final touch = all[i];
      final home = _home(touch, m);
      final pop = Curves.elasticOut.transform(
        ((now - touch.since).inMilliseconds / 600).clamp(0.0, 1.0),
      );
      if (_picked) {
        final from = settled[i];
        final e = _ease(jump);
        if (touch.pointer == winner!.pointer) {
          // Hops up from beside the pedestal onto it.
          final at = Offset.lerp(from, pedestal, e)! -
              Offset(0, math.sin(math.pi * e.clamp(0, 1)) * m * 1.2);
          pieces.add((touch, at, landed ? math.sin(_t * 3) * 0.04 : 0, 1.15));
        } else {
          // Topples over and slides back to its player.
          final side = from.dx < pedestal.dx ? -1.0 : 1.0;
          pieces.add((
            touch,
            Offset.lerp(from, home, e)!,
            side * 1.45 * _ease(jump * 1.4),
            1.0,
          ));
        }
      } else {
        final excite = picker.phase == FingerPhase.arming
            ? picker.armProgress(now)
            : 0.0;
        final wobble =
            math.sin(_t * (3 + excite * 9) + touch.pointer) *
            (0.06 + excite * 0.1);
        pieces.add((touch, pulled[i], wobble, pop));
      }
    }

    if (picker.phase == FingerPhase.deciding) {
      _paintField(
        canvas,
        magnet,
        m,
        [for (final p in pieces) p.$2],
        strong: all.indexWhere((touch) => touch.pointer == _racer),
        // The leader's field line grows stronger as it pulls ahead.
        strength: _pull,
      );
    }
    _paintMagnet(canvas, magnet, m);
    _paintCountdown(canvas, magnet, m);

    // Back to front, so nearer meeples overlap the ones behind them.
    pieces.sort((a, b) => a.$2.dy.compareTo(b.$2.dy));
    for (final (touch, at, angle, scale) in pieces) {
      _paintMeeple(
        canvas,
        at,
        m,
        fingerPalette[touch.colorIndex],
        angle: angle,
        scale: scale,
        shadow: !_picked || angle.abs() < 0.3,
      );
    }

    if (landed) {
      _paintConfetti(canvas, pedestal - Offset(0, m * 1.1), m, winner!);
    }
  }

  /// Where a finger's meeple stands: just above the fingertip so the
  /// finger doesn't hide it.
  Offset _home(FingerTouch touch, double m) =>
      touch.position - Offset(0, m * 0.55);

  /// How far through the pull we are, from 0 to 1 (1 once picked).
  double get _pull {
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

  /// Share of its own way to the pedestal a meeple has covered, so a finger
  /// placed near the middle gets no head start. Each keeps its own steady
  /// pace for the whole race: the chosen one is fastest from the start and
  /// arrives just as the race ends, while the others, each a little slower,
  /// are still on their way. Nobody stalls.
  double _covered(FingerTouch touch, double race) {
    final seed = picker.decidingAt.inMilliseconds;
    final pace = touch.pointer == _racer
        ? 1.0
        : 0.72 + 0.18 * ((_hash(touch.pointer, seed) % 1000) / 1000);
    // A small drift so nobody looks robotic; zero at both ends and too
    // small to let anyone overtake.
    final drift =
        0.03 * math.sin(race * math.pi * 3 + touch.pointer) * race * (1 - race);
    return (pace * race + drift).clamp(0.0, 1.0);
  }

  static int _hash(int pointer, int seed) =>
      ((pointer + 31) * 2654435761 + seed * 40503) & 0x7fffffff;

  /// Pointer of the meeple that wins the race: drawn secretly when the pull
  /// starts, revealed when it ends.
  int? get _racer => picker.chosen?.pointer ?? picker.winner?.pointer;

  /// Meeple positions (feet) during the race to the pedestal.
  ///
  /// Each meeple sets off from its own spot and closes in at its own pace
  /// (see [_covered]); the chosen one leads all the way and arrives beside
  /// the pedestal. They bump apart like solid pieces, and the chosen one
  /// always has right of way. [settled] gives the final spots without the
  /// wobble.
  List<Offset> _racePositions(
    List<FingerTouch> touches,
    Offset pedestal,
    double m, {
    bool settled = false,
  }) {
    final race = settled ? 1.0 : _pull;
    final racer = _racer;
    final points = <Offset>[];
    for (var i = 0; i < touches.length; i++) {
      final touch = touches[i];
      final home = _home(touch, m);
      if (race == 0) {
        points.add(home);
        continue;
      }
      var dir = home - pedestal;
      dir = dir.distance < 1
          ? Offset(
              math.cos(i * 2.4 - math.pi / 2),
              math.sin(i * 2.4 - math.pi / 2),
            )
          : dir / dir.distance;
      // The finish line is beside the pedestal, ready to hop on.
      final finish = pedestal + dir * m * 0.95;
      final isRacer = touch.pointer == racer;
      var at = Offset.lerp(home, finish, _covered(touch, race))!;
      if (!settled) {
        // Nervous shuffling; the trailing meeples struggle a little more.
        final shake =
            m * (0.04 * math.sin(math.pi * race) + (isRacer ? 0 : 0.04 * race));
        at += Offset(
          math.sin(_t * 23 + touch.pointer * 5) * shake,
          math.cos(_t * 19 + touch.pointer * 3) * shake,
        );
      }
      points.add(at);
    }

    // Bump apart wherever two meeples would overlap.
    final gap = m * 0.75;
    for (var pass = 0; pass < 4; pass++) {
      for (var i = 0; i < points.length; i++) {
        for (var j = i + 1; j < points.length; j++) {
          final d = points[j] - points[i];
          final dist = d.distance;
          if (dist >= gap) {
            continue;
          }
          final away = dist == 0 ? const Offset(1, 0) : d / dist;
          final overlap = gap - dist;
          // The racer barges through; whoever is in the way is shoved aside.
          if (touches[i].pointer == racer) {
            points[j] += away * overlap;
          } else if (touches[j].pointer == racer) {
            points[i] -= away * overlap;
          } else {
            points[i] -= away * (overlap / 2);
            points[j] += away * (overlap / 2);
          }
        }
      }
    }
    return points;
  }

  void _paintTable(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.1),
          radius: 1.2,
          colors: [Color(0xFFC08A55), Color(0xFF94622F), Color(0xFF5E3A1B)],
          stops: [0, 0.6, 1],
        ).createShader(rect),
    );
    // Planks.
    final seam = Paint()
      ..color = const Color(0xFF4A2D14).withValues(alpha: 0.35)
      ..strokeWidth = 2;
    const planks = 5;
    for (var i = 1; i < planks; i++) {
      final x = size.width * i / planks;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), seam);
    }
    // Wood grain.
    final grain = Paint()
      ..color = const Color(0xFF4A2D14).withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var plank = 0; plank < planks; plank++) {
      final left = size.width * plank / planks;
      for (var line = 0; line < 3; line++) {
        final x = left + size.width / planks * (0.25 + line * 0.25);
        final path = Path()..moveTo(x, 0);
        for (var y = 0.0; y <= size.height; y += 24) {
          path.lineTo(x + math.sin(y / 70 + plank * 2 + line) * 5, y);
        }
        canvas.drawPath(path, grain);
      }
    }
  }

  void _paintPedestal(
    Canvas canvas,
    Offset top,
    double m, {
    required bool glow,
  }) {
    final rx = m * 0.75;
    final ry = rx * 0.32;
    final height = m * 0.45;
    canvas.drawOval(
      Rect.fromCenter(
        center: top + Offset(0, height + ry * 0.6),
        width: rx * 2.4,
        height: ry * 2.4,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    if (glow) {
      canvas.drawCircle(
        top,
        rx * 1.6,
        Paint()
          ..color = _gold.withValues(alpha: 0.45 + 0.15 * math.sin(_t * 4))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
      );
    }
    final body = Path()
      ..moveTo(top.dx - rx, top.dy)
      ..lineTo(top.dx - rx, top.dy + height)
      ..arcTo(
        Rect.fromCenter(
          center: top + Offset(0, height),
          width: rx * 2,
          height: ry * 2,
        ),
        math.pi,
        -math.pi,
        false,
      )
      ..lineTo(top.dx + rx, top.dy)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          colors: [_goldDark, _gold, _goldLight, _gold, _goldDark],
          stops: [0, 0.3, 0.5, 0.7, 1],
        ).createShader(
          Rect.fromLTWH(top.dx - rx, top.dy, rx * 2, height + ry),
        ),
    );
    canvas.drawOval(
      Rect.fromCenter(center: top, width: rx * 2, height: ry * 2),
      Paint()..color = _goldLight,
    );
    canvas.drawOval(
      Rect.fromCenter(center: top, width: rx * 2, height: ry * 2),
      Paint()
        ..color = _goldDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // A big "1" on the front.
    final label = TextPainter(
      text: TextSpan(
        text: '1',
        style: TextStyle(
          color: Colors.white,
          fontSize: height * 0.85,
          fontWeight: FontWeight.w900,
          shadows: const [Shadow(color: _goldDark, blurRadius: 2)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(
      canvas,
      top + Offset(-label.width / 2, height * 0.55 + ry * 0.3 - label.height / 2),
    );
  }

  void _paintMagnet(Canvas canvas, Offset at, double m) {
    final deciding = picker.phase == FingerPhase.deciding;
    // Rattles while it pulls.
    final shake = deciding
        ? Offset(math.sin(_t * 47) * 2.5, math.cos(_t * 41) * 1.5)
        : Offset.zero;
    final c = at + shake;
    final r = m * 0.42;
    final thickness = m * 0.26;
    if (deciding || _picked) {
      final glowColor = _picked
          ? fingerPalette[picker.winner!.colorIndex]
          : const Color(0xFF8FD3FF);
      canvas.drawCircle(
        c + Offset(0, r * 0.4),
        r * 1.9,
        Paint()
          ..color = glowColor.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );
    }
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = _magnetDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness + 3,
    );
    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = _magnet
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness,
    );
    for (final side in const [-1.0, 1.0]) {
      final leg = Rect.fromCenter(
        center: c + Offset(side * r, r * 0.35),
        width: thickness,
        height: r * 0.7,
      );
      canvas.drawRect(leg, Paint()..color = _magnet);
      final tip = Rect.fromCenter(
        center: c + Offset(side * r, r * 0.86),
        width: thickness,
        height: r * 0.32,
      );
      canvas.drawRect(tip, Paint()..color = _steel);
      canvas.drawRect(
        tip,
        Paint()
          ..color = const Color(0xFF78909C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
    // A shine along the top of the bend.
    canvas.drawArc(
      rect.deflate(thickness * 0.15),
      math.pi * 1.2,
      math.pi * 0.35,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness * 0.2
        ..strokeCap = StrokeCap.round,
    );
  }

  /// The magnet's pull: flickering field lines to every meeple. The line to
  /// meeple [strong] brightens with [strength] as it pulls ahead.
  void _paintField(
    Canvas canvas,
    Offset magnet,
    double m,
    List<Offset> to, {
    int strong = -1,
    double strength = 0,
  }) {
    final tips = [
      magnet + Offset(-m * 0.42, m * 0.45),
      magnet + Offset(m * 0.42, m * 0.45),
    ];
    for (var i = 0; i < to.length; i++) {
      final boost = i == strong ? strength : 0.0;
      final flicker =
          (0.35 + 0.35 * math.sin(_t * 30 + i * 2.3)) * (1 - boost) + boost;
      final target = to[i] - Offset(0, m * 0.6);
      final from = tips[target.dx < magnet.dx ? 0 : 1];
      final mid = Offset.lerp(from, target, 0.5)! +
          Offset(math.sin(_t * 17 + i) * m * 0.3, -m * 0.2);
      canvas.drawPath(
        Path()
          ..moveTo(from.dx, from.dy)
          ..quadraticBezierTo(mid.dx, mid.dy, target.dx, target.dy),
        Paint()
          ..color = const Color(0xFFBDEBFF).withValues(alpha: flicker)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 + boost * 3
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3),
      );
    }
  }

  void _paintCountdown(Canvas canvas, Offset magnet, double m) {
    final progress = picker.armProgress(now);
    if (picker.phase != FingerPhase.arming || progress <= 0) {
      return;
    }
    canvas.drawArc(
      Rect.fromCircle(center: magnet + Offset(0, m * 0.2), radius: m * 0.85),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3),
    );
  }

  void _paintRing(Canvas canvas, FingerTouch touch, {required bool dim}) {
    final color = fingerPalette[touch.colorIndex].withValues(
      alpha: dim ? 0.35 : 0.9,
    );
    canvas.drawCircle(
      touch.position,
      30 * (1 + 0.05 * math.sin(_t * 5 + touch.pointer)),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3),
    );
  }

  /// A wooden meeple standing with its feet at [feet].
  void _paintMeeple(
    Canvas canvas,
    Offset feet,
    double m,
    Color color, {
    required double angle,
    required double scale,
    required bool shadow,
  }) {
    if (scale <= 0.01) {
      return;
    }
    if (shadow) {
      canvas.drawOval(
        Rect.fromCenter(
          center: feet + Offset(0, m * 0.02),
          width: m * 0.8 * scale,
          height: m * 0.16 * scale,
        ),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
    canvas.save();
    canvas.translate(feet.dx, feet.dy);
    canvas.rotate(angle);
    canvas.scale(m * scale);
    canvas.translate(0, -0.5);
    final dark = Color.lerp(color, Colors.black, 0.4)!;
    // The thick wooden side, so it reads as a real piece.
    canvas.drawPath(_meeple.shift(const Offset(0.05, 0.05)), Paint()..color = dark);
    canvas.drawPath(
      _meeple,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(color, Colors.white, 0.3)!, color],
        ).createShader(const Rect.fromLTWH(-0.5, -0.5, 1, 1)),
    );
    canvas.drawPath(
      _meeple,
      Paint()
        ..color = dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.025
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-0.06, -0.38), width: 0.12, height: 0.07),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
    canvas.restore();
  }

  /// Confetti bursting from the pedestal once the winner lands.
  void _paintConfetti(
    Canvas canvas,
    Offset origin,
    double m,
    FingerTouch winner,
  ) {
    final tau =
        (now - picker.pickedAt! - _jump).inMicroseconds / 1e6;
    if (tau < 0 || tau > 1.8) {
      return;
    }
    final colors = [
      fingerPalette[winner.colorIndex],
      _gold,
      Colors.white,
      fingerPalette[(winner.colorIndex + 3) % fingerPalette.length],
    ];
    final gravity = m * 9;
    for (var i = 0; i < 32; i++) {
      final angle = -math.pi / 2 + (i / 32 - 0.5) * math.pi * 1.3;
      final speed = m * (3.5 + (i % 5) * 0.8);
      final at =
          origin +
          Offset(math.cos(angle), math.sin(angle)) * speed * tau +
          Offset(0, gravity * tau * tau / 2);
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate(tau * (6 + i % 4) + i);
      canvas.drawRect(
        const Rect.fromLTWH(-4, -2, 8, 4),
        Paint()
          ..color = colors[i % colors.length].withValues(
            alpha: (1 - tau / 1.8).clamp(0.0, 1.0),
          ),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant MeeplesPainter oldDelegate) => true;
}
