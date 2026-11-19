import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'finger_picker.dart';

/// The Puzzle Factory: every player color has its own glossy piece, and
/// the ten pieces fit together into one 6 × 6 puzzle. Factory pieces fly
/// in from outside, turning to fit: first the shapes nobody holds, then
/// the other players' shapes, and each player whose shape is taken fades.
/// A single gap is left, and the chosen player's own piece clicks in last
/// as the puzzle turns platinum around it.
///
/// The winner is drawn fairly when the suspense starts. The shapes go in
/// in a random order, so nobody knows whose gap is left until the end.
class PuzzlePainter extends CustomPainter {
  const PuzzlePainter({required this.picker, required this.now});

  final FingerPicker picker;
  final Duration now;

  static const _bg = Color(0xFF232428);
  static const _bgLight = Color(0xFF34363C);
  static const _card = Color(0xFF34363C);
  static const _cardEdge = Color(0xFF4C4F57);
  static const _hole = Color(0xFFECEDEF);
  static const _holeLine = Color(0xFFD3D5DA);

  /// The finished puzzle's platinum shine: light, middle and dark. Neutral,
  /// so every winner's color stands out against it.
  static const _finish = [
    Color(0xFFFFFFFF),
    Color(0xFFC9CED6),
    Color(0xFF7F8896),
  ];

  /// The finish's main color, for the card's rim, glow and sparkles.
  static const _shine = Color(0xFFC9CED6);
  static const _factory = Color(0xFF7D8590);

  /// The puzzle grid, and each player color's piece within it as
  /// (column, row) cells. Together they cover the grid exactly.
  static const _grid = 6;
  static const _pieces = [
    [(3, 1), (3, 2), (3, 3), (4, 2)], // T
    [(2, 3), (2, 4), (2, 5), (1, 5)], // L
    [(5, 2), (5, 3), (4, 3), (4, 4)], // S
    [(0, 3), (1, 3), (0, 4), (1, 4), (0, 5)], // P
    [(0, 1), (2, 1), (0, 2), (1, 2), (2, 2)], // U
    [(0, 0), (1, 0), (2, 0), (3, 0)], // I
    [(4, 0), (5, 0), (4, 1), (5, 1)], // O
    [(5, 4), (5, 5), (4, 5)], // small L
    [(3, 4), (3, 5)], // domino
    [(1, 1)], // single block
  ];

  /// Shares of the suspense: the shapes nobody holds fly in, then the
  /// other players' shapes, one by one, all but the chosen one's.
  static const _fillFrom = 0.03;
  static const _fillBy = 0.99;
  static const _fastFall = 0.07;
  static const _slowFall = 0.14;

  /// Seconds after the pick: the last piece flies in and snaps, then the
  /// puzzle turns platinum.
  static const _lastFlight = 0.3;
  static const _finishFrom = 0.38;

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

  static int _hash(int pointer, int seed) =>
      ((pointer + 31) * 2654435761 + seed * 40503) & 0x7fffffff;

  static List<(int, int)> _shape(int colorIndex) =>
      _pieces[colorIndex % _pieces.length];

