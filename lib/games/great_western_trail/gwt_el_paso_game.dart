import 'package:flutter/material.dart';

import '../../domain/models/game_state.dart';
import '../../domain/models/player.dart';
import '../../domain/models/player_score.dart';
import 'gwt_edition.dart';
import 'gwt_el_paso_buildings_screen.dart';
import 'gwt_scoring.dart';
import 'gwt_sheet.dart';
import 'gwt_starting_resources_screen.dart';
import 'gwt_train_cards_randomizer_screen.dart';
import 'gwt_state.dart';

class GreatWesternTrailElPasoGame extends GwtEditionGame {
  const GreatWesternTrailElPasoGame();

  static const idValue = 'great_western_trail_el_paso';
  static const coverAsset =
      'assets/games/great_western_trail_el_paso/cover.jpg';

  @override
  String get id => idValue;

  @override
  String get name => 'Great Western Trail El Paso';

  @override
  String? get editionLabel => 'El Paso';

  @override
  String get l10nPrefix => 'game.gwtep';

  @override
  String get description =>
      'A shorter standalone Great Western Trail. Drive your herd along the '
      'trail to El Paso, hire workers, build, and ship your cattle by train '
      'to the trading posts, then score the 7 categories of the pad.';

  @override
  String? get designer => 'Alexander Pfister, Johannes Krenner';

  @override
  String? get publisher => 'Lookout Games';

  @override
  String? get playTime => '60–90 min';

  @override
  Color get accentColor => const Color(0xFF9A4A1F);

  @override
  int get minPlayers => 1;

  @override
  String? get released => '2025';

  @override
  String? get coverImageAsset => coverAsset;

  @override
  Widget? buildBuildingsRandomizer() => GwtElPasoBuildingsScreen(game: this);

  @override
  Widget? buildStartingResources() {
    return GwtStartingResourcesScreen(
      game: this,
      setup: GwtStartingSetup.elPaso,
    );
  }

  @override
  bool get includeRailsToTheNorthExpansion => false;

  @override
  bool get showTrainCardsRandomizer => true;

  @override
  Widget? buildTrainCardsRandomizer() =>
      GwtTrainCardsRandomizerScreen(game: this);

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
      pad: GwtPadKind.elPaso,
    );
  }

  @override
  List<PlayerScore> scores(GameState state) {
    return GwtScoring.scores(state as GwtState, pad: GwtPadKind.elPaso);
  }

  @override
  List<Player> winners(GameState state) {
    return GwtScoring.winners(state as GwtState, pad: GwtPadKind.elPaso);
  }

  @override
  String? scoreFootnote(GameState state) {
    return 'Highest total wins. 5 dollars = 1 VP. Ties: most leftover dollars.';
  }
}
