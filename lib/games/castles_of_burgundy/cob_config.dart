import '../../domain/models/game_config.dart';

class CobConfig extends GameConfig {
  const CobConfig();

  @override
  Map<String, dynamic> toJson() => const {};

  factory CobConfig.fromJson(Map<String, dynamic> json) {
    return const CobConfig();
  }
}
