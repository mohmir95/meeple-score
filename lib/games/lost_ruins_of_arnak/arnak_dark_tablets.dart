import '../../domain/models/player.dart';

/// Per-player dark tablet results for the Spider Temple ("The Cost of
/// Ambition") end-game scoring.
class DarkTabletResult {
  const DarkTabletResult({
    required this.altarPoints,
    required this.usedTablets,
    required this.pointsPerTablet,
  });

  /// VP won from altar majorities.
  final int altarPoints;

  /// Dark tablets this player placed on altars.
  final int usedTablets;

  /// Negative VP each used tablet costs (0 if no supply space is empty).
  final int pointsPerTablet;

  int get tabletPoints => usedTablets * pointsPerTablet;

  int get total => altarPoints + tabletPoints;
}

/// Altars and dark tablet supply rules for the Spider Temple.
class ArnakDarkTablets {
  const ArnakDarkTablets._();

  /// VP printed above each altar.
  static const altarValues = [2, 2, 3, 3, 4];

  /// Research track row each altar sits on, matching [altarValues].
  static const altarRows = [1, 2, 3, 5, 6];

  /// Most tablets one player can place on a single altar.
  static const maxPerAltar = 3;

  /// Negative VP printed on each dark tablet supply space, left to right.
  static const spacePenalties = [-1, -2, -2, -3, -3, -4, -5];

  /// Each supply space holds as many tablets as there are players.
  static int supplySize(int playerCount) => spacePenalties.length * playerCount;

  /// Tablets [playerId] placed on each altar, padded to [altarValues].
  static List<int> countsFor(Map<String, List<int>> altars, String playerId) {
    final counts = altars[playerId] ?? const [];
    return [
      for (var i = 0; i < altarValues.length; i++)
        i < counts.length ? counts[i].clamp(0, maxPerAltar) : 0,
    ];
  }

  static int usedBy(Map<String, List<int>> altars, String playerId) {
    return countsFor(altars, playerId).fold(0, (sum, n) => sum + n);
  }

  static int totalUsed(List<Player> players, Map<String, List<int>> altars) {
    return players.fold(0, (sum, p) => sum + usedBy(altars, p.id));
  }

  /// Supply spaces fully emptied by the tablets placed on altars.
  static int emptiedSpaces(
    List<Player> players,
    Map<String, List<int>> altars,
  ) {
    if (players.isEmpty) {
      return 0;
    }
    final emptied = totalUsed(players, altars) ~/ players.length;
    return emptied.clamp(0, spacePenalties.length);
  }

  /// The rightmost empty space sets the cost of every used tablet.
  static int pointsPerTablet(
    List<Player> players,
    Map<String, List<int>> altars,
  ) {
    final emptied = emptiedSpaces(players, altars);
    return emptied == 0 ? 0 : spacePenalties[emptied - 1];
  }

  /// Players with the most tablets on [altar]; ties all win. Empty if nobody
  /// placed a tablet there.
  static List<Player> altarWinners(
    List<Player> players,
    Map<String, List<int>> altars,
    int altar,
  ) {
    var best = 0;
    for (final player in players) {
      final n = countsFor(altars, player.id)[altar];
      if (n > best) {
        best = n;
      }
    }
    if (best == 0) {
      return const [];
    }
    return [
      for (final player in players)
        if (countsFor(altars, player.id)[altar] == best) player,
    ];
  }

  static Map<String, DarkTabletResult> results(
    List<Player> players,
    Map<String, List<int>> altars,
  ) {
    final altarPoints = {for (final player in players) player.id: 0};
    for (var altar = 0; altar < altarValues.length; altar++) {
      for (final winner in altarWinners(players, altars, altar)) {
        altarPoints[winner.id] = altarPoints[winner.id]! + altarValues[altar];
      }
    }
    final perTablet = pointsPerTablet(players, altars);
    return {
      for (final player in players)
        player.id: DarkTabletResult(
          altarPoints: altarPoints[player.id]!,
          usedTablets: usedBy(altars, player.id),
          pointsPerTablet: perTablet,
        ),
    };
  }
}
