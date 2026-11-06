import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'finger_picker.dart';

/// The Mysterious Cauldron: every finger gets a tiny glowing ingredient in
/// its color. One by one they drop into a bubbling cauldron, the potion
/// glows and bubbles faster through everyone's colors, the cauldron shakes
/// violently, and a burst of smoke clears to show one player's color
/// floating above it.
///
/// The winner is drawn fairly when the suspense starts. The ingredients go
/// in one after another and the potion cycles through every color, so
/// nothing on screen hints at the result before the smoke clears.
class CauldronPainter extends CustomPainter {
  const CauldronPainter({required this.picker, required this.now});

  final FingerPicker picker;
  final Duration now;

  static const _brewGreen = Color(0xFF7CFC5A);
  static const _iron = Color(0xFF2B2833);
  static const _ironLight = Color(0xFF5A5466);
  static const _smoke = Color(0xFFE9E3F5);
  static const _flame = Color(0xFFFF8A1E);
  static const _flameCore = Color(0xFFFFE07A);

  /// Shares of the suspense: the ingredients drop in, the potion brews,
  /// and finally the cauldron shakes violently.
  static const _dropFrom = 0.04;
  static const _dropBy = 0.34;
  static const _flight = 0.12;
  static const _brew = 0.34;
  static const _violent = 0.76;

  /// Seconds after the pick: smoke billows up, then clears.
  static const _billow = 0.25;
  static const _cleared = 1.5;

  double get _t => now.inMicroseconds / 1e6;

  bool get _picked =>
      picker.phase == FingerPhase.picked && picker.winner != null;

  bool get _deciding => picker.phase == FingerPhase.deciding;

  /// How far through the suspense we are, from 0 to 1 (1 once picked).
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
    final rim = Offset(size.width / 2, size.height * 0.56);
    final k = (math.min(size.width, size.height) * 0.2).clamp(64.0, 120.0);

    _paintDen(canvas, size);

