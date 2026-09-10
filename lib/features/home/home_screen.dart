import 'package:flutter/material.dart';

import '../../data/game_session_repository.dart';
import '../../domain/board_game.dart';
import '../../domain/game_registry.dart';
import '../../domain/models/game_session.dart';
import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/widgets/app_page.dart';
import '../play/play_screen.dart';
import '../play/play_session.dart';
import '../setup/setup_screen.dart';
import 'game_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.registry,
    required this.repository,
  });

  final GameRegistry registry;
  final GameSessionRepository repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, GameSession> _sessions = {};
  bool _loading = true;
  var _openedActive = false;

  @override
  void initState() {
    super.initState();
    _reload(restoreActive: true);
  }

  Future<void> _reload({bool restoreActive = false}) async {
    final sessions = await widget.repository.loadAll();
    final activeId = await widget.repository.loadActiveGameId();
    if (!mounted) {
      return;
    }
    setState(() {
      _sessions = sessions;
      _loading = false;
    });
    if (restoreActive && !_openedActive) {
      _openedActive = true;
      await _restoreActive(activeId, sessions);
    }
  }

  Future<void> _restoreActive(
    String? activeId,
    Map<String, GameSession> sessions,
  ) async {
    if (activeId == null) {
      return;
    }
    final session = sessions[activeId];
    final game = widget.registry.tryLookup(activeId);
    if (session == null || game == null || !mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PlayScreen(
          session: PlaySession.fromSaved(
            game: game,
            session: session,
            repository: widget.repository,
          ),
        ),
      ),
    );
    if (mounted) {
      await _reload();
    }
  }

  Future<void> _openGame(BoardGame game) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SetupScreen(
          game: game,
          repository: widget.repository,
        ),
      ),
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppPage(
      title: l10n.t('app.title'),
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          child: Image.asset(
            'assets/branding/app-icon.png',
            semanticLabel: l10n.t('app.iconLabel'),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(value: 0))
          : ListView(
              padding: EdgeInsets.fromLTRB(
                Breakpoints.isCompact(context) ? 12 : 20,
                12,
                Breakpoints.isCompact(context) ? 12 : 20,
                28,
              ),
              children: [
                GameGrid(
                  children: [
                    for (final game in widget.registry.games)
                      GameCard(
                        game: game,
                        session: _sessions[game.id],
                        onOpen: () => _openGame(game),
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}
