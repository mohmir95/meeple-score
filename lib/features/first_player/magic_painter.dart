import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'finger_picker.dart';

enum _Mood { happy, confused, determined, proud }

/// The Octopus's Magic Show: a cute, overconfident octopus magician. Its
/// wand flops, it shakes it hard, and POOF! A burst of stars reveals the
/// player who goes first, and the magician takes a bow.
class MagicPainter extends CustomPainter {
  const MagicPainter({required this.picker, required this.now});

  /// An octopus has eight arms, so it hosts up to eight volunteers.
  static const arms = 8;

  final FingerPicker picker;
  final Duration now;

  static const _skin = Color(0xFFB57EDC);
  static const _skinLight = Color(0xFFD9B8F0);
  static const _skinDark = Color(0xFF7E4BA8);
  static const _ink = Color(0xFF2A1636);
  static const _gold = Color(0xFFFFC83D);
  static const _goldDark = Color(0xFFB8860B);
  static const _curtain = Color(0xFFB0202E);
  static const _curtainDark = Color(0xFF6E0F19);

  static const _starColors = [
    Color(0xFFFF5C8A),
    Color(0xFFFFC83D),
    Color(0xFF5CD6FF),
    Color(0xFF8BE36B),
    Color(0xFFC08BFF),
    Colors.white,
  ];

  double get _t => now.inMicroseconds / 1e6;

  bool get _picked =>
      picker.phase == FingerPhase.picked && picker.winner != null;

  /// How far through the trick we are, from 0 to 1.
  double get _show {
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

  /// Seconds since the POOF (the reveal), or -1 before it.
  double get _since =>
      _picked ? (now - picker.pickedAt!).inMicroseconds / 1e6 : -1;

  static double _seg(double x, double from, double to) =>
      ((x - from) / (to - from)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.43);
    final r = (math.min(size.width, size.height) * 0.1).clamp(36.0, 66.0);
    final show = _show;
    final since = _since;
    final winner = picker.winner;

    _paintStage(canvas, size, center, r, since);

    // Every volunteer's spot on stage.
    final fingers = picker.touches.values.toList();
    for (final touch in fingers) {
      final isWinner = _picked && touch.pointer == winner!.pointer;
      _paintVolunteer(
        canvas,
        touch,
        dim: _picked && !isWinner && since > 0.3,
        golden: isWinner ? _seg(since, 0.3, 0.8) : 0,
      );
    }

    _paintCountdown(canvas, center, r);

    // The trick, scene by scene.
    var mood = _Mood.happy;
    var wand = -0.5; // radians from pointing right; negative is up
    var bend = 0.0;
    var hatLift = 0.0;
    var shake = 0.0;
    var bow = 0.0;
    if (picker.phase == FingerPhase.deciding) {
      // 1. Ta-da: tips the hat.
      hatLift = math.sin(math.pi * _seg(show, 0, 0.16));
      // 2. Confident wand waving…
      final wave = _seg(show, 0.16, 0.45);
      wand = -0.5 + math.sin(wave * math.pi * 4) * 0.5 * (wave > 0 ? 1 : 0);
      // …until the wand flops.
      final flop = Curves.easeOutBack.transform(_seg(show, 0.45, 0.58));
      bend = flop;
      if (show > 0.45) {
        mood = _Mood.confused;
        wand = -0.5 + 0.9 * flop;
      }
      // 3. Shakes it hard and the wand straightens out again.
      final fix = _seg(show, 0.68, 1);
      if (show > 0.68) {
        mood = _Mood.determined;
        bend = 1 - Curves.easeOut.transform(fix);
        wand = -0.9 * Curves.easeOut.transform(fix) + 0.4 * (1 - fix);
        shake = 0.25 + 0.75 * fix;
      }
    } else if (_picked) {
      // 4–5. POOF, then a proud bow toward the winner.
      mood = since < 0.5 ? _Mood.determined : _Mood.proud;
      wand = -1.0;
      bow = Curves.easeInOut.transform(_seg(since, 0.5, 0.95));
    }

    final lean = _picked && winner != null
        ? (winner.position.dx < center.dx ? -1.0 : 1.0)
        : 0.0;
    _paintMagician(
      canvas,
      center,
      r,
      mood: mood,
      wandAngle: wand + math.sin(_t * 48) * 0.12 * shake,
      bend: bend,
      hatLift: hatLift,
      bow: bow * lean,
      sparks: shake,
    );

    if (_picked) {
      // Where the wand's tip is once raised for the reveal.
      final tip = center + Offset(r * 2.05, -r * 1.86);
      _paintPoof(canvas, size, tip, r, since);
      _paintWinnerSparkle(canvas, winner!, since);
    }
  }

