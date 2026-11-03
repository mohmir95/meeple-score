import 'package:board_game_score_sheet/domain/models/game_status.dart';
import 'package:board_game_score_sheet/domain/models/player.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_config.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_el_paso_game.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_player_line.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_scoring.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const game = GreatWesternTrailElPasoGame();
  const ann = Player(id: 'a', name: 'Ann', colorValue: 0xFFC62828);
  const ben = Player(id: 'b', name: 'Ben', colorValue: 0xFF1565C0);

  GwtState stateOf(GwtPlayerLine a, GwtPlayerLine b) => GwtState(
    players: const [ann, ben],
    config: const GwtConfig(),
    status: GameStatus.inProgress,
    lines: {'a': a, 'b': b},
  );

  test('adds the 7 categories of the pad', () {
    const line = GwtPlayerLine(
      dollars: 13,
      buildings: 19,
      tradingPosts: 13,
      workers: 9,
      cattle: 20,
      bonusTiles: 6,
      objectives: 8,
      // Scored by other editions only.
      stations: 50,
      deliveries: 50,
      hazards: 50,
      playerBoard: 50,
      clearedThreeVpSpace: true,
    );
    expect(GwtScoring.totalFor(line, pad: GwtPadKind.elPaso), 2 + 75);
  });

  test('triggering the game end scores 2 VP for one player only', () {
    var state = stateOf(const GwtPlayerLine(), const GwtPlayerLine());
    state = state.updateLine('a', const GwtPlayerLine(hasJobMarketToken: true));
    expect(game.scores(state).first.total, 2);

    state = state.updateLine('b', const GwtPlayerLine(hasJobMarketToken: true));
    expect(game.scores(state).map((score) => score.total), [0, 2]);
  });

  test('new categories survive a save', () {
    const line = GwtPlayerLine(workers: 4, bonusTiles: 7);
    final restored = GwtPlayerLine.fromJson(line.toJson());
    expect(restored.workers, 4);
    expect(restored.bonusTiles, 7);
  });

  test('a tie goes to the most money left after converting', () {
    final state = stateOf(
      const GwtPlayerLine(dollars: 12, buildings: 5),
      const GwtPlayerLine(dollars: 14, buildings: 5),
    );
    expect(game.winners(state), [ben]);
    final scores = game.scores(state);
    expect(scores.first.isLeader, isFalse);
    expect(scores.last.isLeader, isTrue);
  });

  test('a tie on money too is shared', () {
    final state = stateOf(
      const GwtPlayerLine(dollars: 12, buildings: 5),
      const GwtPlayerLine(dollars: 7, buildings: 6),
    );
    expect(game.winners(state), [ann, ben]);
  });

  test('other editions keep shared wins on a tie', () {
    final state = stateOf(
      const GwtPlayerLine(dollars: 12, buildings: 5),
      const GwtPlayerLine(dollars: 14, buildings: 5),
    );
    expect(GwtScoring.winners(state), [ann, ben]);
  });

  test('the hub offers the scoresheet and starting resources', () {
    expect(game.showBuildingsRandomizer, isFalse);
    expect(game.showStartingResources, isTrue);
    expect(game.hasScoresheet, isTrue);
  });
}
