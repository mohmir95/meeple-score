import 'package:flutter/material.dart';

import '../../data/game_session_repository.dart';
import '../../domain/board_game.dart';
import '../../domain/models/game_config.dart';
import '../../domain/models/game_session.dart';
import '../../domain/models/game_status.dart';
import '../../domain/models/player.dart';
import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/player_colors.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/game_icon_badge.dart';
import '../../shared/widgets/player_editor.dart';
import '../../shared/widgets/primary_button.dart';
import '../play/play_screen.dart';
import '../play/play_session.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({
    super.key,
    required this.game,
    required this.repository,
  });

  final BoardGame game;
  final GameSessionRepository repository;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late List<Player> _players;
  late GameConfig _config;
  GameSession? _saved;
  bool _loading = true;

  BoardGame get _game => widget.game;

  @override
  void initState() {
    super.initState();
    _players = defaultPlayers(
      count: _game.minPlayers,
      palette: _game.playerColors,
    );
    _config = _game.createDefaultConfig();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final saved = await widget.repository.load(_game.id);
    final roster = await widget.repository.loadRoster(_game.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _saved = saved;
      if (saved != null) {
        final state = _game.stateFromJson(saved.stateJson);
        _players = [...state.players];
        _config = state.config;
      } else if (roster.isNotEmpty) {
        _players = roster;
      } else {
        final l10n = context.l10n;
        _players = [
          for (var i = 0; i < _players.length; i++)
            _players[i].copyWith(
              name: l10n.t('players.numbered', {'n': '${i + 1}'}),
            ),
        ];
      }
      _loading = false;
    });
  }

  bool get _hasSaved => _saved != null;
  bool get _canResume =>
      _saved != null && _saved!.stateJson['status'] != GameStatus.finished.name;

  bool get _namesValid =>
      _players.every((player) => player.name.trim().isNotEmpty);

  Future<void> _startNewGame({required bool replacing}) async {
    final l10n = context.l10n;
    if (!_namesValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('setup.needNames'))),
      );
      return;
    }

    if (replacing && _hasSaved) {
      final confirmed = await showConfirmDialog(
        context,
        title: l10n.t('setup.startNewTitle'),
        message: l10n.t('setup.startNewMessage', {
          'game': l10n.t('${_game.l10nPrefix}.name'),
        }),
        confirmLabel: l10n.t('setup.startNewGame'),
        destructive: true,
      );
      if (!confirmed) {
        return;
      }
    }

    final players = [
      for (final player in _players) player.copyWith(name: player.name.trim()),
    ];
    final session = PlaySession.start(
      game: _game,
      players: players,
      config: _config,
      repository: widget.repository,
    );
    await session.update(session.state);

    if (!mounted) {
      return;
    }
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => PlayScreen(session: session),
      ),
    );
  }

  Future<void> _continueSaved() async {
    final saved = _saved;
    if (saved == null) {
      return;
    }
    final session = PlaySession.fromSaved(
      game: _game,
      session: saved,
      repository: widget.repository,
    );
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => PlayScreen(session: session),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final startLabel = _hasSaved
        ? l10n.t('setup.startNewGame')
        : l10n.t('setup.startGame');
    return AppPage(
      title: l10n.t('${_game.l10nPrefix}.name'),
      bottomNavigationBar: _loading
          ? null
          : Material(
              elevation: 3,
              color: Theme.of(context).colorScheme.surface,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    Breakpoints.isCompact(context) ? 12 : 20,
                    8,
                    Breakpoints.isCompact(context) ? 12 : 20,
                    12,
                  ),
                  child: Breakpoints.isCompact(context)
                      ? PrimaryButton(
                          label: startLabel,
                          icon: Icons.play_arrow,
                          onPressed: () => _startNewGame(replacing: _hasSaved),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            PrimaryButton(
                              label: startLabel,
                              icon: Icons.play_arrow,
                              onPressed: () => _startNewGame(replacing: _hasSaved),
                            ),
                          ],
                        ),
                ),
              ),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(value: 0))
          : ListView(
              padding: EdgeInsets.all(Breakpoints.isCompact(context) ? 12 : 20),
              children: [
                _SetupIntro(game: _game),
                if (_hasSaved) ...[
                  const SizedBox(height: 20),
                  Card(
                    child: ListTile(
                      leading: Icon(
                        _canResume ? Icons.play_circle_outline : Icons.history,
                      ),
                      title: Text(
                        _canResume
                            ? l10n.t('setup.continueSaved')
                            : l10n.t('setup.reviewLast'),
                      ),
                      subtitle: Text(l10n.t('setup.storedOnDevice')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _continueSaved,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                PlayerEditor(
                  players: _players,
                  minPlayers: _game.minPlayers,
                  maxPlayers: _game.maxPlayers,
                  colorOptions: _game.playerColors,
                  uniqueColors: _game.uniquePlayerColors,
                  onChanged: (players) {
                    setState(() => _players = players);
                    widget.repository.saveRoster(_game.id, players);
                  },
                ),
                const SizedBox(height: 24),
                _game.buildConfigEditor(
                  config: _config,
                  onChanged: (config) => setState(() => _config = config),
                ),
              ],
            ),
    );
  }
}

class _SetupIntro extends StatelessWidget {
  const _SetupIntro({required this.game});

  final BoardGame game;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final compact = Breakpoints.isCompact(context);
    final facts = <String>[
      l10n.t('home.playersCount', {
        'min': '${game.minPlayers}',
        'max': '${game.maxPlayers}',
      }),
      if (game.playTime != null) l10n.t('${game.l10nPrefix}.playTime'),
      if (game.released != null) game.released!,
    ];
    final credit = [
      if (game.designer != null) game.designer!,
      if (game.publisher != null) game.publisher!,
    ].join(' · ');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _CoverThumb(game: game),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final fact in facts)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.surface.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(
                              fact,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (credit.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      credit,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (!compact) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.t('${game.l10nPrefix}.description'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverThumb extends StatelessWidget {
  const _CoverThumb({required this.game});

  final BoardGame game;

  static const size = 96.0;

  @override
  Widget build(BuildContext context) {
    final child = game.coverImageAsset == null
        ? GameIconBadge(icon: game.icon, color: game.accentColor, size: size)
        : Image.asset(
            game.coverImageAsset!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.2),
            semanticLabel: context.l10n.t('${game.l10nPrefix}.name'),
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(width: size, height: size, child: child),
    );
  }
}
