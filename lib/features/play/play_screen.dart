import 'package:flutter/material.dart';

import '../../domain/models/game_status.dart';
import '../../domain/models/player.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/player_editor.dart';
import '../../shared/widgets/score_board.dart';
import 'play_session.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({
    super.key,
    required this.session,
  });

  final PlaySession session;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  PlaySession get _session => widget.session;

  @override
  void initState() {
    super.initState();
    _session.repository.saveActiveGameId(_session.game.id);
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Reset scores?',
      message: 'Player names stay. All scores are cleared.',
      confirmLabel: 'Reset',
      destructive: true,
    );
    if (confirmed) {
      await _session.reset();
    }
  }

  Future<void> _finish() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Finish game?',
      message: _session.game.winnerMessage(_session.state),
      confirmLabel: 'Finish',
    );
    if (confirmed) {
      await _session.finish();
    }
  }

  Future<void> _editPlayers() async {
    var players = List<Player>.from(_session.state.players);
    final saved = await showModalBottomSheet<List<Player>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PlayerEditor(
                      players: players,
                      minPlayers: _session.game.minPlayers,
                      maxPlayers: _session.game.maxPlayers,
                      colorOptions: _session.game.playerColors,
                      uniqueColors: _session.game.uniquePlayerColors,
                      readOnly: _session.isFinished,
                      onChanged: (next) {
                        setModalState(() => players = next);
                      },
                    ),
                    const SizedBox(height: 12),
                    if (!_session.isFinished)
                      FilledButton(
                        onPressed: () => Navigator.of(sheetContext).pop(players),
                        child: const Text('Save players'),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
    if (saved != null) {
      await _session.update(_session.state.copyWithPlayers(saved));
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = Breakpoints.isCompact(context);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _session.repository.saveActiveGameId(null);
        }
      },
      child: ListenableBuilder(
      listenable: _session,
      builder: (context, _) {
        final state = _session.state;
        final scores = _session.game.scores(state);
        final reachedGoal = _session.game.hasReachedGoal(state);
        const appBarForeground = Colors.white;
        final actions = <Widget>[
          if (!compact) ...[
            TextButton.icon(
              onPressed: _editPlayers,
              style: TextButton.styleFrom(foregroundColor: appBarForeground),
              icon: const Icon(Icons.group_outlined),
              label: const Text('Players'),
            ),
            if (!_session.isFinished)
              TextButton.icon(
                onPressed: _reset,
                style: TextButton.styleFrom(foregroundColor: appBarForeground),
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset'),
              ),
            if (!_session.isFinished)
              TextButton.icon(
                onPressed: _finish,
                style: TextButton.styleFrom(foregroundColor: appBarForeground),
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Finish'),
              ),
          ],
          if (compact)
            PopupMenuButton<_PlayAction>(
              color: Theme.of(context).colorScheme.surface,
              iconColor: appBarForeground,
              onSelected: (action) {
                switch (action) {
                  case _PlayAction.players:
                    _editPlayers();
                  case _PlayAction.reset:
                    _reset();
                  case _PlayAction.finish:
                    _finish();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _PlayAction.players,
                  child: Text('Players'),
                ),
                if (!_session.isFinished)
                  const PopupMenuItem(
                    value: _PlayAction.reset,
                    child: Text('Reset game'),
                  ),
                if (!_session.isFinished)
                  const PopupMenuItem(
                    value: _PlayAction.finish,
                    child: Text('Finish game'),
                  ),
              ],
            ),
        ];

        return AppPage(
          title: _session.game.name,
          actions: actions,
          body: ListView(
            padding: EdgeInsets.fromLTRB(
              compact ? 12 : 20,
              compact ? 12 : 20,
              compact ? 12 : 20,
              compact ? 24 : 20,
            ),
            children: [
              if (_session.isFinished)
                _StatusBanner(
                  icon: Icons.emoji_events,
                  color: Theme.of(context).colorScheme.primary,
                  title: _session.game.winnerMessage(state),
                  message: 'This game is finished. You can still review the sheet.',
                )
              else if (reachedGoal)
                _StatusBanner(
                  icon: Icons.celebration_outlined,
                  color: Theme.of(context).colorScheme.tertiary,
                  title: 'Target reached',
                  message: 'You can keep playing or finish the game when you are ready.',
                ),
              if (scores.isNotEmpty) ...[
                ScoreBoard(
                  scores: scores,
                  footnote: _session.game.scoreFootnote(state),
                ),
                const SizedBox(height: 16),
              ],
              _session.game.buildScoreSheet(
                state: state,
                onChanged: _session.update,
                readOnly: _session.isFinished,
              ),
              if (_session.isFinished) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    await _session.update(state.copyWithStatus(GameStatus.inProgress));
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Reopen game'),
                ),
              ],
            ],
          ),
        );
      },
      ),
    );
  }
}

enum _PlayAction { players, reset, finish }

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(message),
      ),
    );
  }
}
