// Renders the covers of the Century combination games from the standalone
// covers: each game in its own diagonal band, split by wavy white shorelines,
// the first game in the title bottom-left, under the game's box logo.
//
// Run from the project root (outside test/ so CI never runs it):
//   flutter test tool/century_covers_test.dart
//
// To add a cover, add a _Cover to _covers and its path to pubspec.yaml.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _sr = 'assets/games/century_spice_road/cover.webp';
const _ew = 'assets/games/century_eastern_wonders/cover.webp';
const _anw = 'assets/games/century_a_new_world/cover.webp';

/// The art of one standalone cover: [top] and [bottom] bound the part below
/// the printed title and above the publisher logo, as fractions of the
/// height. The square crop is centred sideways.
class _Art {
  const _Art(this.path, {required this.top, this.bottom = 1});

  final String path;
  final double top;
  final double bottom;
}

/// A box logo cut from a photo of the box. The logo is cream on a darker
/// background, so a pixel's darkest channel says how much logo it holds:
/// [low] and below is background, [high] and above is logo. [bottom] crops
/// off anything under the logo, as a fraction of the height.
class _Logo {
  const _Logo(
    this.path, {
    required this.low,
    required this.high,
    this.bottom = 1,
    this.width = 500,
    this.clear = const [],
  });

  final String path;
  final int low;
  final int high;
  final double bottom;

  /// On the 600px cover.
  final double width;

  /// Background-only areas, as fractions of the uncropped image, where
  /// bright art would otherwise show through.
  final List<Rect> clear;
}

class _Cover {
  const _Cover(this.out, this.logo, this.arts);

  final String out;
  final _Logo logo;

  /// Bottom-left band first.
  final List<_Art> arts;
}

// Spice Road's art, and the others' art clear of their logos.
const _srArt = _Art(_sr, top: 0.44);
const _ewArt = _Art(_ew, top: 0.42, bottom: 0.88);
const _anwArt = _Art(_anw, top: 0.42, bottom: 0.88);

const _logos = 'tool/century_logos';

const _covers = [
  _Cover(
    'assets/games/century_from_sand_to_sea/cover.png',
    // Without the "A Mid-Century Adventure" line.
    _Logo(
      '$_logos/sand_to_sea.png',
      low: 115,
      high: 175,
      bottom: 0.81,
      width: 540,
      clear: [
        Rect.fromLTRB(0.6, 0, 1, 0.33),
        Rect.fromLTRB(0.985, 0.33, 1, 1),
        Rect.fromLTRB(0.93, 0.64, 1, 1),
      ],
    ),
    [_srArt, _ewArt],
  ),
  _Cover(
    'assets/games/century_from_east_to_west/cover.png',
    _Logo('$_logos/east_to_west_1.png', low: 95, high: 175),
    [_srArt, _anwArt],
  ),
  _Cover(
    'assets/games/century_from_east_to_west_ew/cover.png',
    _Logo('$_logos/east_to_west_2.png', low: 95, high: 175),
    [_ewArt, _anwArt],
  ),
  _Cover(
    'assets/games/century_from_east_to_west_all/cover.png',
    _Logo('$_logos/east_to_west_3.png', low: 95, high: 175),
    [_srArt, _ewArt, _anwArt],
  ),
];

/// The radius of the gaps [_cutOut] fills inside the logo.
const _fill = 2;

/// [logo] with its background made transparent and cropped to its bottom.
Future<ui.Image> _cutOut(_Logo logo) async {
  final img = await _load(logo.path);
  final data = (await img.toByteData())!.buffer.asUint8List();
  final w = img.width, h = (img.height * logo.bottom).round();
  double soft(int i) {
    final r = data[i * 4], g = data[i * 4 + 1], b = data[i * 4 + 2];
    final darkest = math.min(r, math.min(g, b));
    return ((darkest - logo.low) / (logo.high - logo.low)).clamp(0.0, 1.0);
  }

  // The letters have thin dark lines inside their edges: fill any gap of
  // up to 2 * _fill pixels inside the logo (a morphological closing), so
  // those lines keep their colour instead of turning see-through.
  final bright = List.generate(w * h, (i) => soft(i) > 0.5);
  List<bool> grow(List<bool> mask, bool value) => List.generate(w * h, (i) {
    final x = i % w, y = i ~/ w;
    for (var dy = -_fill; dy <= _fill; dy++) {
      for (var dx = -_fill; dx <= _fill; dx++) {
        final nx = x + dx, ny = y + dy;
        if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
        if (dx * dx + dy * dy > _fill * _fill) continue;
        if (mask[ny * w + nx] == value) return value;
      }
    }
    return !value;
  });
  final inside = grow(grow(bright, true), false);

  final out = Uint8List(w * h * 4);
  for (var i = 0; i < w * h; i++) {
    var r = data[i * 4], g = data[i * 4 + 1], b = data[i * 4 + 2];
    final x = (i % w) / img.width, y = (i ~/ w) / img.height;
    final a = logo.clear.any((r) => r.contains(Offset(x, y)))
        ? 0.0
        : inside[i]
        ? 1.0
        : soft(i);
    // Filled lines show the background through them: make them a neutral
    // dark so the green or purple doesn't come along.
    if (inside[i] && !bright[i]) {
      r = g = b = ((r + g + b) / 3 * 0.75).round();
    }
    out
      ..[i * 4] = r
      ..[i * 4 + 1] = g
      ..[i * 4 + 2] = b
      ..[i * 4 + 3] = (a * 255).round();
  }
  final buffer = await ui.ImmutableBuffer.fromUint8List(out);
  final descriptor = ui.ImageDescriptor.raw(
    buffer,
    width: w,
    height: h,
    pixelFormat: ui.PixelFormat.rgba8888,
  );
  final codec = await descriptor.instantiateCodec();
  return (await codec.getNextFrame()).image;
}

