import 'package:flutter/material.dart';

import '../../domain/board_game.dart';
import '../../domain/json_values.dart';
import '../../domain/models/game_config.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/game_status.dart';
import '../../domain/models/player.dart';
import '../../domain/models/player_score.dart';
import 'alchemists_logic_screen.dart';
import 'alchemists_starting_resources_screen.dart';

/// Alchemists: so far the hub offers a tutorial for the logic puzzle.
class AlchemistsGame extends BoardGame {
  const AlchemistsGame();

  static const idValue = 'alchemists';
  static const coverAsset = 'assets/games/alchemists/cover.png';
  static const purple = Color(0xFF6B3A9E);

  @override
  String get id => idValue;

  @override
  String get name => 'Alchemists';

  @override
  String get l10nPrefix => 'game.alchemists';

  @override
  String get description =>
      'Mix ingredients, test potions and deduce the secret alchemical '
      'properties of each ingredient. Publish theories to gain reputation, '
      'but beware: a wrong theory can be debunked.';

  @override
  String? get designer => 'Matúš Kotry';

  @override
  String? get publisher => 'Czech Games Edition';

  @override
  String? get released => '2014';

  @override
  String? get playTime => '120 min';

  @override
  IconData get icon => Icons.science_outlined;

  @override
  Color get accentColor => purple;

  @override
  int get minPlayers => 2;

  @override
  int get maxPlayers => 4;

  @override
  String? get coverImageAsset => coverAsset;

  /// No scoresheet yet; the hub offers the logic puzzle tutorial.
  @override
  bool get showScoresheet => false;

  @override
  bool get showQuickReference => true;

  @override
  String get quickReferenceTitleKey => 'hub.logicPuzzle';

  @override
  Widget buildQuickReference() => const AlchemistsLogicScreen();

  @override
  bool get showStartingResources => true;

  @override
  Widget? buildStartingResources() => const AlchemistsStartingResourcesScreen();

  /// The official companion app that reads the ingredient cards.
  @override
  String? get onlineUrl => 'https://alchemists.czechgames.com/';

  @override
  String get onlineTitleKey => 'hub.cardReaderApp';

  @override
  GameConfig createDefaultConfig() => const _AlchemistsConfig();

  @override
  GameConfig configFromJson(Map<String, dynamic> json) =>
      const _AlchemistsConfig();

  @override
  GameState createInitialState({
    required List<Player> players,
    required GameConfig config,
  }) {
    return _AlchemistsState(players: players, status: GameStatus.inProgress);
  }

  @override
  GameState stateFromJson(Map<String, dynamic> json) {
    return _AlchemistsState(
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

class _AlchemistsConfig extends GameConfig {
  const _AlchemistsConfig();

  @override
  Map<String, dynamic> toJson() => const {};
}

class _AlchemistsState extends GameState {
  const _AlchemistsState({required this.players, required this.status});

  @override
  final List<Player> players;

  @override
  final GameStatus status;

  @override
  GameConfig get config => const _AlchemistsConfig();

  @override
  GameState copyWithPlayers(List<Player> players) =>
      _AlchemistsState(players: players, status: status);

  @override
  GameState copyWithStatus(GameStatus status) =>
      _AlchemistsState(players: players, status: status);

  @override
  Map<String, dynamic> toJson() => {
    'players': players.map((player) => player.toJson()).toList(),
    'status': status.name,
  };
}
