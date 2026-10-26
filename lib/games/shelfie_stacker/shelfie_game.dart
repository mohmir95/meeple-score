import 'package:flutter/material.dart';

import '../../domain/board_game.dart';
import '../../domain/models/game_config.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/game_status.dart';
import '../../domain/models/player.dart';
import '../../domain/models/player_score.dart';
import '../../shared/player_colors.dart';
import 'shelfie_config.dart';
import 'shelfie_finish.dart';
import 'shelfie_player_line.dart';
import 'shelfie_scoring.dart';
import 'shelfie_setup_hints_screen.dart';
import 'shelfie_sheet.dart';
import 'shelfie_state.dart';

class ShelfieStackerGame extends BoardGame {
  const ShelfieStackerGame();

  static const idValue = 'shelfie_stacker';
  static const coverAsset = 'assets/games/shelfie_stacker/cover.jpg';

  @override
  String get id => idValue;

  @override
  String get name => 'Shelfie Stacker';

  @override
  String get l10nPrefix => 'game.shelfie';

  @override
  String get description =>
      'Build the best board game shelfie. Each round you draft dice and stack '
      'them in the columns of your Big Shelf, chasing tall columns and high '
      'top dice. Dice you cannot place go to the Shelf of Shame. After the '
      'last round, score the same rows as the official pad.';

  @override
  String? get designer => 'Shem Phillips';

  @override
  String? get publisher => 'Arkus Games';

  @override
  String? get released => '2021';

  @override
  String? get playTime => '20–40 min';

  @override
  IconData get icon => Icons.shelves;

  @override
  Color get accentColor => const Color(0xFF2F6DB5);

  @override
  int get minPlayers => 1;

  @override
  int get maxPlayers => 4;

  @override
  String? get coverImageAsset => coverAsset;

  @override
  bool get showSetupHints => true;

  @override
  Widget? buildSetupHints() => const ShelfieSetupHintsScreen();

  /// The four colors across the top of the printed pad.
  @override
  List<PlayerColorOption> get playerColors => const [
    PlayerColorOption(name: 'Blue', color: Color(0xFF4A86C8)),
    PlayerColorOption(name: 'Green', color: Color(0xFF2E8B4E)),
    PlayerColorOption(name: 'Orange', color: Color(0xFFE08A3C)),
    PlayerColorOption(name: 'Purple', color: Color(0xFFB04FA8)),
  ];

  @override
  GameConfig createDefaultConfig() => const ShelfieConfig();

  @override
  GameConfig configFromJson(Map<String, dynamic> json) {
    return ShelfieConfig.fromJson(json);
  }

  @override
  GameState createInitialState({
    required List<Player> players,
    required GameConfig config,
  }) {
    return ShelfieState(
      players: players,
      config: config as ShelfieConfig,
      status: GameStatus.inProgress,
      lines: {
        for (final player in players) player.id: const ShelfiePlayerLine(),
      },
    );
  }

  @override
  GameState stateFromJson(Map<String, dynamic> json) {
    return ShelfieState.fromJson(json);
  }

  @override
  Widget buildScoreSheet({
    required GameState state,
    required ValueChanged<GameState> onChanged,
    required bool readOnly,
  }) {
    return ShelfieSheet(
      state: state as ShelfieState,
      onChanged: onChanged,
      readOnly: readOnly,
    );
  }

  @override
  List<PlayerScore> scores(GameState state) {
    return ShelfieScoring.scores(state as ShelfieState);
  }

  @override
  List<Player> winners(GameState state) {
    return ShelfieScoring.winners(state as ShelfieState);
  }

  @override
  Future<GameState?> prepareFinish({
    required BuildContext context,
    required GameState state,
  }) async {
    final shelfie = state as ShelfieState;
    if (ShelfieScoring.tiedByTotal(shelfie).length < 2) {
      return shelfie.copyWith(lowestCardPlayerId: null);
    }
    final choice = await showShelfieLowestCardDialog(context, shelfie);
    if (choice == null) {
      return null;
    }
    return shelfie.copyWith(lowestCardPlayerId: choice);
  }

  @override
  String? scoreFootnote(GameState state) {
    return 'Highest total wins. Ties go to the lowest-valued Character Card still in hand.';
  }
}
