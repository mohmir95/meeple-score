import 'package:flutter/material.dart';

import '../../domain/board_game.dart';
import '../../domain/models/game_config.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/game_status.dart';
import '../../domain/models/player.dart';
import '../../domain/models/player_score.dart';
import '../../shared/player_colors.dart';
import 'gwt_config.dart';
import 'gwt_player_line.dart';
import 'gwt_scoring.dart';
import 'gwt_sheet.dart';
import 'gwt_state.dart';

/// Shared Great Western Trail rules, pad, and player colors.
/// Editions only differ by id, cover, copy, and year.
abstract class GwtEditionGame extends BoardGame {
  const GwtEditionGame();

  @override
  String get name => 'Great Western Trail';

  @override
  String get description =>
      'You are ranchers driving cattle from Texas to Kansas City, then shipping '
      'them west by train. Each loop around the trail you hire cowboys, craftsmen, '
      'and engineers, put up buildings, and chase a stronger herd. When the job '
      'market fills, everyone scores the same categories as the official pad.';

  @override
  String? get designer => 'Alexander Pfister';

  @override
  String? get publisher => 'eggertspiele';

  @override
  String? get playTime => '75–150 min';

  @override
  IconData get icon => Icons.terrain;

  @override
  Color get accentColor => const Color(0xFF6B4F2A);

  @override
  int get minPlayers => 2;

  @override
  int get maxPlayers => 4;

  @override
  List<PlayerColorOption> get playerColors => const [
    PlayerColorOption(name: 'Red', color: Color(0xFFC62828)),
    PlayerColorOption(name: 'Blue', color: Color(0xFF1565C0)),
    PlayerColorOption(name: 'Yellow', color: Color(0xFFF9A825)),
    PlayerColorOption(name: 'White', color: Color(0xFFF4F4F4)),
  ];

  @override
  GameConfig createDefaultConfig() => const GwtConfig();

  @override
  GameConfig configFromJson(Map<String, dynamic> json) {
    return GwtConfig.fromJson(json);
  }

  @override
  GameState createInitialState({
    required List<Player> players,
    required GameConfig config,
  }) {
    return GwtState(
      players: players,
      config: config as GwtConfig,
      status: GameStatus.inProgress,
      lines: {for (final player in players) player.id: const GwtPlayerLine()},
    );
  }

  @override
  GameState stateFromJson(Map<String, dynamic> json) {
    return GwtState.fromJson(json);
  }

  @override
  Widget buildScoreSheet({
    required GameState state,
    required ValueChanged<GameState> onChanged,
    required bool readOnly,
  }) {
    return GwtSheet(
      state: state as GwtState,
      onChanged: onChanged,
      readOnly: readOnly,
      l10nPrefix: l10nPrefix,
    );
  }

  @override
  List<PlayerScore> scores(GameState state) {
    return GwtScoring.scores(state as GwtState);
  }

  @override
  List<Player> winners(GameState state) {
    return GwtScoring.winners(state as GwtState);
  }

  @override
  String? scoreFootnote(GameState state) {
    return 'Highest total wins. 5 dollars = 1 VP.';
  }
}
