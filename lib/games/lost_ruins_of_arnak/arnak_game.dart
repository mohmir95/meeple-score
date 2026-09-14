import 'package:flutter/material.dart';

import '../../domain/board_game.dart';
import '../../domain/models/game_config.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/game_status.dart';
import '../../domain/models/player.dart';
import '../../domain/models/player_score.dart';
import '../../shared/player_colors.dart';
import 'arnak_config.dart';
import 'arnak_finish.dart';
import 'arnak_player_line.dart';
import 'arnak_scoring.dart';
import 'arnak_sheet.dart';
import 'arnak_state.dart';

class LostRuinsOfArnakGame extends BoardGame {
  const LostRuinsOfArnakGame();

  static const idValue = 'lost_ruins_of_arnak';
  static const coverAsset = 'assets/games/lost_ruins_of_arnak/cover.webp';

  @override
  String get id => idValue;

  @override
  String get name => 'Lost Ruins of Arnak';

  @override
  String get l10nPrefix => 'game.arnak';

  @override
  String get description =>
      'Lead an expedition onto the uncharted island of Arnak. Equip your team, '
      'uncover artifacts and archaeological sites, overcome guardians, and '
      'piece together research that may reveal the Lost Temple. After five '
      'rounds, score the same categories as the official pad.';

  @override
  String? get designer => 'Mín & Elwen';

  @override
  String? get publisher => 'Czech Games Edition';

  @override
  String? get released => '2020';

  @override
  String? get playTime => '30–120 min';

  @override
  IconData get icon => Icons.explore;

  @override
  Color get accentColor => const Color(0xFF2F5D3A);

  @override
  int get minPlayers => 1;

  @override
  int get maxPlayers => 4;

  @override
  String? get coverImageAsset => coverAsset;

  @override
  List<PlayerColorOption> get playerColors => const [
    PlayerColorOption(name: 'Red', color: Color(0xFFC62828)),
    PlayerColorOption(name: 'Blue', color: Color(0xFF1565C0)),
    PlayerColorOption(name: 'Yellow', color: Color(0xFFF9A825)),
    PlayerColorOption(name: 'Green', color: Color(0xFF2E7D32)),
  ];

  @override
  GameConfig createDefaultConfig() => const ArnakConfig();

  @override
  GameConfig configFromJson(Map<String, dynamic> json) {
    return ArnakConfig.fromJson(json);
  }

  @override
  GameState createInitialState({
    required List<Player> players,
    required GameConfig config,
  }) {
    return ArnakState(
      players: players,
      config: config as ArnakConfig,
      status: GameStatus.inProgress,
      lines: {for (final player in players) player.id: const ArnakPlayerLine()},
    );
  }

  @override
  GameState stateFromJson(Map<String, dynamic> json) {
    return ArnakState.fromJson(json);
  }

  @override
  Widget buildScoreSheet({
    required GameState state,
    required ValueChanged<GameState> onChanged,
    required bool readOnly,
  }) {
    return ArnakSheet(
      state: state as ArnakState,
      onChanged: onChanged,
      readOnly: readOnly,
    );
  }

  @override
  List<PlayerScore> scores(GameState state) {
    return ArnakScoring.scores(state as ArnakState);
  }

  @override
  List<Player> winners(GameState state) {
    return ArnakScoring.winners(state as ArnakState);
  }

  @override
  Future<GameState?> prepareFinish({
    required BuildContext context,
    required GameState state,
  }) async {
    final arnak = state as ArnakState;
    if (ArnakScoring.tiedByTotal(arnak).length < 2) {
      return arnak.copyWith(lostTempleFirstPlayerId: null);
    }
    final choice = await showArnakLostTempleDialog(context, arnak);
    if (choice == null) {
      return null;
    }
    return arnak.copyWith(lostTempleFirstPlayerId: choice);
  }

  @override
  String? scoreFootnote(GameState state) {
    return 'Highest total wins. Ties go to whoever reached the Lost Temple first, then the highest research score.';
  }
}
