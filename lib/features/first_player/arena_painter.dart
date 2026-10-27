import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'finger_picker.dart';

/// Finger Arena: every finger gets a little boxer. They bounce into the
/// ring, trade jabs and get bopped back to their corners one by one; the
/// last one standing is the champion and goes first.
class ArenaPainter extends CustomPainter {
  const ArenaPainter({required this.picker, required this.now});

  final FingerPicker picker;
  final Duration now;

  static const _gold = Color(0xFFFFC83D);
  static const _goldDark = Color(0xFFB8860B);
  static const _ink = Color(0xFF1B1B24);
  static const _pow = Color(0xFFFFE066);

  /// Share of the bout spent hopping into the ring.
  static const _enter = 0.24;

  /// How long a knocked-out fighter flies back to its corner, as a share of
  /// the bout.
  static const _flight = 0.1;

  /// Before a knockout, how long the attacker spends closing in and
  /// jabbing, as a share of the bout; and how long it takes to step back.
  static const _approach = 0.13;
  static const _stepBack = 0.05;

  /// Farthest a rival can be (in body radii) for an ordinary jab to reach.
  static const _reach = 3.2;

  double get _t => now.inMicroseconds / 1e6;

  bool get _picked =>
      picker.phase == FingerPhase.picked && picker.winner != null;

  /// How far through the bout we are, from 0 to 1 (1 once picked).
  double get _bout {
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

  /// The last one standing: drawn secretly when the bout starts.
  int? get _champion => picker.chosen?.pointer ?? picker.winner?.pointer;

  static double _ease(double x) =>
      Curves.easeInOutCubic.transform(x.clamp(0.0, 1.0));

  static int _hash(int pointer, int seed) =>
      ((pointer + 31) * 2654435761 + seed * 40503) & 0x7fffffff;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.46);
    final f = (math.min(size.width, size.height) * 0.055).clamp(20.0, 30.0);
    final ringR = math.min(size.width, size.height) * 0.34;

    _paintRing(canvas, size, center, ringR);

    final winner = picker.winner;
    final cheer = _picked
        ? ((now - picker.pickedAt!).inMilliseconds / 450).clamp(0.0, 1.0)
        : 0.0;

    final fingers = picker.touches.values.toList();
    final all = [
      ...fingers,
      if (_picked && !picker.touches.containsKey(winner!.pointer)) winner,
    ];
    final ko = _knockouts(all);
    final bout = _bout;

    for (final touch in all) {
      final isWinner = _picked && touch.pointer == winner!.pointer;
      _paintFingerRing(canvas, touch, dim: _picked && !isWinner, glow: isWinner);
    }
    _paintBell(canvas, center, f);

    if (_picked) {
      _paintRays(canvas, center, f, cheer, fingerPalette[winner!.colorIndex]);
    }

    // Where every fighter still standing would be, before any duel.
    final index = {for (var i = 0; i < all.length; i++) all[i].pointer: i};
    final slots = _slots(all, center, f);
    Offset base(int pointer, double at) => _arenaPos(
      slots[pointer]!,
      index[pointer]!,
      at,
      center,
      ringR,
      _home(all[index[pointer]!], f),
    );
    final standing = <int, Offset>{};
    for (final touch in all) {
      final down = ko[touch.pointer];
      if (down == null || bout < down) {
        standing[touch.pointer] =
            bout == 0 ? _home(touch, f) : base(touch.pointer, bout);
      }
    }

    // Every knockout is a real duel: the attacker steps right up to its
    // rival and throws a flurry of jabs that land just as the rival goes
    // down, then steps back.
    final flurries = <int, Offset>{};
    final attackers = _attackers(all, ko);
    for (final MapEntry(key: loser, value: down) in ko.entries) {
      final attacker = attackers[loser]!;
      final start = down - _approach;
      if (bout < start || bout > down + _stepBack || _picked) {
        continue;
      }
      final from = standing[attacker];
      if (from == null) {
        continue;
      }
      final rival = base(loser, math.min(bout, down));
      final weight = bout <= down
          ? _ease((bout - start) / (_approach * 0.7))
          : 1 - _ease((bout - down) / _stepBack);
      final away = from - rival;
      final side = away.distance < 1 ? const Offset(1, 0) : away / away.distance;
      standing[attacker] = Offset.lerp(from, rival + side * f * 2.2, weight)!;
      if (bout <= down) {
        flurries[attacker] = rival;
      }
    }

