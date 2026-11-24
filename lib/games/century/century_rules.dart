import 'package:flutter/material.dart';

/// A spice cube colour, in upgrade order.
enum CenturySpice {
  turmeric(Color(0xFFF2B33A)),
  saffron(Color(0xFFD23A2E)),
  cardamom(Color(0xFF5DAA3A)),
  cinnamon(Color(0xFF6B4228));

  const CenturySpice(this.color);

  final Color color;
}

/// Numbers from the Century: Spice Road rulebook.
class CenturyRules {
  const CenturyRules._();

  static const playerCounts = [2, 3, 4, 5];

  static const faceUpPointCards = 5;
  static const faceUpMerchantCards = 6;

  /// Purple-bordered starting cards in the box: a Create 2 and an Upgrade 2
  /// for each of up to 5 players.
  static const startingCards = 10;
  static const startingCardsPerPlayer = 2;

  static int startingCardsToBox(int players) =>
      startingCards - startingCardsPerPlayer * players;

  /// Gold coins above the leftmost point card, and as many silver coins
  /// above the second one.
  static int coinsPerPile(int players) => players * 2;

  static const goldPoints = 3;
  static const silverPoints = 1;

  static const caravanLimit = 10;

  /// The game ends after the round in which a player claims this many point
  /// cards.
  static int pointCardsToEnd(int players) => players <= 3 ? 6 : 5;

  /// Cubes on each caravan by seat (1-based): later seats get a little more.
  static Map<CenturySpice, int> startingSpices(int seat) => switch (seat) {
    1 => const {CenturySpice.turmeric: 3},
    2 || 3 => const {CenturySpice.turmeric: 4},
    _ => const {CenturySpice.turmeric: 3, CenturySpice.saffron: 1},
  };
}

/// Hub tiles of every Century game, in reading order.
const centuryHubTileOrder = [
  'hub-setup-hints',
  'hub-starting-resources',
  'hub-guide',
  'hub-scoring-hints',
];
