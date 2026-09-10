import 'package:flutter/material.dart';

import 'models/game_config.dart';
import 'models/game_state.dart';
import 'models/player.dart';
import 'models/player_score.dart';
import '../shared/player_colors.dart';

/// Contract every board game implements.
///
/// Scoring and state live in the game's own files. Shared screens call these
/// methods so a new game can be added without changing existing ones.
abstract class BoardGame {
  const BoardGame();

  String get id;
  String get name;
  String get description;
  IconData get icon;
  Color get accentColor;
  int get minPlayers;
  int get maxPlayers;

  /// Shown on setup, e.g. "First Edition".
  String? get editionLabel => null;

  String get l10nPrefix => 'game.$id';

  String? get designer => null;

  String? get publisher => null;

  /// Publication year, e.g. "2016".
  String? get released => null;

  /// Typical play time, e.g. "75–150 min".
  String? get playTime => null;

  /// Game-specific meeple colors. Empty means the editor hides color swatches.
  List<PlayerColorOption> get playerColors => const [];

  bool get uniquePlayerColors =>
      playerColors.isNotEmpty && playerColors.length >= maxPlayers;

  /// Optional box art shown on the home screen.
  String? get coverImageAsset => null;

  GameConfig createDefaultConfig();

  GameConfig configFromJson(Map<String, dynamic> json);

  GameState createInitialState({
    required List<Player> players,
    required GameConfig config,
  });

  GameState stateFromJson(Map<String, dynamic> json);

  /// Optional game-specific setup controls (target score, variants, etc.).
  Widget buildConfigEditor({
    required GameConfig config,
    required ValueChanged<GameConfig> onChanged,
  }) {
    return const SizedBox.shrink();
  }

  /// Game-specific score sheet. Call [onChanged] after every mutation.
  Widget buildScoreSheet({
    required GameState state,
    required ValueChanged<GameState> onChanged,
    required bool readOnly,
  });

  List<PlayerScore> scores(GameState state);

  List<Player> winners(GameState state);

  bool hasReachedGoal(GameState state) => false;

  String? scoreFootnote(GameState state) => null;

  String winnerMessage(GameState state) {
    final winningPlayers = winners(state);
    if (winningPlayers.isEmpty) {
      return 'No winner yet.';
    }
    if (winningPlayers.length == 1) {
      return '${winningPlayers.first.name} wins!';
    }
    final names = winningPlayers.map((player) => player.name).join(', ');
    return '$names tied!';
  }
}
