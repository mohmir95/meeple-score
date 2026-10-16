import 'package:flutter/material.dart';

import '../../shared/player_colors.dart';

/// Player pieces in the Special Edition, in seat order.
///
/// A game starts with red and blue. Yellow and purple are the seats added
/// after that. Each player takes the board, dice, turn-order marker, and
/// victory-point marker in that color. White is the extra die, not a player
/// color.
const cobPlayerColors = <PlayerColorOption>[
  PlayerColorOption(name: 'Red', color: Color(0xFFC0392B)),
  PlayerColorOption(name: 'Blue', color: Color(0xFF2E86C1)),
  PlayerColorOption(name: 'Yellow', color: Color(0xFFE6A817)),
  PlayerColorOption(name: 'Purple', color: Color(0xFF6A3D9A)),
];
