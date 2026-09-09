import 'player.dart';

class PlayerScore {
  const PlayerScore({
    required this.player,
    required this.total,
    this.isLeader = false,
  });

  final Player player;
  final int total;
  final bool isLeader;
}