    // Where every fighter is drawn, how it leans, and whether it's down.
    final fighters = <(FingerTouch, Offset, double, bool)>[];
    for (final touch in all) {
      final home = _home(touch, f);
      final down = ko[touch.pointer];
      if (bout == 0) {
        fighters.add((touch, home, 0, false));
        continue;
      }
      if (down != null && bout >= down) {
        // Bopped: flies back to its own corner and lands flat.
        final k = ((bout - down) / _flight).clamp(0.0, 1.0);
        final from = base(touch.pointer, down);
        final at = Offset.lerp(from, home, _ease(k))! -
            Offset(0, math.sin(math.pi * k) * f * 2.2);
        final side = from.dx < home.dx ? 1.0 : -1.0;
        fighters.add((touch, at, side * 1.5 * k, k >= 1));
        continue;
      }
      var at = standing[touch.pointer]!;
      if (_picked && touch.pointer == winner!.pointer) {
        // The champion bounces to the middle of the ring.
        at = Offset.lerp(at, center, _ease(cheer))! -
            Offset(0, (math.sin(_t * 9).abs()) * f * 0.5 * cheer);
      } else {
        // Light on its feet.
        at += Offset(0, -math.sin(_t * 11 + touch.pointer).abs() * f * 0.25);
      }
      fighters.add((touch, at, 0, false));
    }

    // Back to front, so nearer fighters overlap the ones behind.
    fighters.sort((a, b) => a.$2.dy.compareTo(b.$2.dy));
    for (final (touch, at, lean, flat) in fighters) {
      final isWinner = _picked && touch.pointer == winner!.pointer;
      final isDown = ko[touch.pointer] != null && bout >= ko[touch.pointer]!;
      var target = flurries[touch.pointer];
      final flurry = target != null;
      if (target == null && !isDown && !_picked && bout > _enter) {
        // Only jab at a rival that is actually within reach.
        final near = _nearest(touch.pointer, at, standing, ko, bout);
        if (near != null && (near - at).distance <= f * _reach) {
          target = near;
        }
      }
      _paintFighter(
        canvas,
        at,
        f,
        touch,
        lean: lean,
        down: isDown,
        flat: flat,
        target: target,
        flurry: flurry,
        cheering: isWinner,
      );
    }

    // "POW!" on the fighter that just got hit.
    for (final touch in all) {
      final down = ko[touch.pointer];
      if (down != null && bout >= down && bout - down < 0.08) {
        final at = base(touch.pointer, down);
        _paintPow(canvas, at - Offset(0, f * 0.6), f, (bout - down) / 0.08);
      }
    }

