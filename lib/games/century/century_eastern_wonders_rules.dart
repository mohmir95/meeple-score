import 'century_rules.dart';

/// Numbers from the Century: Eastern Wonders rulebook. Cubes use the same
/// four colours as Spice Road, under other spice names.
class EasternWondersRules {
  const EasternWondersRules._();

  /// Spice names of the four cube colours, in upgrade order.
  static const spiceNames = {
    CenturySpice.turmeric: 'ginger',
    CenturySpice.saffron: 'chili',
    CenturySpice.cardamom: 'tea',
    CenturySpice.cinnamon: 'cloves',
  };

  /// One market tile of each trade symbol goes back to the box.
  static const tradeSymbols = 4;

  static const ports = 4;

  /// The Closed Port tile is shuffled into this many VP tiles from the top
  /// of the pile.
  static const closedPortAmong = 5;

  /// Bonus VP tiles, stacked with the 6 on top.
  static const bonusVp = [6, 5, 4, 3];

  static const outpostsPerPlayer = 20;
  static const cargoLimit = 10;

  /// The game ends after the round in which a player claims this many VP
  /// tiles, at any player count.
  static const vpTilesToEnd = 4;

  /// Bonus tiles that also score at the end of the game.
  static const harvestBonusVp = 1;
  static const upgradeBonusVp = 2;

  /// The starting cube sets; in reverse turn order each player takes one.
  static const startingSets = <Map<CenturySpice, int>>[
    {CenturySpice.turmeric: 4},
    {CenturySpice.turmeric: 2, CenturySpice.saffron: 1},
    {CenturySpice.saffron: 2},
    {CenturySpice.turmeric: 1, CenturySpice.cardamom: 1},
  ];
}
