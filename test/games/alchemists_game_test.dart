import 'package:board_game_score_sheet/domain/game_registry.dart';
import 'package:board_game_score_sheet/games/alchemists/alchemists_game.dart';
import 'package:flutter_test/flutter_test.dart';

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
    expect(game.buildSetupHints(), isNull);
    expect(game.buildStartingResources(), isNull);
    expect(game.minPlayers, 2);
    expect(game.maxPlayers, 4);
  });
}
