import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/board_game.dart';
import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/loading_image.dart';

/// El Paso's train: 1 locomotive and 3 wagons, each with a front side and a
/// reverse side marked with a star.
class GwtTrainCards {
  const GwtTrainCards._();

  /// Engineers 1–4; card 1 is the locomotive.
  static const count = 4;

  static const aspect = 620 / 390;

  static const _icons = 'assets/games/great_western_trail_el_paso/icons';

  static String asset(int engineers, {required bool star}) =>
      '$_icons/train-$engineers-${star ? 'star' : 'front'}.png';

  /// A first game uses every front side.
  static List<bool> firstGame() => List.filled(count, false);

  /// Turns some or all cards to the star side, never none.
  static List<bool> random(math.Random random) {
    while (true) {
      final sides = [for (var i = 0; i < count; i++) random.nextBool()];
      if (sides.contains(true)) {
        return sides;
      }
    }
  }
}

class GwtTrainCardsRandomizerScreen extends StatefulWidget {
  const GwtTrainCardsRandomizerScreen({
    super.key,
    required this.game,
    this.random,
  });

  final BoardGame game;

  /// Injected by tests for repeatable draws.
  final math.Random? random;

  @override
  State<GwtTrainCardsRandomizerScreen> createState() =>
      _GwtTrainCardsRandomizerScreenState();
}

class _GwtTrainCardsRandomizerScreenState
    extends State<GwtTrainCardsRandomizerScreen> {
  late final math.Random _random = widget.random ?? math.Random();
  late List<bool> _stars = GwtTrainCards.random(_random);
  var _firstGame = false;
  var _precached = false;

  void _draw() => setState(() => _stars = GwtTrainCards.random(_random));

  void _setFirstGame(bool value) {
    setState(() {
      _firstGame = value;
      _stars = value
          ? GwtTrainCards.firstGame()
          : GwtTrainCards.random(_random);
    });
  }

  /// Loads both sides of every card up front, so draws swap instantly.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) {
      return;
    }
    _precached = true;
    for (var n = 1; n <= GwtTrainCards.count; n++) {
      for (final star in [false, true]) {
        precacheImage(AssetImage(GwtTrainCards.asset(n, star: star)), context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final stars = _stars.where((star) => star).length;

    return AppPage(
      title: l10n.t('hub.trainCardsRandomizer'),
      coverImageAsset: widget.game.coverImageAsset,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: Breakpoints.contentMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.t('gwt.trainCards.hint'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.3,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                SwitchListTile(
                  key: const ValueKey('gwt-train-cards-first-game'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.t('gwt.trainCards.firstGame')),
                  subtitle: Text(l10n.t('gwt.trainCards.firstGameHint')),
                  value: _firstGame,
                  onChanged: _setFirstGame,
                ),
                const SizedBox(height: 4),
                Center(
                  child: FilledButton.icon(
                    key: const ValueKey('gwt-train-cards-randomize'),
                    onPressed: _firstGame ? null : _draw,
                    icon: const Icon(Icons.shuffle),
                    label: Text(l10n.t('gwt.randomizer.randomize')),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.t('gwt.trainCards.starCount', {
                    'n': '$stars',
                    'total': '${GwtTrainCards.count}',
                  }),
                  key: const ValueKey('gwt-train-cards-summary'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                // The train runs from the locomotive on the left in every
                // language, as on the table.
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const gap = 12.0;
                      final columns = constraints.maxWidth >= 720 ? 4 : 2;
                      final width =
                          (constraints.maxWidth - gap * (columns - 1)) /
                          columns;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (var i = 0; i < GwtTrainCards.count; i++)
                            SizedBox(
                              width: width,
                              child: _TrainCard(
                                key: ValueKey('gwt-train-card-${i + 1}'),
                                engineers: i + 1,
                                star: _stars[i],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One train card, showing the side in play.
class _TrainCard extends StatelessWidget {
  const _TrainCard({super.key, required this.engineers, required this.star});

  final int engineers;
  final bool star;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final kind = l10n.t(
      engineers == 1 ? 'gwt.trainCards.locomotive' : 'gwt.trainCards.wagon',
    );
    final side = l10n.t(
      star ? 'gwt.trainCards.starSide' : 'gwt.trainCards.frontSide',
    );
    final title = l10n.t('gwt.trainCards.card', {
      'n': '$engineers',
      'kind': kind,
    });
    return Semantics(
      label: '$title, $side',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: GwtTrainCards.aspect,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: Tween(begin: 0.9, end: 1.0).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: DecoratedBox(
                key: ValueKey('gwt-train-$engineers-$star'),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: loadingImage(
                  GwtTrainCards.asset(engineers, star: star),
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.medium,
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              maxLines: 1,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            side,
            style: theme.textTheme.labelMedium?.copyWith(
              color: star
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: star ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
