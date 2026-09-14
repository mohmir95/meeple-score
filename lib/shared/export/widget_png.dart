import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

typedef CapturePngHook =
    Future<Uint8List> Function(GlobalKey key, {double pixelRatio});

CapturePngHook? capturePngOverride;

Future<Uint8List> capturePng(
  GlobalKey key, {
  double pixelRatio = 2,
}) {
  final override = capturePngOverride;
  if (override != null) {
    return override(key, pixelRatio: pixelRatio);
  }
  return capturePngFromKey(key, pixelRatio: pixelRatio);
}

Future<Uint8List> capturePngFromKey(
  GlobalKey key, {
  double pixelRatio = 2,
}) async {
  final context = key.currentContext;
  final boundary = context?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) {
    throw StateError('Missing score sheet');
  }
  if (boundary.size.isEmpty) {
    throw StateError('Score sheet has no size');
  }
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      throw StateError('Could not encode PNG');
    }
    return data.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
