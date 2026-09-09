import 'package:board_game_score_sheet/shared/ids.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('newId returns a non-empty unique-looking value', () {
    final first = newId();
    final second = newId();
    expect(first, isNotEmpty);
    expect(second, isNotEmpty);
    expect(first, isNot(second));
  });
}
