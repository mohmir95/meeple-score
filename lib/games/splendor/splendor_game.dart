import 'package:flutter/material.dart';

import '../../domain/board_game.dart';
import '../../domain/json_values.dart';
import '../../domain/models/game_config.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/game_status.dart';
import '../../domain/models/player.dart';
import '../../domain/models/player_score.dart';
import 'splendor_setup_hints_screen.dart';

/// Splendor offers setup help only, so the hub has no score sheet.
class SplendorGame extends BoardGame {
  const SplendorGame();

  static const idValue = 'splendor';
  static const coverAsset = 'assets/games/splendor/cover.jpg';
  static const navy = Color(0xFF1D4F91);

  @override
  String get id => idValue;

  @override
  String get name => 'Splendor';

  @override
  String get l10nPrefix => 'game.splendor';

  @override
  String get description =>
      'Collect gems, buy Development cards that give lasting bonuses, and '
      'win the favour of nobles. Reaching 15 Prestige points triggers the '
      'end of the game.';

  @override
  String? get designer => 'Marc André';

  @override
  String? get publisher => 'Space Cowboys';

  @override
  String? get released => '2014';

  @override
  String? get playTime => '30 min';

  @override
  IconData get icon => Icons.diamond_outlined;

  @override
  Color get accentColor => navy;

  @override
  int get minPlayers => 2;

  @override
  int get maxPlayers => 4;

  @override
  String? get coverImageAsset => coverAsset;

  @override
  bool get showScoresheet => false;

  @override
  bool get showSetupHints => true;

  @override
  Widget? buildSetupHints() => const SplendorSetupHintsScreen();

  @override
  GameConfig createDefaultConfig() => const _SplendorConfig();

  @override
  GameConfig configFromJson(Map<String, dynamic> json) =>
      const _SplendorConfig();

  @override
  GameState createInitialState({
    required List<Player> players,
    required GameConfig config,
  }) {
    return _SplendorState(players: players, status: GameStatus.inProgress);
  }

  @override
  GameState stateFromJson(Map<String, dynamic> json) {
    return _SplendorState(
      players: readMapList(json['players']).map(Player.fromJson).toList(),
      status: GameStatus.fromName(json['status'] as String?),
    );
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
  List<PlayerScore> scores(GameState state) => const [];

  @override
  List<Player> winners(GameState state) => const [];
}

class _SplendorConfig extends GameConfig {
  const _SplendorConfig();

  @override
  Map<String, dynamic> toJson() => const {};
}

class _SplendorState extends GameState {
  const _SplendorState({required this.players, required this.status});

  @override
  final List<Player> players;

  @override
  final GameStatus status;

  @override
  GameConfig get config => const _SplendorConfig();

  @override
  GameState copyWithPlayers(List<Player> players) =>
      _SplendorState(players: players, status: status);

  @override
  GameState copyWithStatus(GameStatus status) =>
      _SplendorState(players: players, status: status);

  @override
  Map<String, dynamic> toJson() => {
    'players': players.map((player) => player.toJson()).toList(),
    'status': status.name,
  };
}
