import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/board_game.dart';
import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/loading_image.dart';

/// El Paso's buildings: 6 stacks of common building tiles, each turned to
/// its a- or b-side, and 6 neutral tiles placed on board spaces B to G next
/// to the fixed El Paso tile.
class GwtElPasoBuildings {
  const GwtElPasoBuildings._();

  static const _root = 'assets/games/great_western_trail_el_paso/buildings';

  /// Worker cost printed on each common building stack, 1 to 6.
  static const workerCosts = [1, 2, 3, 5, 7, 9];

  static const neutralSpaces = ['B', 'C', 'D', 'E', 'F', 'G'];

  static const elPasoAsset = '$_root/neutral/a.png';

  static String commonAsset(int stack, String side) =>
      '$_root/common/$stack$side.png';

  static String neutralAsset(String tile) =>
      '$_root/neutral/${tile.toLowerCase()}.png';

  /// A first game plays every stack on its a-side.
  static List<String> firstGameSides() => List.filled(workerCosts.length, 'a');

  /// Turns any number of stacks to the b-side, but at least one.
  static List<String> randomSides(math.Random random) {
    while (true) {
      final sides = [
        for (var i = 0; i < workerCosts.length; i++)
          random.nextBool() ? 'b' : 'a',
      ];
      if (sides.contains('b')) {
        return sides;
      }
    }
  }

  /// A first game puts each neutral tile on its matching letter.
  static List<String> firstGameNeutral() => [...neutralSpaces];

  static List<String> randomNeutral(math.Random random) =>
      [...neutralSpaces]..shuffle(random);
}

class GwtElPasoBuildingsScreen extends StatefulWidget {
  const GwtElPasoBuildingsScreen({super.key, required this.game, this.random});

  final BoardGame game;

  /// Injected by tests for repeatable draws.
  final math.Random? random;

  @override
  State<GwtElPasoBuildingsScreen> createState() =>
      _GwtElPasoBuildingsScreenState();
}

