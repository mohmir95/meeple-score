import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'first_player_screen.dart';

/// A small picture of a scenery for the scenery switcher: a magician's hat,
/// a bubbling cauldron, a bomb, a UFO and a boxing glove.
///
/// Drawn as a one-color silhouette; the details are cut out, so whatever is
/// behind the icon shows through them.
class SceneryIcon extends StatelessWidget {
  const SceneryIcon(
    this.theme, {
    super.key,
    this.size = 24,
    this.color = Colors.white,
  });

  final FirstPlayerTheme theme;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _SceneryIconPainter(theme, color)),
    );
  }
}

class _SceneryIconPainter extends CustomPainter {
  const _SceneryIconPainter(this.theme, this.color);

  final FirstPlayerTheme theme;
  final Color color;

  Paint get _fill => Paint()..color = color;

  /// Erases what's under it, for the cut-out details.
  static final _cut = Paint()
    ..blendMode = BlendMode.clear
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.055
    ..strokeCap = StrokeCap.round;

  static final _hole = Paint()..blendMode = BlendMode.clear;

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn in a 1 × 1 box, on its own layer so the cut-outs only erase
    // the icon.
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.scale(size.width, size.height);
    switch (theme) {
      case FirstPlayerTheme.magic:
        _hat(canvas);
      case FirstPlayerTheme.cauldron:
        _cauldron(canvas);
      case FirstPlayerTheme.bomb:
        _bomb(canvas);
      case FirstPlayerTheme.ufo:
        _ufo(canvas);
      case FirstPlayerTheme.arena:
        _glove(canvas);
    }
    canvas.restore();
  }

  void _hat(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromLTRBR(0.26, 0.24, 0.7, 0.76, const Radius.circular(0.04)),
      _fill,
    );
    canvas.drawOval(const Rect.fromLTRB(0.06, 0.7, 0.9, 0.86), _fill);
    // The band, and the line where the brim meets the crown.
    canvas.drawLine(const Offset(0.26, 0.58), const Offset(0.7, 0.58), _cut);
    canvas.drawLine(const Offset(0.3, 0.71), const Offset(0.66, 0.71), _cut);
    _sparkle(canvas, const Offset(0.83, 0.2), 0.14);
    _sparkle(canvas, const Offset(0.12, 0.36), 0.08);
  }

  void _bomb(Canvas canvas) {
    canvas.drawCircle(const Offset(0.44, 0.6), 0.3, _fill);
    canvas.drawRect(const Rect.fromLTRB(0.5, 0.24, 0.66, 0.38), _fill);
    canvas.drawPath(
      Path()
        ..moveTo(0.6, 0.25)
        ..quadraticBezierTo(0.65, 0.1, 0.77, 0.16),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.06
        ..strokeCap = StrokeCap.round,
    );
    // A shine on the bomb.
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(0.44, 0.6), radius: 0.19),
      math.pi * 1.05,
      math.pi * 0.4,
      false,
      _cut,
    );
    _sparkle(canvas, const Offset(0.84, 0.14), 0.13);
  }

  void _cauldron(Canvas canvas) {
    // The pot, its rim and two little feet.
    canvas.drawPath(
      Path()
        ..moveTo(0.14, 0.44)
        ..cubicTo(0.04, 0.7, 0.24, 0.88, 0.5, 0.88)
        ..cubicTo(0.76, 0.88, 0.96, 0.7, 0.86, 0.44)
        ..close(),
      _fill,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(0.08, 0.38, 0.92, 0.5, const Radius.circular(0.06)),
      _fill,
    );
    for (final x in const [0.3, 0.7]) {
      canvas.drawRect(Rect.fromLTRB(x - 0.05, 0.84, x + 0.05, 0.94), _fill);
    }
    canvas.drawLine(const Offset(0.14, 0.53), const Offset(0.86, 0.53), _cut);
    // Bubbles rising out of it.
    canvas.drawCircle(const Offset(0.38, 0.26), 0.07, _fill);
    canvas.drawCircle(const Offset(0.6, 0.16), 0.09, _fill);
    canvas.drawCircle(const Offset(0.66, 0.31), 0.045, _fill);
  }

  void _ufo(Canvas canvas) {
    // The dome, the saucer, and the beam below.
    canvas.drawArc(
      const Rect.fromLTRB(0.3, 0.14, 0.7, 0.54),
      math.pi,
      math.pi,
      true,
      _fill,
    );
    canvas.drawOval(const Rect.fromLTRB(0.04, 0.3, 0.96, 0.54), _fill);
    for (final x in const [0.24, 0.5, 0.76]) {
      canvas.drawCircle(Offset(x, 0.43), 0.035, _hole);
    }
    canvas.drawPath(
      Path()
        ..moveTo(0.4, 0.6)
        ..lineTo(0.6, 0.6)
        ..lineTo(0.74, 0.92)
        ..lineTo(0.26, 0.92)
        ..close(),
      Paint()..color = color.withValues(alpha: 0.55),
    );
  }

  void _glove(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromLTRBR(0.3, 0.1, 0.88, 0.68, const Radius.circular(0.26)),
      _fill,
    );
    // The thumb bulges out the side, with a seam where it meets the fist.
    canvas.drawOval(const Rect.fromLTRB(0.1, 0.3, 0.48, 0.64), _fill);
    canvas.drawPath(
      Path()
        ..moveTo(0.34, 0.31)
        ..quadraticBezierTo(0.52, 0.36, 0.5, 0.58),
      _cut,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(0.32, 0.7, 0.8, 0.88, const Radius.circular(0.04)),
      _fill,
    );
  }

  /// A four-pointed sparkle.
  void _sparkle(Canvas canvas, Offset at, double r) {
    final path = Path()..moveTo(at.dx, at.dy - r);
    for (var i = 1; i <= 8; i++) {
      final a = -math.pi / 2 + i * math.pi / 4;
      final d = i.isEven ? r : r * 0.32;
      path.lineTo(at.dx + math.cos(a) * d, at.dy + math.sin(a) * d);
    }
    path.close();
    canvas.drawPath(path, _fill);
  }

  @override
  bool shouldRepaint(covariant _SceneryIconPainter oldDelegate) =>
      oldDelegate.theme != theme || oldDelegate.color != color;
}
