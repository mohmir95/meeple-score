import 'gwt_buildings_layout.dart';

enum GwtBuildingArtSet { firstEdition, secondEdition }

abstract final class GwtBuildingArt {
  static const _root = 'assets/games/great_western_trail/buildings';
  static const _secondRoot = 'assets/games/great_western_trail_2e/buildings';
  static const placeholderAsset = '$_root/placeholder.jpg';

  static String? private(
    int number,
    GwtBuildingSide side, {
    GwtBuildingArtSet artSet = GwtBuildingArtSet.firstEdition,
  }) {
    if (artSet == GwtBuildingArtSet.secondEdition) {
      if (number >= 1 && number <= 13) {
        return '$_secondRoot/private/$number${side.code.toLowerCase()}.jpg';
      }
      return placeholderAsset;
    }
    if (number < 1 || number > 13) {
      return null;
    }
    return '$_root/private/$number${side.code.toLowerCase()}.jpg';
  }

  static String public(
    String tile, {
    GwtBuildingArtSet artSet = GwtBuildingArtSet.firstEdition,
  }) {
    if (artSet == GwtBuildingArtSet.secondEdition) {
      return '$_secondRoot/public/${tile.toLowerCase()}.jpg';
    }
    return '$_root/public/${tile.toLowerCase()}.jpg';
  }
}
