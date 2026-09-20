import 'dart:math' as math;

/// Neutral/public buildings placed on the matching board spaces.
/// First and Second Edition use A–G; Argentina uses A–H.
/// A first game puts each tile on its own letter; later games shuffle them.
class GwtPublicBuildingsLayout {
  const GwtPublicBuildingsLayout(
    this.tiles, {
    this.locations = classicLocations,
  });

  static const classicLocations = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
  static const argentinaLocations = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];

  /// Board spaces in letter order.
  final List<String> locations;

  /// Public building tile on each board space, in [locations] order.
  final List<String> tiles;

  String tileOn(String location) => tiles[locations.indexOf(location)];

  factory GwtPublicBuildingsLayout.firstGame({
    List<String> locations = classicLocations,
  }) {
    return GwtPublicBuildingsLayout(locations, locations: locations);
  }

  factory GwtPublicBuildingsLayout.random([
    math.Random? random,
    List<String> locations = classicLocations,
  ]) {
    final rng = random ?? math.Random();
    final tiles = [...locations]..shuffle(rng);
    return GwtPublicBuildingsLayout(
      List.unmodifiable(tiles),
      locations: locations,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! GwtPublicBuildingsLayout ||
        other.tiles.length != tiles.length ||
        other.locations.length != locations.length) {
      return false;
    }
    for (var i = 0; i < locations.length; i++) {
      if (other.locations[i] != locations[i]) {
        return false;
      }
    }
    for (var i = 0; i < tiles.length; i++) {
      if (other.tiles[i] != tiles[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(locations), Object.hashAll(tiles));
}
