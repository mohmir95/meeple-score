import 'package:flutter/material.dart';

import '../../domain/models/player.dart';
import '../../l10n/l10n_scope.dart';
import '../../shared/player_colors.dart';
import 'arnak_config.dart';
import 'arnak_leaders.dart';

/// A leader token, ringed in the player's color.
class ArnakLeaderPortrait extends StatelessWidget {
  const ArnakLeaderPortrait({
    super.key,
    required this.leader,
    required this.size,
    this.colorValue,
  });

  final ArnakLeader leader;
  final double size;

  /// Player color for the ring; none when `null`.
  final int? colorValue;

  @override
  Widget build(BuildContext context) {
    final ring = colorValue;
    return Tooltip(
      message: context.l10n.t(leader.l10nKey),
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(ring == null ? 0 : size * 0.07),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ring == null ? null : playerColor(ring),
        ),
        child: ClipOval(
          child: Image.asset(
            leader.asset,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}

/// Setup toggle for playing with leaders.
class ArnakLeadersToggle extends StatelessWidget {
  const ArnakLeadersToggle({
    super.key,
    required this.config,
    required this.onChanged,
  });

  final ArnakConfig config;
  final ValueChanged<ArnakConfig> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        key: const ValueKey('arnak-leaders-toggle'),
        value: config.leadersEnabled,
        onChanged: (on) => onChanged(config.copyWith(leadersEnabled: on)),
        secondary: SizedBox(
          width: 56,
          height: 36,
          child: Stack(
            children: [
              for (var i = 0; i < 3; i++)
                Positioned(
                  left: i * 10.0,
                  child: ArnakLeaderPortrait(
                    leader: ArnakLeader.all[i * 2],
                    size: 36,
                  ),
                ),
            ],
          ),
        ),
        title: Text(
          l10n.t('arnak.leaders'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(l10n.t('arnak.leadersHint')),
      ),
    );
  }
}

/// Per-player leader pick shown next to the color badge in setup.
class ArnakLeaderPicker extends StatelessWidget {
  const ArnakLeaderPicker({
    super.key,
    required this.config,
    required this.players,
    required this.index,
    this.size = 44,
    required this.onChanged,
  });

  final ArnakConfig config;
  final List<Player> players;
  final int index;
  final ValueChanged<ArnakConfig> onChanged;

  /// Diameter of the portrait (or empty pick circle).
  final double size;

  static const _none = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final player = players[index];
    final current = config.leaderFor(player.id);
    final owners = {
      for (final other in players)
        if (other.id != player.id && config.leaderFor(other.id) != null)
          config.leaderFor(other.id)!.id: other,
    };

    final Widget face = current == null
        ? Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.person_search_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )
        : ArnakLeaderPortrait(
            leader: current,
            size: size,
            colorValue: player.colorValue,
          );

    return PopupMenuButton<String>(
      key: ValueKey('arnak-leader-picker-${player.id}'),
      tooltip: current == null
          ? l10n.t('arnak.leaderPick')
          : l10n.t(current.l10nKey),
      position: PopupMenuPosition.under,
      onSelected: (id) =>
          onChanged(config.withLeader(player.id, id == _none ? null : id)),
      itemBuilder: (context) => [
        for (final leader in ArnakLeader.all)
          PopupMenuItem(
            key: ValueKey('arnak-leader-option-${leader.id}'),
            value: leader.id,
            child: Row(
              children: [
                ArnakLeaderPortrait(leader: leader, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.t(leader.l10nKey),
                        style: TextStyle(
                          fontWeight: leader == current
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                      if (owners[leader.id] case final owner?)
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: playerColor(owner.colorValue),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                l10n.t('arnak.leaderTakenBy', {
                                  'name': owner.name,
                                }),
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (leader == current) const Icon(Icons.check, size: 18),
              ],
            ),
          ),
        if (current != null) ...[
          const PopupMenuDivider(),
          PopupMenuItem(
            value: _none,
            child: Row(
              children: [
                const Icon(Icons.close, size: 20),
                const SizedBox(width: 12),
                Text(l10n.t('arnak.leaderNone')),
              ],
            ),
          ),
        ],
      ],
      child: face,
    );
  }
}