class _GwtElPasoBuildingsScreenState extends State<GwtElPasoBuildingsScreen> {
  late final math.Random _random = widget.random ?? math.Random();
  late List<String> _sides = GwtElPasoBuildings.randomSides(_random);
  late List<String> _neutral = GwtElPasoBuildings.randomNeutral(_random);
  var _commonFirstGame = false;
  var _neutralFirstGame = false;
  var _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) {
      return;
    }
    _precached = true;
    for (var stack = 1; stack <= 6; stack++) {
      for (final side in ['a', 'b']) {
        precacheImage(
          AssetImage(GwtElPasoBuildings.commonAsset(stack, side)),
          context,
        );
      }
    }
    for (final tile in GwtElPasoBuildings.neutralSpaces) {
      precacheImage(AssetImage(GwtElPasoBuildings.neutralAsset(tile)), context);
    }
    precacheImage(const AssetImage(GwtElPasoBuildings.elPasoAsset), context);
  }

  void _setCommonFirstGame(bool value) {
    setState(() {
      _commonFirstGame = value;
      _sides = value
          ? GwtElPasoBuildings.firstGameSides()
          : GwtElPasoBuildings.randomSides(_random);
    });
  }

  void _setNeutralFirstGame(bool value) {
    setState(() {
      _neutralFirstGame = value;
      _neutral = value
          ? GwtElPasoBuildings.firstGameNeutral()
          : GwtElPasoBuildings.randomNeutral(_random);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 2,
      child: AppPage(
        title: l10n.t('hub.buildingsRandomizer'),
        coverImageAsset: widget.game.coverImageAsset,
        body: Column(
          children: [
            TabBar(
              labelColor: scheme.primary,
              unselectedLabelColor: scheme.onSurfaceVariant,
              indicatorColor: scheme.primary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800),
              tabs: [
                Tab(
                  key: const ValueKey('gwtep-tab-common'),
                  text: l10n.t('gwtep.buildings.common'),
                ),
                Tab(
                  key: const ValueKey('gwtep-tab-neutral'),
                  text: l10n.t('gwtep.buildings.neutral'),
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _Panel(
                    hint: l10n.t('gwtep.buildings.commonHint'),
                    firstGameKey: const ValueKey('gwtep-common-first-game'),
                    firstGameHint: l10n.t('gwtep.buildings.commonFirstGame'),
                    firstGame: _commonFirstGame,
                    onFirstGame: _setCommonFirstGame,
                    randomizeKey: const ValueKey('gwtep-common-randomize'),
                    onRandomize: () => setState(
                      () => _sides = GwtElPasoBuildings.randomSides(_random),
                    ),
                    tiles: [
                      for (var i = 0; i < _sides.length; i++)
                        _Tile(
                          key: ValueKey('gwtep-common-${i + 1}'),
                          asset: GwtElPasoBuildings.commonAsset(
                            i + 1,
                            _sides[i],
                          ),
                          title: _TileTitle(
                            prefix: '${i + 1}',
                            letter: _sides[i],
                          ),
                          semanticLabel: l10n.t('gwtep.buildings.stack', {
                            'n': '${i + 1}',
                            'side': _sides[i],
                          }),
                        ),
                    ],
                  ),
                  _Panel(
                    hint: l10n.t('gwtep.buildings.neutralHint'),
                    firstGameKey: const ValueKey('gwtep-neutral-first-game'),
                    firstGameHint: l10n.t('gwtep.buildings.neutralFirstGame'),
                    firstGame: _neutralFirstGame,
                    onFirstGame: _setNeutralFirstGame,
                    randomizeKey: const ValueKey('gwtep-neutral-randomize'),
                    onRandomize: () => setState(
                      () =>
                          _neutral = GwtElPasoBuildings.randomNeutral(_random),
                    ),
                    leading: _ElPasoTile(
                      label: l10n.t('gwtep.buildings.elPaso'),
                    ),
                    tiles: [
                      for (var i = 0; i < _neutral.length; i++)
                        _Tile(
                          key: ValueKey(
                            'gwtep-space-${GwtElPasoBuildings.neutralSpaces[i]}',
                          ),
                          asset: GwtElPasoBuildings.neutralAsset(_neutral[i]),
                          title: _TileTitle(
                            prefix: GwtElPasoBuildings.neutralSpaces[i],
                            letter: _neutral[i],
                            showArrow: true,
                          ),
                          semanticLabel: l10n.t('gwtep.buildings.space', {
                            'space': GwtElPasoBuildings.neutralSpaces[i],
                            'tile': _neutral[i],
                          }),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.hint,
    required this.firstGameKey,
    required this.firstGameHint,
    required this.firstGame,
    required this.onFirstGame,
    required this.randomizeKey,
    required this.onRandomize,
    required this.tiles,
    this.leading,
  });

  final String hint;
  final Key firstGameKey;
  final String firstGameHint;
  final bool firstGame;
  final ValueChanged<bool> onFirstGame;
  final Key randomizeKey;
  final VoidCallback onRandomize;
  final List<Widget> tiles;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < Breakpoints.compact;
        final padding = compact ? 12.0 : 20.0;
        final gap = compact ? 10.0 : 12.0;
        final columns = constraints.maxWidth >= 720 ? 6 : 3;
        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Breakpoints.contentMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    hint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.3,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SwitchListTile(
                    key: firstGameKey,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.t('gwt.trainCards.firstGame')),
                    subtitle: Text(firstGameHint),
                    value: firstGame,
                    onChanged: onFirstGame,
                  ),
                  Center(
                    child: FilledButton.icon(
                      key: randomizeKey,
                      onPressed: firstGame ? null : onRandomize,
                      icon: const Icon(Icons.casino_outlined),
                      label: Text(l10n.t('gwt.randomizer.randomize')),
                    ),
                  ),
                  SizedBox(height: gap),
                  if (leading != null) ...[leading!, SizedBox(height: gap)],
                  // Board order runs left to right in every language.
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width =
                            (constraints.maxWidth - gap * (columns - 1)) /
                            columns;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            for (final tile in tiles)
                              SizedBox(width: width, child: tile),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The El Paso tile always goes on its own space.
class _ElPasoTile extends StatelessWidget {
  const _ElPasoTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      key: const ValueKey('gwtep-el-paso-tile'),
      children: [
        _TileImage(asset: GwtElPasoBuildings.elPasoAsset, size: 72),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    super.key,
    required this.asset,
    required this.title,
    required this.semanticLabel,
  });

  final String asset;
  final Widget title;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          title,
          const SizedBox(height: 6),
          AspectRatio(
            aspectRatio: 1,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: Tween(begin: 0.9, end: 1.0).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: _TileImage(key: ValueKey(asset), asset: asset),
            ),
          ),
        ],
      ),
    );
  }
}

class _TileImage extends StatelessWidget {
  const _TileImage({super.key, required this.asset, this.size});

  final String asset;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: loadingImage(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
      ),
    );
  }
}

/// "1 [a]" for a stack, or "B ← [D]" for a board space and its tile.
class _TileTitle extends StatelessWidget {
  const _TileTitle({
    required this.prefix,
    required this.letter,
    this.showArrow = false,
  });

  final String prefix;
  final String letter;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chip = DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        child: Text(
          letter,
          style: TextStyle(
            color: scheme.onPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 15,
            height: 1.2,
          ),
        ),
      ),
    );
    final label = Text(
      prefix,
      style: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 15,
        color: scheme.onSurface,
      ),
    );
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          label,
          const SizedBox(width: 4),
          if (showArrow) ...[
            Icon(
              Icons.arrow_back_rounded,
              size: 14,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
          ],
          chip,
        ],
      ),
    );
  }
}
