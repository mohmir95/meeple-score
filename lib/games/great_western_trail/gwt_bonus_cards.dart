import 'dart:math' as math;

/// The 4 bonus cards tiles next to the sea routes board (New Zealand), from
/// the lowest drawn set to the highest.
enum GwtBonusTile {
  steeringWheel('steeringWheel', 'steering-wheel'),
  barrel('barrel', 'barrel'),
  bell('bell', 'bell'),
  compass('compass', 'compass');

  const GwtBonusTile(this.key, this._file);

  final String key;
  final String _file;

  String get asset => '${GwtBonusCardsSupply.assetRoot}/$_file.png';
}

/// Setup step 12: draw 4 of the 10 bonus card sets and stack them, lowest set
/// number first, below the steering wheel, barrel, bell, and compass tiles.
class GwtBonusCardsSupply {
  GwtBonusCardsSupply(List<int> sets) : sets = List.unmodifiable(sets) {
    assert(sets.length == GwtBonusTile.values.length);
  }

  static const assetRoot =
      'assets/games/great_western_trail_new_zealand/bonus_cards';
  static const setCount = 10;
  static const cardsInSet = 6;

  /// Set numbers in tile order, so always ascending.
  final List<int> sets;

  factory GwtBonusCardsSupply.random(math.Random random) {
    final all = [for (var set = 1; set <= setCount; set++) set]
      ..shuffle(random);
    return GwtBonusCardsSupply(
      all.take(GwtBonusTile.values.length).toList()..sort(),
    );
  }

  /// Cards per stack, the starred card included.
  static int cardsPerSet(int players) => switch (players) {
    <= 2 => 3,
    3 => 5,
    _ => cardsInSet,
  };

  static String cardAsset(int set) => '$assetRoot/set-$set.jpg';

  /// Card photo size; the corners are rounded when drawn.
  static const cardAspectRatio = 360 / 545;

  int setFor(GwtBonusTile tile) => sets[tile.index];
}
