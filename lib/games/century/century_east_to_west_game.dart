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
import 'century_widgets.dart';
import 'east_to_west_how_to_play_screen.dart';
import 'east_to_west_setup_hints_screen.dart';
import 'new_world_scoring_hints_screen.dart';
import 'new_world_starting_resources_screen.dart';

/// Century: From East to West (Part I) combines Spice Road's Merchant cards
/// with the A New World board. The hub offers setup, rules and scoring help.
class CenturyEastToWestGame extends BoardGame {
  const CenturyEastToWestGame();

  static const idValue = 'century_from_east_to_west';

  /// Composed from the A New World and Spice Road covers.
  static const coverAsset = 'assets/games/century_from_east_to_west/cover.png';

  /// The deep green of the rulebook's header bands.
  static const green = Color(0xFF24543F);

  @override
  String get id => idValue;

  @override
  String get name => 'Spice Road + A New World';

  @override
  bool get showSeriesOnCard => false;

  @override
  String? get editionLabel => 'Spice Road + A New World';

  @override
  String get l10nPrefix => 'game.centuryEtw';

  @override
  String? get seriesId => CenturySpiceRoadGame.seriesIdValue;

  /// Below the printed title, across both halves.
  @override
  Rect? get seriesCoverArt => const Rect.fromLTRB(0, 0.32, 1, 1);

  @override
  String get description =>
      'Spice Road meets A New World: send settlers to work the board, build '
      'a private trade route of Merchant cards, and deliver goods to claim '
      'Point cards.';

  @override
  String? get designer => 'Emerson Matsuuchi';

  @override
  String? get publisher => 'Plan B Games';

  @override
  String? get released => '2019';

  @override
  String? get playTime => '30–60 min';

  @override
  IconData get icon => Icons.explore_outlined;

  @override
  Color get accentColor => green;

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
  Widget? buildGuide() => const EastToWestHowToPlayScreen();

  @override
  String get guideTitleKey => 'hub.howToPlay';

  @override
  IconData get guideIcon => Icons.menu_book_outlined;

  @override
  bool get showSetupHints => true;

  @override
  Widget? buildSetupHints() => const EastToWestSetupHintsScreen();

  /// Starts exactly like A New World.
  @override
  bool get showStartingResources => true;

  @override
  Widget? buildStartingResources() =>
      const NewWorldStartingResourcesScreen(style: CenturyStyleData.eastToWest);

  /// Scores like A New World, plus a bonus tile for Merchant cards.
  @override
  bool get showScoringHints => true;

  @override
  Widget? buildScoringHints() => const NewWorldScoringHintsScreen(
    style: CenturyStyleData.eastToWest,
    merchantBonus: true,
  );

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
