import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'finger_picker.dart';

/// The Quantum Box: every player's color is a glowing particle inside a
/// glass cube. The particles bounce off the glass, split into tiny copies
/// and leave trails, then speed up into chaos as the cube shakes, until
/// the whole box blows apart and the winner's orb bursts out of the blast.
///
/// The winner is drawn fairly when the suspense starts. Every particle
/// moves on its own random path, so nothing hints at the result until the
/// blast.
class QuantumPainter extends CustomPainter {
  const QuantumPainter({required this.picker, required this.now});

  final FingerPicker picker;
  final Duration now;

  static const _bg = Color(0xFF0E1530);
  static const _bgDeep = Color(0xFF060914);

  /// Shares of the suspense: the box settles, the particles turn unstable,
  /// then chaotic right up to the pick, when it all blows.
  static const _unstable = 0.143;
  static const _chaos = 0.571;

  /// How far inside the glass a particle bounces, in cube units.
  static const _wall = 0.82;

  double get _t => now.inMicroseconds / 1e6;

  bool get _picked =>
      picker.phase == FingerPhase.picked && picker.winner != null;

  bool get _deciding => picker.phase == FingerPhase.deciding;

  /// How far through the suspense we are, from 0 to 1. Once picked, it
  /// stays where the pick happened, which is early when it was skipped.
  double get _p {
    if (!_deciding && !_picked) {
      return 0;
    }
    final end = _picked ? picker.pickedAt! : now;
    return ((end - picker.decidingAt).inMicroseconds /
            picker.decideTime.inMicroseconds)
        .clamp(0.0, 1.0);
  }

  /// Seconds since the pick.
  double get _since =>
      _picked ? (now - picker.pickedAt!).inMicroseconds / 1e6 : 0;

  static double _ramp(double x, double from, double to) =>
      ((x - from) / (to - from)).clamp(0.0, 1.0);

  static int _hash(int pointer, int seed) =>
      ((pointer + 31) * 2654435761 + seed * 40503) & 0x7fffffff;

  @override
  void paint(Canvas canvas, Size size) {
    final s = (math.min(size.width, size.height) * 0.22).clamp(70.0, 150.0);
    var centre = Offset(size.width / 2, size.height * 0.45);
    _paintBackdrop(canvas, size, centre, s);

    final winner = picker.winner;
    final fingers = picker.touches.values.toList();
    final all = [
      ...fingers,
      if (_picked && !picker.touches.containsKey(winner!.pointer)) winner,
    ];

    // The blast rocks the whole screen for a moment.
    final blast = _picked ? _since : -1.0;
    canvas.save();
    if (blast >= 0 && blast < 0.45) {
      final shake = 1 - blast / 0.45;
      canvas.translate(
        math.sin(_t * 90) * 10 * shake,
        math.cos(_t * 77) * 8 * shake,
      );
    }

    // The box shakes harder and harder in the chaos, until the freeze.
    final chaos = _deciding ? _ramp(_p, _chaos, 1) : 0.0;
    final frozen = _picked;
    if (!frozen && chaos > 0) {
      centre += Offset(math.sin(_t * 71), math.cos(_t * 63)) * s * 0.03 * chaos;
    }
    final view = _View(
      centre: centre,
      s: s,
      yaw: 0.62 + 0.12 * math.sin(_t * 0.35),
      pitch: -0.48,
    );
    // Once it blows, the box is gone: its shards fly in the blast.
    final open = blast >= 0 ? 1.0 : 0.0;

    if (blast >= 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = fingerPalette[winner!.colorIndex].withValues(
            alpha: 0.16 * _ramp(blast, 0, 0.4),
          ),
      );
    }

    _paintCountdown(canvas, centre, s);
    for (final touch in fingers) {
      final isWinner = _picked && touch.pointer == winner!.pointer;
      _paintRing(canvas, touch, dim: _picked && !isWinner, glow: isWinner);
    }

    _paintCube(canvas, view, front: false, open: open);
    _paintInnerLight(canvas, view, all, chaos, open);

