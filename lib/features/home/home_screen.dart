import 'package:flutter/material.dart';

import '../../data/game_session_repository.dart';
import '../../domain/board_game.dart';
import '../../domain/game_registry.dart';
import '../../domain/game_series.dart';
import '../../domain/models/game_session.dart';
import '../../domain/models/game_status.dart';
import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/widgets/app_page.dart';
import '../first_player/first_player_screen.dart';
import '../hub/game_hub_screen.dart';
import '../play/play_screen.dart';
import '../play/play_session.dart';
import 'game_card.dart';
import 'game_series_card.dart';
import 'game_series_screen.dart';
import '../../shared/widgets/loading_image.dart';

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
    if (session == null || game == null || !game.hasScoresheet || !mounted) {
      return;
    }
    await _openSaved(game, session);
  }

  Future<void> _openGame(BoardGame game) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            GameHubScreen(game: game, repository: widget.repository),
      ),
    );
    await _reload();
  }

  Future<void> _openSaved(BoardGame game, GameSession session) async {
    if (!mounted) {
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

  Future<void> _openSeries(SeriesEntry entry) async {
    await Navigator.of(context).push(
      SeriesPageRoute(
        builder: (context) => GameSeriesScreen(
          series: entry.series,
          games: entry.games,
          repository: widget.repository,
          onOpenGame: _openGame,
          onOpenSaved: _openSaved,
        ),
      ),
    );
    await _reload();
  }

  Widget _cardFor(BoardGame game) {
    final session = game.hasScoresheet ? _sessions[game.id] : null;
    return GameCard(
      game: game,
      session: session,
      onOpen: () => _openGame(game),
      onOpenSaved: session == null ? null : () => _openSaved(game, session),
    );
  }

  Widget _seriesCardFor(SeriesEntry entry) {
    // Resume the most recently played edition that is still in progress.
    BoardGame? resumeGame;
    GameSession? resumeSession;
    for (final game in entry.games) {
      final session = game.hasScoresheet ? _sessions[game.id] : null;
      if (session == null ||
          session.stateJson['status'] == GameStatus.finished.name) {
        continue;
      }
      if (resumeSession == null ||
          session.updatedAt.isAfter(resumeSession.updatedAt)) {
        resumeGame = game;
        resumeSession = session;
      }
    }
    return GameSeriesCard(
      key: ValueKey('home-series-${entry.series.id}'),
      series: entry.series,
      games: entry.games,
      onOpen: () => _openSeries(entry),
      onResume: resumeSession == null
          ? null
          : () => _openSaved(resumeGame!, resumeSession!),
    );
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
          child: loadingImage(
            'assets/branding/app-icon.png',
            semanticLabel: l10n.t('app.iconLabel'),
          ),
        ),
      ),
      actions: [
        IconButton(
          key: const ValueKey('home-first-player'),
          tooltip: l10n.t('firstPlayer.button'),
          icon: const Icon(Icons.touch_app_outlined, color: Colors.white),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => const FirstPlayerScreen(),
            ),
          ),
        ),
      ],
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
                    for (final entry in HomeEntry.group(widget.registry.games))
                      switch (entry) {
                        SingleGameEntry(:final game) => _cardFor(game),
                        SeriesEntry() => _seriesCardFor(entry),
                      },
                  ],
                ),
              ],
            ),
    );
  }
}
