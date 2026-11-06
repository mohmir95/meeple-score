import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import 'turing_notes.dart';

/// Writes a note sheet onto the printed Turing Machine sheet, like pen on
/// paper, and returns it as a PNG.
class TuringSheetImage {
  static const asset = 'assets/games/turing_machine/note_sheet.jpg';

  /// Size of [asset]. Every position below is in these pixels.
  static const width = 1102.0;
  static const height = 1302.0;

  /// Output is upscaled so the handwriting stays sharp.
  static const scale = 2.0;

  static const _pen = Color(0xFF1F2A5A);
  static const _green = Color(0xFF2E9E4F);
  static const _red = Color(0xFFD64545);
  static const _handicap = Color(0xFF5E6E64);
  static const _shapes = [
    Color(0xFF3E9FD0),
    Color(0xFFE5A50A),
    Color(0xFF7D55A8),
  ];

  // Proposal grid (triangle, square, circle) and verifier boxes A–F.
  static const _codeX = [156.0, 220.0, 285.0];
  static const _verifierX = [382.0, 446.0, 510.0, 575.0, 639.0, 704.0];
  static const _firstRowY = 158.0;
  static const _rowStep = 52.25;
  static const _box = 34.0;
  static const _gridTop = 135.0;
  static const _gridBottom = 598.0;

  // Digit elimination panel: columns per shape, 5 at the top.
  static const _digitX = [831.0, 900.0, 968.0];
  static const _digitTopY = 288.0;
  static const _digitStep = 67.0;

  // Notes per verifier: left/right column, three rows (A/B, C/D, E/F).
  static const _notesLeft = [135.0, 640.0];
  static const _notesRight = [555.0, 1040.0];
  static const _criterionLeft = [208.0, 692.0];
  static const _criterionRight = [545.0, 1028.0];
  static const _labelY = [657.0, 865.0, 1071.0];
  static const _criterionY = [800.0, 1005.0, 1210.0];

