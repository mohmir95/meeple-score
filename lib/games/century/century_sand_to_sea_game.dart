import 'package:flutter/material.dart';

import '../../domain/board_game.dart';
import '../../domain/json_values.dart';
import '../../domain/models/game_config.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/game_status.dart';
import '../../domain/models/player.dart';
import '../../domain/models/player_score.dart';
import 'century_rules.dart';
import 'century_game.dart';
import 'sand_to_sea_how_to_play_screen.dart';
import 'sand_to_sea_scoring_hints_screen.dart';
import 'sand_to_sea_setup_hints_screen.dart';
import 'sand_to_sea_starting_resources_screen.dart';

/// Century: From Sand to Sea combines Spice Road's Merchant cards with the
/// Eastern Wonders map. The hub offers setup, rules and scoring help.
class CenturySandToSeaGame extends BoardGame {
  const CenturySandToSeaGame();

  static const idValue = 'century_from_sand_to_sea';

  /// Composed from the Spice Road and Eastern Wonders covers.
  static const coverAsset = 'assets/games/century_from_sand_to_sea/cover.png';

  /// The purple of the rulebook's header bands.
  static const purple = Color(0xFF6B2D5E);

  @override
  String get id => idValue;

  @override
  String get name => 'Spice Road + Eastern Wonders';

  @override
  bool get showSeriesOnCard => false;

  @override
  String? get editionLabel => 'Spice Road + Eastern Wonders';

  @override
  String get l10nPrefix => 'game.centuryFs';

  @override
  String? get seriesId => CenturySpiceRoadGame.seriesIdValue;

  /// Below the printed title, across both halves.
  @override
  Rect? get seriesCoverArt => const Rect.fromLTRB(0, 0.3, 1, 1);

  @override
  String get description =>
      'Spice Road meets Eastern Wonders: play Merchant cards to gather and '
      'trade spices, sail between markets, build outposts and deliver cargo '
      'to ports to claim VP tiles.';

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
  Color get accentColor => purple;

  @override
  int get minPlayers => 2;

  @override
  int get maxPlayers => 4;

  @override
  String? get coverImageAsset => coverAsset;

  @override
  bool get showScoresheet => false;

  @override
  List<String>? get hubTileOrder => centuryHubTileOrder;

  @override
  Widget? buildGuide() => const SandToSeaHowToPlayScreen();

  @override
  String get guideTitleKey => 'hub.howToPlay';

  @override
  IconData get guideIcon => Icons.menu_book_outlined;

  @override
  bool get showSetupHints => true;

  @override
  Widget? buildSetupHints() => const SandToSeaSetupHintsScreen();

  @override
  bool get showStartingResources => true;

  @override
  Widget? buildStartingResources() => const SandToSeaStartingResourcesScreen();

  @override
  bool get showScoringHints => true;

  @override
  Widget? buildScoringHints() => const SandToSeaScoringHintsScreen();

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
