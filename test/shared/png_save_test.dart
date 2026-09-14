import 'package:board_game_score_sheet/shared/export/png_save.dart';
import 'package:board_game_score_sheet/shared/export/widget_png.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds a dated PNG file name from the game id', () {
    expect(
      scoreSheetPngName(
        gameId: 'lost_ruins_of_arnak',
        now: DateTime.utc(2026, 9, 14),
      ),
      'meeple-score-lost_ruins_of_arnak-2026-09-14.png',
    );
  });

  testWidgets('encodes a widget as a PNG', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: key,
          child: const SizedBox(
            width: 24,
            height: 24,
            child: ColoredBox(color: Color(0xFF3498DB)),
          ),
        ),
      ),
    );

    final bytes = await tester.runAsync(
      () => capturePngFromKey(key, pixelRatio: 1),
    );

    expect(bytes, isNotNull);
    expect(bytes!.length, greaterThan(50));
    expect(bytes.sublist(0, 8), <int>[137, 80, 78, 71, 13, 10, 26, 10]);
  });
}
