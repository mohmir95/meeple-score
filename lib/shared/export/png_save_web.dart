import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

Future<void> savePng(Uint8List bytes, String filename) async {
  if (bytes.isEmpty || filename.isEmpty) {
    throw StateError('Missing score sheet image');
  }
  final blob = Blob(
    [bytes.toJS].toJS,
    BlobPropertyBag(type: 'image/png'),
  );
  final url = URL.createObjectURL(blob);
  final anchor = HTMLAnchorElement()
    ..href = url
    ..download = filename;
  document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();
  URL.revokeObjectURL(url);
}
