import 'dart:math' as math;

/// One of the 16 Character Cards every player owns a full set of.
class ShelfieCharacter {
  const ShelfieCharacter(this.number);

  final int number;

  String get nameKey => 'shelfie.char.$number.name';
  String get rulesKey => 'shelfie.char.$number.rules';

  String get asset =>
      'assets/games/shelfie_stacker/characters/'
      '${number.toString().padLeft(2, '0')}.jpg';

  static final all = [
    for (var number = 1; number <= 16; number++) ShelfieCharacter(number),
  ];
}

class ShelfieCharacterDeal {
  const ShelfieCharacterDeal._();

  /// Each player keeps 8 of their 16 Character Cards.
  static const handSize = 8;

  /// One hand per player, sorted by card number. Every player has their own
  /// set, so hands may share numbers. The first game uses cards 1–8.
  static List<List<ShelfieCharacter>> deal(
    int players,
    math.Random random, {
    bool firstGame = false,
  }) {
    return [
      for (var p = 0; p < players; p++)
        firstGame ? ShelfieCharacter.all.take(handSize).toList() : _hand(random),
    ];
  }

  static List<ShelfieCharacter> _hand(math.Random random) {
    final deck = List.of(ShelfieCharacter.all)..shuffle(random);
    return deck.take(handSize).toList()
      ..sort((a, b) => a.number.compareTo(b.number));
  }
}
