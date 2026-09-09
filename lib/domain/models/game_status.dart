enum GameStatus {
  inProgress,
  finished;

  static GameStatus fromName(String? name) {
    return GameStatus.values.firstWhere(
      (value) => value.name == name,
      orElse: () => GameStatus.inProgress,
    );
  }
}
