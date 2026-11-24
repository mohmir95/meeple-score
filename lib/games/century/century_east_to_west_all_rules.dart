import 'century_east_to_west_ew_rules.dart';
import 'century_new_world_rules.dart';

/// Numbers from the Century: From East to West (Spice Road + Eastern Wonders + A New World) rulebook:
/// the A New World board with Spice Road's Merchant cards and an Eastern
/// Wonders island map.
class EastToWestAllRules {
  const EastToWestAllRules._();

  static const playerCounts = NewWorldRules.playerCounts;

  /// Location boards: A2 B2 E2 D2 on top, C1 F2 below A2 and B2.
  static const boards = [
    ['A2', 'B2', 'E2', 'D2'],
    ['C1', 'F2'],
  ];

  static List<String> pointCardMarksRemoved(int players) =>
      NewWorldRules.pointCardMarksRemoved(players);

  /// Every Bonus tile is shuffled; the one left over goes back to the box.
  static const bonusTiles = 25;

  static const explorationTiles = EastToWestEwRules.explorationTiles;
  static const explorationOnIcons = EastToWestEwRules.explorationOnIcons;

  static int explorationOnTwoThree(int players) =>
      EastToWestEwRules.explorationOnTwoThree(players);

  static int explorationToBox(int players) =>
      EastToWestEwRules.explorationToBox(players);

  static const marketLocations = 4;
  static const marketTilesPerSymbol = EastToWestEwRules.marketTilesPerSymbol;
  static const marketTiles = EastToWestEwRules.marketTiles;

  /// Every this many Merchant cards taken earns a Bonus tile from board D2.
  static const merchantCardsPerBonus = 4;

  static const bonusSpaces = EastToWestEwRules.bonusSpaces;
  static const outpostsPerPlayer = EastToWestEwRules.outpostsPerPlayer;

  static int outpostCostPerOutpost(int players) =>
      EastToWestEwRules.outpostCostPerOutpost(players);

  static const visitCost = EastToWestEwRules.visitCost;
  static const pointCardsToEnd = NewWorldRules.pointCardsToEnd;
  static const storageLimit = NewWorldRules.storageLimit;
}
