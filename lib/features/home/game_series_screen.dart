import 'package:flutter/material.dart';

import '../../data/game_session_repository.dart';
import '../../domain/board_game.dart';
import '../../domain/game_series.dart';
import '../../domain/models/game_session.dart';
import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/widgets/app_page.dart';
import 'game_card.dart';

/// Opens a series page with a gentle fade.
class SeriesPageRoute extends PageRouteBuilder<void> {
  SeriesPageRoute({required WidgetBuilder builder})
    : super(
        transitionDuration: GameSeriesScreen.transitionDuration,
        reverseTransitionDuration: GameSeriesScreen.transitionDuration,
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curve = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
            reverseCurve: Curves.easeIn,
          );
          return FadeTransition(opacity: curve, child: child);
        },
      );
}

/// Every edition of a series, as the home page would show them.
class GameSeriesScreen extends StatefulWidget {
  const GameSeriesScreen({
    super.key,
    required this.series,
    required this.games,
    required this.repository,
    required this.onOpenGame,
    required this.onOpenSaved,
  });

  final GameSeries series;
  final List<BoardGame> games;
  final GameSessionRepository repository;

  /// Opens a game's hub; completes when the user comes back.
  final Future<void> Function(BoardGame game) onOpenGame;

  /// Opens a saved scoresheet; completes when the user comes back.
  final Future<void> Function(BoardGame game, GameSession session) onOpenSaved;

  /// How long the banner takes to open up into this page.
  static const transitionDuration = Duration(milliseconds: 300);

  @override
  State<GameSeriesScreen> createState() => _GameSeriesScreenState();
}

class _GameSeriesScreenState extends State<GameSeriesScreen> {
  Map<String, GameSession> _sessions = {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final sessions = await widget.repository.loadAll();
    if (mounted) {
      setState(() => _sessions = sessions);
    }
  }

  Future<void> _open(Future<void> action) async {
    await action;
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final compact = Breakpoints.isCompact(context);
    return AppPage(
      title: context.l10n.t(widget.series.titleKey),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          compact ? 12 : 20,
          12,
          compact ? 12 : 20,
          28,
        ),
        children: [
          GameGrid(
            children: [
              for (final game in widget.games)
                Builder(
                  builder: (context) {
                    final session = game.hasScoresheet
                        ? _sessions[game.id]
                        : null;
                    return GameCard(
                      game: game,
                      session: session,
                      onOpen: () => _open(widget.onOpenGame(game)),
                      onOpenSaved: session == null
                          ? null
                          : () => _open(widget.onOpenSaved(game, session)),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
