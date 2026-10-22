import 'dart:math' as math;

/// Leader tokens from the Expedition Leaders expansions.
class ArnakLeader {
  const ArnakLeader(this.id);

  final String id;

  String get asset => 'assets/games/lost_ruins_of_arnak/leaders/$id.png';

  String get l10nKey => 'arnak.leader.$id';

  static const all = [
    ArnakLeader('captain'),
    ArnakLeader('falconer'),
    ArnakLeader('baroness'),
    ArnakLeader('professor'),
    ArnakLeader('explorer'),
    ArnakLeader('mystic'),
    ArnakLeader('journalist'),
    ArnakLeader('engineer'),
  ];

  static ArnakLeader? byId(String? id) {
    for (final leader in all) {
      if (leader.id == id) {
        return leader;
      }
    }
    return null;
  }
}

/// Deals each player a private, unique hand of leaders to choose from.
class ArnakLeaderDraft {
  const ArnakLeaderDraft._();

  /// Most leaders offered to one player.
  static const maxChoices = 3;

  /// Choices per player: up to [maxChoices], fewer when there aren't enough
  /// leaders for everyone (3–4 players get 2 each).
  static int choicesFor(int playerCount) {
    if (playerCount <= 0) {
      return 0;
    }
    final fair = ArnakLeader.all.length ~/ playerCount;
    return fair < maxChoices ? fair : maxChoices;
  }

  /// One hand per player; no leader appears in two hands.
  static List<List<ArnakLeader>> deal(int playerCount, math.Random random) {
    final pool = [...ArnakLeader.all]..shuffle(random);
    final each = choicesFor(playerCount);
    return [
      for (var p = 0; p < playerCount; p++)
        pool.sublist(p * each, (p + 1) * each),
    ];
  }
}
