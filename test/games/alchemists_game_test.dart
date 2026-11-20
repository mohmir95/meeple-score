import 'package:board_game_score_sheet/domain/game_registry.dart';
import 'package:board_game_score_sheet/features/hub/game_hub_screen.dart';
import 'package:board_game_score_sheet/games/alchemists/alchemists_game.dart';
import 'package:board_game_score_sheet/shared/links/open_url.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import '../helpers/memory_session_repository.dart';

void main() {
  test('Alchemists is registered with the logic puzzle tutorial', () {
    const game = AlchemistsGame();
    expect(
      GameRegistry().lookup(AlchemistsGame.idValue),
      isA<AlchemistsGame>(),
    );
    expect(game.hasScoresheet, isFalse);
    expect(game.showQuickReference, isTrue);
    expect(game.quickReferenceTitleKey, 'hub.logicPuzzle');
    expect(game.onlineUrl, 'https://alchemists.czechgames.com/');
    expect(game.onlineTitleKey, 'hub.cardReaderApp');
    expect(game.buildSetupHints(), isNull);
    expect(game.buildStartingResources(), isNotNull);
    expect(game.minPlayers, 2);
    expect(game.maxPlayers, 4);
  });

  testWidgets('the hub opens the tutorial and links the card reader app', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await pumpWithL10n(
      tester,
      GameHubScreen(
        game: const AlchemistsGame(),
        repository: MemorySessionRepository(),
      ),
    );
    expect(find.text('Scoresheet'), findsNothing);
    expect(find.text('Logic Puzzle Explained'), findsOneWidget);
    expect(find.text('Card Reader App'), findsOneWidget);

    String? opened;
    openUrlOverride = (url) => opened = url;
    addTearDown(() => openUrlOverride = null);
    await tester.tap(find.byKey(const ValueKey('hub-online')));
    expect(opened, 'https://alchemists.czechgames.com/');
  });
}