const _size = 600.0;

Future<ui.Image> _load(String path) async {
  final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
  return (await codec.getNextFrame()).image;
}

/// A wavy line parallel to the top-left to bottom-right diagonal, moved
/// [offset] towards the top-right corner. It runs past the canvas edges.
List<Offset> _shore(double offset) {
  const s = _size;
  final normal = const Offset(1, -1) / math.sqrt2;
  const n = 360;
  return [
    for (var i = 0; i <= n; i++)
      () {
        final t = -0.25 + 1.5 * i / n;
        final inside = t.clamp(0.0, 1.0);
        final fade = math.sin(inside * math.pi); // flat at the corners
        final wave = math.sin(t * math.pi * 2 * 3.5) * 13 * fade;
        return Offset(t * s, t * s) + normal * (offset + wave);
      }(),
  ];
}

Future<void> _render(_Cover cover) async {
  const s = _size;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, s, s));
  final hq = Paint()..filterQuality = FilterQuality.high;
  const full = Rect.fromLTWH(0, 0, s, s);

  Future<void> drawArt(_Art art) async {
    final img = await _load(art.path);
    final h = img.height * (art.bottom - art.top);
    final side = math.min(h, img.width.toDouble());
    final left = (img.width - side) / 2;
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(left, img.height * art.top, side, side),
      full,
      hq,
    );
  }

  // Shorelines between the bands, spaced so each band covers about the
  // same area.
  final count = cover.arts.length;
  final shores = [
    for (var k = 1; k < count; k++) _shore((k - count / 2) * s * 0.34),
  ];

  await drawArt(cover.arts.first);
  for (var k = 1; k < count; k++) {
    // Everything on the top-right side of shoreline k.
    final area = Path()
      ..addPolygon(shores[k - 1], false)
      ..lineTo(s * 2, -s)
      ..close();
    canvas.save();
    canvas.clipPath(area);
    await drawArt(cover.arts[k]);
    canvas.restore();
  }

  // Wet edge, then surf along each shoreline.
  for (final points in shores) {
    final line = Path()..addPolygon(points, false);
    canvas.drawPath(
      line.shift(const Offset(-5, 5)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..color = const Color(0x55402410)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..color = const Color(0xAAFFFFFF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xE6FFFFFF),
    );
  }

  // Title band.
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, s, s * 0.36),
    Paint()
      ..shader = ui.Gradient.linear(Offset.zero, const Offset(0, s * 0.36), [
        const Color(0x99000000),
        const Color(0x00000000),
      ]),
  );
  // The logo, centred at the top over a soft dark shadow.
  final logo = await _cutOut(cover.logo);
  final w = cover.logo.width, h = w * logo.height / logo.width;
  final src = Rect.fromLTWH(
    0,
    0,
    logo.width.toDouble(),
    logo.height.toDouble(),
  );
  final dst = Rect.fromLTWH((s - w) / 2, 12, w, h);
  canvas.drawImageRect(
    logo,
    src,
    dst.shift(const Offset(0, 3)),
    Paint()
      ..filterQuality = FilterQuality.high
      ..colorFilter = const ColorFilter.mode(Color(0xDD000000), BlendMode.srcIn)
      ..imageFilter = ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
  );
  canvas.drawImageRect(logo, src, dst, hq);

  final image = await recorder.endRecording().toImage(s.toInt(), s.toInt());
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(cover.out);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  testWidgets('render Century combination covers', (tester) async {
    await tester.runAsync(() async {
      for (final cover in _covers) {
        await _render(cover);
      }
    });
  });
}
