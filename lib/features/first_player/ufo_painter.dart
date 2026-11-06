import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'finger_picker.dart';

/// The UFO Abduction: every finger gets a little meeple under a starry
/// sky. A tiny UFO sweeps its beam across them, pausing, changing
/// direction and scanning again, until it suddenly locks onto one meeple,
/// beams it up, and flies away leaving a trail of stars.
///
/// The winner is drawn fairly when the scan starts. The UFO's route is
/// random: it stops over winners and losers alike and may come back to the
/// same meeple, so only the final lock gives the result away.
class UfoPainter extends CustomPainter {
  const UfoPainter({required this.picker, required this.now});

  final FingerPicker picker;
  final Duration now;

  static const _hull = Color(0xFFB0BEC5);
  static const _hullDark = Color(0xFF546E7A);
  static const _dome = Color(0xFF80DEEA);
  static const _beam = Color(0xFFE6FFB0);
  static const _alien = Color(0xFF8BC34A);

  /// When the scan is over: the UFO reaches its last stop by then and
  /// hovers there until the pick.
  static const _lastStop = 0.9;

  /// Seconds after the pick: the beam locks, lifts the meeple, retracts,
  /// and the UFO flies off.
  static const _lock = 0.25;
  static const _lifted = 1.15;
  static const _retracted = 1.3;
  static const _gone = 2.4;

  double get _t => now.inMicroseconds / 1e6;

  bool get _picked =>
      picker.phase == FingerPhase.picked && picker.winner != null;

  bool get _deciding => picker.phase == FingerPhase.deciding;

  /// How far through the scan we are, from 0 to 1 (1 once picked).
  double get _p {
    if (_picked) {
      return 1;
    }
    if (!_deciding) {
      return 0;
    }
    return ((now - picker.decidingAt).inMicroseconds /
            picker.decideTime.inMicroseconds)
        .clamp(0.0, 1.0);
  }

  /// Seconds since the pick.
  double get _since =>
      _picked ? (now - picker.pickedAt!).inMicroseconds / 1e6 : 0;

