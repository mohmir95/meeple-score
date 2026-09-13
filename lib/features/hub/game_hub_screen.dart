import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/game_session_repository.dart';
import '../../domain/board_game.dart';
import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/widgets/app_page.dart';
import '../setup/setup_screen.dart';

class GameHubScreen extends StatelessWidget {
  const GameHubScreen({
    super.key,
    required this.game,
    required this.repository,
  });

  final BoardGame game;
  final GameSessionRepository repository;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppPage(
      title: l10n.t('${game.l10nPrefix}.name'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < Breakpoints.compact;
          final gap = compact ? 12.0 : 16.0;
          final padding = compact ? 12.0 : 20.0;
          final tiles = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _HubBanner(
                  title: l10n.t('hub.scoresheet'),
                  icon: Icons.grid_on_rounded,
                  color: game.accentColor,
                  compact: compact,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) =>
                            SetupScreen(game: game, repository: repository),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: _HubBanner(
                  title: l10n.t('hub.buildingsRandomizer'),
                  icon: Icons.home_work_outlined,
                  color: game.accentColor,
                  compact: compact,
                  enabled: false,
                  badge: l10n.t('hub.comingSoon'),
                ),
              ),
            ],
          );

          return ListView(
            padding: EdgeInsets.all(padding),
            children: [
              if (constraints.maxWidth >= Breakpoints.medium)
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 696),
                    child: tiles,
                  ),
                )
              else
                tiles,
            ],
          );
        },
      ),
    );
  }
}

class _HubBanner extends StatelessWidget {
  const _HubBanner({
    required this.title,
    required this.icon,
    required this.color,
    required this.compact,
    this.onTap,
    this.enabled = true,
    this.badge,
  });

  final String title;
  final IconData icon;
  final Color color;
  final bool compact;
  final VoidCallback? onTap;
  final bool enabled;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = enabled
        ? scheme.onSurface
        : scheme.onSurface.withValues(alpha: 0.55);
    final iconSize = compact ? 48.0 : 72.0;

    return Opacity(
      opacity: enabled ? 1 : 0.78,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: enabled
                    ? color.withValues(alpha: 0.28)
                    : scheme.outline.withValues(alpha: 0.35),
              ),
            ),
            child: AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final pad = compact ? 12.0 : 20.0;
                  return Padding(
                    padding: EdgeInsets.all(pad),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: math.max(0, constraints.maxWidth - pad * 2),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: iconSize,
                              height: iconSize,
                              decoration: BoxDecoration(
                                color: color.withValues(
                                  alpha: enabled ? 0.16 : 0.1,
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                icon,
                                color: color.withValues(
                                  alpha: enabled ? 1 : 0.7,
                                ),
                                size: compact ? 26 : 36,
                              ),
                            ),
                            SizedBox(height: compact ? 10 : 16),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style:
                                  (compact
                                          ? Theme.of(
                                              context,
                                            ).textTheme.titleSmall
                                          : Theme.of(
                                              context,
                                            ).textTheme.titleLarge)
                                      ?.copyWith(
                                        color: foreground,
                                        fontWeight: FontWeight.w800,
                                        height: 1.2,
                                      ),
                            ),
                            if (badge != null) ...[
                              const SizedBox(height: 8),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: scheme.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    badge!,
                                    style: TextStyle(
                                      color: scheme.onTertiaryContainer,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
