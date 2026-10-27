import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'finger_picker.dart';

/// Pass the Bomb: every finger gets a ticking bomb, and they all go off at
/// once. Everyone else's bursts into smoke; the first player's bursts into
/// colour, confetti and a gold star.
class BombPainter extends CustomPainter {
  const BombPainter({required this.picker, required this.now});

  final FingerPicker picker;
  final Duration now;

  static const _gold = Color(0xFFFFC83D);
  static const _spark = Color(0xFFFFE066);
  static const _flame = Color(0xFFFF7A1A);
  static const _fuse = Color(0xFFC9A26B);
  static const _cap = Color(0xFF9AA4AE);

  /// Every bomb swells for this long before they all burst.
  static const _swell = Duration(milliseconds: 300);

  /// How long the smoke of a dud lingers.
  static const _puff = Duration(milliseconds: 900);

  double get _t => now.inMicroseconds / 1e6;

  bool get _picked =>
      picker.phase == FingerPhase.picked && picker.winner != null;

  /// How far through the suspense we are, from 0 to 1 (1 once picked).
  double get _suspense {
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

  @override
  void paint(Canvas canvas, Size size) {
    final r = (math.min(size.width, size.height) * 0.06).clamp(22.0, 36.0);
    final center = Offset(size.width / 2, size.height * 0.46);

    _paintBackdrop(canvas, size);

    final winner = picker.winner;
    // Seconds since every bomb went off together (negative while they
    // swell just before).
    final boom = _picked
        ? (now - picker.pickedAt! - _swell).inMicroseconds / 1e6
        : -1.0;

    // The blast shakes the screen for a moment.
    if (boom > 0 && boom < 0.35) {
      final shake = 1 - boom / 0.35;
      canvas.translate(
        math.sin(_t * 80) * 8 * shake,
        math.cos(_t * 71) * 6 * shake,
      );
    }
    if (boom > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = fingerPalette[winner!.colorIndex].withValues(
            alpha: 0.16 * (boom / 0.3).clamp(0.0, 1.0),
          ),
      );
    }

    _paintStopwatch(canvas, center, r);

    final fingers = picker.touches.values.toList();
    final all = [
      ...fingers,
      if (_picked && !picker.touches.containsKey(winner!.pointer)) winner,
    ];

    for (final touch in all) {
      final isWinner = _picked && touch.pointer == winner!.pointer;
      _paintRing(
        canvas,
        touch,
        dim: boom > 0 && !isWinner,
        glow: isWinner && boom > 0,
      );
    }

    final flashing = _flashing(all);
    for (final touch in all) {
      final at = touch.position - Offset(0, r * 2.1);
      final isWinner = _picked && touch.pointer == winner!.pointer;
      if (_picked && boom < 0) {
        // Every bomb swells and flashes just before they all go off.
        final swell = 1 - (-boom / (_swell.inMicroseconds / 1e6));
        _paintBomb(
          canvas,
          at,
          r,
          touch,
          scale: 1 + 0.35 * swell,
          flash: 0.5 + 0.5 * math.sin(_t * 60 + touch.pointer),
          fuse: 0,
        );
        continue;
      }
      if (_picked) {
        if (isWinner) {
          // The first player's bomb bursts into colour and a gold star.
          _paintBoom(canvas, at, r, boom);
          _paintStar(canvas, at, r, boom);
        } else {
          // Everyone else's goes off in a puff of smoke and leaves soot.
          _paintSoot(canvas, at, r, boom);
          _paintBoom(canvas, at, r * 0.75, boom, smoky: true);
          _paintPuff(canvas, at, r, boom);
        }
        continue;
      }
      final pop = Curves.elasticOut.transform(
        ((now - touch.since).inMilliseconds / 500).clamp(0.0, 1.0),
      );
      _paintBomb(
        canvas,
        at,
        r,
        touch,
        scale: pop * (1 + 0.1 * _beat(touch)),
        flash: touch.pointer == flashing ? 0.75 : 0,
        // Every fuse burns down together, so none gives the result away.
        fuse: 1 - 0.95 * _suspense,
      );
    }

    // A white flash as they all go off.
    if (boom > 0 && boom < 0.2) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.white.withValues(alpha: 0.6 * (1 - boom / 0.2)),
      );
    }

    if (boom > 0) {
      _paintConfetti(
        canvas,
        winner!.position - Offset(0, r * 2.1),
        r,
        winner,
        boom,
      );
    }
  }

  static int _hash(int pointer, int seed) =>
      ((pointer + 31) * 2654435761 + seed * 40503) & 0x7fffffff;

  /// The bomb flashing right now. It hops between all the bombs, faster as
  /// time runs out, so the flash gives nothing away.
  int? _flashing(List<FingerTouch> all) {
    if (picker.phase != FingerPhase.deciding || all.isEmpty) {
      return null;
    }
    final every = (170 - 110 * _suspense).round();
    final hop = (now - picker.decidingAt).inMilliseconds ~/ every;
    final seed = picker.decidingAt.inMilliseconds;
    return all[_hash(hop, seed) % all.length].pointer;
  }

  /// The scorch mark a smoky bomb leaves behind.
  void _paintSoot(Canvas canvas, Offset at, double r, double boom) {
    final grow = (boom / 0.25).clamp(0.0, 1.0);
    canvas.drawOval(
      Rect.fromCenter(
        center: at + Offset(0, r * 0.7),
        width: r * 2.2 * grow,
        height: r * 0.9 * grow,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  /// A tick pulse that speeds up as the suspense builds.
  double _beat(FingerTouch touch) {
    final speed = 4 + 14 * _suspense;
    if (picker.phase != FingerPhase.deciding) {
      return 0;
    }
    return math.max(0, math.sin(_t * speed + touch.pointer)) * _suspense;
  }

  void _paintBackdrop(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.15),
          radius: 1.1,
          colors: [Color(0xFF4A3F6B), Color(0xFF2B2D42), Color(0xFF16161F)],
          stops: [0, 0.55, 1],
        ).createShader(rect),
    );
    // Comic-book halftone dots, fading toward the middle.
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.05);
    final middle = size.center(Offset.zero);
    final far = size.shortestSide * 0.75;
    for (var y = 0.0; y < size.height; y += 18) {
      for (var x = (y ~/ 18).isEven ? 0.0 : 9.0; x < size.width; x += 18) {
        final d = ((Offset(x, y) - middle).distance / far).clamp(0.0, 1.0);
        canvas.drawCircle(Offset(x, y), 0.6 + 2.2 * d, dot);
      }
    }
  }

  /// The countdown while fingers hold still: a stopwatch filling up.
  void _paintStopwatch(Canvas canvas, Offset center, double r) {
    final progress = picker.armProgress(now);
    if (picker.phase != FingerPhase.arming || progress <= 0) {
      return;
    }
    final size = r * 1.6;
    canvas.drawCircle(
      center,
      size,
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );
    canvas.drawCircle(
      center,
      size,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: center - Offset(0, size + 5),
        width: size * 0.4,
        height: 8,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size - 7),
      -math.pi / 2,
      math.pi * 2 * progress,
      true,
      Paint()..color = _flame.withValues(alpha: 0.7),
    );
    // The hand.
    final angle = -math.pi / 2 + math.pi * 2 * progress;
    canvas.drawLine(
      center,
      center + Offset(math.cos(angle), math.sin(angle)) * (size - 6),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintRing(
    Canvas canvas,
    FingerTouch touch, {
    required bool dim,
    required bool glow,
  }) {
    final color = fingerPalette[touch.colorIndex];
    if (glow) {
      canvas.drawCircle(
        touch.position,
        52,
        Paint()
          ..color = color.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
      );
    }
    canvas.drawCircle(
      touch.position,
      30 * (1 + 0.05 * math.sin(_t * 5 + touch.pointer)),
      Paint()
        ..color = color.withValues(alpha: dim ? 0.3 : 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = glow ? 6 : 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3),
    );
  }

  /// A cartoon bomb in the player's color. [fuse] is how much fuse is left
  /// (0 to 1) and [flash] how strongly it flashes red.
  void _paintBomb(
    Canvas canvas,
    Offset at,
    double r,
    FingerTouch touch, {
    required double scale,
    required double flash,
    required double fuse,
  }) {
    if (scale <= 0.01) {
      return;
    }
    final color = fingerPalette[touch.colorIndex];
    canvas.drawOval(
      Rect.fromCenter(
        center: at + Offset(0, r * 1.05),
        width: r * 1.6 * scale,
        height: r * 0.35 * scale,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.scale(scale);

    // Fuse first, so the cap covers its root.
    final root = Offset(r * 0.5, -r * 0.82);
    final tip = Offset(r * 1.0, -r * 1.55);
    final fuseEnd = Offset.lerp(root, tip, fuse.clamp(0.0, 1.0))!;
    final bend = Offset.lerp(root, fuseEnd, 0.5)! + Offset(-r * 0.25 * fuse, -r * 0.1);
    canvas.drawPath(
      Path()
        ..moveTo(root.dx, root.dy)
        ..quadraticBezierTo(bend.dx, bend.dy, fuseEnd.dx, fuseEnd.dy),
      Paint()
        ..color = _fuse
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.14
        ..strokeCap = StrokeCap.round,
    );

    final body = Rect.fromCircle(center: Offset.zero, radius: r);
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: [
            Color.lerp(color, Colors.white, 0.25)!,
            color,
            Color.lerp(color, Colors.black, 0.6)!,
          ],
          stops: const [0, 0.45, 1],
        ).createShader(body),
    );
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..color = Color.lerp(color, Colors.black, 0.7)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    if (flash > 0) {
      canvas.drawCircle(
        Offset.zero,
        r,
        Paint()..color = const Color(0xFFFF2D2D).withValues(alpha: flash * 0.8),
      );
    }
    // Shine.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-r * 0.38, -r * 0.42),
        width: r * 0.45,
        height: r * 0.28,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
    // Metal cap.
    canvas.save();
    canvas.translate(root.dx * 0.92, root.dy * 0.92);
    canvas.rotate(0.6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: r * 0.55, height: r * 0.32),
        Radius.circular(r * 0.06),
      ),
      Paint()..color = _cap,
    );
    canvas.restore();

    // A sputtering spark at the end of the fuse.
    final flicker = 0.6 + 0.4 * math.sin(_t * 40 + touch.pointer);
    canvas.drawCircle(
      fuseEnd,
      r * 0.32 * flicker,
      Paint()
        ..color = _flame.withValues(alpha: 0.7)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.2),
    );
    canvas.drawCircle(fuseEnd, r * 0.12, Paint()..color = _spark);
    final sparkPaint = Paint()
      ..color = _spark
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 5; i++) {
      final angle = i * 1.26 + _t * 9 + touch.pointer;
      final length = r * (0.2 + 0.18 * math.sin(_t * 25 + i));
      final dir = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        fuseEnd + dir * r * 0.12,
        fuseEnd + dir * (r * 0.12 + length),
        sparkPaint,
      );
    }
    canvas.restore();
  }

  /// A grey cloud of smoke drifting up from a bomb that just went off;
  /// [boom] is seconds since the blast.
  void _paintPuff(Canvas canvas, Offset at, double r, double boom) {
    final p = boom / (_puff.inMicroseconds / 1e6);
    if (p >= 1 || p < 0) {
      return;
    }
    at -= Offset(0, r * 0.8 * p);
    final paint = Paint()
      ..color = const Color(0xFF9EA3AA).withValues(alpha: 0.6 * (1 - p));
    for (var i = 0; i < 6; i++) {
      final angle = i / 6 * math.pi * 2;
      final spread = r * (0.3 + 0.9 * p);
      canvas.drawCircle(
        at + Offset(math.cos(angle), math.sin(angle)) * spread,
        r * (0.45 + 0.3 * p),
        paint,
      );
    }
  }

  /// The harmless explosion: a comic starburst that grows and fades.
  /// [smoky] bursts are grey: a dud next to the winner's colourful one.
  void _paintBoom(
    Canvas canvas,
    Offset at,
    double r,
    double boom, {
    bool smoky = false,
  }) {
    final p = (boom / 0.6).clamp(0.0, 1.0);
    if (p >= 1) {
      return;
    }
    final fade = 1 - p;
    final layers = smoky
        ? const [
            (Color(0xFF5C6168), 1.0),
            (Color(0xFF8A9098), 0.78),
            (Color(0xFFC3C8CE), 0.55),
          ]
        : const [
            (Color(0xFFFF4D2E), 1.0),
            (_flame, 0.78),
            (_spark, 0.55),
          ];
    for (final (color, size) in layers) {
      final burst = Path();
      const points = 12;
      final outer = r * (1.2 + 3.2 * Curves.easeOut.transform(p)) * size;
      for (var i = 0; i < points * 2; i++) {
        final angle = i * math.pi / points + 0.2;
        final d = i.isEven ? outer : outer * 0.55;
        final point = at + Offset(math.cos(angle), math.sin(angle)) * d;
        if (i == 0) {
          burst.moveTo(point.dx, point.dy);
        } else {
          burst.lineTo(point.dx, point.dy);
        }
      }
      burst.close();
      canvas.drawPath(burst, Paint()..color = color.withValues(alpha: fade));
    }
  }

  /// A gold star left shining over the first player.
  void _paintStar(Canvas canvas, Offset at, double r, double boom) {
    final p = Curves.elasticOut.transform(((boom - 0.2) / 0.7).clamp(0.0, 1.0));
    if (p <= 0) {
      return;
    }
    final outer = r * 1.1 * p;
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5 + math.sin(_t * 2) * 0.08;
      final d = i.isEven ? outer : outer * 0.45;
      final point = at + Offset(math.cos(angle), math.sin(angle)) * d;
      if (i == 0) {
        star.moveTo(point.dx, point.dy);
      } else {
        star.lineTo(point.dx, point.dy);
      }
    }
    star.close();
    canvas.drawCircle(
      at,
      outer * 1.4,
      Paint()
        ..color = _gold.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawPath(star, Paint()..color = _gold);
    canvas.drawPath(
      star,
      Paint()
        ..color = const Color(0xFFB8860B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _paintConfetti(
    Canvas canvas,
    Offset origin,
    double r,
    FingerTouch winner,
    double tau,
  ) {
    if (tau > 1.8) {
      return;
    }
    final colors = [
      fingerPalette[winner.colorIndex],
      _gold,
      Colors.white,
      _flame,
    ];
    final gravity = r * 16;
    for (var i = 0; i < 36; i++) {
      final angle = i / 36 * math.pi * 2;
      final speed = r * (5 + (i % 5) * 1.6);
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
  bool shouldRepaint(covariant BombPainter oldDelegate) => true;
}
