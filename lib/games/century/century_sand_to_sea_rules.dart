import 'century_eastern_wonders_rules.dart';
import 'century_rules.dart';

/// Numbers from the Century: From Sand to Sea rulebook, which plays the
/// Eastern Wonders map with Spice Road's Merchant cards.
class SandToSeaRules {
  const SandToSeaRules._();

  static const playerCounts = [2, 3, 4];

  /// Spice Road's starting cards: each player takes 2, the rest go back to
  /// the box.
  static int startingCardsToBox(int players) =>
      CenturyRules.startingCards -
      CenturyRules.startingCardsPerPlayer * players;

  static const faceUpMerchantCards = 4;

  /// Market tiles removed: 2 of each of the 4 trade symbols.
  static const marketTilesRemovedPerSymbol = 2;
  static const marketTilesRemoved =
      marketTilesRemovedPerSymbol * EasternWondersRules.tradeSymbols;

  static const seaTiles = 4;
  static const ports = EasternWondersRules.ports;
  static const closedPortAmong = EasternWondersRules.closedPortAmong;
  static const bonusVp = EasternWondersRules.bonusVp;

  static const outpostsPerPlayer = 16;
  static const cargoLimit = 10;

  /// Extra cargo spaces from the cargo bonus tile.
  static const cargoBonus = 3;

  /// Cubes paid per outpost already on a market tile when building.
  static int outpostCostPerOutpost(int players) => players == 2 ? 2 : 1;

  /// Cubes paid to each other boat's owner when ending a move with them.
  static const visitCost = 1;

  static const vpTilesToEnd = EasternWondersRules.vpTilesToEnd;

  static const startingSets = EasternWondersRules.startingSets;
}
