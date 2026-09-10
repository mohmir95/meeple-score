import 'package:flutter/material.dart';

import '../../domain/models/player.dart';
import '../../l10n/l10n_scope.dart';
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

  void _add(BuildContext context) {
    if (players.length >= maxPlayers) {
      return;
    }
    onChanged([
      ...players,
      nextPlayer(
        players,
        colorOptions,
        name: context.l10n.t('players.numbered', {
          'n': '${players.length + 1}',
        }),
      ),
    ]);
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

  String _colorName(BuildContext context, int colorValue) {
    final l10n = context.l10n;
    for (final option in colorOptions) {
      if (option.value == colorValue) {
        return l10n.colorLabel(option.name);
      }
    }
    return l10n.t('players.color');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.t('players.title'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (var i = 0; i < players.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                _PlayerColorBadge(
                  number: i + 1,
                  colorValue: players[i].colorValue,
                  colorName: _colorName(context, players[i].colorValue),
                  options: colorOptions,
                  enabled: !readOnly && colorOptions.isNotEmpty,
                  onSelected: (value) => _setColor(i, value),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: ValueKey(players[i].id),
                    initialValue: players[i].name,
                    enabled: !readOnly,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.t('players.fieldLabel', {'n': '${i + 1}'}),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) => _rename(i, value),
                  ),
                ),
                if (!readOnly)
                  IconButton(
                    tooltip: l10n.t('players.remove'),
                    onPressed:
                        players.length > minPlayers ? () => _remove(i) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
              ],
            ),
          ),
        if (!readOnly)
          PrimaryButton(
            label: players.length >= maxPlayers
                ? l10n.t('players.limitReached')
                : l10n.t('players.add'),
            icon: Icons.person_add_alt_1,
            onPressed: players.length >= maxPlayers ? null : () => _add(context),
          ),
      ],
    );
  }
}

class _PlayerColorBadge extends StatelessWidget {
  const _PlayerColorBadge({
    required this.number,
    required this.colorValue,
    required this.colorName,
    required this.options,
    required this.enabled,
    required this.onSelected,
  });

  final int number;
  final int colorValue;
  final String colorName;
  final List<PlayerColorOption> options;
  final bool enabled;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final fill = playerColor(colorValue);
    final badge = Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(
          color: playerColorOutline(colorValue),
          width: isLightPlayerColor(colorValue) ? 1.5 : 0,
        ),
      ),
      child: Text(
        '$number',
        style: TextStyle(
          color: onPlayerColor(colorValue),
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    if (!enabled) {
      return Tooltip(message: colorName, child: badge);
    }

    return PopupMenuButton<int>(
      tooltip: colorName,
      position: PopupMenuPosition.under,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem(
            value: option.value,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: option.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: playerColorOutline(option.value),
                      width: isLightPlayerColor(option.value) ? 1.5 : 0,
                    ),
                  ),
                  child: option.value == colorValue
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: onPlayerColor(option.value),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Text(context.l10n.colorLabel(option.name)),
              ],
            ),
          ),
      ],
      child: badge,
    );
  }
}
