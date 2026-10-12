import 'package:board_game_score_sheet/domain/models/game_status.dart';
import 'package:board_game_score_sheet/domain/models/player.dart';
import 'package:board_game_score_sheet/games/castles_of_burgundy/cob_config.dart';
import 'package:board_game_score_sheet/games/castles_of_burgundy/cob_player_line.dart';
import 'package:board_game_score_sheet/games/castles_of_burgundy/cob_scoring.dart';
import 'package:board_game_score_sheet/games/castles_of_burgundy/cob_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ada = Player(id: 'ada', name: 'Ada', colorValue: 0xFFF9A825);
  const sam = Player(id: 'sam', name: 'Sam', colorValue: 0xFF1565C0);

  CobState game({
    CobPlayerLine adaLine = const CobPlayerLine(),
    CobPlayerLine samLine = const CobPlayerLine(),
  }) {
    return CobState(
      players: const [ada, sam],
      config: const CobConfig(),
      status: GameStatus.inProgress,
      lines: {'ada': adaLine, 'sam': samLine},
    );
  }

  test('highest score track total wins', () {
    final state = game(
      adaLine: const CobPlayerLine(victoryPoints: 142),
      samLine: const CobPlayerLine(victoryPoints: 128),
    );

    expect(CobScoring.totalFor(state.lineFor('ada')), 142);
    expect(CobScoring.winners(state), [ada]);
    expect(CobScoring.scores(state).first.isLeader, isTrue);
  });

  test('tied totals share the win', () {
    final state = game(
      adaLine: const CobPlayerLine(victoryPoints: 100),
      samLine: const CobPlayerLine(victoryPoints: 100),
    );

    expect(CobScoring.winners(state), [ada, sam]);
  });

  test('an empty score track has no winner yet', () {
    expect(CobScoring.winners(game()), isEmpty);
  });

  test('negative points are stored as zero', () {
    expect(
      const CobPlayerLine().copyWith(victoryPoints: -4).victoryPoints,
      0,
    );
  });

  test('round-trips state through JSON', () {
    final original = game(adaLine: const CobPlayerLine(victoryPoints: 87));
    final restored = CobState.fromJson(original.toJson());

    expect(restored.players, original.players);
    expect(restored.status, original.status);
    expect(restored.lineFor('ada').victoryPoints, 87);
    expect(restored.lineFor('sam').victoryPoints, 0);
  });
}
