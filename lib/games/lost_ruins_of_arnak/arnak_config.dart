import '../../domain/models/game_config.dart';

class ArnakConfig extends GameConfig {
  const ArnakConfig();

  @override
  Map<String, dynamic> toJson() => const {};

  factory ArnakConfig.fromJson(Map<String, dynamic> json) {
    return const ArnakConfig();
  }
}