  static Future<Uint8List> render(TuringNotes notes) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    final sheet = frame.image;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(scale);
    canvas.drawImageRect(
      sheet,
      Rect.fromLTWH(0, 0, sheet.width.toDouble(), sheet.height.toDouble()),
      const Rect.fromLTWH(0, 0, width, height),
      Paint()..filterQuality = FilterQuality.high,
    );
    sheet.dispose();
    paint(canvas, notes);
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      (width * scale).round(),
      (height * scale).round(),
    );
    picture.dispose();
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        throw StateError('Could not encode PNG');
      }
      return bytes.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  /// Draws everything written on [notes]; the sheet itself is drawn first.
  static void paint(Canvas canvas, TuringNotes notes) {
    _fitText(canvas, notes.player, const Rect.fromLTRB(830, 44, 1012, 90));
    _fitText(canvas, notes.problem, const Rect.fromLTRB(830, 100, 1012, 146));

    for (var r = 0; r < TuringNotes.rounds; r++) {
      final y = _firstRowY + _rowStep * r;
      for (var s = 0; s < TuringNotes.shapes; s++) {
        final digit = notes.codes[r][s];
        if (digit != null) {
          _centered(canvas, '$digit', Offset(_codeX[s], y), 30, _pen);
        }
      }
      for (var v = 0; v < notes.verifierCount; v++) {
        _mark(canvas, notes.results[r][v], Offset(_verifierX[v], y));
      }
    }

    // Unused verifiers get a line drawn through their column.
    final strike = Paint()
      ..color = _pen
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (var v = notes.verifierCount; v < TuringNotes.verifiers; v++) {
      canvas.drawLine(
        Offset(_verifierX[v], _gridTop),
        Offset(_verifierX[v], _gridBottom),
        strike,
      );
    }

    for (var s = 0; s < TuringNotes.shapes; s++) {
      for (var d = 1; d <= TuringNotes.digitCount; d++) {
        final center = Offset(
          _digitX[s],
          _digitTopY + _digitStep * (TuringNotes.digitCount - d),
        );
        switch (notes.digits[s][d - 1]) {
          case DigitMark.none:
            break;
          case DigitMark.crossed:
            _cross(canvas, center, 20, _red, 5);
          case DigitMark.circled:
            canvas.drawCircle(
              center,
              27,
              Paint()
                ..color = _pen
                ..style = PaintingStyle.stroke
                ..strokeWidth = 4,
            );
        }
      }
    }

    for (var v = 0; v < notes.verifierCount; v++) {
      final column = v % 2;
      final row = v ~/ 2;
      _fitText(
        canvas,
        notes.notes[v],
        Rect.fromLTRB(
          _notesLeft[column],
          _labelY[row] - 18,
          _notesRight[column],
          _criterionY[row] - 26,
        ),
        maxSize: 22,
        middle: false,
      );
      _fitText(
        canvas,
        notes.criteria[v],
        Rect.fromLTRB(
          _criterionLeft[column],
          _criterionY[row] - 17,
          _criterionRight[column],
          _criterionY[row] + 17,
        ),
        maxSize: 22,
      );
    }

    // The final code goes in the empty corner above the proposal grid.
    if (notes.finalCode.any((digit) => digit != null)) {
      for (var s = 0; s < TuringNotes.shapes; s++) {
        final digit = notes.finalCode[s];
        final center = Offset(_codeX[s], 34);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: 46, height: 46),
            const Radius.circular(10),
          ),
          Paint()
            ..color = _shapes[s]
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
        if (digit != null) {
          _centered(canvas, '$digit', center, 30, _shapes[s]);
        }
      }
    }
  }

  static void _mark(Canvas canvas, VerifierMark mark, Offset center) {
    final rect = Rect.fromCenter(center: center, width: _box, height: _box);
    switch (mark) {
      case VerifierMark.none:
        break;
      case VerifierMark.pass:
        final path = Path()
          ..moveTo(rect.left + 7, center.dy + 1)
          ..lineTo(center.dx - 3, rect.bottom - 8)
          ..lineTo(rect.right - 5, rect.top + 6);
        canvas.drawPath(
          path,
          Paint()
            ..color = _green
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      case VerifierMark.fail:
        _cross(canvas, center, 11, _red, 5);
      case VerifierMark.handicap:
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(3), const Radius.circular(6)),
          Paint()..color = _handicap,
        );
    }
  }

  static void _cross(
    Canvas canvas,
    Offset center,
    double half,
    Color color,
    double stroke,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center + Offset(-half, -half),
      center + Offset(half, half),
      paint,
    );
    canvas.drawLine(
      center + Offset(half, -half),
      center + Offset(-half, half),
      paint,
    );
  }

  static void _centered(
    Canvas canvas,
    String text,
    Offset center,
    double size,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
    painter.dispose();
  }

  /// Persian notes read right to left.
  static TextDirection _directionOf(String text) {
    final rtl = RegExp('[֐-ࣿיִ-﷿ﹰ-﻿]');
    final latin = RegExp('[A-Za-z]');
    final firstRtl = text.indexOf(rtl);
    final firstLatin = text.indexOf(latin);
    if (firstRtl < 0) {
      return TextDirection.ltr;
    }
    return firstLatin < 0 || firstRtl < firstLatin
        ? TextDirection.rtl
        : TextDirection.ltr;
  }

  /// Writes [text] inside [box], shrinking the font until it fits.
  static void _fitText(
    Canvas canvas,
    String text,
    Rect box, {
    double maxSize = 26,
    double minSize = 12,
    bool middle = true,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final direction = _directionOf(trimmed);
    TextPainter? painter;
    for (var size = maxSize; size >= minSize; size -= 1) {
      painter?.dispose();
      painter = TextPainter(
        text: TextSpan(
          text: trimmed,
          style: TextStyle(
            color: _pen,
            fontSize: size,
            fontWeight: FontWeight.w600,
            height: 1.15,
          ),
        ),
        textDirection: direction,
        textAlign: TextAlign.start,
        ellipsis: '…',
        maxLines: (box.height / (size * 1.15)).floor().clamp(1, 20),
      )..layout(minWidth: box.width, maxWidth: box.width);
      if (!painter.didExceedMaxLines && painter.height <= box.height) {
        break;
      }
    }
    final fitted = painter!;
    final top = middle && box.height > fitted.height
        ? box.top + (box.height - fitted.height) / 2
        : box.top;
    fitted.paint(canvas, Offset(box.left, top));
    fitted.dispose();
  }
}