    if (_picked) {
      _paintConfetti(canvas, center - Offset(0, f), f, winner!);
    }
  }

  /// Where a finger's fighter waits: just above the fingertip.
  Offset _home(FingerTouch touch, double f) =>
      touch.position - Offset(0, f * 1.7);

  /// The side of the ring each fighter takes, as an angle around [center]:
  /// the side nearest its own finger. Fighters on the same side spread out
  /// evenly but keep their order, so nobody has to cross over anybody.
  Map<int, double> _slots(List<FingerTouch> all, Offset center, double f) {
    final n = all.length;
    if (n == 0) {
      return const {};
    }
    final angles = {
      for (final touch in all)
        touch.pointer: () {
          final d = _home(touch, f) - center;
          return math.atan2(d.dy, d.dx);
        }(),
    };
    final order = all.map((touch) => touch.pointer).toList()
      ..sort((a, b) => angles[a]!.compareTo(angles[b]!));
    // Evenly spaced slots, turned to sit as close as possible to where the
    // fingers are (the circular mean of the offsets).
    final step = math.pi * 2 / n;
    var sx = 0.0;
    var sy = 0.0;
    for (var k = 0; k < n; k++) {
      final offset = angles[order[k]]! - k * step;
      sx += math.cos(offset);
      sy += math.sin(offset);
    }
    final start = math.atan2(sy, sx);
    return {for (var k = 0; k < n; k++) order[k]: start + k * step};
  }

  /// A fighter's spot in the ring at [bout]: walk in from its own side,
  /// then circle and weave. Depends only on [bout] so a knockout can start
  /// from where it happened.
  Offset _arenaPos(
    double slot,
    int i,
    double bout,
    Offset center,
    double ringR,
    Offset home,
  ) {
    // Circling only starts once everyone is in the ring.
    final angle = slot + math.max(0.0, bout - _enter) * 2.4;
    final r = ringR * (0.5 + 0.18 * math.sin(bout * 9 + i * 1.7));
    final spot =
        center +
        Offset(math.cos(angle) * r, math.sin(angle) * r * 0.85) +
        Offset(math.sin(bout * 23 + i) * 6, math.cos(bout * 19 + i) * 6);
    // A gentle walk-in rather than a dash.
    return Offset.lerp(
      home,
      spot,
      Curves.easeInOutSine.transform((bout / _enter).clamp(0.0, 1.0)),
    )!;
  }

  /// When each loser gets bopped, as a share of the bout. The order is
  /// shuffled every round, and the champion is never knocked out.
  Map<int, double> _knockouts(List<FingerTouch> all) {
    final champion = _champion;
    if (champion == null) {
      return const {};
    }
    final seed = picker.decidingAt.inMilliseconds;
    final losers = [
      for (final touch in all)
        if (touch.pointer != champion) touch.pointer,
    ]..sort((a, b) => _hash(a, seed).compareTo(_hash(b, seed)));
    return {
      for (var k = 0; k < losers.length; k++)
        // The first knockout waits until everyone is in the ring.
        losers[k]: 0.38 + 0.5 * (k + 1) / losers.length,
    };
  }

  /// Who knocks out each loser: a fighter still standing at that moment
  /// (sometimes the future champion), varied from round to round.
  Map<int, int> _attackers(List<FingerTouch> all, Map<int, double> ko) {
    final seed = picker.decidingAt.inMilliseconds;
    return {
      for (final MapEntry(key: loser, value: down) in ko.entries)
        loser: () {
          final candidates = [
            for (final touch in all)
              if (touch.pointer != loser &&
                  (ko[touch.pointer] ?? 2) > down)
                touch.pointer,
          ];
          return candidates[_hash(loser, seed + 7) % candidates.length];
        }(),
    };
  }

  /// The closest fighter still standing, to jab at.
  Offset? _nearest(
    int pointer,
    Offset at,
    Map<int, Offset> standing,
    Map<int, double> ko,
    double bout,
  ) {
    Offset? best;
    var bestDistance = double.infinity;
    for (final entry in standing.entries) {
      final down = ko[entry.key];
      if (entry.key == pointer || (down != null && bout >= down)) {
        continue;
      }
      final d = (entry.value - at).distance;
      if (d < bestDistance) {
        bestDistance = d;
        best = entry.value;
      }
    }
    return best;
  }

  void _paintRing(Canvas canvas, Size size, Offset center, double ringR) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.1),
          radius: 1.1,
          colors: [Color(0xFF3A3A4A), Color(0xFF1E1E28), Color(0xFF0E0E14)],
          stops: [0, 0.6, 1],
        ).createShader(rect),
    );
    final half = ringR * 1.25;
    final mat = Rect.fromCenter(center: center, width: half * 2, height: half * 2);
    // Apron, then the canvas mat.
    canvas.drawRect(
      mat.inflate(14),
      Paint()..color = const Color(0xFF7A1F2B),
    );
    canvas.drawRect(
      mat,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF3D7CC9), Color(0xFF2A5E9E)],
        ).createShader(mat),
    );
    canvas.drawCircle(
      center,
      ringR * 0.38,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    // Three ropes around the ring.
    for (final (color, inset) in const [
      (Color(0xFFE53935), 0.0),
      (Colors.white, 6.0),
      (Color(0xFF1E88E5), 12.0),
    ]) {
      canvas.drawRect(
        mat.deflate(inset),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    // Corner posts.
    for (final corner in [
      mat.topLeft,
      mat.topRight,
      mat.bottomLeft,
      mat.bottomRight,
    ]) {
      canvas.drawCircle(corner, 9, Paint()..color = const Color(0xFFCFD8DC));
      canvas.drawCircle(
        corner,
        9,
        Paint()
          ..color = const Color(0xFF546E7A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  /// The countdown: a boxing bell with a ring filling around it.
  void _paintBell(Canvas canvas, Offset center, double f) {
    final progress = picker.armProgress(now);
    if (picker.phase != FingerPhase.arming || progress <= 0) {
      return;
    }
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: f * 1.6),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..color = _gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    final ring = 0.12 * math.sin(_t * 30) * progress;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(ring);
    final bell = Path()
      ..moveTo(-f * 0.8, f * 0.45)
      ..quadraticBezierTo(-f * 0.75, -f * 0.75, 0, -f * 0.8)
      ..quadraticBezierTo(f * 0.75, -f * 0.75, f * 0.8, f * 0.45)
      ..close();
    canvas.drawPath(bell, Paint()..color = _gold);
    canvas.drawPath(
      bell,
      Paint()
        ..color = _goldDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(Offset(0, f * 0.55), f * 0.18, Paint()..color = _goldDark);
    canvas.restore();
  }

  void _paintFingerRing(
    Canvas canvas,
    FingerTouch touch, {
    required bool dim,
    required bool glow,
  }) {
    final color = fingerPalette[touch.colorIndex];
    canvas.drawCircle(
      touch.position,
      28 * (1 + 0.05 * math.sin(_t * 5 + touch.pointer)),
      Paint()
        ..color = color.withValues(alpha: dim ? 0.3 : 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = glow ? 6 : 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3),
    );
  }

  void _paintFighter(
    Canvas canvas,
    Offset at,
    double f,
    FingerTouch touch, {
    required double lean,
    required bool down,
    required bool flat,
    required Offset? target,
    required bool cheering,
    bool flurry = false,
  }) {
    final pop = Curves.elasticOut.transform(
      ((now - touch.since).inMilliseconds / 500).clamp(0.0, 1.0),
    );
    if (pop <= 0.01) {
      return;
    }
    final color = fingerPalette[touch.colorIndex];
    final dark = Color.lerp(color, Colors.black, 0.45)!;
    final glove = Color.lerp(color, Colors.black, 0.25)!;

    canvas.drawOval(
      Rect.fromCenter(
        center: at + Offset(0, f * 1.05),
        width: f * 1.7,
        height: f * 0.45,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(lean);
    canvas.scale(pop);

    // Gloves: guard up, a jab toward the nearest rival, or raised in
    // victory.
    final toTarget = target == null ? null : target - at;
    final aim = toTarget == null || toTarget.distance == 0
        ? const Offset(0, 1)
        : toTarget / toTarget.distance;
    final jab = target == null
        ? 0.0
        : math.max(0.0, math.sin(_t * (flurry ? 22 : 9) + touch.pointer * 1.9));
    // The glove stops at the rival's body instead of punching past it.
    final reach = toTarget == null
        ? 0.0
        : math.max(0.0, math.min(f * 1.2, toTarget.distance - f * 1.3));
    for (final side in const [-1.0, 1.0]) {
      Offset hand;
      if (cheering) {
        hand = Offset(side * f * 0.95, -f * 1.35 - math.sin(_t * 9).abs() * 4);
      } else if (down) {
        hand = Offset(side * f * 1.15, f * 0.25);
      } else {
        final guard = Offset(side * f * 0.85, -f * 0.1);
        // In a flurry both gloves take turns; otherwise the lead hand jabs.
        final punching =
            flurry ? (side > 0) == (math.sin(_t * 11) > 0) : side > 0;
        hand = punching && target != null
            ? guard + aim * reach * jab
            : guard + aim * f * 0.25;
      }
      canvas.drawCircle(hand, f * 0.42, Paint()..color = glove);
      canvas.drawCircle(
        hand,
        f * 0.42,
        Paint()
          ..color = dark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      canvas.drawCircle(
        hand + Offset(-f * 0.12, -f * 0.12),
        f * 0.1,
        Paint()..color = Colors.white.withValues(alpha: 0.5),
      );
    }

    // Round body.
    final body = Rect.fromCircle(center: Offset.zero, radius: f);
    canvas.drawCircle(
      Offset.zero,
      f,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: [Color.lerp(color, Colors.white, 0.3)!, color, dark],
          stops: const [0, 0.55, 1],
        ).createShader(body),
    );
    canvas.drawCircle(
      Offset.zero,
      f,
      Paint()
        ..color = dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // A sweatband.
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: f * 0.92),
      math.pi * 1.15,
      math.pi * 0.7,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = f * 0.18,
    );

    // Face.
    final eye = Paint()..color = _ink;
    for (final side in const [-1.0, 1.0]) {
      final e = Offset(side * f * 0.32, -f * 0.12);
      if (down) {
        final x = Paint()
          ..color = _ink
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round;
        final s = f * 0.12;
        canvas.drawLine(e - Offset(s, s), e + Offset(s, s), x);
        canvas.drawLine(e + Offset(-s, s), e + Offset(s, -s), x);
      } else if (cheering) {
        canvas.drawArc(
          Rect.fromCenter(center: e, width: f * 0.3, height: f * 0.24),
          math.pi * 1.1,
          math.pi * 0.8,
          false,
          Paint()
            ..color = _ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round,
        );
      } else {
        canvas.drawCircle(e, f * 0.1, eye);
        // Determined brows.
        canvas.drawLine(
          e + Offset(-side * f * 0.16, -f * 0.2),
          e + Offset(side * f * 0.12, -f * 0.13),
          Paint()
            ..color = _ink
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round,
        );
      }
    }
    final mouth = Offset(0, f * 0.32);
    if (cheering) {
      canvas.drawArc(
        Rect.fromCenter(center: mouth, width: f * 0.5, height: f * 0.36),
        0,
        math.pi,
        true,
        Paint()..color = _ink,
      );
    } else if (down) {
      canvas.drawCircle(mouth, f * 0.09, Paint()..color = _ink);
    } else {
      canvas.drawLine(
        mouth - Offset(f * 0.14, 0),
        mouth + Offset(f * 0.14, 0),
        Paint()
          ..color = _ink
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.restore();

    // Dizzy stars circling a fighter that's down.
    if (flat) {
      for (var i = 0; i < 3; i++) {
        final angle = _t * 4 + i * math.pi * 2 / 3;
        _paintStar(
          canvas,
          at + Offset(math.cos(angle) * f * 0.9, -f * 0.9 + math.sin(angle) * f * 0.3),
          f * 0.22,
          Paint()..color = _pow,
        );
      }
    }
  }

  /// The comic "POW!" when a fighter gets bopped.
  void _paintPow(Canvas canvas, Offset at, double f, double p) {
    final scale = Curves.easeOut.transform(p.clamp(0.0, 1.0));
    final fade = 1 - p.clamp(0.0, 1.0);
    final burst = Path();
    const points = 10;
    for (var i = 0; i < points * 2; i++) {
      final angle = i * math.pi / points;
      final d = (i.isEven ? f * 1.6 : f * 0.95) * (0.6 + 0.6 * scale);
      final point = at + Offset(math.cos(angle), math.sin(angle)) * d;
      i == 0 ? burst.moveTo(point.dx, point.dy) : burst.lineTo(point.dx, point.dy);
    }
    burst.close();
    canvas.drawPath(burst, Paint()..color = _pow.withValues(alpha: fade));
    canvas.drawPath(
      burst,
      Paint()
        ..color = const Color(0xFFE53935).withValues(alpha: fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    final label = TextPainter(
      text: TextSpan(
        text: 'POW!',
        style: TextStyle(
          color: const Color(0xFFD32F2F).withValues(alpha: fade),
          fontSize: f * 0.75,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, at - Offset(label.width / 2, label.height / 2));
  }

  /// Golden rays behind the champion.
  void _paintRays(
    Canvas canvas,
    Offset center,
    double f,
    double cheer,
    Color color,
  ) {
    final paint = Paint()
      ..color = _gold.withValues(alpha: 0.25 * cheer)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    for (var i = 0; i < 14; i++) {
      final angle = i / 14 * math.pi * 2 + _t * 0.5;
      final length = f * 7 * cheer;
      canvas.drawPath(
        Path()
          ..moveTo(center.dx, center.dy)
          ..lineTo(
            center.dx + math.cos(angle - 0.07) * length,
            center.dy + math.sin(angle - 0.07) * length,
          )
          ..lineTo(
            center.dx + math.cos(angle + 0.07) * length,
            center.dy + math.sin(angle + 0.07) * length,
          )
          ..close(),
        paint,
      );
    }
    canvas.drawCircle(
      center,
      f * 2.4,
      Paint()
        ..color = color.withValues(alpha: 0.4 * cheer)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
  }

  void _paintStar(Canvas canvas, Offset at, double r, Paint paint) {
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final d = i.isEven ? r : r * 0.45;
      final p = at + Offset(math.cos(angle), math.sin(angle)) * d;
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    star.close();
    canvas.drawPath(star, paint);
  }

  void _paintConfetti(
    Canvas canvas,
    Offset origin,
    double f,
    FingerTouch winner,
  ) {
    final tau = (now - picker.pickedAt!).inMicroseconds / 1e6 - 0.3;
    if (tau < 0 || tau > 1.8) {
      return;
    }
    final colors = [
      fingerPalette[winner.colorIndex],
      _gold,
      Colors.white,
      const Color(0xFFE53935),
    ];
    final gravity = f * 16;
    for (var i = 0; i < 36; i++) {
      final angle = i / 36 * math.pi * 2;
      final speed = f * (5 + (i % 5) * 1.6);
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
  bool shouldRepaint(covariant ArenaPainter oldDelegate) => true;
}