    final spots = <int, _Particle>{};
    for (final touch in all) {
      spots[touch.pointer] = _particle(touch, view);
    }
    // The particles, back to front.
    final order = [...all]
      ..sort((a, b) => spots[a.pointer]!.z.compareTo(spots[b.pointer]!.z));
    for (final touch in order) {
      _paintParticle(canvas, touch, spots[touch.pointer]!, view);
    }
    if (_deciding && !frozen) {
      _paintCollisions(canvas, all, spots, s, chaos);
    }

    _paintCube(canvas, view, front: true, open: open);

    if (_picked) {
      _paintReveal(canvas, size, view, winner!);
    }
    canvas.restore();
  }

  void _paintBackdrop(Canvas canvas, Size size, Offset centre, double s) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.1),
          radius: 1.0,
          colors: [Color(0xFF1A2550), _bg, _bgDeep],
          stops: [0, 0.5, 1],
        ).createShader(rect),
    );
    // Soft out-of-focus lights drifting in the dark.
    final random = math.Random(11);
    for (var i = 0; i < 16; i++) {
      final color = fingerPalette[i % fingerPalette.length];
      final at = Offset(
        (random.nextDouble() * size.width + _t * (4 + i % 3 * 3)) %
                (size.width + 80) -
            40,
        random.nextDouble() * size.height,
      );
      canvas.drawCircle(
        at,
        10 + random.nextDouble() * 26,
        Paint()
          ..color = color.withValues(alpha: 0.07 + random.nextDouble() * 0.07)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }
    // A glossy floor reflecting the box's glow.
    canvas.drawOval(
      Rect.fromCenter(
        center: centre + Offset(0, s * 1.55),
        width: s * 3.2,
        height: s * 0.7,
      ),
      Paint()
        ..color = const Color(0xFF6E8CFF).withValues(alpha: 0.12)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.25),
    );
  }

  void _paintCountdown(Canvas canvas, Offset centre, double s) {
    final progress = picker.armProgress(now);
    if (picker.phase != FingerPhase.arming || progress <= 0) {
      return;
    }
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: s * 1.85),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3),
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

  /// The glass cube: the far faces and edges behind the particles, or the
  /// near ones in front. [open] sends the faces flying apart.
  void _paintCube(
    Canvas canvas,
    _View view, {
    required bool front,
    required double open,
  }) {
    // When the suspense starts the box shimmers into focus.
    final shimmer = _deciding
        ? math.sin(math.pi * _ramp(_p, 0, _unstable))
        : 0.0;
    for (final face in _faces) {
      final normal = view.rotate(face.normal);
      final facing = normal.$3 > 0;
      if (facing != front) {
        continue;
      }
      final push = open * 1.3;
      final corners = [
        for (final i in face.corners)
          view.project(_add(_corner(i), _scale(face.normal, push))),
      ];
      final fade = 1 - _ramp(open, 0, 0.55);
      if (fade <= 0) {
        continue;
      }
      final path = Path()..addPolygon(corners, true);
      final bounds = path.getBounds();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: (front ? 0.1 : 0.05) * fade),
              Colors.white.withValues(alpha: 0.015 * fade),
              const Color(
                0xFF9DB4FF,
              ).withValues(alpha: (front ? 0.07 : 0.03) * fade),
            ],
          ).createShader(bounds),
      );
      if (front) {
        // A soft reflection streaking across the glass.
        final a = Offset.lerp(corners[0], corners[1], 0.15)!;
        final b = Offset.lerp(corners[3], corners[2], 0.45)!;
        canvas.drawLine(
          a,
          b,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.12 * fade)
            ..strokeWidth = view.s * 0.08
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, view.s * 0.04),
        );
      }
      final edge = Paint()
        ..color = Colors.white.withValues(
          alpha: ((front ? 0.65 : 0.25) + 0.3 * shimmer) * fade,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = front ? 2.2 : 1.4
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, edge);
      if (front) {
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFFB8C8FF).withValues(alpha: 0.35 * fade)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
        // Bright glints on the corners.
        for (final c in corners) {
          canvas.drawCircle(
            c,
            2.4,
            Paint()..color = Colors.white.withValues(alpha: 0.8 * fade),
          );
        }
      }
    }
  }

  /// The light inside the box, growing more intense with the chaos.
  void _paintInnerLight(
    Canvas canvas,
    _View view,
    List<FingerTouch> all,
    double chaos,
    double open,
  ) {
    final energy = _deciding ? 0.15 + 0.55 * chaos : 0.12;
    final glow = (energy * (1 - open)).clamp(0.0, 1.0);
    if (glow <= 0) {
      return;
    }
    canvas.drawCircle(
      view.centre,
      view.s * (0.9 + 0.5 * chaos),
      Paint()
        ..color = const Color(0xFFCAD6FF).withValues(alpha: 0.35 * glow)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, view.s * 0.45),
    );
  }

  /// Where a particle is, in cube units, at time [tau] of its motion.
  (double, double, double) _motion(FingerTouch touch, double tau) {
    final random = math.Random(_hash(touch.pointer, 17));
    final start = (
      (random.nextDouble() - 0.5) * 1.2,
      (random.nextDouble() - 0.5) * 1.2,
      (random.nextDouble() - 0.5) * 1.2,
    );
    if (tau <= 0) {
      return start;
    }
    final phase = math.Random(
      picker.decidingAt.inMilliseconds * 7 + _hash(touch.pointer, 3) % 9973,
    );
    double axis() => (phase.nextDouble() - 0.5) * 2;
    var v = (axis(), axis(), axis());
    final length = math.sqrt(v.$1 * v.$1 + v.$2 * v.$2 + v.$3 * v.$3) + 1e-6;
    v = _scale(v, 1.6 / length);
    final wobble = phase.nextDouble() * math.pi * 2;
    // Straight runs that bounce off the glass, with a wobble that keeps
    // changing their direction.
    return (
      _fold(start.$1 + v.$1 * tau + 0.25 * math.sin(tau * 3.1 + wobble)),
      _fold(start.$2 + v.$2 * tau + 0.25 * math.sin(tau * 2.6 + wobble * 2)),
      _fold(start.$3 + v.$3 * tau + 0.25 * math.cos(tau * 2.9 + wobble)),
    );
  }

  /// Bounces a coordinate back and forth between the walls.
  static double _fold(double x) {
    final u = x / _wall;
    final m = (u + 1) % 4;
    return _wall * (1 - (m - 2).abs());
  }

  /// How far each particle has travelled at share [p] of the suspense:
  /// steady while unstable, then faster and faster in the chaos.
  double _tau(double p) {
    final seconds = picker.decideTime.inMicroseconds / 1e6;
    final calm = math.max(0.0, p - 0.02) * seconds * 0.6;
    final rushing = math.max(0.0, p - _chaos) * seconds;
    return calm + rushing * rushing * 0.5;
  }

  _Particle _particle(FingerTouch touch, _View view) {
    final p = _p;
    final tau = _tau(p);
    var at = _motion(touch, tau);
    if (!_deciding && !_picked) {
      // Waiting: drifting gently.
      final w = touch.pointer * 1.7;
      at = _add(at, (
        0.08 * math.sin(_t * 0.9 + w),
        0.08 * math.cos(_t * 1.1 + w),
        0.08 * math.sin(_t * 0.7 + w * 2),
      ));
    }
    // In the chaos everything starts to orbit round the middle.
    final swirl = (math.pow(_ramp(p, _chaos, 1), 2) * 5).toDouble();
    if (swirl > 0) {
      final c = math.cos(swirl);
      final sn = math.sin(swirl);
      at = (at.$1 * c - at.$3 * sn, at.$2, at.$1 * sn + at.$3 * c);
    }
    final rotated = view.rotate(at);
    return _Particle(at, tau, view.project(at), rotated.$3);
  }

  void _paintParticle(
    Canvas canvas,
    FingerTouch touch,
    _Particle particle,
    _View view,
  ) {
    final color = fingerPalette[touch.colorIndex];
    final r = view.s * 0.11 * view.depthScale(particle.z);

    // Arriving: a comet from the finger into the box.
    final arrive = Curves.easeOutCubic.transform(
      ((now - touch.since).inMilliseconds / 550).clamp(0.0, 1.0),
    );
    if (arrive < 1) {
      final from = touch.position;
      final at = Offset.lerp(from, particle.screen, arrive)!;
      canvas.drawLine(
        Offset.lerp(from, particle.screen, math.max(0, arrive - 0.25))!,
        at,
        Paint()
          ..color = color.withValues(alpha: 0.6)
          ..strokeWidth = r * 0.9
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.4),
      );
      _dot(canvas, at, r, color, 1);
      return;
    }

    // At the pick every particle goes up in the blast.
    if (_picked) {
      return;
    }

    final p = _p;
    // Colorful trails behind it.
    if (_deciding && particle.tau > 0) {
      final path = Path()..moveTo(particle.screen.dx, particle.screen.dy);
      for (var k = 1; k <= 10; k++) {
        final past = math.max(0.0, particle.tau - k * 0.035 * (1 + p * 2));
        final back = _particleAt(touch, past, p, view);
        path.lineTo(back.dx, back.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.8
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.3),
      );
    }

    // Tiny copies splitting off and orbiting it.
    final split = _deciding ? _ramp(_p, _unstable, _unstable + 0.08) : 0.0;
    if (split > 0) {
      for (var c = 0; c < 2; c++) {
        final angle = particle.tau * (3 + c) + c * math.pi + touch.pointer;
        final offset = (
          0.2 * split * math.cos(angle),
          0.2 * split * math.sin(angle * 1.3),
          0.2 * split * math.sin(angle),
        );
        final copy = view.project(_add(particle.local, offset));
        _dot(canvas, copy, r * 0.45, color, 0.75);
      }
    }

    // In the chaos each glow swells, so the light in the box intensifies.
    final heat = _deciding ? _ramp(_p, _chaos, 1) : 0.0;
    _dot(canvas, particle.screen, r, color, 1, heat: heat);
  }

  /// A particle's screen spot at an earlier [tau], for its trail.
  Offset _particleAt(FingerTouch touch, double tau, double p, _View view) {
    var at = _motion(touch, tau);
    final swirl = (math.pow(_ramp(p, _chaos, 1), 2) * 5).toDouble();
    if (swirl > 0) {
      final c = math.cos(swirl);
      final sn = math.sin(swirl);
      at = (at.$1 * c - at.$3 * sn, at.$2, at.$1 * sn + at.$3 * c);
    }
    return view.project(at);
  }

  /// A glowing particle with a white-hot core.
  void _dot(
    Canvas canvas,
    Offset at,
    double r,
    Color color,
    double alpha, {
    double heat = 0,
  }) {
    if (alpha <= 0 || r <= 0.2) {
      return;
    }
    canvas.drawCircle(
      at,
      r * (3 + 2.5 * heat),
      Paint()
        ..color = color.withValues(alpha: (0.4 + 0.2 * heat) * alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * (1.6 + heat)),
    );
    canvas.drawCircle(at, r, Paint()..color = color.withValues(alpha: alpha));
    canvas.drawCircle(
      at,
      r * 0.5,
      Paint()..color = Colors.white.withValues(alpha: 0.9 * alpha),
    );
  }

  /// Sparks where particles pass close to each other in the chaos.
  void _paintCollisions(
    Canvas canvas,
    List<FingerTouch> all,
    Map<int, _Particle> spots,
    double s,
    double chaos,
  ) {
    if (_p < _unstable) {
      return;
    }
    final reach = s * (0.18 + 0.12 * chaos);
    for (var i = 0; i < all.length; i++) {
      for (var j = i + 1; j < all.length; j++) {
        final a = spots[all[i].pointer]!;
        final b = spots[all[j].pointer]!;
        final d = (a.screen - b.screen).distance;
        if (d < reach) {
          final strength = 1 - d / reach;
          _sparkle(
            canvas,
            Offset.lerp(a.screen, b.screen, 0.5)!,
            s * 0.12 * strength,
            Colors.white.withValues(alpha: 0.9 * strength),
          );
        }
      }
    }
  }

  /// The reveal: the box blows apart in a flash, shockwaves, flying shards
  /// and sparks, and the winner's orb bursts out of it.
  void _paintReveal(Canvas canvas, Size size, _View view, FingerTouch winner) {
    final color = fingerPalette[winner.colorIndex];
    final centre = view.centre;
    final blast = _since;

    // The blast: a white flash, then shockwaves rolling out.
    if (blast < 0.3) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.85 * (1 - blast / 0.3)),
      );
    }
    final far = size.longestSide;
    for (var i = 0; i < 3; i++) {
      final w = _ramp(blast, i * 0.09, i * 0.09 + 0.8);
      if (w <= 0 || w >= 1) {
        continue;
      }
      final e = Curves.easeOutCubic.transform(w);
      canvas.drawCircle(
        centre,
        far * 0.9 * e,
        Paint()
          ..color = (i == 1 ? color : Color.lerp(color, Colors.white, 0.6)!)
              .withValues(alpha: 0.8 * (1 - w))
          ..style = PaintingStyle.stroke
          ..strokeWidth = view.s * 0.18 * (1 - w) + 1
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + 8 * w),
      );
    }

    // Shards of the glass box flung out, spinning.
    if (blast < 1.1) {
      final fade = 1 - blast / 1.1;
      final random = math.Random(picker.decidingAt.inMilliseconds + 41);
      for (final face in _faces) {
        final corners = [
          for (final i in face.corners) view.project(_corner(i)),
        ];
        final mid = corners.reduce((a, b) => a + b) / 4;
        for (var k = 0; k < 4; k++) {
          final a = corners[k];
          final b = corners[(k + 1) % 4];
          final piece = (mid + a + b) / 3;
          var dir = piece - centre;
          dir = dir.distance < 1 ? const Offset(0, -1) : dir / dir.distance;
          final speed = view.s * (3.5 + random.nextDouble() * 3);
          final spin = (random.nextDouble() - 0.5) * 14;
          final move =
              dir * speed * blast + Offset(0, view.s * 2.2 * blast * blast);
          canvas.save();
          canvas.translate(piece.dx + move.dx, piece.dy + move.dy);
          canvas.rotate(spin * blast);
          final shard = Path()
            ..moveTo((mid - piece).dx, (mid - piece).dy)
            ..lineTo((a - piece).dx, (a - piece).dy)
            ..lineTo((b - piece).dx, (b - piece).dy)
            ..close();
          canvas.drawPath(
            shard,
            Paint()
              ..color = const Color(0xFFCAD6FF).withValues(alpha: 0.18 * fade),
          );
          canvas.drawPath(
            shard,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.75 * fade)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4,
          );
          canvas.restore();
        }
      }
    }

    // Sparks streaking out of the blast.
    if (blast < 1.2) {
      final random = math.Random(picker.decidingAt.inMilliseconds + 97);
      for (var i = 0; i < 56; i++) {
        final a = random.nextDouble() * math.pi * 2;
        final speed = view.s * (2.5 + random.nextDouble() * 5);
        final dir = Offset(math.cos(a), math.sin(a));
        final head = centre + dir * speed * blast;
        final tail = centre + dir * speed * math.max(0.0, blast - 0.08);
        final fade = (1 - blast / 1.2).clamp(0.0, 1.0);
        canvas.drawLine(
          tail,
          head,
          Paint()
            ..color = (i.isEven ? color : Colors.white).withValues(alpha: fade)
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // The orb, bursting out big and settling, with threads of light
    // swirling round it.
    final grow = Curves.elasticOut.transform(_ramp(blast, 0, 1.0));
    final at =
        centre + Offset(0, math.sin(_t * 2) * 4 * _ramp(blast, 0.8, 1.2));
    final radius = view.s * (0.1 + 0.5 * grow);
    canvas.drawCircle(
      at,
      radius * 2.3,
      Paint()
        ..color = color.withValues(alpha: 0.45)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.9),
    );
    final body = Rect.fromCircle(center: at, radius: radius);
    canvas.drawCircle(
      at,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white,
            Color.lerp(color, Colors.white, 0.35)!,
            color,
            color.withValues(alpha: 0.2),
          ],
          stops: const [0, 0.3, 0.75, 1],
        ).createShader(body),
    );
    final shown = grow.clamp(0.0, 1.0);
    final thread = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    for (var i = 0; i < 7; i++) {
      final spin = _t * (0.8 + i * 0.15) + i * 0.9;
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate(spin);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: radius * (2.2 + 0.25 * (i % 3)),
          height: radius * (0.7 + 0.2 * (i % 2)),
        ),
        thread
          ..color = Color.lerp(
            color,
            Colors.white,
            0.4,
          )!.withValues(alpha: 0.55 * shown),
      );
      canvas.restore();
    }
    for (var i = 0; i < 8; i++) {
      final a = _t * 1.2 + i * math.pi / 4;
      _sparkle(
        canvas,
        at + Offset(math.cos(a), math.sin(a)) * radius * 1.6,
        3 + 2 * math.sin(_t * 5 + i),
        Colors.white.withValues(alpha: 0.85 * shown),
      );
    }
  }

  /// A four-pointed sparkle.
  void _sparkle(Canvas canvas, Offset at, double r, Color color) {
    if (r <= 0.3) {
      return;
    }
    final path = Path()..moveTo(at.dx, at.dy - r);
    for (var i = 1; i <= 8; i++) {
      final a = -math.pi / 2 + i * math.pi / 4;
      final d = i.isEven ? r : r * 0.3;
      path.lineTo(at.dx + math.cos(a) * d, at.dy + math.sin(a) * d);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  static (double, double, double) _corner(int i) => (
    i & 1 == 0 ? -1.0 : 1.0,
    i & 2 == 0 ? -1.0 : 1.0,
    i & 4 == 0 ? -1.0 : 1.0,
  );

  static (double, double, double) _add(
    (double, double, double) a,
    (double, double, double) b,
  ) => (a.$1 + b.$1, a.$2 + b.$2, a.$3 + b.$3);

  static (double, double, double) _scale(
    (double, double, double) a,
    double k,
  ) => (a.$1 * k, a.$2 * k, a.$3 * k);

  /// The cube's six faces, by corner index, with their outward normals.
  static const _faces = [
    _Face([0, 2, 6, 4], (-1, 0, 0)),
    _Face([1, 3, 7, 5], (1, 0, 0)),
    _Face([0, 1, 5, 4], (0, -1, 0)),
    _Face([2, 3, 7, 6], (0, 1, 0)),
    _Face([0, 1, 3, 2], (0, 0, -1)),
    _Face([4, 5, 7, 6], (0, 0, 1)),
  ];

  @override
  bool shouldRepaint(covariant QuantumPainter oldDelegate) => true;
}

class _Face {
  const _Face(this.corners, this.normal);

  final List<int> corners;
  final (double, double, double) normal;
}

/// A particle this frame: where it is in the box, how far it has moved,
/// where it shows on screen and how near it is.
class _Particle {
  const _Particle(this.local, this.tau, this.screen, this.z);

  final (double, double, double) local;
  final double tau;
  final Offset screen;
  final double z;
}

/// How the box is turned and drawn: [s] is half its edge on screen.
class _View {
  const _View({
    required this.centre,
    required this.s,
    required this.yaw,
    required this.pitch,
  });

  final Offset centre;
  final double s;
  final double yaw;
  final double pitch;

  static const _camera = 4.5;

  (double, double, double) rotate((double, double, double) v) {
    final (x, y, z) = v;
    final x1 = x * math.cos(yaw) + z * math.sin(yaw);
    final z1 = -x * math.sin(yaw) + z * math.cos(yaw);
    final y2 = y * math.cos(pitch) - z1 * math.sin(pitch);
    final z2 = y * math.sin(pitch) + z1 * math.cos(pitch);
    return (x1, y2, z2);
  }

  /// Nearer things look bigger.
  double depthScale(double z) => _camera / (_camera - z);

  Offset project((double, double, double) v) {
    final (x, y, z) = rotate(v);
    return centre + Offset(x, y) * s * depthScale(z);
  }
}
