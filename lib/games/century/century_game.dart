import 'package:flutter/material.dart';

import '../../domain/board_game.dart';
import '../../domain/json_values.dart';
import '../../domain/models/game_config.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/game_status.dart';
import '../../domain/models/player.dart';
import '../../domain/models/player_score.dart';
import 'century_scoring_hints_screen.dart';
import 'century_setup_hints_screen.dart';
import 'century_starting_resources_screen.dart';

/// Century: Spice Road offers setup and scoring help only, so the hub has no
/// score sheet.
class CenturySpiceRoadGame extends BoardGame {
  const CenturySpiceRoadGame();

  static const idValue = 'century_spice_road';
  static const coverAsset = 'assets/games/century_spice_road/cover.webp';

  /// The plum of the rulebook's header bands.
  static const plum = Color(0xFF6A2C4E);

  @override
  String get id => idValue;

  @override
  String get name => 'Century: Spice Road';

  @override
  String? get editionLabel => 'Spice Road';

  @override
  String get l10nPrefix => 'game.century';

  /// Every Century game shares one home page banner.
  static const seriesIdValue = 'century';

  @override
  String? get seriesId => seriesIdValue;

  @override
  Rect? get seriesCoverArt => const Rect.fromLTRB(0, 0.4, 1, 1);

  @override
  String get description =>
      'Lead a caravan along the Spice Road: play merchant cards to gather, '
      'upgrade and trade spices, then deliver them to claim point cards.';

  @override
  String? get designer => 'Emerson Matsuuchi';

  @override
  String? get publisher => 'Plan B Games';

  @override
  String? get released => '2017';

  @override
  String? get playTime => '30–45 min';

  @override
  IconData get icon => Icons.local_shipping_outlined;

  @override
  Color get accentColor => plum;

  @override
  int get minPlayers => 2;

  @override
  int get maxPlayers => 5;

  @override
  String? get coverImageAsset => coverAsset;

  @override
  bool get showScoresheet => false;

  @override
  bool get showSetupHints => true;

  @override
  Widget? buildSetupHints() => const CenturySetupHintsScreen();

  @override
  bool get showStartingResources => true;

  @override
  Widget? buildStartingResources() => const CenturyStartingResourcesScreen();

  @override
  bool get showScoringHints => true;

  @override
  Widget? buildScoringHints() => const CenturyScoringHintsScreen();

  @override
  GameConfig createDefaultConfig() => const _CenturyConfig();

  @override
  GameConfig configFromJson(Map<String, dynamic> json) =>
      const _CenturyConfig();

  @override
  GameState createInitialState({
    required List<Player> players,
    required GameConfig config,
  }) {
    return _CenturyState(players: players, status: GameStatus.inProgress);
  }

  @override
  GameState stateFromJson(Map<String, dynamic> json) {
    return _CenturyState(
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

class _CenturyConfig extends GameConfig {
  const _CenturyConfig();

  @override
  Map<String, dynamic> toJson() => const {};
}

class _CenturyState extends GameState {
  const _CenturyState({required this.players, required this.status});

  @override
  final List<Player> players;

  @override
  final GameStatus status;

  @override
  GameConfig get config => const _CenturyConfig();

  @override
  GameState copyWithPlayers(List<Player> players) =>
      _CenturyState(players: players, status: status);

  @override
  GameState copyWithStatus(GameStatus status) =>
      _CenturyState(players: players, status: status);

  @override
  Map<String, dynamic> toJson() => {
    'players': players.map((player) => player.toJson()).toList(),
    'status': status.name,
  };
}
