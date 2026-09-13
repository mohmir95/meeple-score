import 'package:board_game_score_sheet/domain/models/game_status.dart';
import 'package:board_game_score_sheet/domain/models/player.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_config.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_player_line.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_scoring.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ada = Player(id: 'ada', name: 'Ada', colorValue: 0xFFD62828);
  const sam = Player(id: 'sam', name: 'Sam', colorValue: 0xFF2A9D8F);

  GwtState game({
    GwtPlayerLine adaLine = const GwtPlayerLine(),
    GwtPlayerLine samLine = const GwtPlayerLine(),
  }) {
    return GwtState(
      players: const [ada, sam],
      config: const GwtConfig(),
      status: GameStatus.inProgress,
      lines: {'ada': adaLine, 'sam': samLine},
    );
  }

  test('converts dollars to VP at 5:1 and ignores leftover coins', () {
    expect(GwtScoring.coinPoints(23), 4);
    expect(GwtScoring.coinPoints(4), 0);
    expect(GwtScoring.coinPoints(0), 0);
  });

  test('sums every pad row including token and 3-VP disc', () {
    const line = GwtPlayerLine(
      dollars: 23,
      buildings: 10,
      deliveries: -6,
      stations: 5,
      hazards: 3,
      cattle: 8,
      objectives: -2,
      stationMasters: 4,
      playerBoard: 8,
      clearedThreeVpSpace: true,
      hasJobMarketToken: true,
    );

    expect(
      GwtScoring.totalFor(line),
      4 + 10 - 6 + 5 + 3 + 8 - 2 + 4 + 8 + 3 + 2,
    );
  });

  test('only one player can hold the job market token', () {
    final current = game(adaLine: const GwtPlayerLine(hasJobMarketToken: true));
    final next = current.updateLine(
      'sam',
      const GwtPlayerLine(hasJobMarketToken: true),
    );

    expect(next.lineFor('sam').hasJobMarketToken, isTrue);
    expect(next.lineFor('ada').hasJobMarketToken, isFalse);
    expect(GwtScoring.winners(next), [sam]);
  });

  test('round-trips state through JSON', () {
    final original = game(
      adaLine: const GwtPlayerLine(dollars: 15, deliveries: -6),
    );
    final restored = GwtState.fromJson(original.toJson());
    expect(restored.lineFor('ada').dollars, 15);
    expect(restored.lineFor('ada').deliveries, -6);
    expect(GwtScoring.totalFor(restored.lineFor('ada')), 3 - 6);
  });
}
