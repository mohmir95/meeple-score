import '../../domain/json_values.dart';

/// One player's pad entries. Columns and dice are stored as counts; the pad
/// shows the points they are worth.
class ShelfiePlayerLine {
  const ShelfiePlayerLine({
    this.fiveTall = 0,
    this.fourTall = 0,
    this.threeTall = 0,
    this.pips = 0,
    this.rewards = 0,
    this.shameDice = 0,
  });

  /// The Big Shelf has five columns.
  static const columns = 5;

  /// Highest pip total: a 6 on top of every column.
  static const maxPips = columns * 6;

  /// Columns exactly 5 dice tall (6 points each).
  final int fiveTall;

  /// Columns exactly 4 dice tall (3 points each).
  final int fourTall;

  /// Columns exactly 3 dice tall (1 point each).
  final int threeTall;

  /// Pips on the top-most die of each Big Shelf column.
  final int pips;

  /// Points from Reward Cards and other bonuses.
  final int rewards;

  /// Dice in the Shelf of Shame (−2 points each).
  final int shameDice;

  /// Columns already counted in one of the 5/4/3-tall rows.
  int get scoredColumns => fiveTall + fourTall + threeTall;

  bool get isEmpty =>
      fiveTall == 0 &&
      fourTall == 0 &&
      threeTall == 0 &&
      pips == 0 &&
      rewards == 0 &&
      shameDice == 0;

  ShelfiePlayerLine copyWith({
    int? fiveTall,
    int? fourTall,
    int? threeTall,
    int? pips,
    int? rewards,
    int? shameDice,
  }) {
    return ShelfiePlayerLine(
      fiveTall: fiveTall ?? this.fiveTall,
      fourTall: fourTall ?? this.fourTall,
      threeTall: threeTall ?? this.threeTall,
      pips: pips ?? this.pips,
      rewards: rewards ?? this.rewards,
      shameDice: shameDice ?? this.shameDice,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fiveTall': fiveTall,
      'fourTall': fourTall,
      'threeTall': threeTall,
      'pips': pips,
      'rewards': rewards,
      'shameDice': shameDice,
    };
  }

  factory ShelfiePlayerLine.fromJson(Map<String, dynamic> json) {
    return ShelfiePlayerLine(
      fiveTall: readInt(json['fiveTall']),
      fourTall: readInt(json['fourTall']),
      threeTall: readInt(json['threeTall']),
      pips: readInt(json['pips']),
      rewards: readInt(json['rewards']),
      shameDice: readInt(json['shameDice']),
    );
  }
}
