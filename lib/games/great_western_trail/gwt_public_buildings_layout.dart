import 'dart:math' as math;

/// Neutral/public buildings A–G, placed on the matching board spaces.
/// A first game puts each tile on its own letter; later games shuffle them.
class GwtPublicBuildingsLayout {
  const GwtPublicBuildingsLayout(this.tiles);

  static const locations = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];

  /// Public building tile on each board space, in A–G order.
  final List<String> tiles;

  String tileOn(String location) => tiles[locations.indexOf(location)];

  factory GwtPublicBuildingsLayout.firstGame() {
    return const GwtPublicBuildingsLayout(locations);
  }

  factory GwtPublicBuildingsLayout.random([math.Random? random]) {
    final rng = random ?? math.Random();
    final tiles = [...locations]..shuffle(rng);
    return GwtPublicBuildingsLayout(List.unmodifiable(tiles));
  }

  @override
  bool operator ==(Object other) {
    if (other is! GwtPublicBuildingsLayout || other.tiles.length != tiles.length) {
      return false;
    }
    for (var i = 0; i < tiles.length; i++) {
      if (other.tiles[i] != tiles[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(tiles);
}
