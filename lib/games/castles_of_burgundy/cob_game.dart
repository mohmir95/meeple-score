import 'package:flutter/material.dart';

import '../../domain/board_game.dart';
import '../../domain/models/game_config.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/game_status.dart';
import '../../domain/models/player.dart';
import '../../domain/models/player_score.dart';
import '../../shared/player_colors.dart';
import 'cob_config.dart';
import 'cob_palette.dart';
import 'cob_duchy_randomizer_screen.dart';
import 'cob_player_line.dart';
import 'cob_quick_reference_screen.dart';
import 'cob_scoring.dart';
import 'cob_state.dart';

class CastlesOfBurgundySpecialEditionGame extends BoardGame {
  const CastlesOfBurgundySpecialEditionGame();

  static const idValue = 'castles_of_burgundy_se';
  static const coverAsset = 'assets/games/castles_of_burgundy/cover.webp';

  @override
  String get id => idValue;

  @override
  String get name => 'The Castles of Burgundy Special Edition';

  @override
  String? get editionLabel => 'Special Edition';

  @override
  String get l10nPrefix => 'game.cobse';

  @override
  String get description =>
      'Settle estates in the Duchy of Burgundy. Across five phases you draft '
      'tiles, complete colored regions, sell goods, and climb the victory '
      'track. The Special Edition adds solo play and the expansion tiles.';

  @override
  String? get designer => 'Stefan Feld';

  @override
  String? get publisher => 'alea';

  @override
  String? get released => '2019';

  @override
  String? get playTime => '30–90 min';

  @override
  IconData get icon => Icons.castle;

  @override
  Color get accentColor => const Color(0xFF7A2E3B);

  @override
  int get minPlayers => 1;

  @override
  int get maxPlayers => 4;

  @override
  String? get coverImageAsset => coverAsset;

  @override
  bool get showQuickReference => true;

  @override
  Widget buildQuickReference() => const CobQuickReferenceScreen();

  @override
  bool get showDuchyBoardRandomizer => true;

  @override
  Widget? buildDuchyBoardRandomizer() => const CobDuchyRandomizerScreen();

  @override
  List<PlayerColorOption> get playerColors => cobPlayerColors;

  @override
  GameConfig createDefaultConfig() => const CobConfig();

  @override
  GameConfig configFromJson(Map<String, dynamic> json) {
    return CobConfig.fromJson(json);
  }

  @override
  GameState createInitialState({
    required List<Player> players,
    required GameConfig config,
  }) {
    return CobState(
      players: players,
      config: config as CobConfig,
      status: GameStatus.inProgress,
      lines: {for (final player in players) player.id: const CobPlayerLine()},
    );
  }

  @override
  GameState stateFromJson(Map<String, dynamic> json) {
    return CobState.fromJson(json);
  }

  @override
  Widget buildScoreSheet({
    required GameState state,
    required ValueChanged<GameState> onChanged,
    required bool readOnly,
  }) {
    return const SizedBox.shrink();
  }

  @override
  List<PlayerScore> scores(GameState state) {
    return CobScoring.scores(state as CobState);
  }

  @override
  List<Player> winners(GameState state) {
    return CobScoring.winners(state as CobState);
  }

  @override
  String? scoreFootnote(GameState state) {
    return 'Highest total wins.';
  }
}
