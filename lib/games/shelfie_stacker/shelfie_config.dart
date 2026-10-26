import '../../domain/models/game_config.dart';

class ShelfieConfig extends GameConfig {
  const ShelfieConfig();

  @override
  Map<String, dynamic> toJson() => const {};

  factory ShelfieConfig.fromJson(Map<String, dynamic> json) {
    return const ShelfieConfig();
  }
}
