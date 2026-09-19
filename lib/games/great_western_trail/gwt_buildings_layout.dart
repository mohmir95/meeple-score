import 'dart:math' as math;

enum GwtBuildingSide {
  a,
  b;

  String get code => this == a ? 'A' : 'B';
}

/// First-edition setup: each private building uses side A or B, and every
/// player uses the same sides. Rails to the North adds 11–12; the 13th
/// Building expansion adds 13.
class GwtBuildingsLayout {
  const GwtBuildingsLayout(
    this._baseSides, {
    this.includesRailsToTheNorth = false,
    this.includesThirteenthBuilding = false,
    this.side11,
    this.side12,
    this.side13,
  });

  static const baseCount = 10;

  final List<GwtBuildingSide> _baseSides;
  final bool includesRailsToTheNorth;
  final bool includesThirteenthBuilding;
  final GwtBuildingSide? side11;
  final GwtBuildingSide? side12;
  final GwtBuildingSide? side13;

  List<int> get visibleNumbers => [
    for (var n = 1; n <= baseCount; n++) n,
    if (includesRailsToTheNorth) ...[11, 12],
    if (includesThirteenthBuilding) 13,
  ];

  List<GwtBuildingSide> get sides => [
    for (final number in visibleNumbers) sideOf(number),
  ];

  GwtBuildingSide sideOf(int buildingNumber) {
    return switch (buildingNumber) {
      >= 1 && <= 10 => _baseSides[buildingNumber - 1],
      11 => side11!,
      12 => side12!,
      13 => side13!,
      _ => throw RangeError('Unknown building $buildingNumber'),
    };
  }

  factory GwtBuildingsLayout.random({
    math.Random? random,
    bool railsToTheNorth = false,
    bool thirteenthBuilding = false,
  }) {
    final rng = random ?? math.Random();
    GwtBuildingSide roll() =>
        rng.nextBool() ? GwtBuildingSide.a : GwtBuildingSide.b;
    return GwtBuildingsLayout(
      [for (var i = 0; i < baseCount; i++) roll()],
      includesRailsToTheNorth: railsToTheNorth,
      includesThirteenthBuilding: thirteenthBuilding,
      side11: railsToTheNorth ? roll() : null,
      side12: railsToTheNorth ? roll() : null,
      side13: thirteenthBuilding ? roll() : null,
    );
  }

  GwtBuildingsLayout withRailsToTheNorth(bool enabled, [math.Random? random]) {
    if (enabled == includesRailsToTheNorth) {
      return this;
    }
    final rng = random ?? math.Random();
    GwtBuildingSide roll() =>
        rng.nextBool() ? GwtBuildingSide.a : GwtBuildingSide.b;
    return GwtBuildingsLayout(
      _baseSides,
      includesRailsToTheNorth: enabled,
      includesThirteenthBuilding: includesThirteenthBuilding,
      side11: enabled ? (side11 ?? roll()) : side11,
      side12: enabled ? (side12 ?? roll()) : side12,
      side13: side13,
    );
  }

  GwtBuildingsLayout withThirteenthBuilding(
    bool enabled, [
    math.Random? random,
  ]) {
    if (enabled == includesThirteenthBuilding) {
      return this;
    }
    final rng = random ?? math.Random();
    return GwtBuildingsLayout(
      _baseSides,
      includesRailsToTheNorth: includesRailsToTheNorth,
      includesThirteenthBuilding: enabled,
      side11: side11,
      side12: side12,
      side13: enabled
          ? (side13 ??
                (rng.nextBool() ? GwtBuildingSide.a : GwtBuildingSide.b))
          : side13,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! GwtBuildingsLayout ||
        other.includesRailsToTheNorth != includesRailsToTheNorth ||
        other.includesThirteenthBuilding != includesThirteenthBuilding) {
      return false;
    }
    final numbers = visibleNumbers;
    if (other.visibleNumbers.length != numbers.length) {
      return false;
    }
    for (final number in numbers) {
      if (other.sideOf(number) != sideOf(number)) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    includesRailsToTheNorth,
    includesThirteenthBuilding,
    Object.hashAll(sides),
  );
}
