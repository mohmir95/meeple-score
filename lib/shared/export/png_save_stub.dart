import 'dart:typed_data';

Future<void> savePng(Uint8List bytes, String filename) async {
  if (bytes.isEmpty || filename.isEmpty) {
    throw StateError('Missing score sheet image');
  }
}
