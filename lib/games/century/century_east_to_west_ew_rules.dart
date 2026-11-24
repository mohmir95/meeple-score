import 'century_new_world_rules.dart';

/// Numbers from the Century: From East to West (Eastern Wonders + A New World) rulebook, which
/// plays the A New World board with an Eastern Wonders island map.
class EastToWestEwRules {
  const EastToWestEwRules._();

  static const playerCounts = NewWorldRules.playerCounts;

  /// Location boards, laid out as a 2×2 square: A2 B2 on top, C1 F2 below.
  static const boards = [
    ['A2', 'B2'],
    ['C1', 'F2'],
  ];

  static List<String> pointCardMarksRemoved(int players) =>
      NewWorldRules.pointCardMarksRemoved(players);

  /// Bonus tiles left after removing the ones marked I or III.
  static const bonusTilesInPlay = 17;

  static const explorationTiles = NewWorldRules.explorationTiles;

  /// One on every location with an Exploration icon.
  static const explorationOnIcons = 7;

  /// Tiles on the "2-3" locations: 2 with 2 or 3 players, none with 4.
  static int explorationOnTwoThree(int players) => players <= 3 ? 2 : 0;

  static int explorationToBox(int players) =>
      explorationTiles - explorationOnIcons - explorationOnTwoThree(players);

  /// Market tiles of each trade symbol around the one Sea tile.
  static const marketTilesPerSymbol = 3;
  static const tradeSymbols = 4;
  static const marketTiles = marketTilesPerSymbol * tradeSymbols;

  static const outpostsPerPlayer = 12;

  /// Side B of the player board.
  static const bonusSpaces = 4;

  /// Cubes paid per outpost already on a market tile when building.
  static int outpostCostPerOutpost(int players) => players == 2 ? 2 : 1;

  /// Cubes paid to each other boat's owner where your boat stops.
  static const visitCost = 1;

  static const pointCardsToEnd = NewWorldRules.pointCardsToEnd;
  static const storageLimit = NewWorldRules.storageLimit;
}
