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
    final compact = Breakpoints.isCompact(context);
    return AppPage(
      title: l10n.t('${game.l10nPrefix}.name'),
      body: ListView(
        padding: EdgeInsets.all(compact ? 12 : 20),
        children: [
          _HubBanner(
            title: l10n.t('hub.scoresheet'),
            icon: Icons.grid_on_rounded,
            color: game.accentColor,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) =>
                      SetupScreen(game: game, repository: repository),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _HubBanner(
            title: l10n.t('hub.buildingsRandomiser'),
            icon: Icons.home_work_outlined,
            color: game.accentColor,
            enabled: false,
            badge: l10n.t('hub.comingSoon'),
          ),
        ],
      ),
    );
  }
}

class _HubBanner extends StatelessWidget {
  const _HubBanner({
    required this.title,
    required this.icon,
    required this.color,
    this.onTap,
    this.enabled = true,
    this.badge,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool enabled;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final compact = Breakpoints.isCompact(context);
    final foreground = enabled
        ? scheme.onSurface
        : scheme.onSurface.withValues(alpha: 0.55);

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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Container(
                    width: compact ? 56 : 64,
                    height: compact ? 56 : 64,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: enabled ? 0.16 : 0.1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      icon,
                      color: color.withValues(alpha: enabled ? 1 : 0.7),
                      size: compact ? 28 : 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: foreground,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (badge != null)
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
                    )
                  else
                    Icon(
                      Icons.chevron_right,
                      color: foreground.withValues(alpha: 0.55),
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
