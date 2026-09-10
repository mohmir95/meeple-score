import 'package:flutter/material.dart';

import '../../domain/models/player.dart';
import '../../domain/models/player_score.dart';
import '../../l10n/l10n_scope.dart';
import '../layout/breakpoints.dart';
import '../player_colors.dart';

class ScoreBoard extends StatelessWidget {
  const ScoreBoard({
    super.key,
    required this.scores,
    this.footnote,
  });

  final List<PlayerScore> scores;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    if (scores.isEmpty) {
      return const SizedBox.shrink();
    }

    final compact = Breakpoints.isCompact(context);
    return Card(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 12 : 16,
          compact ? 12 : 16,
          compact ? 12 : 16,
          8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.t('score.scores'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final score in scores)
                  _ScoreChip(score: score),
              ],
            ),
            if (footnote != null) ...[
              const SizedBox(height: 8),
              Text(
                footnote!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.score});

  final PlayerScore score;

  @override
  Widget build(BuildContext context) {
    final color = playerColor(score.player.colorValue);
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color,
        child: Text(
          _initials(score.player),
          style: TextStyle(
            color: onPlayerColor(score.player.colorValue),
            fontSize: 12,
          ),
        ),
      ),
      label: Text(
        '${score.player.name}: ${score.total}',
        style: TextStyle(
          fontWeight: score.isLeader ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      side: score.isLeader
          ? BorderSide(color: playerColorOutline(score.player.colorValue), width: 1.5)
          : BorderSide(
              color: isLightPlayerColor(score.player.colorValue)
                  ? playerColorOutline(score.player.colorValue)
                  : color.withValues(alpha: 0.3),
            ),
    );
  }
}

String _initials(Player player) {
  final parts = player.name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) {
    return '?';
  }
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
}
