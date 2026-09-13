import 'package:flutter/material.dart';

import '../../domain/models/game_state.dart';
import '../../domain/models/player.dart';
import '../../domain/models/player_score.dart';
import 'gwt_edition.dart';
import 'gwt_scoring.dart';
import 'gwt_sheet.dart';
import 'gwt_state.dart';

class GreatWesternTrailArgentinaGame extends GwtEditionGame {
  const GreatWesternTrailArgentinaGame();

  static const idValue = 'great_western_trail_argentina';
  static const coverAsset =
      'assets/games/great_western_trail_argentina/cover.webp';

  @override
  String get id => idValue;

  @override
  String get name => 'Great Western Trail Argentina';

  @override
  String? get editionLabel => 'Argentina';

  @override
  String get l10nPrefix => 'game.gwta';

  @override
  String get description =>
      'Travel the plains of the Pampas with your cattle and deliver them to '
      'Buenos Aires. Argentina adds ships, city maps, farmer tiles, exhaustion '
      'cards, and new station master tiles.';

  @override
  Color get accentColor => const Color(0xFF1B4F4A);

  @override
  int get minPlayers => 1;

  @override
  String? get released => '2022';

  @override
  String? get coverImageAsset => coverAsset;

  @override
  Widget buildScoreSheet({
    required GameState state,
    required ValueChanged<GameState> onChanged,
    required bool readOnly,
  }) {
    return GwtSheet(
      state: state as GwtState,
      onChanged: onChanged,
      readOnly: readOnly,
      l10nPrefix: l10nPrefix,
      pad: GwtPadKind.argentina,
    );
  }

  @override
  List<PlayerScore> scores(GameState state) {
    return GwtScoring.scores(state as GwtState, pad: GwtPadKind.argentina);
  }

  @override
  List<Player> winners(GameState state) {
    return GwtScoring.winners(state as GwtState, pad: GwtPadKind.argentina);
  }

  @override
  String? scoreFootnote(GameState state) {
    return 'Highest total wins. 5 pesos = 1 VP.';
  }
}
