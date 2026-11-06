import 'package:flutter/material.dart';

import '../../domain/board_game.dart';
import '../../domain/json_values.dart';
import '../../domain/models/game_config.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/game_status.dart';
import '../../domain/models/player.dart';
import '../../domain/models/player_score.dart';
import 'turing_note_sheet_screen.dart';

/// Turing Machine has no scores: the hub offers a deduction note sheet only.
class TuringMachineGame extends BoardGame {
  const TuringMachineGame();

  static const idValue = 'turing_machine';
  static const coverAsset = 'assets/games/turing_machine/cover.webp';
  static const green = Color(0xFF2E9E4F);

  @override
  String get id => idValue;

  @override
  String get name => 'Turing Machine';

  @override
  String get l10nPrefix => 'game.turing';

  @override
  String get description =>
      'Find the secret three-digit code before everyone else. Build a code '
      'with the punch cards, test it against the verifiers, and deduce '
      'which criterion each verifier checks.';

  @override
  String? get designer => 'Fabien Gridel, Yoann Levet';

  @override
  String? get publisher => 'Le Scorpion Masqué';

  @override
  String? get released => '2022';

  @override
  String? get playTime => '20 min';

  @override
  IconData get icon => Icons.memory;

  @override
  Color get accentColor => green;

  @override
  int get minPlayers => 1;

  @override
  int get maxPlayers => 4;

  @override
  String? get coverImageAsset => coverAsset;

  @override
  bool get showNoteSheet => true;

  @override
  Widget buildNoteSheet() => const TuringNoteSheetScreen();

  /// Online problems, beyond the 20 in the rulebook.
  @override
  String? get onlineUrl => 'https://turingmachine.info/';

  @override
  GameConfig createDefaultConfig() => const _TuringConfig();

  @override
  GameConfig configFromJson(Map<String, dynamic> json) => const _TuringConfig();

  @override
  GameState createInitialState({
    required List<Player> players,
    required GameConfig config,
  }) {
    return _TuringState(players: players, status: GameStatus.inProgress);
  }

  @override
  GameState stateFromJson(Map<String, dynamic> json) {
    return _TuringState(
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

class _TuringConfig extends GameConfig {
  const _TuringConfig();

  @override
  Map<String, dynamic> toJson() => const {};
}

class _TuringState extends GameState {
  const _TuringState({required this.players, required this.status});

  @override
  final List<Player> players;

  @override
  final GameStatus status;

  @override
  GameConfig get config => const _TuringConfig();

  @override
  GameState copyWithPlayers(List<Player> players) =>
      _TuringState(players: players, status: status);

  @override
  GameState copyWithStatus(GameStatus status) =>
      _TuringState(players: players, status: status);

  @override
  Map<String, dynamic> toJson() => {
    'players': players.map((player) => player.toJson()).toList(),
    'status': status.name,
  };
}
