import 'dart:math' as math;

enum GwtBuildingSide {
  a,
  b;

  String get code => this == a ? 'A' : 'B';
}

/// Private-building setup: each tile uses side A or B, and every player uses
/// the same sides. First Edition has 10 base tiles; Rails to the North adds
/// 11–12 and the 13th Building expansion adds 13. Second Edition has 12 base
/// tiles; Rails to the North adds building 13.
class GwtBuildingsLayout {
  const GwtBuildingsLayout(
    this._baseSides, {
    this.baseCount = 10,
    this.includesRailsToTheNorth = false,
    this.includesThirteenthBuilding = false,
    this.side11,
    this.side12,
    this.side13,
  });

  final int baseCount;
  final List<GwtBuildingSide> _baseSides;
  final bool includesRailsToTheNorth;
  final bool includesThirteenthBuilding;
  final GwtBuildingSide? side11;
  final GwtBuildingSide? side12;
  final GwtBuildingSide? side13;

  /// Extra private buildings added by Rails to the North.
  /// First Edition: 11–12. Second Edition already has 12, so Rails adds 13.
  static List<int> railsExtraNumbersFor(int baseCount) =>
      baseCount >= 12 ? const [13] : const [11, 12];

  List<int> get railsExtraNumbers => railsExtraNumbersFor(baseCount);

  List<int> get visibleNumbers {
    final numbers = [for (var n = 1; n <= baseCount; n++) n];
    if (includesRailsToTheNorth) {
      for (final n in railsExtraNumbers) {
        if (!numbers.contains(n)) {
          numbers.add(n);
        }
      }
    }
    if (includesThirteenthBuilding && !numbers.contains(13)) {
      numbers.add(13);
    }
    return numbers;
  }

  List<GwtBuildingSide> get sides => [
    for (final number in visibleNumbers) sideOf(number),
  ];

  GwtBuildingSide sideOf(int buildingNumber) {
    if (buildingNumber >= 1 && buildingNumber <= baseCount) {
      return _baseSides[buildingNumber - 1];
    }
    return switch (buildingNumber) {
      11 => side11!,
      12 => side12!,
      13 => side13!,
      _ => throw RangeError('Unknown building $buildingNumber'),
    };
  }

  factory GwtBuildingsLayout.random({
    math.Random? random,
    int baseCount = 10,
    bool railsToTheNorth = false,
    bool thirteenthBuilding = false,
  }) {
    final rng = random ?? math.Random();
    GwtBuildingSide roll() =>
        rng.nextBool() ? GwtBuildingSide.a : GwtBuildingSide.b;
    final extras = railsExtraNumbersFor(baseCount);
    final railsAdds13 = railsToTheNorth && extras.contains(13);
    return GwtBuildingsLayout(
      [for (var i = 0; i < baseCount; i++) roll()],
      baseCount: baseCount,
      includesRailsToTheNorth: railsToTheNorth,
      includesThirteenthBuilding: thirteenthBuilding,
      side11: railsToTheNorth && extras.contains(11) ? roll() : null,
      side12: railsToTheNorth && extras.contains(12) ? roll() : null,
      side13: thirteenthBuilding || railsAdds13 ? roll() : null,
    );
  }

  GwtBuildingsLayout withRailsToTheNorth(bool enabled, [math.Random? random]) {
    if (enabled == includesRailsToTheNorth) {
      return this;
    }
    final rng = random ?? math.Random();
    GwtBuildingSide roll() =>
        rng.nextBool() ? GwtBuildingSide.a : GwtBuildingSide.b;
    final extras = railsExtraNumbers;
    return GwtBuildingsLayout(
      _baseSides,
      baseCount: baseCount,
      includesRailsToTheNorth: enabled,
      includesThirteenthBuilding: includesThirteenthBuilding,
      side11: extras.contains(11) && enabled ? (side11 ?? roll()) : side11,
      side12: extras.contains(12) && enabled ? (side12 ?? roll()) : side12,
      side13: extras.contains(13) && enabled ? (side13 ?? roll()) : side13,
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
      baseCount: baseCount,
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
        other.baseCount != baseCount ||
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
    baseCount,
    includesRailsToTheNorth,
    includesThirteenthBuilding,
    Object.hashAll(sides),
  );
}
