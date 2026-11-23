import 'century_rules.dart';

/// Numbers from the Century: A New World rulebook. Cubes use the same four
/// colours as Spice Road, under other goods' names.
class NewWorldRules {
  const NewWorldRules._();

  static const playerCounts = [2, 3, 4];

  /// Goods names of the four cube colours, in upgrade order.
  static const goodsNames = {
    CenturySpice.turmeric: 'corn',
    CenturySpice.saffron: 'meat',
    CenturySpice.cardamom: 'tobacco',
    CenturySpice.cinnamon: 'fur',
  };

  /// Location boards always used, and the three of which one is picked.
  static const fixedBoards = ['A1', 'B1', 'C1'];
  static const choiceBoards = ['D1', 'E1', 'F1'];

  /// Point card marks removed for the player count, besides the white star
  /// cards that are always removed.
  static List<String> pointCardMarksRemoved(int players) => switch (players) {
    2 => const ['3+', '=4'],
    3 => const ['=4'],
    _ => const [],
  };

  static const bonusTilesInPlay = 17;

  static const explorationTiles = 10;

  /// Tiles on the "2-3" locations; with 4 players those stay uncovered.
  static const explorationExtra = 2;

  static int explorationOnTwoThree(int players) =>
      players <= 3 ? explorationExtra : 0;

  static const settlers = 12;

  /// Settlers on the player board at the start; the rest wait in reserve.
  static int settlersOnBoard(int players) => players == 2 ? 7 : 6;

  static const storageLimit = 10;
  static const bonusSpaces = 3;

  /// The game ends after the round in which a player claims this many Point
  /// cards, at any player count.
  static const pointCardsToEnd = 8;

  static const explorationTileVp = 3;

  /// Bonus tile points: per icon, per pair of icons, per 2 settlers, and a
  /// flat tile with no requirement.
  static const bonusPerIcon = 2;
  static const bonusPerPair = 3;
  static const bonusPerTwoSettlers = 1;
  static const bonusFlat = 3;

  /// Cubes by seat: the same as Spice Road, up to 4 players.
  static Map<CenturySpice, int> startingCubes(int seat) =>
      CenturyRules.startingSpices(seat);
}
