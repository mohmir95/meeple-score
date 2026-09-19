import 'package:flutter/material.dart';

import 'gwt_building_art.dart';
import 'gwt_buildings_randomizer_screen.dart';
import 'gwt_edition.dart';

class GreatWesternTrailGame extends GwtEditionGame {
  const GreatWesternTrailGame();

  static const idValue = 'great_western_trail_1e';
  static const coverAsset = 'assets/games/great_western_trail/cover.webp';

  @override
  String get id => idValue;

  @override
  String get name => 'Great Western Trail';

  @override
  String get l10nPrefix => 'game.gwt';

  @override
  String? get released => '2016';

  @override
  String? get coverImageAsset => coverAsset;

  @override
  bool get includeThirteenthBuildingExpansion => true;

  @override
  GwtBuildingArtSet get buildingArtSet => GwtBuildingArtSet.firstEdition;

  @override
  Widget? buildBuildingsRandomizer() {
    return GwtBuildingsRandomizerScreen(game: this);
  }
}
