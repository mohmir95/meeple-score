import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../player_colors.dart';
import 'player_editor.dart';

/// A row of numbered player color badges with add/remove buttons, used by
/// randomizers that only need a player count and colors (no names).
class PlayerColorRoster extends StatelessWidget {
  const PlayerColorRoster({
    super.key,
    required this.colors,
    required this.options,
    required this.accent,
    required this.keyPrefix,
    required this.onAdd,
    required this.onRemove,
    required this.onColor,
    this.minPlayers = 1,
    this.showCountControls = true,
    this.showNumbers = true,
  });

  /// Each player's color, in seat order.
  final List<PlayerColorOption> colors;

  /// Colors players can pick from; also caps the player count.
  final List<PlayerColorOption> options;
  final Color accent;

  /// Keys become `$keyPrefix-color-$i`, `$keyPrefix-add-player` and
  /// `$keyPrefix-remove-player`.
  final String keyPrefix;
  final ValueChanged<int> onAdd;
  final VoidCallback onRemove;
  final void Function(int index, int colorValue) onColor;
  final int minPlayers;
  final bool showCountControls;

  /// False shows plain color circles, for pages that name players by color.
  final bool showNumbers;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < colors.length; i++)
          PlayerColorBadge(
            key: ValueKey('$keyPrefix-color-$i'),
            number: i + 1,
            showNumber: showNumbers,
            colorValue: colors[i].value,
            colorName: l10n.colorLabel(colors[i].name),
            options: options,
            enabled: true,
            onSelected: (value) => onColor(i, value),
          ),
        if (showCountControls && colors.length < options.length)
          _AddPlayerButton(
            key: ValueKey('$keyPrefix-add-player'),
            options: options,
            used: {for (final color in colors) color.value},
            accent: accent,
            onSelected: onAdd,
          ),
        if (showCountControls && colors.length > minPlayers)
          _PlayerCountButton(
            key: ValueKey('$keyPrefix-remove-player'),
            tooltip: l10n.t('players.remove'),
            icon: Icons.remove,
            accent: accent,
            onPressed: onRemove,
          ),
      ],
    );
  }
}

class _AddPlayerButton extends StatelessWidget {
  const _AddPlayerButton({
    super.key,
    required this.options,
    required this.used,
    required this.accent,
    required this.onSelected,
  });

  final List<PlayerColorOption> options;
  final Set<int> used;
  final Color accent;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final remaining = [
      for (final option in options)
        if (!used.contains(option.value)) option,
    ];
    if (remaining.length == 1) {
      return _PlayerCountButton(
        tooltip: l10n.t('players.add'),
        icon: Icons.add,
        accent: accent,
        onPressed: () => onSelected(remaining.single.value),
      );
    }
    return PopupMenuButton<int>(
      tooltip: l10n.t('players.add'),
      position: PopupMenuPosition.under,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final option in remaining)
          PopupMenuItem(
            value: option.value,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: option.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: playerColorOutline(option.value),
                      width: isLightPlayerColor(option.value) ? 1.5 : 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(l10n.colorLabel(option.name)),
              ],
            ),
          ),
      ],
      child: _PlayerCircle(icon: Icons.add, accent: accent),
    );
  }
}

class _PlayerCountButton extends StatelessWidget {
  const _PlayerCountButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.accent,
    this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color accent;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: _PlayerCircle(icon: icon, accent: accent),
        ),
      ),
    );
  }
}

class _PlayerCircle extends StatelessWidget {
  const _PlayerCircle({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accent, width: 1.5),
      ),
      child: Icon(icon, color: accent),
    );
  }
}
