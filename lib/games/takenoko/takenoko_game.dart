import 'package:flutter/material.dart';

import '../../domain/board_game.dart';
import '../../domain/json_values.dart';
import '../../domain/models/game_config.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/game_status.dart';
import '../../domain/models/player.dart';
import '../../domain/models/player_score.dart';
import '../century/century_widgets.dart';
import 'takenoko_how_to_play_screen.dart';
import 'takenoko_scoring_hints_screen.dart';
import 'takenoko_second_edition_screen.dart';
import 'takenoko_setup_hints_screen.dart';

/// Takenoko offers setup, rules and scoring help, so the hub has no score
/// sheet.
class TakenokoGame extends BoardGame {
  const TakenokoGame();

  static const idValue = 'takenoko';
  static const coverAsset = 'assets/games/takenoko/cover.jpg';

  /// Bamboo green, like the rulebook's shoots.
  static const bamboo = Color(0xFF4E8A3A);

  /// Bamboo bands on the rulebook's parchment, for the hub pages.
  static const style = CenturyStyleData(
    coverAsset: coverAsset,
    accent: bamboo,
    dark: Color(0xFF274A1D),
    paper: Color(0xFFF7F1E2),
  );

  @override
  String get id => idValue;

  @override
  String get name => 'Takenoko';

  @override
  String get l10nPrefix => 'game.takenoko';

  @override
  String get description =>
      'Tend the Emperor’s bamboo garden: lay plots, irrigate them and grow '
      'bamboo with the gardener, while a hungry panda eats it. Complete '
      'objectives to score.';

  @override
  String? get designer => 'Antoine Bauza';

  @override
  String? get publisher => 'Matagot, Bombyx';

  @override
  String? get released => '2011';

  @override
  String? get playTime => '45 min';

  @override
  IconData get icon => Icons.grass_rounded;

  @override
  Color get accentColor => bamboo;

  @override
  int get minPlayers => 2;

  @override
  int get maxPlayers => 4;

  @override
  String? get coverImageAsset => coverAsset;

  /// The cover is 917×900.
  @override
  double get coverAspectRatio => 917 / 900;

  @override
  bool get showScoresheet => false;

  /// What changed from the 1st to the 2nd edition rulebook.
  @override
  bool get showQuickReference => true;

  @override
  String get quickReferenceTitleKey => 'hub.updatedRules';

  @override
  Widget buildQuickReference() => const TakenokoSecondEditionScreen();

  @override
  List<String>? get hubTileOrder => const [
    'hub-setup-hints',
    'hub-guide',
    'hub-quick-reference',
    'hub-scoring-hints',
  ];

  @override
  Widget? buildGuide() => const TakenokoHowToPlayScreen();

  @override
  String get guideTitleKey => 'hub.howToPlay';

  @override
  IconData get guideIcon => Icons.auto_stories_outlined;

  @override
  bool get showSetupHints => true;

  @override
  Widget? buildSetupHints() => const TakenokoSetupHintsScreen();

  @override
  bool get showScoringHints => true;

  @override
  Widget? buildScoringHints() => const TakenokoScoringHintsScreen();

  @override
  GameConfig createDefaultConfig() => const _TakenokoConfig();

  @override
  GameConfig configFromJson(Map<String, dynamic> json) =>
      const _TakenokoConfig();

  @override
  GameState createInitialState({
    required List<Player> players,
    required GameConfig config,
  }) {
    return _TakenokoState(players: players, status: GameStatus.inProgress);
  }

  @override
  GameState stateFromJson(Map<String, dynamic> json) {
    return _TakenokoState(
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

class _TakenokoConfig extends GameConfig {
  const _TakenokoConfig();

  @override
  Map<String, dynamic> toJson() => const {};
}

class _TakenokoState extends GameState {
  const _TakenokoState({required this.players, required this.status});

  @override
  final List<Player> players;

  @override
  final GameStatus status;

  @override
  GameConfig get config => const _TakenokoConfig();

  @override
  GameState copyWithPlayers(List<Player> players) =>
      _TakenokoState(players: players, status: status);

  @override
  GameState copyWithStatus(GameStatus status) =>
      _TakenokoState(players: players, status: status);

  @override
  Map<String, dynamic> toJson() => {
    'players': players.map((player) => player.toJson()).toList(),
    'status': status.name,
  };
}
