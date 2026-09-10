import 'package:flutter/material.dart';

import '../../domain/board_game.dart';
import '../../domain/models/game_session.dart';
import '../../domain/models/game_status.dart';
import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';

class GameCard extends StatelessWidget {
  const GameCard({
    super.key,
    required this.game,
    required this.session,
    required this.onOpen,
  });

  final BoardGame game;
  final GameSession? session;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final inProgress = session != null &&
        session!.stateJson['status'] != GameStatus.finished.name;
    final finished = session != null &&
        session!.stateJson['status'] == GameStatus.finished.name;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: game.accentColor.withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Cover(game: game),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x33000000),
                          Color(0x00000000),
                          Color(0xCC1A0F08),
                        ],
                        stops: [0, 0.4, 1],
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    top: 12,
                    end: 12,
                    child: _StatusPill(
                      inProgress: inProgress,
                      finished: finished,
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.t('${game.l10nPrefix}.name'),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                            shadows: const [
                              Shadow(blurRadius: 12, color: Colors.black54),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.l10n.t('home.playersCount', {
                            'min': '${game.minPlayers}',
                            'max': '${game.maxPlayers}',
                          }),
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: const Color(0xFFEAF3FA),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.game});

  final BoardGame game;

  @override
  Widget build(BuildContext context) {
    if (game.coverImageAsset == null) {
      return ColoredBox(
        color: game.accentColor,
        child: Icon(game.icon, color: Colors.white, size: 72),
      );
    }
    return Image.asset(
      game.coverImageAsset!,
      fit: BoxFit.cover,
      alignment: const Alignment(0, -0.2),
      semanticLabel: context.l10n.t('${game.l10nPrefix}.name'),
      errorBuilder: (context, error, stackTrace) {
        return ColoredBox(
          color: game.accentColor,
          child: Icon(game.icon, color: Colors.white, size: 72),
        );
      },
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.inProgress,
    required this.finished,
  });

  final bool inProgress;
  final bool finished;

  @override
  Widget build(BuildContext context) {
    if (!inProgress && !finished) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    final color = inProgress ? scheme.primary : scheme.tertiary;
    final foreground = inProgress ? scheme.onPrimary : scheme.onTertiary;
    final l10n = context.l10n;
    final label = inProgress ? l10n.t('home.resume') : l10n.t('home.lastGame');
    final icon = inProgress ? Icons.play_arrow_rounded : Icons.emoji_events;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameGrid extends StatelessWidget {
  const GameGrid({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = Breakpoints.gameGridCount(constraints.maxWidth);
        const gap = 16.0;
        const maxCardWidth = 340.0;
        final rawWidth = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - gap * (columns - 1)) / columns;
        final cardWidth = rawWidth.clamp(0, maxCardWidth).toDouble();

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          alignment: WrapAlignment.center,
          children: [
            for (final child in children)
              SizedBox(width: cardWidth, child: child),
          ],
        );
      },
    );
  }
}
