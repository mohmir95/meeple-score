import 'package:flutter/material.dart';

import '../../domain/models/game_state.dart';
import '../../domain/models/player.dart';
import '../../domain/models/player_score.dart';
import 'gwt_building_art.dart';
import 'gwt_buildings_randomizer_screen.dart';
import 'gwt_edition.dart';
import 'gwt_public_buildings_layout.dart';
import 'gwt_scoring.dart';
import 'gwt_sheet.dart';
import 'gwt_starting_resources_screen.dart';
import 'gwt_state.dart';

class GreatWesternTrailNewZealandGame extends GwtEditionGame {
  const GreatWesternTrailNewZealandGame();

  static const idValue = 'great_western_trail_new_zealand';
  static const coverAsset =
      'assets/games/great_western_trail_new_zealand/cover.webp';

  @override
  String get id => idValue;

  @override
  String get name => 'Great Western Trail New Zealand';

  @override
  String? get editionLabel => 'New Zealand';

  @override
  String get l10nPrefix => 'game.gwtnz';

  @override
  String get description =>
      'Run a sheep station on the South Island of New Zealand. Breed better '
      'sheep, raise the value of your wool, and ship it from the harbours to '
      'trading posts around the world.';

  @override
  Color get accentColor => const Color(0xFF2E5E3A);

  @override
  int get minPlayers => 1;

  @override
  String? get released => '2023';

  @override
  String? get coverImageAsset => coverAsset;

  @override
  GwtBuildingArtSet get buildingArtSet => GwtBuildingArtSet.newZealand;

  @override
  bool get includeRailsToTheNorthExpansion => false;

  @override
  int get privateBuildingBaseCount => 10;

  @override
  List<String> get publicBuildingLocations =>
      GwtPublicBuildingsLayout.argentinaLocations;

  @override
  Widget? buildBuildingsRandomizer() {
    return GwtBuildingsRandomizerScreen(game: this);
  }

  @override
  Widget? buildStartingResources() {
    return GwtStartingResourcesScreen(
      game: this,
      setup: GwtStartingSetup.newZealand,
    );
  }

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
      pad: GwtPadKind.newZealand,
    );
  }

  @override
  List<PlayerScore> scores(GameState state) {
    return GwtScoring.scores(state as GwtState, pad: GwtPadKind.newZealand);
  }

  @override
  List<Player> winners(GameState state) {
    return GwtScoring.winners(state as GwtState, pad: GwtPadKind.newZealand);
  }

  @override
  String? scoreFootnote(GameState state) {
    return 'Highest total wins. 5 pounds = 1 VP.';
  }
}
