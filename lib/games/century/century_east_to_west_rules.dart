import 'century_new_world_rules.dart';

/// Numbers from the Century: From East to West (Part I) rulebook, which
/// plays the A New World board with Spice Road's Merchant cards.
class EastToWestRules {
  const EastToWestRules._();

  static const playerCounts = NewWorldRules.playerCounts;

  /// Location boards, laid out as a 2×2 square: A1 B1 on top, E2 C2 below.
  static const boards = [
    ['A1', 'B1'],
    ['E2', 'C2'],
  ];

  static List<String> pointCardMarksRemoved(int players) =>
      NewWorldRules.pointCardMarksRemoved(players);

  /// Bonus tiles left after removing the ones marked III.
  static const bonusTilesInPlay = 20;

  static const explorationTiles = NewWorldRules.explorationTiles;

  /// With 2 or 3 players, 2 Exploration tiles cover the "2-3" locations;
  /// every other tile waits beside the board.
  static int explorationOnBoard(int players) =>
      NewWorldRules.explorationOnTwoThree(players);

  static int explorationBeside(int players) =>
      explorationTiles - explorationOnBoard(players);

  static const marketLocations = 4;

  /// The trade route below your player board holds at most this many cards.
  static const tradeRouteLimit = 5;

  /// The new bonus tile: points for every 2 Merchant cards you have.
  static const merchantBonusVp = 2;

  static const pointCardsToEnd = NewWorldRules.pointCardsToEnd;
  static const storageLimit = NewWorldRules.storageLimit;

  /// Settlers needed to use a trade route card: 1, plus 1 for each card
  /// without settlers to its left.
  static int routeSettlers(int emptyCardsToTheLeft) => 1 + emptyCardsToTheLeft;
}
