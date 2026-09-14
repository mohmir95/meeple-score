import 'board_game.dart';
import '../games/great_western_trail/gwt_2e_game.dart';
import '../games/great_western_trail/gwt_argentina_game.dart';
import '../games/great_western_trail/gwt_game.dart';
import '../games/lost_ruins_of_arnak/arnak_game.dart';

/// Single registration point for available board games.
class GameRegistry {
  GameRegistry({List<BoardGame>? games})
    : games = List.unmodifiable(
        games ??
            const [
              GreatWesternTrailGame(),
              GreatWesternTrailSecondEditionGame(),
              GreatWesternTrailArgentinaGame(),
              LostRuinsOfArnakGame(),
            ],
      );

  final List<BoardGame> games;

  BoardGame lookup(String id) {
    return games.firstWhere(
      (game) => game.id == id,
      orElse: () => throw StateError('Unknown board game: $id'),
    );
  }

  BoardGame? tryLookup(String id) {
    for (final game in games) {
      if (game.id == id) {
        return game;
      }
    }
    return null;
  }
}
