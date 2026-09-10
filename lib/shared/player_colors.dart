import 'package:flutter/material.dart';

import '../domain/models/player.dart';
import 'ids.dart';

class PlayerColorOption {
  const PlayerColorOption({
    required this.name,
    required this.color,
  });

  final String name;
  final Color color;

  int get value => color.toARGB32();
}

const int fallbackPlayerColor = 0xFF607D8B;

Color playerColor(int colorValue) => Color(colorValue);

Color onPlayerColor(int colorValue) {
  return playerColor(colorValue).computeLuminance() > 0.55
      ? const Color(0xFF212121)
      : Colors.white;
}

bool isLightPlayerColor(int colorValue) {
  return playerColor(colorValue).computeLuminance() > 0.7;
}

Color playerColorOutline(int colorValue) {
  return isLightPlayerColor(colorValue)
      ? const Color(0xFF6B7C8A)
      : playerColor(colorValue);
}

bool isPlayerColorSelected(int colorValue, PlayerColorOption option) {
  return colorValue == option.value;
}

int nextColorValue(List<Player> existing, List<PlayerColorOption> palette) {
  if (palette.isEmpty) {
    return fallbackPlayerColor;
  }
  final used = {for (final player in existing) player.colorValue};
  for (final option in palette) {
    if (!used.contains(option.value)) {
      return option.value;
    }
  }
  return palette[existing.length % palette.length].value;
}

List<Player> defaultPlayers({
  required int count,
  required List<PlayerColorOption> palette,
}) {
  final players = <Player>[];
  for (var index = 0; index < count; index++) {
    players.add(
      Player(
        id: newId(),
        name: 'Player ${index + 1}',
        colorValue: nextColorValue(players, palette),
      ),
    );
  }
  return players;
}

Player nextPlayer(
  List<Player> existing,
  List<PlayerColorOption> palette, {
  String? name,
}) {
  return Player(
    id: newId(),
    name: name ?? 'Player ${existing.length + 1}',
    colorValue: nextColorValue(existing, palette),
  );
}
