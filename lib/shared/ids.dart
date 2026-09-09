import 'dart:math';

String newId() {
  final random = Random();
  final stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
  // Flutter web compiles to JS, where `1 << 32` is 0 and Random.nextInt(0) throws.
  final salt = random.nextInt(0x7fffffff).toRadixString(16);
  return '$stamp$salt';
}
