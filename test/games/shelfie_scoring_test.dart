import 'package:board_game_score_sheet/domain/models/game_status.dart';
import 'package:board_game_score_sheet/domain/models/player.dart';
import 'package:board_game_score_sheet/games/shelfie_stacker/shelfie_config.dart';
import 'package:board_game_score_sheet/games/shelfie_stacker/shelfie_player_line.dart';
import 'package:board_game_score_sheet/games/shelfie_stacker/shelfie_scoring.dart';
import 'package:board_game_score_sheet/games/shelfie_stacker/shelfie_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const blue = Player(id: 'blue', name: 'Blue', colorValue: 0xFF4A86C8);
  const green = Player(id: 'green', name: 'Green', colorValue: 0xFF2E8B4E);

  ShelfieState game(
    Map<String, ShelfiePlayerLine> lines, {
    String? lowestCardPlayerId,
  }) {
    return ShelfieState(
      players: const [blue, green],
      config: const ShelfieConfig(),
      status: GameStatus.inProgress,
      lines: lines,
      lowestCardPlayerId: lowestCardPlayerId,
    );
  }

  test('matches the rulebook scoring example', () {
    // 1 column 5 tall, 1 column 4 tall, 2 columns 3 tall, 28 pips,
    // 4 + 8 from reward cards, 4 dice in the Shelf of Shame.
    const line = ShelfiePlayerLine(
      fiveTall: 1,
      fourTall: 1,
      threeTall: 2,
      pips: 28,
      rewards: 12,
      shameDice: 4,
    );
    expect(ShelfieScoring.fiveTall(line), 6);
    expect(ShelfieScoring.fourTall(line), 3);
    expect(ShelfieScoring.threeTall(line), 2);
    expect(ShelfieScoring.shame(line), -8);
    expect(ShelfieScoring.totalFor(line), 43);
    expect(line.scoredColumns, 4);
  });

  test('an empty Shelf of Shame scores a plain 0', () {
    expect(ShelfieScoring.shameFor(0).toString(), '0');
    expect(ShelfieScoring.shameFor(3), -6);
  });

  test('highest total wins', () {
    final state = game({
      'blue': const ShelfiePlayerLine(pips: 20),
      'green': const ShelfiePlayerLine(pips: 18),
    });
    expect(ShelfieScoring.winners(state), [blue]);
  });

  test('a tie goes to the lowest Character Card, else it is shared', () {
    final lines = {
      'blue': const ShelfiePlayerLine(fiveTall: 1, pips: 10),
      'green': const ShelfiePlayerLine(pips: 18, shameDice: 1),
    };
    expect(ShelfieScoring.tiedByTotal(game(lines)), [blue, green]);
    expect(ShelfieScoring.winners(game(lines)), [blue, green]);
    expect(
      ShelfieScoring.winners(game(lines, lowestCardPlayerId: 'green')),
      [green],
    );
    expect(
      ShelfieScoring.winners(
        game(lines, lowestCardPlayerId: ShelfieState.sharedVictory),
      ),
      [blue, green],
    );
  });

  test('nobody leads before anything is scored', () {
    expect(ShelfieScoring.winners(game(const {})), isEmpty);
  });

  test('round-trips through JSON', () {
    final state = game({
      'blue': const ShelfiePlayerLine(fourTall: 2, rewards: 4, shameDice: 3),
    }, lowestCardPlayerId: 'blue');
    final restored = ShelfieState.fromJson(state.toJson());
    expect(restored.lineFor('blue').toJson(), state.lineFor('blue').toJson());
    expect(restored.lowestCardPlayerId, 'blue');
  });
}
