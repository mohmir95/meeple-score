import '../../domain/models/game_config.dart';

class GwtConfig extends GameConfig {
  const GwtConfig();

  @override
  Map<String, dynamic> toJson() => const {};

  factory GwtConfig.fromJson(Map<String, dynamic> json) {
    return const GwtConfig();
  }
}
