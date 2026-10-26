import 'package:board_game_score_sheet/domain/game_registry.dart';
import 'package:board_game_score_sheet/shared/player_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

void main() {
  for (final game in GameRegistry().games.where((game) => game.hasScoresheet)) {
    for (final width in [360.0, 390.0, 1200.0]) {
      testWidgets('${game.id} pad fits ${width.toInt()}px with any player count', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        for (var count = game.minPlayers; count <= game.maxPlayers; count++) {
          final state = game.createInitialState(
            players: defaultPlayers(count: count, palette: game.playerColors),
            config: game.createDefaultConfig(),
          );
          await pumpWithL10n(
            tester,
            Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: game.buildScoreSheet(
                  state: state,
                  onChanged: (_) {},
                  readOnly: false,
                ),
              ),
            ),
          );

          final sideways = tester
              .stateList<ScrollableState>(find.byType(Scrollable))
              .where((s) => s.position.axis == Axis.horizontal);
          expect(sideways, isNotEmpty);
          for (final scrollable in sideways) {
            expect(
              scrollable.position.maxScrollExtent,
              0,
              reason: '$count players',
            );
          }
        }
      });
    }
  }
}
