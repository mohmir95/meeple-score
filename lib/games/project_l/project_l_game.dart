import 'package:flutter/material.dart';

import '../../domain/board_game.dart';
import '../../domain/json_values.dart';
import '../../domain/models/game_config.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/game_status.dart';
import '../../domain/models/player.dart';
import '../../domain/models/player_score.dart';
import 'project_l_revised_rules_screen.dart';
import 'project_l_setup_hints_screen.dart';

/// Project L offers setup help only, so the hub has no score sheet.
class ProjectLGame extends BoardGame {
  const ProjectLGame();

  static const idValue = 'project_l';
  static const coverAsset = 'assets/games/project_l/cover.webp';
  static const cyan = Color(0xFF0A9DC9);

  @override
  String get id => idValue;

  @override
  String get name => 'Project L';

  @override
  String get l10nPrefix => 'game.projectL';

  @override
  String get description =>
      'Fill puzzles with colourful pieces to earn points and bigger pieces. '
      'Build an engine of shapes, upgrade your pieces and finish the most '
      'valuable puzzles before the Black deck runs out.';

  @override
  String? get designer => 'Adam Španěl, Jan Soukal, Michal Mikeš';

  @override
  String? get publisher => 'Boardcubator';

  @override
  String? get released => '2019';

  @override
  String? get playTime => '30–60 min';

  @override
  IconData get icon => Icons.extension_outlined;

  @override
  Color get accentColor => cyan;

  @override
  int get minPlayers => 1;

  /// Rulebook 2.5: 6 players needs the Ghost Piece or Phoenix expansion.
  @override
  int get maxPlayers => 6;

  @override
  String? get coverImageAsset => coverAsset;

  @override
  bool get showScoresheet => false;

  /// Rule changes from rulebooks 2.0 and 2.5 that fit the original box.
  @override
  bool get showQuickReference => true;

  @override
  String get quickReferenceTitleKey => 'hub.revisedRules';

  @override
  Widget buildQuickReference() => const ProjectLRevisedRulesScreen();

  @override
  bool get showSetupHints => true;

  @override
  Widget? buildSetupHints() => const ProjectLSetupHintsScreen();

  @override
  GameConfig createDefaultConfig() => const _ProjectLConfig();

  @override
  GameConfig configFromJson(Map<String, dynamic> json) =>
      const _ProjectLConfig();

  @override
  GameState createInitialState({
    required List<Player> players,
    required GameConfig config,
  }) {
    return _ProjectLState(players: players, status: GameStatus.inProgress);
  }

  @override
  GameState stateFromJson(Map<String, dynamic> json) {
    return _ProjectLState(
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

class _ProjectLConfig extends GameConfig {
  const _ProjectLConfig();

  @override
  Map<String, dynamic> toJson() => const {};
}

class _ProjectLState extends GameState {
  const _ProjectLState({required this.players, required this.status});

  @override
  final List<Player> players;

  @override
  final GameStatus status;

  @override
  GameConfig get config => const _ProjectLConfig();

  @override
  GameState copyWithPlayers(List<Player> players) =>
      _ProjectLState(players: players, status: status);

  @override
  GameState copyWithStatus(GameStatus status) =>
      _ProjectLState(players: players, status: status);

  @override
  Map<String, dynamic> toJson() => {
    'players': players.map((player) => player.toJson()).toList(),
    'status': status.name,
  };
}
