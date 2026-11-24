import 'package:board_game_score_sheet/domain/game_registry.dart';
import 'package:board_game_score_sheet/domain/game_series.dart';
import 'package:board_game_score_sheet/features/hub/game_hub_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import '../helpers/memory_session_repository.dart';

void main() {
  final centuryGames = [
    for (final game in GameRegistry().games)
      if (game.seriesId == GameSeries.century.id) game,
  ];

  test('all seven Century games are covered', () {
    expect(centuryGames, hasLength(7));
  });

  for (final game in centuryGames) {
    testWidgets('${game.id} hub reads Setup Hints, Starting Resources, How to '
        'Play, Scoring Hints', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpWithL10n(
        tester,
        GameHubScreen(game: game, repository: MemorySessionRepository()),
      );
      Offset at(String key) => tester.getTopLeft(find.byKey(ValueKey(key)));
      final order = [
        'hub-setup-hints',
        'hub-starting-resources',
        'hub-guide',
        'hub-scoring-hints',
      ].map(at).toList();
      for (var i = 1; i < order.length; i++) {
        // Reading order: a later row, or further along the same row.
        final before = order[i - 1], after = order[i];
        expect(
          after.dy > before.dy ||
              (after.dy == before.dy && after.dx > before.dx),
          isTrue,
          reason: 'tile $i is out of order',
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
}