    final winner = picker.winner;
    final revealed = _picked ? _ramp(_since, _billow, _cleared) : 0.0;
    if (revealed > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = fingerPalette[winner!.colorIndex].withValues(
            alpha: 0.14 * revealed,
          ),
      );
    }

    final fingers = picker.touches.values.toList();
    final all = [
      ...fingers,
      if (_picked && !picker.touches.containsKey(winner!.pointer)) winner,
    ];
    for (final touch in fingers) {
      final isWinner = _picked && touch.pointer == winner!.pointer;
      _paintRing(canvas, touch, dim: _picked && !isWinner);
    }

    // The cauldron rattles harder and harder at the end; the burst calms it.
    final violent = _deciding ? _ramp(_p, _violent, 1) : 0.0;
    final shake = Offset(
      math.sin(_t * 61) * k * 0.07 * violent,
      math.cos(_t * 53) * k * 0.04 * violent,
    );
    final pot = rim + shake;
    final potion = _potionColor(all, winner);
    final brewing = _deciding || _picked ? _ramp(_p, _brew, 1) : 0.0;

    _paintCountdown(canvas, rim, k);
    _paintGlow(canvas, pot, k, potion, brewing);
    _paintFire(canvas, pot, k, 0.6 + 0.4 * brewing);
    _paintPot(canvas, pot, k, potion, brewing, violent);

    // Ingredients waiting by their players, or on their way in.
    for (var i = 0; i < all.length; i++) {
      _paintIngredientFor(canvas, all[i], i, all.length, pot, k);
    }

    if (_picked) {
      _paintOrb(canvas, pot, k, winner!);
      _paintSmoke(canvas, pot, k, size);
    }
  }

  /// Where a finger's ingredient floats: just above the fingertip so the
  /// finger doesn't hide it.
  Offset _home(FingerTouch touch) => touch.position - const Offset(0, 48);

  /// When the [i]th of [n] ingredients sets off, as a share of the suspense.
  double _setOff(int i, int n) {
    final stagger = n <= 1 ? 0.0 : (_dropBy - _flight - _dropFrom) / (n - 1);
    return _dropFrom + i * math.min(stagger, 0.06);
  }

  /// The potion: green at first, then cycling through every player's
  /// color, faster and faster. Once picked it turns the winner's color.
  Color _potionColor(List<FingerTouch> all, FingerTouch? winner) {
    final colors = [for (final touch in all) fingerPalette[touch.colorIndex]];
    Color cycling() {
      if (colors.isEmpty) {
        return _brewGreen;
      }
      // Faster as it brews: the phase grows with the square of time.
      final brew = _ramp(_p, _brew, 1);
      final elapsed = brew * picker.decideTime.inMicroseconds / 1e6;
      final phase = elapsed * (0.8 + 1.6 * brew);
      final i = phase.floor();
      // Holds each color, then switches quickly, so it never looks muddy.
      final f = Curves.easeInOut.transform(_ramp(phase - i, 0.6, 1));
      return Color.lerp(
        colors[i % colors.length],
        colors[(i + 1) % colors.length],
        f,
      )!;
    }

    final brew = _ramp(_p, _brew, _brew + 0.06);
    final current = Color.lerp(_brewGreen, cycling(), brew)!;
    if (!_picked) {
      return current;
    }
    return Color.lerp(
      current,
      fingerPalette[winner!.colorIndex],
      _ramp(_since, 0.1, _billow + 0.2),
    )!;
  }

  void _paintDen(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, 0.15),
          radius: 1.1,
          colors: [Color(0xFF3A2B55), Color(0xFF1B1530), Color(0xFF0C0A16)],
          stops: [0, 0.55, 1],
        ).createShader(rect),
    );
    // A stone floor.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.9),
        width: size.width * 1.4,
        height: size.height * 0.34,
      ),
      Paint()..color = const Color(0xFF241C33).withValues(alpha: 0.8),
    );
    // Magic dust drifting up.
    for (var i = 0; i < 18; i++) {
      final seed = i * 37.0;
      final rise = (_t * (0.03 + (i % 5) * 0.01) + i / 18) % 1;
      final at = Offset(
        size.width * ((seed * 0.618) % 1) + math.sin(_t + i) * 10,
        size.height * (1 - rise),
      );
      canvas.drawCircle(
        at,
        1.5 + (i % 3),
        Paint()
          ..color = const Color(
            0xFFCBB6FF,
          ).withValues(alpha: 0.25 * math.sin(math.pi * rise)),
      );
    }
  }

  void _paintRing(Canvas canvas, FingerTouch touch, {required bool dim}) {
    canvas.drawCircle(
      touch.position,
      30 * (1 + 0.05 * math.sin(_t * 5 + touch.pointer)),
      Paint()
        ..color = fingerPalette[touch.colorIndex].withValues(
          alpha: dim ? 0.3 : 0.9,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3),
    );
  }

  void _paintCountdown(Canvas canvas, Offset rim, double k) {
    final progress = picker.armProgress(now);
    if (picker.phase != FingerPhase.arming || progress <= 0) {
      return;
    }
    canvas.drawArc(
      Rect.fromCircle(center: rim + Offset(0, k * 0.45), radius: k * 1.45),
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

  /// The potion's light, brighter as it brews.
  void _paintGlow(
    Canvas canvas,
    Offset rim,
    double k,
    Color potion,
    double brewing,
  ) {
    final flicker = 0.85 + 0.15 * math.sin(_t * (6 + brewing * 20));
    canvas.drawCircle(
      rim - Offset(0, k * 0.2),
      k * (1.3 + brewing * 0.9),
      Paint()
        ..color = potion.withValues(alpha: (0.18 + 0.4 * brewing) * flicker)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
    );
  }

  /// Logs and flickering flames under the pot.
  void _paintFire(Canvas canvas, Offset rim, double k, double strength) {
    final base = rim + Offset(0, k * 1.32);
    final log = Paint()
      ..color = const Color(0xFF4E2F1A)
      ..strokeWidth = k * 0.14
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      base + Offset(-k * 0.7, k * 0.05),
      base + Offset(k * 0.6, -k * 0.08),
      log,
    );
    canvas.drawLine(
      base + Offset(-k * 0.6, -k * 0.08),
      base + Offset(k * 0.7, k * 0.05),
      log,
    );
    canvas.drawCircle(
      base,
      k * 0.8,
      Paint()
        ..color = _flame.withValues(alpha: 0.3 * strength)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
    for (var i = 0; i < 5; i++) {
      final x = (i - 2) * k * 0.22;
      final height =
          k *
          (0.35 + 0.15 * math.sin(_t * (9 + i * 2.3) + i)) *
          strength *
          (i == 2 ? 1.3 : 1);
      final width = k * 0.16;
      final foot = base + Offset(x, -k * 0.02);
      final flame = Path()
        ..moveTo(foot.dx - width, foot.dy)
        ..quadraticBezierTo(
          foot.dx - width,
          foot.dy - height * 0.6,
          foot.dx + math.sin(_t * 7 + i) * width * 0.4,
          foot.dy - height,
        )
        ..quadraticBezierTo(
          foot.dx + width,
          foot.dy - height * 0.6,
          foot.dx + width,
          foot.dy,
        )
        ..close();
      canvas.drawPath(flame, Paint()..color = _flame);
      canvas.drawPath(
        flame.transform(
          (Matrix4.identity()
                ..translateByDouble(foot.dx, foot.dy, 0, 1)
                ..scaleByDouble(0.55, 0.6, 1, 1)
                ..translateByDouble(-foot.dx, -foot.dy, 0, 1))
              .storage,
        ),
        Paint()..color = _flameCore,
      );
    }
  }

  /// The iron cauldron with its potion and bubbles.
  void _paintPot(
    Canvas canvas,
    Offset rim,
    double k,
    Color potion,
    double brewing,
    double violent,
  ) {
    // Little feet.
    for (final side in const [-1.0, 1.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: rim + Offset(side * k * 0.55, k * 1.22),
            width: k * 0.16,
            height: k * 0.26,
          ),
          Radius.circular(k * 0.05),
        ),
        Paint()..color = _iron,
      );
    }
    final body = Path()
      ..moveTo(rim.dx - k * 0.95, rim.dy)
      ..cubicTo(
        rim.dx - k * 1.3,
        rim.dy + k * 0.75,
        rim.dx - k * 0.75,
        rim.dy + k * 1.25,
        rim.dx,
        rim.dy + k * 1.22,
      )
      ..cubicTo(
        rim.dx + k * 0.75,
        rim.dy + k * 1.25,
        rim.dx + k * 1.3,
        rim.dy + k * 0.75,
        rim.dx + k * 0.95,
        rim.dy,
      )
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_ironLight, _iron, Color(0xFF15131A)],
            ).createShader(
              Rect.fromLTWH(rim.dx - k * 1.2, rim.dy, k * 2.4, k * 1.25),
            ),
    );
    // A shine and the potion's light on the iron.
    canvas.drawArc(
      Rect.fromLTWH(rim.dx - k * 1.0, rim.dy + k * 0.05, k * 0.9, k * 1.0),
      math.pi * 0.75,
      math.pi * 0.45,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = k * 0.08
        ..strokeCap = StrokeCap.round,
    );

    // The potion's surface.
    final surface = Rect.fromCenter(
      center: rim,
      width: k * 1.8,
      height: k * 0.34,
    );
    canvas.drawOval(
      surface,
      Paint()
        ..shader = RadialGradient(
          colors: [Color.lerp(potion, Colors.white, 0.45)!, potion],
        ).createShader(surface),
    );
    _paintBubbles(canvas, rim, k, potion, brewing, violent);
    // The rim.
    canvas.drawOval(
      Rect.fromCenter(center: rim, width: k * 1.98, height: k * 0.44),
      Paint()
        ..color = _ironLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = k * 0.12,
    );
    canvas.drawOval(
      Rect.fromCenter(center: rim, width: k * 1.98, height: k * 0.44),
      Paint()
        ..color = _iron
        ..style = PaintingStyle.stroke
        ..strokeWidth = k * 0.04,
    );
  }

  /// Bubbles swelling and popping on the potion, faster as it brews.
  void _paintBubbles(
    Canvas canvas,
    Offset rim,
    double k,
    Color potion,
    double brewing,
    double violent,
  ) {
    final count = 6 + (brewing * 8).round();
    final rate = 0.6 + brewing * 1.8 + violent * 1.5;
    for (var j = 0; j < count; j++) {
      final life = (_t * rate + j * 0.37) % 1;
      final x = math.sin(j * 2.7 + (_t * rate + j * 0.37).floor() * 1.3);
      final at = rim + Offset(x * k * 0.75, -life * k * 0.12 * (1 + violent));
      final r =
          k * (0.05 + 0.06 * ((j * 7) % 3) / 2) * math.sin(math.pi * life);
      if (r <= 0.5) {
        continue;
      }
      canvas.drawCircle(
        at,
        r,
        Paint()..color = Color.lerp(potion, Colors.white, 0.35)!,
      );
      canvas.drawCircle(
        at,
        r,
        Paint()
          ..color = Color.lerp(potion, Colors.black, 0.25)!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
    // Sparks spitting out as it boils over.
    if (violent > 0) {
      for (var j = 0; j < 10; j++) {
        final life = (_t * 1.8 + j * 0.13) % 1;
        final a = -math.pi / 2 + (j / 9 - 0.5) * 1.6;
        final at =
            rim +
            Offset(math.cos(a), math.sin(a)) * k * (0.2 + life * 1.1) +
            Offset(0, life * life * k * 0.8);
        canvas.drawCircle(
          at,
          2.5,
          Paint()
            ..color = Color.lerp(
              potion,
              Colors.white,
              0.5,
            )!.withValues(alpha: violent * (1 - life)),
        );
      }
    }
  }

  void _paintIngredientFor(
    Canvas canvas,
    FingerTouch touch,
    int i,
    int n,
    Offset rim,
    double k,
  ) {
    final color = fingerPalette[touch.colorIndex];
    final home = _home(touch);
    if (!(_deciding || _picked)) {
      final pop = Curves.elasticOut.transform(
        ((now - touch.since).inMilliseconds / 500).clamp(0.0, 1.0),
      );
      final bob = math.sin(_t * 3 + touch.pointer) * 4;
      _paintIngredient(
        canvas,
        home + Offset(0, bob),
        color,
        touch.colorIndex,
        scale: pop,
        spin: math.sin(_t * 2 + i) * 0.3,
      );
      return;
    }
    final start = _setOff(i, n);
    final f = _ramp(_p, start, start + _flight);
    if (f >= 1) {
      // In the pot: a splash of its color as it lands.
      final splash = _ramp(_p, start + _flight, start + _flight + 0.06);
      if (splash < 1 && !_picked) {
        for (var d = 0; d < 6; d++) {
          final a = -math.pi / 2 + (d / 5 - 0.5) * 2.2;
          final at =
              _target(i, n, rim, k) +
              Offset(math.cos(a), math.sin(a)) * k * 0.35 * splash +
              Offset(0, splash * splash * k * 0.25);
          canvas.drawCircle(
            at,
            3.5 * (1 - splash) + 1,
            Paint()..color = color.withValues(alpha: 1 - splash),
          );
        }
      }
      return;
    }
    // A high arc over to the pot, spinning on the way.
    final end = _target(i, n, rim, k);
    final e = Curves.easeIn.transform(f);
    final top = math.min(home.dy, end.dy) - k * 1.2;
    final control = Offset((home.dx + end.dx) / 2, top);
    final u = 1 - e;
    final at = home * (u * u) + control * (2 * u * e) + end * (e * e);
    _paintIngredient(
      canvas,
      at,
      color,
      touch.colorIndex,
      scale: 1 - 0.35 * e,
      spin: f * math.pi * 3,
    );
  }

  /// Where the [i]th ingredient falls in, spread across the potion.
  Offset _target(int i, int n, Offset rim, double k) {
    final spread = n <= 1 ? 0.0 : (i / (n - 1) - 0.5) * k * 0.9;
    return rim + Offset(spread, 0);
  }

  /// A tiny glowing ingredient: an orb, a crystal, a star or a drop.
  void _paintIngredient(
    Canvas canvas,
    Offset at,
    Color color,
    int kind, {
    double scale = 1,
    double spin = 0,
    double size = 11,
  }) {
    if (scale <= 0.01) {
      return;
    }
    final r = size * scale;
    canvas.drawCircle(
      at,
      r * 2.2,
      Paint()
        ..color = color.withValues(alpha: 0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r),
    );
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(spin);
    final Path shape;
    switch (kind % 4) {
      case 0:
        shape = Path()
          ..addOval(Rect.fromCircle(center: Offset.zero, radius: r));
      case 1:
        shape = Path()
          ..moveTo(0, -r * 1.3)
          ..lineTo(r * 0.8, 0)
          ..lineTo(0, r * 1.3)
          ..lineTo(-r * 0.8, 0)
          ..close();
      case 2:
        shape = Path()..moveTo(0, -r * 1.25);
        for (var p = 1; p <= 10; p++) {
          final a = -math.pi / 2 + p * math.pi / 5;
          final d = p.isEven ? r * 1.25 : r * 0.55;
          shape.lineTo(math.cos(a) * d, math.sin(a) * d);
        }
        shape.close();
      default:
        shape = Path()
          ..moveTo(0, -r * 1.35)
          ..quadraticBezierTo(r * 1.1, r * 0.1, 0, r)
          ..quadraticBezierTo(-r * 1.1, r * 0.1, 0, -r * 1.35)
          ..close();
    }
    canvas.drawPath(
      shape,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [Colors.white, Color.lerp(color, Colors.white, 0.3)!, color],
          stops: const [0, 0.3, 1],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: r * 1.3)),
    );
    canvas.drawPath(
      shape,
      Paint()
        ..color = Color.lerp(color, Colors.black, 0.4)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.restore();
  }

  /// The winner's color rising out of the potion as the smoke clears.
  void _paintOrb(Canvas canvas, Offset rim, double k, FingerTouch winner) {
    final rise = Curves.easeOutBack.transform(_ramp(_since, 0.15, 1.1));
    if (rise <= 0) {
      return;
    }
    final color = fingerPalette[winner.colorIndex];
    final bob = math.sin(_t * 2.5) * 5 * _ramp(_since, 1.1, 1.6);
    final at = rim - Offset(0, k * 1.35 * rise + bob);
    canvas.drawCircle(
      at,
      k * 0.9,
      Paint()
        ..color = color.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );
    // A wisp of potion trailing up to it.
    canvas.drawPath(
      Path()
        ..moveTo(rim.dx - k * 0.1, rim.dy)
        ..quadraticBezierTo(
          rim.dx + math.sin(_t * 2) * k * 0.3,
          (rim.dy + at.dy) / 2,
          at.dx,
          at.dy + k * 0.25,
        ),
      Paint()
        ..color = color.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = k * 0.08
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    _paintIngredient(
      canvas,
      at,
      color,
      winner.colorIndex,
      size: k * 0.24,
      scale: rise.clamp(0.0, 1.2),
      spin: math.sin(_t * 1.5) * 0.25,
    );
    // Sparkles circling it.
    for (var i = 0; i < 6; i++) {
      final a = _t * 1.4 + i * math.pi / 3;
      final p =
          at + Offset(math.cos(a) * k * 0.55, math.sin(a) * k * 0.3) * rise;
      _sparkle(
        canvas,
        p,
        4 + 2 * math.sin(_t * 5 + i),
        Colors.white.withValues(alpha: 0.85 * rise.clamp(0.0, 1.0)),
      );
    }
  }

  /// A big puff of smoke that billows up and clears.
  void _paintSmoke(Canvas canvas, Offset rim, double k, Size size) {
    final s = _since;
    if (s >= _cleared) {
      return;
    }
    if (s < 0.2) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.white.withValues(alpha: 0.5 * (1 - s / 0.2)),
      );
    }
    final grow = Curves.easeOut.transform(_ramp(s, 0, _billow));
    final fade = 1 - Curves.easeIn.transform(_ramp(s, _billow, _cleared));
    final drift = _ramp(s, _billow, _cleared);
    for (var i = 0; i < 16; i++) {
      final a = i / 16 * math.pi * 2 + i * 0.3;
      final reach =
          k * (0.4 + 0.9 * grow + 1.2 * drift) * (0.7 + 0.3 * (i % 3));
      final at =
          rim -
          Offset(0, k * 0.9) +
          Offset(math.cos(a) * reach, math.sin(a) * reach * 0.75) -
          Offset(0, drift * k * 0.6);
      canvas.drawCircle(
        at,
        k * (0.35 + 0.35 * grow) * (0.8 + 0.2 * (i % 2)),
        Paint()
          ..color = _smoke.withValues(alpha: 0.9 * fade)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }
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

  @override
  bool shouldRepaint(covariant CauldronPainter oldDelegate) => true;
}