  void _paintStage(
    Canvas canvas,
    Size size,
    Offset center,
    double r,
    double since,
  ) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A0F2E), Color(0xFF3A2160), Color(0xFF241338)],
          stops: [0, 0.6, 1],
        ).createShader(rect),
    );
    // Stage floor.
    final floor = Rect.fromCenter(
      center: Offset(size.width / 2, center.dy + r * 2.4),
      width: size.width * 1.3,
      height: r * 2.2,
    );
    canvas.drawOval(floor, Paint()..color = const Color(0xFF4A2A1C));
    // The spotlight.
    canvas.drawPath(
      Path()
        ..moveTo(size.width / 2 - 20, 0)
        ..lineTo(size.width / 2 + 20, 0)
        ..lineTo(center.dx + r * 2.6, center.dy + r * 2.4)
        ..lineTo(center.dx - r * 2.6, center.dy + r * 2.4)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.07),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + r * 2.3),
        width: r * 5.2,
        height: r * 1.1,
      ),
      Paint()
        ..color = const Color(0xFFFFF3C4).withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    // A happy glow on the stage after the trick.
    if (since > 0) {
      canvas.drawRect(
        rect,
        Paint()
          ..color = _gold.withValues(alpha: 0.08 * _seg(since, 0, 0.4)),
      );
    }

    // Curtains on both sides, with soft pleats.
    for (final side in const [-1.0, 1.0]) {
      final width = size.width * 0.13;
      final x = side < 0 ? 0.0 : size.width - width;
      final curtain = Rect.fromLTWH(x, 0, width, size.height);
      canvas.drawRect(
        curtain,
        Paint()
          ..shader = LinearGradient(
            colors: const [
              _curtainDark,
              _curtain,
              _curtainDark,
              _curtain,
              _curtainDark,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(curtain),
      );
    }
    // The valance with a gold fringe.
    final valance = Rect.fromLTWH(0, 0, size.width, 26);
    canvas.drawRect(valance, Paint()..color = _curtain);
    for (var x = 0.0; x < size.width; x += 30) {
      canvas.drawOval(
        Rect.fromLTWH(x, 14, 30, 22),
        Paint()..color = _curtain,
      );
    }
    final fringe = Paint()
      ..color = _gold
      ..strokeWidth = 2;
    for (var x = 4.0; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, 30), Offset(x, 38), fringe);
    }
  }

  void _paintVolunteer(
    Canvas canvas,
    FingerTouch touch, {
    required bool dim,
    required double golden,
  }) {
    final color = fingerPalette[touch.colorIndex];
    final radius = 34 * (1 + 0.05 * math.sin(_t * 5 + touch.pointer));
    // The winner keeps its own colour (a gold ring would look like the
    // yellow player's), framed by a gold halo instead.
    if (golden > 0) {
      canvas.drawCircle(
        touch.position,
        radius + 9,
        Paint()
          ..color = _gold.withValues(alpha: golden)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 5),
      );
      canvas.drawCircle(
        touch.position,
        radius - 4,
        Paint()..color = color.withValues(alpha: 0.3 * golden),
      );
    }
    canvas.drawCircle(
      touch.position,
      radius,
      Paint()
        ..color = color.withValues(alpha: dim ? 0.3 : 0.95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 + 3 * golden
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4),
    );
    if (dim) {
      return;
    }
    // A little twinkling star above every volunteer.
    final pop = Curves.elasticOut.transform(
      ((now - touch.since).inMilliseconds / 500).clamp(0.0, 1.0),
    );
    final at = touch.position - Offset(0, 54 + math.sin(_t * 3 + touch.pointer) * 4);
    // The winner's star moves into the big gold star instead.
    _paintStar(
      canvas,
      at,
      (9 + 2 * math.sin(_t * 6 + touch.pointer)) * pop * (1 - golden),
      Paint()..color = color,
      spin: _t * 0.8 + touch.pointer,
    );
  }

  void _paintCountdown(Canvas canvas, Offset center, double r) {
    final progress = picker.armProgress(now);
    if (picker.phase != FingerPhase.arming || progress <= 0) {
      return;
    }
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r * 1.55),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..color = _gold.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3),
    );
  }

  void _paintMagician(
    Canvas canvas,
    Offset at,
    double r, {
    required _Mood mood,
    required double wandAngle,
    required double bend,
    required double hatLift,
    required double bow,
    required double sparks,
  }) {
    final bob = math.sin(_t * 2.2) * r * 0.05;
    canvas.save();
    // Bows from the base of the body toward the winner.
    final pivot = at + Offset(0, r * 1.1);
    canvas.translate(pivot.dx, pivot.dy + bob);
    canvas.rotate(bow * 0.45);
    canvas.translate(-pivot.dx, -pivot.dy);

    // Shadow on the stage.
    canvas.drawOval(
      Rect.fromCenter(
        center: at + Offset(0, r * 1.7),
        width: r * 2.8,
        height: r * 0.5,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Seven curly arms below; the eighth holds the wand.
    for (var i = 0; i < 7; i++) {
      final angle = math.pi * (0.12 + 0.76 * i / 6) + math.sin(_t * 1.6 + i) * 0.1;
      final tip = at + Offset(math.cos(angle) * r * 1.4, math.sin(angle) * r * 1.25 + r * 0.4);
      _paintArm(canvas, at + Offset(0, r * 0.4), tip, r, i * 1.3);
    }

    // The wand arm and wand.
    final shoulder = at + Offset(r * 0.75, r * 0.15);
    final hand = shoulder + Offset(math.cos(wandAngle) * r * 0.9, math.sin(wandAngle) * r * 0.9);
    _paintArm(canvas, shoulder, hand, r, 9, width: 0.8);
    _paintWand(canvas, hand, wandAngle, r, bend, sparks);

    // The body.
    final head = Rect.fromCenter(
      center: at - Offset(0, r * 0.1),
      width: r * 2.1,
      height: r * 2.15,
    );
    canvas.drawOval(
      head,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.5),
          colors: [_skinLight, _skin, _skinDark],
          stops: [0, 0.6, 1],
        ).createShader(head),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: at + Offset(-r * 0.35, -r * 0.65),
        width: r * 0.5,
        height: r * 0.26,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
    // A tiny bow tie.
    final tie = at + Offset(0, r * 0.82);
    for (final side in const [-1.0, 1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(tie.dx, tie.dy)
          ..lineTo(tie.dx + side * r * 0.3, tie.dy - r * 0.15)
          ..lineTo(tie.dx + side * r * 0.3, tie.dy + r * 0.15)
          ..close(),
        Paint()..color = const Color(0xFFE53935),
      );
    }
    canvas.drawCircle(tie, r * 0.07, Paint()..color = const Color(0xFFB71C1C));

    _paintFace(canvas, at, r, mood);
    _paintHat(canvas, at - Offset(0, r * 1.05), r, hatLift);
    canvas.restore();

    if (mood == _Mood.confused) {
      _paintLabel(canvas, at + Offset(-r * 1.25, -r * 1.55), '?', r * 0.75);
    }
  }

  void _paintFace(Canvas canvas, Offset at, double r, _Mood mood) {
    final ink = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.07
      ..strokeCap = StrokeCap.round;
    for (final side in const [-1.0, 1.0]) {
      final eye = at + Offset(side * r * 0.4, -r * 0.05);
      if (mood == _Mood.proud) {
        canvas.drawArc(
          Rect.fromCenter(center: eye, width: r * 0.4, height: r * 0.32),
          math.pi * 1.1,
          math.pi * 0.8,
          false,
          ink,
        );
      } else {
        // Confused: one eye big, one squinting.
        final squint = mood == _Mood.confused && side > 0 ? 0.45 : 1.0;
        canvas.drawOval(
          Rect.fromCenter(
            center: eye,
            width: r * 0.48,
            height: r * 0.56 * squint,
          ),
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          eye + Offset(0, r * 0.03),
          r * 0.16 * (squint < 1 ? 0.7 : 1),
          Paint()..color = _ink,
        );
        canvas.drawCircle(
          eye + Offset(-r * 0.05, -r * 0.04),
          r * 0.05,
          Paint()..color = Colors.white,
        );
        if (mood == _Mood.determined) {
          canvas.drawLine(
            eye + Offset(-side * r * 0.22, -r * 0.42),
            eye + Offset(side * r * 0.2, -r * 0.3),
            ink,
          );
        }
      }
      canvas.drawOval(
        Rect.fromCenter(
          center: eye + Offset(side * r * 0.12, r * 0.36),
          width: r * 0.28,
          height: r * 0.14,
        ),
        Paint()..color = const Color(0xFFFF5C9A).withValues(alpha: 0.45),
      );
    }
    final mouth = at + Offset(0, r * 0.42);
    switch (mood) {
      case _Mood.confused:
        // A wobbly "huh?".
        canvas.drawPath(
          Path()
            ..moveTo(mouth.dx - r * 0.18, mouth.dy)
            ..quadraticBezierTo(
              mouth.dx - r * 0.06,
              mouth.dy - r * 0.08,
              mouth.dx,
              mouth.dy,
            )
            ..quadraticBezierTo(
              mouth.dx + r * 0.06,
              mouth.dy + r * 0.08,
              mouth.dx + r * 0.18,
              mouth.dy,
            ),
          ink,
        );
      case _Mood.proud:
        canvas.drawArc(
          Rect.fromCenter(center: mouth, width: r * 0.5, height: r * 0.4),
          0,
          math.pi,
          true,
          Paint()..color = _ink,
        );
      case _Mood.happy:
      case _Mood.determined:
        canvas.drawArc(
          Rect.fromCenter(
            center: mouth - Offset(0, r * 0.08),
            width: r * 0.36,
            height: r * 0.26,
          ),
          math.pi * 0.15,
          math.pi * 0.7,
          false,
          ink,
        );
    }
  }

  void _paintHat(Canvas canvas, Offset brim, double r, double lift) {
    canvas.save();
    // Tipping the hat: up and tilted back.
    canvas.translate(brim.dx, brim.dy - lift * r * 0.6);
    canvas.rotate(-0.15 - lift * 0.35);
    final w = r * 1.0;
    final h = r * 0.95;
    final crown = RRect.fromRectAndCorners(
      Rect.fromLTWH(-w / 2, -h, w, h),
      topLeft: Radius.circular(r * 0.08),
      topRight: Radius.circular(r * 0.08),
    );
    canvas.drawRRect(crown, Paint()..color = const Color(0xFF1C1C24));
    canvas.drawRect(
      Rect.fromLTWH(-w / 2, -h * 0.32, w, h * 0.2),
      Paint()..color = const Color(0xFF8E24AA),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 1.6, height: r * 0.3),
      Paint()..color = const Color(0xFF26262F),
    );
    // A shine on the crown.
    canvas.drawRect(
      Rect.fromLTWH(-w * 0.35, -h * 0.9, w * 0.1, h * 0.5),
      Paint()..color = Colors.white.withValues(alpha: 0.15),
    );
    canvas.restore();
    if (lift > 0.3) {
      _paintStar(
        canvas,
        brim - Offset(-r * 0.6, r * 1.4),
        r * 0.18 * lift,
        Paint()..color = _gold,
      );
    }
  }

  /// The wand: straight and proud, or flopping over by [bend].
  void _paintWand(
    Canvas canvas,
    Offset hand,
    double angle,
    double r,
    double bend,
    double sparks,
  ) {
    final length = r * 1.5;
    final dir = Offset(math.cos(angle), math.sin(angle));
    final normal = Offset(-dir.dy, dir.dx);
    // Flops downward (toward +y) like wet spaghetti.
    final droop = normal.dy > 0 ? normal : -normal;
    final tip =
        hand + dir * length * (1 - 0.35 * bend) + droop * length * 0.75 * bend;
    final control = hand + dir * length * 0.6;
    final path = Path()
      ..moveTo(hand.dx, hand.dy)
      ..quadraticBezierTo(control.dx, control.dy, tip.dx, tip.dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF111111)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.13
        ..strokeCap = StrokeCap.round,
    );
    // White tip.
    final tipDir = tip - control;
    final unit = tipDir.distance == 0 ? dir : tipDir / tipDir.distance;
    canvas.drawLine(
      tip - unit * r * 0.22,
      tip,
      Paint()
        ..color = Colors.white
        ..strokeWidth = r * 0.13
        ..strokeCap = StrokeCap.round,
    );
    // A sad little fizzle when it flops, and sparks when it's shaken.
    if (bend > 0.6 && sparks == 0) {
      canvas.drawCircle(
        tip + Offset(0, r * 0.1),
        r * 0.18,
        Paint()..color = Colors.white.withValues(alpha: 0.3),
      );
    }
    final count = (sparks * 10).round();
    for (var i = 0; i < count; i++) {
      final a = i * 2.4 + _t * 14;
      final d = r * (0.25 + 0.35 * ((i * 0.37 + _t * 3) % 1));
      _paintStar(
        canvas,
        tip + Offset(math.cos(a), math.sin(a)) * d,
        r * 0.09,
        Paint()..color = _starColors[i % _starColors.length],
      );
    }
    if (sparks > 0) {
      canvas.drawCircle(
        tip,
        r * 0.5 * sparks,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35 * sparks)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }
  }

  void _paintArm(
    Canvas canvas,
    Offset from,
    Offset to,
    double r,
    double phase, {
    double width = 1,
  }) {
    final line = to - from;
    final length = line.distance;
    if (length < 1) {
      return;
    }
    final dir = line / length;
    final normal = Offset(-dir.dy, dir.dx);
    const steps = 16;
    final left = <Offset>[];
    final right = <Offset>[];
    for (var i = 0; i <= steps; i++) {
      final s = i / steps;
      final wave = math.sin(s * math.pi * 2 - _t * 3 + phase) * r * 0.12 * s;
      final p = Offset.lerp(from, to, s)! + normal * wave;
      final w = r * width * (0.3 - 0.2 * s);
      left.add(p + normal * w / 2);
      right.add(p - normal * w / 2);
    }
    final path = Path()..moveTo(left.first.dx, left.first.dy);
    for (final p in left.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    for (final p in right.reversed) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = _skin);
    canvas.drawPath(
      path,
      Paint()
        ..color = _skinDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(to, r * width * 0.06, Paint()..color = _skin);
  }

  /// POOF: a puff of smoke and colourful stars bursting across the stage.
  void _paintPoof(
    Canvas canvas,
    Size size,
    Offset origin,
    double r,
    double since,
  ) {
    if (since > 2) {
      return;
    }
    final cloud = _seg(since, 0, 0.6);
    if (cloud < 1) {
      final fade = 1 - cloud;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.7 * fade);
      for (var i = 0; i < 8; i++) {
        final a = i / 8 * math.pi * 2;
        canvas.drawCircle(
          origin + Offset(math.cos(a), math.sin(a)) * r * (0.3 + 1.2 * cloud),
          r * (0.45 + 0.4 * cloud),
          paint,
        );
      }
      if (since < 0.45) {
        _paintLabel(canvas, origin, 'POOF!', r * 0.55 * (0.7 + cloud));
      }
    }
    // Stars burst out and drift down across the whole stage.
    final reach = math.max(size.width, size.height) * 0.75;
    for (var i = 0; i < 46; i++) {
      final a = i / 46 * math.pi * 2 + i * 0.7;
      final speed = 0.55 + (i % 7) * 0.08;
      final out = Curves.easeOut.transform(_seg(since, 0, 1.1)) * reach * speed;
      final at =
          origin +
          Offset(math.cos(a), math.sin(a)) * out +
          Offset(0, since * since * r * 2);
      final alpha = (1 - _seg(since, 1.2, 2)).clamp(0.0, 1.0);
      _paintStar(
        canvas,
        at,
        r * (0.1 + (i % 3) * 0.05),
        Paint()
          ..color = _starColors[i % _starColors.length].withValues(
            alpha: alpha,
          ),
        spin: since * 4 + i,
      );
    }
  }

  /// The winner's spot lights up with a golden sparkle and a star.
  void _paintWinnerSparkle(Canvas canvas, FingerTouch winner, double since) {
    final g = _seg(since, 0.3, 0.8);
    if (g <= 0) {
      return;
    }
    final at = winner.position;
    final color = fingerPalette[winner.colorIndex];
    canvas.drawCircle(
      at,
      64 * (1 + 0.06 * math.sin(_t * 5)),
      Paint()
        ..color = _gold.withValues(alpha: 0.4 * g)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
    // The winner's ring again, on top of the glow so its colour stays
    // bright and clear, like its star.
    final radius = 34 * (1 + 0.05 * math.sin(_t * 5 + winner.pointer));
    canvas.drawCircle(
      at,
      radius - 3,
      Paint()
        ..color = Color.lerp(color, Colors.white, 0.25)!.withValues(
          alpha: 0.55 * g,
        ),
    );
    canvas.drawCircle(
      at,
      radius,
      Paint()
        ..color = color.withValues(alpha: g)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );
    canvas.drawCircle(
      at,
      radius - 4.5,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.8 * g)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    for (var i = 0; i < 10; i++) {
      final a = i / 10 * math.pi * 2 + _t * 0.8;
      final twinkle = 0.5 + 0.5 * math.sin(_t * 7 + i * 1.7);
      _paintStar(
        canvas,
        at + Offset(math.cos(a), math.sin(a)) * (46 + 10 * twinkle) * g,
        (3 + 3 * twinkle) * g,
        Paint()..color = const Color(0xFFFFF3C4),
      );
    }
    final pop = Curves.elasticOut.transform(_seg(since, 0.4, 1.1));
    final star = at - Offset(0, 64 + math.sin(_t * 3) * 4);
    _paintStar(canvas, star, 28 * pop, Paint()..color = _gold, spin: 0);
    _paintStar(
      canvas,
      star,
      28 * pop,
      Paint()
        ..color = _goldDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
      spin: 0,
    );
    // The winner's own coloured star, set in the middle of the gold one.
    _paintStar(canvas, star, 16 * pop, Paint()..color = color, spin: 0);
    _paintStar(
      canvas,
      star,
      16 * pop,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
      spin: 0,
    );
  }

  void _paintLabel(Canvas canvas, Offset at, String text, double size) {
    final label = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: size,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          shadows: const [Shadow(color: Color(0xFF8E24AA), blurRadius: 6)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, at - Offset(label.width / 2, label.height / 2));
  }

  void _paintStar(
    Canvas canvas,
    Offset at,
    double r,
    Paint paint, {
    double spin = 0,
  }) {
    if (r <= 0) {
      return;
    }
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5 + spin;
      final d = i.isEven ? r : r * 0.45;
      final p = at + Offset(math.cos(a), math.sin(a)) * d;
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    star.close();
    canvas.drawPath(star, paint);
  }

  @override
  bool shouldRepaint(covariant MagicPainter oldDelegate) => true;
}
