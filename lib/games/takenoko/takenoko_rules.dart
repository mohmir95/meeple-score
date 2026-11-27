import 'package:flutter/material.dart';

/// The three objective decks, with their card back colours.
enum TakenokoObjective {
  plot(Color(0xFF3F6FB5)),
  gardener(Color(0xFFB8322E)),
  panda(Color(0xFF7A5A9E));

  const TakenokoObjective(this.color);

  final Color color;
}

/// Numbers from the Takenoko rulebook (same in both editions).
class TakenokoRules {
  const TakenokoRules._();

  static const playerCounts = [2, 3, 4];

  /// Completing this many objectives starts the last round.
  static int objectivesToEnd(int players) => switch (players) {
    2 => 9,
    3 => 8,
    _ => 7,
  };

  /// Plot tiles besides the pond, shuffled into the draw pile.
  static const plots = 27;
  static const irrigationChannels = 20;
  static const improvements = 9;
  static const actionTokensPerPlayer = 2;

  static const emperorPoints = 2;

  static const handLimit = 5;

  /// The Emperor card's green back.
  static const emperorColor = Color(0xFF7DB843);
}
