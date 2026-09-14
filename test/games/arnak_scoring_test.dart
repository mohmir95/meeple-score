import 'package:board_game_score_sheet/domain/models/game_status.dart';
import 'package:board_game_score_sheet/domain/models/player.dart';
import 'package:board_game_score_sheet/games/lost_ruins_of_arnak/arnak_config.dart';
import 'package:board_game_score_sheet/games/lost_ruins_of_arnak/arnak_player_line.dart';
import 'package:board_game_score_sheet/games/lost_ruins_of_arnak/arnak_scoring.dart';
import 'package:board_game_score_sheet/games/lost_ruins_of_arnak/arnak_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ada = Player(id: 'ada', name: 'Ada', colorValue: 0xFFC62828);
  const sam = Player(id: 'sam', name: 'Sam', colorValue: 0xFF1565C0);

  ArnakState game({
    ArnakPlayerLine adaLine = const ArnakPlayerLine(),
    ArnakPlayerLine samLine = const ArnakPlayerLine(),
  }) {
    return ArnakState(
      players: const [ada, sam],
      config: const ArnakConfig(),
      status: GameStatus.inProgress,
      lines: {'ada': adaLine, 'sam': samLine},
    );
  }

  test('sums every official pad row including negative fear', () {
    const line = ArnakPlayerLine(
      research: 24,
      templeTiles: 11,
      idols: 15,
      guardians: 10,
      cards: 8,
      fear: -3,
    );

    expect(ArnakScoring.totalFor(line), 24 + 11 + 15 + 10 + 8 - 3);
  });

  test('tied totals stay shared until Lost Temple first is chosen', () {
    final state = game(
      adaLine: const ArnakPlayerLine(research: 18, cards: 4),
      samLine: const ArnakPlayerLine(research: 12, cards: 10),
    );

    expect(ArnakScoring.totalFor(state.lineFor('ada')), 22);
    expect(ArnakScoring.totalFor(state.lineFor('sam')), 22);
    expect(ArnakScoring.tiedByTotal(state), [ada, sam]);
    expect(ArnakScoring.winners(state), [ada, sam]);
  });

  test('Lost Temple first among tied players wins', () {
    final state = game(
      adaLine: const ArnakPlayerLine(research: 18, cards: 4),
      samLine: const ArnakPlayerLine(research: 12, cards: 10),
    ).copyWith(lostTempleFirstPlayerId: sam.id);

    expect(ArnakScoring.winners(state), [sam]);
  });

  test('if no one reached the temple, highest research among the tie wins', () {
    final state = game(
      adaLine: const ArnakPlayerLine(research: 18, cards: 4),
      samLine: const ArnakPlayerLine(research: 12, cards: 10),
    ).copyWith(lostTempleFirstPlayerId: ArnakState.nobodyReachedLostTemple);

    expect(ArnakScoring.winners(state), [ada]);
  });

  test('if no one reached the temple and research is tied, they share', () {
    final state = game(
      adaLine: const ArnakPlayerLine(research: 12, idols: 9),
      samLine: const ArnakPlayerLine(research: 12, guardians: 9),
    ).copyWith(lostTempleFirstPlayerId: ArnakState.nobodyReachedLostTemple);

    expect(ArnakScoring.winners(state), [ada, sam]);
  });

  test('round-trips state through JSON', () {
    final original = game(
      adaLine: const ArnakPlayerLine(research: 16, fear: -2),
    );
    final restored = ArnakState.fromJson(original.toJson());
    expect(restored.lineFor('ada').research, 16);
    expect(restored.lineFor('ada').fear, -2);
    expect(restored.lostTempleFirstPlayerId, isNull);
    expect(ArnakScoring.totalFor(restored.lineFor('ada')), 14);

    final withFirst = original.copyWith(lostTempleFirstPlayerId: ada.id);
    expect(
      ArnakState.fromJson(withFirst.toJson()).lostTempleFirstPlayerId,
      ada.id,
    );
    expect(
      ArnakState.fromJson(
        original
            .copyWith(
              lostTempleFirstPlayerId: ArnakState.nobodyReachedLostTemple,
            )
            .toJson(),
      ).lostTempleFirstPlayerId,
      ArnakState.nobodyReachedLostTemple,
    );
  });

  test('fear cannot be positive', () {
    expect(ArnakPlayerLine.normalizeFear(4), 0);
    expect(ArnakPlayerLine.normalizeFear(0), 0);
    expect(ArnakPlayerLine.normalizeFear(-5), -5);
    expect(const ArnakPlayerLine().copyWith(fear: 3).fear, 0);
    expect(ArnakPlayerLine.fromJson({'fear': 6}).fear, 0);
    expect(ArnakScoring.totalFor(const ArnakPlayerLine(fear: 4)), 0);
  });
}
