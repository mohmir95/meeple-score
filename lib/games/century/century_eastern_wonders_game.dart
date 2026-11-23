import 'package:flutter/material.dart';

import '../../domain/board_game.dart';
import '../../domain/json_values.dart';
import '../../domain/models/game_config.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/game_status.dart';
import '../../domain/models/player.dart';
import '../../domain/models/player_score.dart';
import 'century_game.dart';
import 'eastern_wonders_scoring_hints_screen.dart';
import 'eastern_wonders_setup_hints_screen.dart';
import 'eastern_wonders_starting_resources_screen.dart';

/// Century: Eastern Wonders offers setup and scoring help only, so the hub
/// has no score sheet.
class CenturyEasternWondersGame extends BoardGame {
  const CenturyEasternWondersGame();

  static const idValue = 'century_eastern_wonders';
  static const coverAsset = 'assets/games/century_eastern_wonders/cover.webp';

  /// The brick red of the rulebook's header bands.
  static const brick = Color(0xFF8A2E1E);

  @override
  String get id => idValue;

  @override
  String get name => 'Century: Eastern Wonders';

  @override
  String? get editionLabel => 'Eastern Wonders';

  @override
  String get l10nPrefix => 'game.centuryEw';

  @override
  String? get seriesId => CenturySpiceRoadGame.seriesIdValue;

  @override
  Rect? get seriesCoverArt => const Rect.fromLTRB(0, 0.42, 1, 1);

  @override
  String get description =>
      'Sail the islands of the Far East: trade spices at markets, build '
      'outposts, and deliver cargo to ports to claim VP tiles.';

  @override
  String? get designer => 'Emerson Matsuuchi';

  @override
  String? get publisher => 'Plan B Games';

  @override
  String? get released => '2018';

  @override
  String? get playTime => '30–60 min';

  @override
  IconData get icon => Icons.sailing_outlined;

  @override
  Color get accentColor => brick;

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
  Widget? buildSetupHints() => const EasternWondersSetupHintsScreen();

  @override
  bool get showStartingResources => true;

  @override
  Widget? buildStartingResources() =>
      const EasternWondersStartingResourcesScreen();

  @override
  bool get showScoringHints => true;

  @override
  Widget? buildScoringHints() => const EasternWondersScoringHintsScreen();

  @override
  GameConfig createDefaultConfig() => const _Config();

  @override
  GameConfig configFromJson(Map<String, dynamic> json) => const _Config();

  @override
  GameState createInitialState({
    required List<Player> players,
    required GameConfig config,
  }) {
    return _State(players: players, status: GameStatus.inProgress);
  }

  @override
  GameState stateFromJson(Map<String, dynamic> json) {
    return _State(
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

class _Config extends GameConfig {
  const _Config();

  @override
  Map<String, dynamic> toJson() => const {};
}

class _State extends GameState {
  const _State({required this.players, required this.status});

  @override
  final List<Player> players;

  @override
  final GameStatus status;

  @override
  GameConfig get config => const _Config();

  @override
  GameState copyWithPlayers(List<Player> players) =>
      _State(players: players, status: status);

  @override
  GameState copyWithStatus(GameStatus status) =>
      _State(players: players, status: status);

  @override
  Map<String, dynamic> toJson() => {
    'players': players.map((player) => player.toJson()).toList(),
    'status': status.name,
  };
}
