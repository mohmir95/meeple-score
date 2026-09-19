import 'gwt_buildings_layout.dart';

abstract final class GwtBuildingArt {
  static const _root = 'assets/games/great_western_trail/buildings';

  static String? private(int number, GwtBuildingSide side) {
    if (number < 1 || number > 13) {
      return null;
    }
    return '$_root/private/$number${side.code.toLowerCase()}.jpg';
  }

  static String public(String tile) => '$_root/public/${tile.toLowerCase()}.jpg';
}
