import 'package:flutter/material.dart';

import '../../domain/models/player.dart';
import '../player_colors.dart';
import 'primary_button.dart';

class PlayerEditor extends StatelessWidget {
  const PlayerEditor({
    super.key,
    required this.players,
    required this.onChanged,
    required this.minPlayers,
    required this.maxPlayers,
    this.colorOptions = const [],
    this.uniqueColors = false,
    this.readOnly = false,
  });

  final List<Player> players;
  final ValueChanged<List<Player>> onChanged;
  final int minPlayers;
  final int maxPlayers;
  final List<PlayerColorOption> colorOptions;
  final bool uniqueColors;
  final bool readOnly;

  void _rename(int index, String name) {
    final next = [...players];
    next[index] = next[index].copyWith(name: name);
    onChanged(next);
  }

  void _remove(int index) {
    if (players.length <= minPlayers) {
      return;
    }
    final next = [...players]..removeAt(index);
    onChanged(next);
  }

  void _add() {
    if (players.length >= maxPlayers) {
      return;
    }
    onChanged([...players, nextPlayer(players, colorOptions)]);
  }

  void _setColor(int index, int colorValue) {
    if (readOnly || players[index].colorValue == colorValue) {
      return;
    }
    final next = [...players];
    final takenBy = next.indexWhere((player) => player.colorValue == colorValue);
    final previous = next[index].colorValue;
    next[index] = next[index].copyWith(colorValue: colorValue);
    if (takenBy != -1 && takenBy != index && uniqueColors) {
      next[takenBy] = next[takenBy].copyWith(colorValue: previous);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Players', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (var i = 0; i < players.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: playerColor(players[i].colorValue),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: onPlayerColor(players[i].colorValue),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey(players[i].id),
                        initialValue: players[i].name,
                        enabled: !readOnly,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Player ${i + 1}',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) => _rename(i, value),
                      ),
                    ),
                    if (!readOnly)
                      IconButton(
                        tooltip: 'Remove player',
                        onPressed:
                            players.length > minPlayers ? () => _remove(i) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                  ],
                ),
                if (colorOptions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        for (final option in colorOptions)
                          _ColorSwatch(
                            option: option,
                            selected: isPlayerColorSelected(
                              players[i].colorValue,
                              option,
                            ),
                            onTap: readOnly ? null : () => _setColor(i, option.value),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        if (!readOnly)
          PrimaryButton(
            label: players.length >= maxPlayers
                ? 'Player limit reached'
                : 'Add player',
            icon: Icons.person_add_alt_1,
            onPressed: players.length >= maxPlayers ? null : _add,
          ),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final PlayerColorOption option;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    return Tooltip(
      message: option.name,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: option.color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : outline,
              width: selected ? 3 : 1,
            ),
          ),
          child: selected
              ? Icon(
                  Icons.check,
                  size: 20,
                  color: onPlayerColor(option.value),
                )
              : null,
        ),
      ),
    );
  }
}