  static double _ramp(double x, double from, double to) =>
      ((x - from) / (to - from)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final u = (math.min(size.width, size.height) * 0.1).clamp(34.0, 56.0);
    final mm = (u * 0.8).clamp(30.0, 42.0);

    _paintSky(canvas, size);

    final winner = picker.winner;
    final fingers = picker.touches.values.toList();
    final all = [
      ...fingers,
      if (_picked && !picker.touches.containsKey(winner!.pointer)) winner,
    ];
    if (_picked && _since > _lifted) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = fingerPalette[winner!.colorIndex].withValues(
            alpha: 0.12 * _ramp(_since, _lifted, _lifted + 0.4),
          ),
      );
    }
    for (final touch in fingers) {
      final isWinner = _picked && touch.pointer == winner!.pointer;
      _paintRing(canvas, touch, dim: _picked && !isWinner, glow: isWinner);
    }

    final home = Offset(size.width / 2, size.height * 0.46);
    final focus = _focus(all, home);
    var ufo = focus - Offset(0, _altitude(focus, size));
    ufo += Offset(0, math.sin(_t * 2.2) * 4);
    if (_picked && _since > _retracted) {
      ufo = _flightPoint(ufo, size, u, _ramp(_since, _retracted, _gone));
    }

    _paintTrail(canvas, ufo, size, u);
    _paintBeam(canvas, ufo, focus, u, winner);

    // Meeples stand by their players; the winner rides the beam up.
    for (final touch in all) {
      final isWinner = _picked && touch.pointer == winner!.pointer;
      if (isWinner) {
        continue;
      }
      _paintMeepleAt(canvas, touch, mm, _feet(touch));
    }
    if (_picked) {
      final rise = Curves.easeInOutCubic.transform(
        _ramp(_since, _lock, _lifted),
      );
      if (rise < 1) {
        final feet = Offset.lerp(_feet(winner!), ufo + Offset(0, mm), rise)!;
        _paintMeeple(
          canvas,
          feet,
          mm,
          fingerPalette[winner.colorIndex],
          angle: math.sin(_since * 6) * 0.3 * rise,
          scale: 1 - 0.55 * rise,
        );
      }
    }

    _paintCountdown(canvas, ufo, u);
    _paintUfo(canvas, ufo, u, size);
  }

  /// Where a finger's meeple stands: just above the fingertip.
  Offset _feet(FingerTouch touch) => touch.position - const Offset(0, 34);

  /// How high the UFO hovers above the spot it's scanning.
  double _altitude(Offset focus, Size size) =>
      math.max(60, math.min(size.height * 0.3, focus.dy - 80));

  /// The UFO's route: a random series of stops over the meeples, never the
  /// same one twice in a row, ending over the winner. Each stop is
  /// (meeple, arrive, leave) as shares of the scan.
  List<(FingerTouch, double, double)> _route(List<FingerTouch> all) {
    final target = picker.chosen ?? picker.winner;
    if (target == null || all.isEmpty) {
      return const [];
    }
    final random = math.Random(picker.decidingAt.inMilliseconds * 31 + 7);
    final count = (all.length + 2).clamp(4, 6);
    final stops = <FingerTouch>[];
    for (var j = 0; j < count - 1; j++) {
      final options = [
        for (final touch in all)
          if (stops.isEmpty || touch.pointer != stops.last.pointer)
            if (j < count - 2 || touch.pointer != target.pointer) touch,
      ];
      stops.add(
        options.isEmpty ? all.first : options[random.nextInt(options.length)],
      );
    }
    stops.add(target);

    // Uneven legs and pauses, so the rhythm can't be read.
    final moves = [for (var j = 0; j < count; j++) 1 + random.nextDouble()];
    final pauses = [
      for (var j = 0; j < count - 1; j++) 0.6 + random.nextDouble() * 0.9,
    ];
    final total =
        moves.fold(0.0, (a, b) => a + b) + pauses.fold(0.0, (a, b) => a + b);
    const from = 0.04;
    final scale = (_lastStop - from) / total;
    var at = from;
    return [
      for (var j = 0; j < count; j++)
        (
          stops[j],
          at += moves[j] * scale,
          j < count - 1 ? (at += pauses[j] * scale) : 1.0,
        ),
    ];
  }

  /// The spot on the ground the UFO is over right now.
  Offset _focus(List<FingerTouch> all, Offset home) {
    if (!(_deciding || _picked)) {
      return home;
    }
    final route = _route(all);
    var from = home;
    var leftAt = 0.04;
    for (final (touch, arrive, leave) in route) {
      final spot = touch.position;
      if (_p < arrive) {
        final e = Curves.easeInOutCubic.transform(_ramp(_p, leftAt, arrive));
        return Offset.lerp(from, spot, e)!;
      }
      if (_p < leave || leave >= 1) {
        // Hovering: the beam sweeps a little from side to side.
        final sweep = _picked
            ? 0.0
            : math.sin((_p - arrive) * 40) *
                  14 *
                  math.sin(math.pi * _ramp(_p, arrive, leave));
        return spot + Offset(sweep, 0);
      }
      from = spot;
      leftAt = leave;
    }
    return from;
  }

  /// The path out: a swoop across the sky to the far side, climbing as it
  /// goes, so its trail of stars crosses the screen.
  Offset _flightPoint(Offset start, Size size, double u, double f) {
    final e = Curves.easeInCubic.transform(f);
    final right = start.dx < size.width / 2;
    final end = Offset(
      right ? size.width + u * 3 : -u * 3,
      math.max(-u * 3, start.dy - size.height * 0.15),
    );
    final control = Offset(
      (start.dx + end.dx) / 2,
      start.dy + size.height * 0.08,
    );
    final v = 1 - e;
    return start * (v * v) + control * (2 * v * e) + end * (e * e);
  }

  void _paintSky(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B1033), Color(0xFF1B2257), Color(0xFF2E2A5E)],
        ).createShader(rect),
    );
    for (var i = 0; i < 70; i++) {
      final x = ((i * 0.618034) % 1) * size.width;
      final y = ((i * 0.381966 + i * i * 0.0137) % 1) * size.height * 0.85;
      final twinkle = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(_t * 2 + i * 1.7));
      canvas.drawCircle(
        Offset(x, y),
        i % 7 == 0 ? 1.8 : 1.1,
        Paint()..color = Colors.white.withValues(alpha: 0.7 * twinkle),
      );
    }
    // The moon.
    final moon = Offset(size.width * 0.16, size.height * 0.12);
    canvas.drawCircle(
      moon,
      34,
      Paint()
        ..color = const Color(0xFFFFF4C2).withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawCircle(moon, 20, Paint()..color = const Color(0xFFFFF4C2));
    canvas.drawCircle(
      moon + const Offset(8, -5),
      17,
      Paint()..color = const Color(0xFF0E1438),
    );
    // Rolling hills along the bottom.
    final hills = Path()..moveTo(0, size.height);
    for (var x = 0.0; x <= size.width; x += 8) {
      hills.lineTo(
        x,
        size.height * 0.88 +
            math.sin(x / size.width * math.pi * 3) * size.height * 0.025,
      );
    }
    hills
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(hills, Paint()..color = const Color(0xFF141838));
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
        40,
        Paint()
          ..color = color.withValues(alpha: 0.35 + 0.1 * math.sin(_t * 4))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }
    canvas.drawCircle(
      touch.position,
      30 * (1 + 0.05 * math.sin(_t * 5 + touch.pointer)),
      Paint()
        ..color = color.withValues(alpha: dim ? 0.3 : 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3),
    );
  }

  void _paintCountdown(Canvas canvas, Offset ufo, double u) {
    final progress = picker.armProgress(now);
    if (picker.phase != FingerPhase.arming || progress <= 0) {
      return;
    }
    canvas.drawArc(
      Rect.fromCircle(center: ufo, radius: u * 1.5),
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

  /// The tractor beam: a pale scanning cone while searching, a bright cone
  /// in the winner's color once it locks on.
  void _paintBeam(
    Canvas canvas,
    Offset ufo,
    Offset focus,
    double u,
    FingerTouch? winner,
  ) {
    double strength;
    Color color;
    var bottom = focus.dy + 10;
    if (_picked) {
      final lock = _ramp(_since, 0, _lock);
      final retract = Curves.easeIn.transform(
        _ramp(_since, _lifted, _retracted),
      );
      if (retract >= 1) {
        return;
      }
      strength = 0.55 + 0.4 * lock;
      color = Color.lerp(_beam, fingerPalette[winner!.colorIndex], lock)!;
      bottom = bottom + (ufo.dy + u * 0.3 - bottom) * retract;
    } else if (_deciding) {
      strength = _ramp(_p, 0, 0.06) * (0.4 + 0.12 * math.sin(_t * 20));
      color = _beam;
    } else {
      return;
    }
    final top = ufo + Offset(0, u * 0.3);
    final spread = u * 1.25;
    final cone = Path()
      ..moveTo(top.dx - u * 0.35, top.dy)
      ..lineTo(top.dx + u * 0.35, top.dy)
      ..lineTo(focus.dx + spread, bottom)
      ..lineTo(focus.dx - spread, bottom)
      ..close();
    canvas.drawPath(
      cone,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.7 * strength),
            color.withValues(alpha: 0.25 * strength),
          ],
        ).createShader(cone.getBounds())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(focus.dx, bottom),
        width: spread * 2,
        height: spread * 0.45,
      ),
      Paint()
        ..color = color.withValues(alpha: 0.45 * strength)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // Scan lines sliding down the beam.
    if (!_picked || _since < _lifted) {
      for (var i = 0; i < 3; i++) {
        final f = (_t * 1.2 + i / 3) % 1;
        final y = top.dy + (bottom - top.dy) * f;
        final half = u * 0.35 + (spread - u * 0.35) * f;
        final x = top.dx + (focus.dx - top.dx) * f;
        canvas.drawLine(
          Offset(x - half, y),
          Offset(x + half, y),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.35 * strength)
            ..strokeWidth = 2,
        );
      }
    }
  }

  /// Stars left behind as the UFO flies off with the winner. They linger,
  /// twinkling softly.
  void _paintTrail(Canvas canvas, Offset ufo, Size size, double u) {
    if (!_picked || _since <= _retracted) {
      return;
    }
    final winner = fingerPalette[picker.winner!.colorIndex];
    final start = _flightStart(size);
    final f = _ramp(_since, _retracted, _gone);
    const stars = 18;
    for (var i = 0; i < stars; i++) {
      final s = i / stars;
      if (s > f) {
        break;
      }
      final at =
          _flightPoint(start, size, u, s) +
          Offset(math.sin(i * 2.3) * u * 0.3, math.cos(i * 1.7) * u * 0.3);
      final age = _since - (_retracted + s * (_gone - _retracted));
      final alpha =
          (0.35 + 0.65 * math.exp(-age * 1.5)) *
          (0.6 + 0.4 * math.sin(_t * 4 + i));
      _sparkle(
        canvas,
        at,
        3 + (i % 3) * 2.0,
        (i.isEven ? Colors.white : winner).withValues(alpha: alpha),
      );
    }
  }

  /// Where the UFO was when it set off, for the star trail.
  Offset _flightStart(Size size) {
    final all = [
      ...picker.touches.values,
      if (!picker.touches.containsKey(picker.winner!.pointer)) picker.winner!,
    ];
    final home = Offset(size.width / 2, size.height * 0.46);
    final focus = _focus(all, home);
    return focus - Offset(0, _altitude(focus, size));
  }

  void _paintUfo(Canvas canvas, Offset at, double u, Size size) {
    if (at.dy < -u * 2 || at.dx > size.width + u * 2) {
      return;
    }
    final flying = _picked && _since > _retracted;
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(
      flying
          // Leans into the direction it flies off in.
          ? (_flightStart(size).dx < size.width / 2 ? 0.25 : -0.25) *
                _ramp(_since, _retracted, _retracted + 0.3)
          : math.sin(_t * 1.6) * 0.05,
    );
    // Glow under the saucer.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, u * 0.2), width: u * 2.6, height: u),
      Paint()
        ..color = _dome.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    // The glass dome with its pilot.
    final dome = Rect.fromCenter(
      center: Offset(0, -u * 0.12),
      width: u * 1.05,
      height: u * 1.0,
    );
    canvas.drawArc(
      dome,
      math.pi,
      math.pi,
      true,
      Paint()..color = _dome.withValues(alpha: 0.5),
    );
    canvas.drawCircle(Offset(0, -u * 0.25), u * 0.2, Paint()..color = _alien);
    for (final side in const [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(side * u * 0.08, -u * 0.27),
          width: u * 0.09,
          height: u * 0.12,
        ),
        Paint()..color = Colors.black,
      );
    }
    canvas.drawArc(
      dome.deflate(u * 0.08),
      math.pi * 1.15,
      math.pi * 0.3,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    // The saucer.
    final hull = Rect.fromCenter(
      center: Offset(0, u * 0.05),
      width: u * 2.2,
      height: u * 0.55,
    );
    canvas.drawOval(
      hull,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, _hull, _hullDark],
          stops: [0, 0.45, 1],
        ).createShader(hull),
    );
    canvas.drawOval(
      hull,
      Paint()
        ..color = const Color(0xFF37474F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Blinking lights around the rim.
    const lights = [
      Color(0xFFFF5252),
      Color(0xFFFFEB3B),
      Color(0xFF69F0AE),
      Color(0xFF40C4FF),
      Color(0xFFFF4081),
    ];
    for (var i = 0; i < 5; i++) {
      final x = (i - 2) * u * 0.38;
      final on = ((_t * 4).floor() + i) % 3 == 0;
      final color = lights[i];
      if (on) {
        canvas.drawCircle(
          Offset(x, u * 0.1),
          u * 0.14,
          Paint()
            ..color = color.withValues(alpha: 0.6)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
      }
      canvas.drawCircle(
        Offset(x, u * 0.1),
        u * 0.07,
        Paint()..color = on ? color : color.withValues(alpha: 0.35),
      );
    }
    canvas.restore();
  }

  void _paintMeepleAt(
    Canvas canvas,
    FingerTouch touch,
    double mm,
    Offset feet,
  ) {
    final pop = Curves.elasticOut.transform(
      ((now - touch.since).inMilliseconds / 500).clamp(0.0, 1.0),
    );
    // A nervous little wobble while the beam is searching.
    final nervous = _deciding ? 0.08 : 0.03;
    _paintMeeple(
      canvas,
      feet,
      mm,
      fingerPalette[touch.colorIndex],
      angle: math.sin(_t * (_deciding ? 9 : 3) + touch.pointer) * nervous,
      scale: pop,
      shadow: true,
    );
  }

  /// A wooden meeple standing with its feet at [feet].
  void _paintMeeple(
    Canvas canvas,
    Offset feet,
    double m,
    Color color, {
    double angle = 0,
    double scale = 1,
    bool shadow = false,
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
        Paint()..color = Colors.black.withValues(alpha: 0.35),
      );
    }
    canvas.save();
    canvas.translate(feet.dx, feet.dy);
    canvas.rotate(angle);
    canvas.scale(m * scale);
    canvas.translate(0, -0.5);
    final dark = Color.lerp(color, Colors.black, 0.4)!;
    canvas.drawPath(
      _meeple.shift(const Offset(0.05, 0.05)),
      Paint()..color = dark,
    );
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
        ..strokeWidth = 0.03
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  /// A four-pointed sparkle.
  void _sparkle(Canvas canvas, Offset at, double r, Color color) {
    final path = Path()..moveTo(at.dx, at.dy - r);
    for (var i = 1; i <= 8; i++) {
      final a = -math.pi / 2 + i * math.pi / 4;
      final d = i.isEven ? r : r * 0.3;
      path.lineTo(at.dx + math.cos(a) * d, at.dy + math.sin(a) * d);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  /// The classic meeple, one unit tall, feet on y = 0.5.
  static final Path _meeple = Path.combine(
    PathOperation.union,
    Path()
      ..addOval(Rect.fromCircle(center: const Offset(0, -0.32), radius: 0.17)),
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

  @override
  bool shouldRepaint(covariant UfoPainter oldDelegate) => true;
}
