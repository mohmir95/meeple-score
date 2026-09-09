class GameSession {
  const GameSession({
    required this.gameId,
    required this.createdAt,
    required this.updatedAt,
    required this.stateJson,
  });

  final String gameId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> stateJson;

  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'state': stateJson,
    };
  }

  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      gameId: json['gameId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      stateJson: Map<String, dynamic>.from(json['state'] as Map),
    );
  }
}