  @override
  void paint(Canvas canvas, Size size) {
    final c = (math.min(size.width, size.height) * 0.095).clamp(28.0, 46.0);
    final centre = Offset(size.width / 2, size.height * 0.42);
    final origin = centre - Offset(c * _grid / 2, c * _grid / 2);

    _paintBackdrop(canvas, size);

    final winner = picker.winner;
    if (_picked) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = fingerPalette[winner!.colorIndex].withValues(
            alpha: 0.1 * _ramp(_since, _lastFlight, _lastFlight + 0.4),
          ),
      );
    }

    final finished = _picked
        ? _ramp(_since, _finishFrom, _finishFrom + 0.4)
        : 0.0;
    _paintCard(canvas, origin, c, finished);
    _paintCountdown(canvas, centre, c);

    final fingers = picker.touches.values.toList();
    final all = [
      ...fingers,
      if (_picked && !picker.touches.containsKey(winner!.pointer)) winner,
    ];
    for (final touch in fingers) {
      final isWinner = _picked && touch.pointer == winner!.pointer;
      _paintRing(canvas, touch, dim: _picked && !isWinner, glow: isWinner);
    }

    final building = _deciding || _picked;
    final target = picker.chosen ?? winner;
    final fills = building && target != null
        ? _fills(all, target)
        : const <(int, double, double)>[];
    _paintFills(canvas, size, fills, origin, c, target);

    // The players' pieces wait by their fingers. Once a piece of the same
    // shape is placed, that player is out; the chosen one flies in last.
    final placed = {
      for (final (shape, start, flight) in fills)
        if (_p >= start + flight) shape,
    };
    for (final touch in all) {
      final isTarget = target != null && touch.pointer == target.pointer;
      if (isTarget && _picked) {
        continue;
      }
      _paintWaiting(
        canvas,
        touch,
        c,
        nervous: building,
        out: placed.contains(touch.colorIndex % _pieces.length),
      );
    }
    if (_picked) {
      _paintPlaced(
        canvas,
        target!,
        _ramp(_since, 0, _lastFlight),
        origin,
        c,
        last: true,
        finished: 0,
      );
      if (_since > _finishFrom + 0.4) {
        _paintShine(canvas, origin, c);
      }
    }
  }

  /// The pieces that fill the puzzle from outside, as (shape, start,
  /// flight), shares of the suspense: first the shapes nobody holds, then
  /// the other players' shapes in a random order. The chosen player's
  /// shape is left as the last gap.
  List<(int, double, double)> _fills(
    List<FingerTouch> all,
    FingerTouch target,
  ) {
    final held = {for (final touch in all) touch.colorIndex % _pieces.length};
    final random = math.Random(picker.decidingAt.inMilliseconds * 31 + 9);
    final free = [
      for (var i = 0; i < _pieces.length; i++)
        if (!held.contains(i)) i,
    ]..shuffle(random);
    final others = [
      for (final shape in held)
        if (shape != target.colorIndex % _pieces.length) shape,
    ]..shuffle(random);

    // One stream of pieces right up to the pick: quick at first, then
    // spacing out and flying slower, so the last few build the suspense.
    final shapes = [...free, ...others];
    final n = shapes.length;
    final schedule = <(int, double, double)>[];
    for (var i = 0; i < n; i++) {
      final x = n <= 1 ? 1.0 : i / (n - 1);
      final flight = _fastFall + (_slowFall - _fastFall) * x;
      final start =
          _fillFrom + (_fillBy - _slowFall - _fillFrom) * math.pow(x, 1.7);
      schedule.add((shapes[i], start, flight));
    }
    return schedule;
  }

  /// How far a placed piece has turned platinum: the shine spreads out
  /// from the winner's piece once it's in.
  double _finishFor(int colorIndex, FingerTouch? target) {
    if (!_picked || target == null) {
      return 0;
    }
    final from = _centroid(_shape(target.colorIndex));
    final to = _centroid(_shape(colorIndex));
    final delay = (to - from).distance * 0.04;
    return _ramp(_since, _finishFrom + delay, _finishFrom + delay + 0.2);
  }

  void _paintBackdrop(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.1,
          colors: [_bgLight, _bg, Color(0xFF151619)],
          stops: [0, 0.6, 1],
        ).createShader(rect),
    );
    // A fine dot grid, like the puzzle cards.
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.06);
    for (var y = 12.0; y < size.height; y += 24) {
      for (var x = 12.0; x < size.width; x += 24) {
        canvas.drawCircle(Offset(x, y), 1.2, dot);
      }
    }
  }

  /// The dark puzzle card with its white cut-out.
  void _paintCard(Canvas canvas, Offset origin, double c, double finished) {
    final hole = origin & Size.square(c * _grid);
    final card = RRect.fromRectAndRadius(
      hole.inflate(c * 0.7),
      Radius.circular(c * 0.4),
    );
    if (finished > 0) {
      canvas.drawRRect(
        card.inflate(c * 0.15),
        Paint()
          ..color = _shine.withValues(alpha: 0.35 * finished)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, c * 0.5),
      );
    }
    canvas.drawRRect(
      card.shift(Offset(0, c * 0.18)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawRRect(
      card,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF41444B), _card, Color(0xFF2A2C31)],
        ).createShader(card.outerRect),
    );
    canvas.drawRRect(
      card,
      Paint()
        ..color = Color.lerp(_cardEdge, _shine, finished)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 + 2 * finished,
    );
    // Dots around the cut-out.
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.18);
    for (var i = 0; i <= _grid; i++) {
      for (final at in [
        Offset(hole.left + i * c, hole.top - c * 0.35),
        Offset(hole.left + i * c, hole.bottom + c * 0.35),
        Offset(hole.left - c * 0.35, hole.top + i * c),
        Offset(hole.right + c * 0.35, hole.top + i * c),
      ]) {
        canvas.drawCircle(at, 1.6, dot);
      }
    }
    final cut = RRect.fromRectAndRadius(hole, Radius.circular(c * 0.12));
    canvas.drawRRect(cut, Paint()..color = _hole);
    final line = Paint()
      ..color = _holeLine
      ..strokeWidth = 1;
    for (var i = 1; i < _grid; i++) {
      canvas.drawLine(
        Offset(hole.left + i * c, hole.top),
        Offset(hole.left + i * c, hole.bottom),
        line,
      );
      canvas.drawLine(
        Offset(hole.left, hole.top + i * c),
        Offset(hole.right, hole.top + i * c),
        line,
      );
    }
    // A shadow along the top edge, so the cut-out looks recessed.
    final lip = Rect.fromLTWH(hole.left, hole.top, hole.width, c * 0.18);
    canvas.save();
    canvas.clipRRect(cut);
    canvas.drawRect(
      lip,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.25), Colors.transparent],
        ).createShader(lip),
    );
    canvas.restore();
  }

  void _paintCountdown(Canvas canvas, Offset centre, double c) {
    final progress = picker.armProgress(now);
    if (picker.phase != FingerPhase.arming || progress <= 0) {
      return;
    }
    final width = c * _grid;
    final top = centre.dy + c * _grid / 2 + c * 1.1;
    final track = RRect.fromLTRBR(
      centre.dx - width / 2,
      top,
      centre.dx + width / 2,
      top + 8,
      const Radius.circular(4),
    );
    canvas.drawRRect(
      track,
      Paint()..color = Colors.white.withValues(alpha: 0.15),
    );
    canvas.drawRRect(
      RRect.fromLTRBR(
        track.left,
        track.top,
        track.left + width * progress,
        track.bottom,
        const Radius.circular(4),
      ),
      Paint()..color = Colors.white,
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

  /// The middle of a piece's cells, in grid units.
  static Offset _centroid(List<(int, int)> cells) {
    var x = 0.0;
    var y = 0.0;
    for (final (cx, cy) in cells) {
      x += cx + 0.5;
      y += cy + 0.5;
    }
    return Offset(x / cells.length, y / cells.length);
  }

  /// Where a piece sits in the puzzle, on screen.
  Offset _slot(List<(int, int)> cells, Offset origin, double c) =>
      origin + _centroid(cells) * c;

  /// Pieces flying in from outside the screen, turning to fit and snapping
  /// into the puzzle.
  void _paintFills(
    Canvas canvas,
    Size size,
    List<(int, double, double)> fills,
    Offset origin,
    double c,
    FingerTouch? target,
  ) {
    final centre = origin + Offset(c * _grid / 2, c * _grid / 2);
    final far = math.max(size.width, size.height) * 0.8;
    for (final (shape, start, flight) in fills) {
      final f = _ramp(_p, start, start + flight);
      if (f <= 0) {
        continue;
      }
      final cells = _pieces[shape];
      final slot = _slot(cells, origin, c);
      final random = math.Random(
        picker.decidingAt.inMilliseconds * 13 + shape * 977,
      );
      // From a random spot beyond the edge of the screen, on a curve.
      final a = random.nextDouble() * math.pi * 2;
      final from = centre + Offset(math.cos(a), math.sin(a)) * far;
      final bend =
          (from - slot) * 0.5 +
          Offset(-(from - slot).dy, (from - slot).dx) *
              (random.nextDouble() - 0.5) *
              0.6;
      final control = slot + bend;
      final e = Curves.easeOutCubic.transform(f);
      final w = 1 - e;
      final at = from * (w * w) + control * (2 * w * e) + slot * (e * e);
      final turns = (1 + random.nextInt(3)) * (random.nextBool() ? 1 : -1);
      // Once the round is picked every piece has settled, with no flash.
      final land = _picked
          ? 1.0
          : _ramp(_p, start + flight, start + flight + 0.05);
      _paintPiece(
        canvas,
        cells,
        _factory,
        c,
        at,
        turns * math.pi / 2 * (1 - Curves.easeOutCubic.transform(f)),
        scale: 1 + 0.08 * math.sin(math.pi * land),
        snap: land,
        finished: _finishFor(shape, target),
      );
    }
  }

  /// Where a finger's piece waits: above the fingertip.
  Offset _home(FingerTouch touch) => touch.position - const Offset(0, 74);

  /// How a waiting piece is turned: a quarter turn of its own, so each
  /// one has to turn to fit.
  double _homeTurn(FingerTouch touch) =>
      (_hash(touch.pointer, 7) % 4) * math.pi / 2;

  void _paintWaiting(
    Canvas canvas,
    FingerTouch touch,
    double c, {
    required bool nervous,
    required bool out,
  }) {
    final pop = Curves.elasticOut.transform(
      ((now - touch.since).inMilliseconds / 500).clamp(0.0, 1.0),
    );
    final bob = out ? 0.0 : math.sin(_t * 2.5 + touch.pointer) * 3;
    // Once the building starts, the pieces still in jitter nervously; a
    // piece whose spot is taken fades and settles.
    final jitter = out
        ? 0.0
        : nervous
        ? math.sin(_t * (18 + 10 * _p) + touch.pointer) * 0.05 * (0.5 + _p)
        : math.sin(_t * 1.8 + touch.pointer) * 0.1;
    if (out) {
      canvas.saveLayer(
        null,
        Paint()..color = Colors.black.withValues(alpha: 0.35),
      );
    }
    _paintPiece(
      canvas,
      _shape(touch.colorIndex),
      fingerPalette[touch.colorIndex],
      c * 0.55,
      _home(touch) + Offset(0, bob),
      _homeTurn(touch) + jitter,
      scale: pop,
    );
    if (out) {
      canvas.restore();
    }
  }

  /// The chosen player's piece flying [f] of the way from its finger into
  /// the last gap, growing to full size and turning to fit.
  void _paintPlaced(
    Canvas canvas,
    FingerTouch touch,
    double f,
    Offset origin,
    double c, {
    required bool last,
    required double finished,
  }) {
    final cells = _shape(touch.colorIndex);
    final slot = _slot(cells, origin, c);
    final home = _home(touch);
    // A high arc over to the puzzle.
    final e = Curves.easeOutCubic.transform(f);
    final lift = math.sin(math.pi * e) * c * 1.5;
    final at = Offset.lerp(home, slot, e)! - Offset(0, lift);
    final turn = _homeTurn(touch);
    // Turns the short way round to fit, with one extra spin for flair.
    final angle = (turn + math.pi * 2) * (1 - Curves.easeOutCubic.transform(f));
    // Others flash as they land; the last one when it clicks in.
    final snap = last ? _ramp(_since - _lastFlight, 0, 0.2) : _ramp(f, 0.9, 1);
    if (last && snap > 0 && snap < 1) {
      // A flash as the final piece clicks in.
      canvas.drawCircle(
        slot,
        c * (1 + 3 * snap),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.6 * (1 - snap))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    }
    _paintPiece(
      canvas,
      cells,
      fingerPalette[touch.colorIndex],
      c * (0.55 + 0.45 * e),
      at,
      angle,
      scale: last ? 1 + 0.12 * math.sin(math.pi * snap) : 1,
      snap: snap,
      glow: last ? _ramp(_since, _lastFlight, _lastFlight + 0.4) : 0,
      finished: finished,
    );
  }

  /// A shine sweeping across the finished finished puzzle, with sparkles.
  void _paintShine(Canvas canvas, Offset origin, double c) {
    final hole = origin & Size.square(c * _grid);
    final sweep = ((_since - _finishFrom - 0.4) * 0.6) % 1.6 - 0.3;
    canvas.save();
    canvas.clipRect(hole);
    final x = hole.left + hole.width * sweep;
    canvas.drawPath(
      Path()
        ..moveTo(x, hole.top)
        ..lineTo(x + c * 1.2, hole.top)
        ..lineTo(x - c * 0.4, hole.bottom)
        ..lineTo(x - c * 1.6, hole.bottom)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.3),
    );
    canvas.restore();
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 + _t * 0.5;
      final twinkle = math.sin(_t * 3 + i * 1.3).clamp(0.0, 1.0);
      _sparkle(
        canvas,
        hole.center + Offset(math.cos(a), math.sin(a)) * c * (_grid / 2 + 1),
        c * 0.22 * twinkle,
        _shine.withValues(alpha: twinkle),
      );
    }
  }

  /// A glossy plastic piece made of [cells], [s] wide each, centred on
  /// [at] and turned by [angle]. [snap] flashes it as it clicks in, [glow]
  /// rims it in white, and [finished] turns it platinum.
  void _paintPiece(
    Canvas canvas,
    List<(int, int)> cells,
    Color color,
    double s,
    Offset at,
    double angle, {
    double scale = 1,
    double snap = 0,
    double glow = 0,
    double finished = 0,
  }) {
    if (scale <= 0.01) {
      return;
    }
    final centre = _centroid(cells);
    var minX = 99;
    var minY = 99;
    var maxX = -99;
    var maxY = -99;
    for (final (x, y) in cells) {
      minX = math.min(minX, x);
      minY = math.min(minY, y);
      maxX = math.max(maxX, x);
      maxY = math.max(maxY, y);
    }
    final inset = s * 0.09;
    final shape = Path();
    for (final (x, y) in cells) {
      shape.addRect(
        Rect.fromLTWH(
          (x - centre.dx) * s + inset,
          (y - centre.dy) * s + inset,
          s - inset * 2,
          s - inset * 2,
        ),
      );
    }
    final bounds = Rect.fromLTRB(
      (minX - centre.dx) * s,
      (minY - centre.dy) * s,
      (maxX + 1 - centre.dx) * s,
      (maxY + 1 - centre.dy) * s,
    );
    const finish = _finish;
    final colors = [
      Color.lerp(Color.lerp(color, Colors.white, 0.35)!, finish[0], finished)!,
      Color.lerp(color, finish[1], finished)!,
      Color.lerp(Color.lerp(color, Colors.black, 0.3)!, finish[2], finished)!,
    ];
    // The fill and a round-joined stroke of the same paint knit the cells
    // into one smooth, rounded piece.
    Paint body(PaintingStyle style) => Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ).createShader(bounds)
      ..style = style
      ..strokeWidth = inset * 2.2
      ..strokeJoin = StrokeJoin.round;

    canvas.save();
    canvas.translate(at.dx, at.dy + s * 0.14 * scale);
    canvas.rotate(angle);
    canvas.scale(scale);
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = inset * 2.2
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawPath(shape, shadow);
    canvas.drawPath(shape, shadow..style = PaintingStyle.fill);
    canvas.restore();

    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(angle);
    canvas.scale(scale);
    if (glow > 0) {
      canvas.drawPath(
        shape,
        Paint()
          ..color = color.withValues(alpha: 0.6 * glow)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.5
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.3),
      );
      // A bright rim so the winner stands out against the platinum.
      canvas.drawPath(
        shape,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.95 * glow)
          ..style = PaintingStyle.stroke
          ..strokeWidth = inset * 2.2 + 5
          ..strokeJoin = StrokeJoin.round,
      );
    }
    if (snap > 0 && snap < 1) {
      // A white flash around the piece as it clicks in.
      canvas.drawPath(
        shape,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.8 * (1 - snap))
          ..style = PaintingStyle.stroke
          ..strokeWidth = inset * 2.2 + 6
          ..strokeJoin = StrokeJoin.round,
      );
    }
    canvas.drawPath(shape, body(PaintingStyle.stroke));
    canvas.drawPath(shape, body(PaintingStyle.fill));
    // A glossy glint on each cell.
    final glint = Paint()..color = Colors.white.withValues(alpha: 0.35);
    for (final (x, y) in cells) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            (x - centre.dx) * s + s * 0.16,
            (y - centre.dy) * s + s * 0.14,
            s * 0.34,
            s * 0.12,
          ),
          Radius.circular(s * 0.06),
        ),
        glint,
      );
    }
    canvas.restore();
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

  @override
  bool shouldRepaint(covariant PuzzlePainter oldDelegate) => true;
}
