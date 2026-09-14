import 'dart:typed_data';

import 'png_save_impl.dart' as impl;

typedef PngSaveHook = Future<void> Function(Uint8List bytes, String filename);

PngSaveHook? pngSaveOverride;

Future<void> savePng(Uint8List bytes, String filename) {
  return (pngSaveOverride ?? impl.savePng)(bytes, filename);
}

String scoreSheetPngName({required String gameId, required DateTime now}) {
  final year = now.year.toString().padLeft(4, '0');
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return 'meeple-score-$gameId-$year-$month-$day.png';
}
