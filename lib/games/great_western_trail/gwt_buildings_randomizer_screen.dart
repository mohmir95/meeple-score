import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/board_game.dart';
import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/widgets/app_page.dart';
import 'gwt_building_art.dart';
import 'gwt_buildings_layout.dart';
import 'gwt_edition.dart';
import 'gwt_public_buildings_layout.dart';

class GwtBuildingsRandomizerScreen extends StatefulWidget {
  const GwtBuildingsRandomizerScreen({
    super.key,
    required this.game,
    this.random,
    this.initialLayout,
    this.initialPublicLayout,
  });

  final BoardGame game;
  final math.Random? random;
  final GwtBuildingsLayout? initialLayout;
  final GwtPublicBuildingsLayout? initialPublicLayout;

  @override
  State<GwtBuildingsRandomizerScreen> createState() =>
      _GwtBuildingsRandomizerScreenState();
}

class _GwtBuildingsRandomizerScreenState
    extends State<GwtBuildingsRandomizerScreen>
    with TickerProviderStateMixin {
  static const _appearDuration = Duration(milliseconds: 400);
  static const _fadeOutDuration = Duration(milliseconds: 350);
  static const _fadeInDuration = Duration(milliseconds: 450);

  late GwtBuildingsLayout _layout;
  late GwtPublicBuildingsLayout _publicLayout;
  late final AnimationController _privateFade;
  late final AnimationController _publicFade;
  late final CurvedAnimation _privateVisibility;
  late final CurvedAnimation _publicVisibility;
  var _privateBusy = false;
  var _publicBusy = false;

  bool get _includeThirteenthBuilding {
    final game = widget.game;
    return game is GwtEditionGame && game.includeThirteenthBuildingExpansion;
  }

  bool get _includeRailsToTheNorth {
    final game = widget.game;
    return game is GwtEditionGame && game.includeRailsToTheNorthExpansion;
  }

  int get _baseCount {
    final game = widget.game;
    if (game is GwtEditionGame) {
      return game.privateBuildingBaseCount;
    }
    return 10;
  }

  GwtBuildingArtSet get _artSet {
    final game = widget.game;
    if (game is GwtEditionGame) {
      return game.buildingArtSet;
    }
    return GwtBuildingArtSet.firstEdition;
  }

  @override
  void initState() {
    super.initState();
    _layout = widget.initialLayout ??
        GwtBuildingsLayout.random(
          random: widget.random,
          baseCount: _baseCount,
        );
    if (!_includeThirteenthBuilding &&
        _layout.includesThirteenthBuilding) {
      _layout = _layout.withThirteenthBuilding(false);
    }
    if (!_includeRailsToTheNorth && _layout.includesRailsToTheNorth) {
      _layout = _layout.withRailsToTheNorth(false);
    }
    _publicLayout = widget.initialPublicLayout ??
        GwtPublicBuildingsLayout.random(widget.random);
    _privateFade = AnimationController(
      vsync: this,
      duration: _appearDuration,
    );
    _publicFade = AnimationController(
      vsync: this,
      duration: _appearDuration,
    );
    _privateVisibility = CurvedAnimation(
      parent: _privateFade,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _publicVisibility = CurvedAnimation(
      parent: _publicFade,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _privateFade.forward();
    _publicFade.forward();
  }

  @override
  void dispose() {
    _privateVisibility.dispose();
    _publicVisibility.dispose();
    _privateFade.dispose();
    _publicFade.dispose();
    super.dispose();
  }

  Future<void> _randomizePrivate() async {
    if (_privateBusy) {
      return;
    }
    _privateBusy = true;
    try {
      _privateFade.duration = _fadeOutDuration;
      await _privateFade.reverse();
      if (!mounted) {
        return;
      }
      setState(() {
        _layout = GwtBuildingsLayout.random(
          random: widget.random,
          baseCount: _baseCount,
          railsToTheNorth: _includeRailsToTheNorth &&
              _layout.includesRailsToTheNorth,
          thirteenthBuilding: _includeThirteenthBuilding &&
              _layout.includesThirteenthBuilding,
        );
      });
      _privateFade.duration = _fadeInDuration;
      await _privateFade.forward();
    } on TickerCanceled {
      return;
    } finally {
      if (mounted) {
        _privateBusy = false;
      }
    }
  }

  Future<void> _randomizePublic() async {
    if (_publicBusy) {
      return;
    }
    _publicBusy = true;
    try {
      _publicFade.duration = _fadeOutDuration;
      await _publicFade.reverse();
      if (!mounted) {
        return;
      }
      setState(() {
        _publicLayout = GwtPublicBuildingsLayout.random(widget.random);
      });
      _publicFade.duration = _fadeInDuration;
      await _publicFade.forward();
    } on TickerCanceled {
      return;
    } finally {
      if (mounted) {
        _publicBusy = false;
      }
    }
  }

  void _setRailsToTheNorth(bool enabled) {
    setState(() {
      _layout = _layout.withRailsToTheNorth(enabled, widget.random);
    });
  }

  void _setThirteenthBuilding(bool enabled) {
    setState(() {
      _layout = _layout.withThirteenthBuilding(enabled, widget.random);
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
                  key: const ValueKey('gwt-tab-private'),
                  text: l10n.t('gwt.randomizer.privateBuildings'),
                ),
                Tab(
                  key: const ValueKey('gwt-tab-public'),
                  text: l10n.t('gwt.randomizer.publicBuildings'),
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _PrivateBuildingsPanel(
                    layout: _layout,
                    visibility: _privateVisibility,
                    artSet: _artSet,
                    includeThirteenthBuilding: _includeThirteenthBuilding,
                    includeRailsToTheNorth: _includeRailsToTheNorth,
                    onRailsToTheNorth: _setRailsToTheNorth,
                    onThirteenthBuilding: _setThirteenthBuilding,
                    onRandomize: _randomizePrivate,
                  ),
                  _PublicBuildingsPanel(
                    layout: _publicLayout,
                    visibility: _publicVisibility,
                    artSet: _artSet,
                    onRandomize: _randomizePublic,
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

class _PrivateBuildingsPanel extends StatelessWidget {
  const _PrivateBuildingsPanel({
    required this.layout,
    required this.visibility,
    required this.artSet,
    required this.includeThirteenthBuilding,
    required this.includeRailsToTheNorth,
    required this.onRailsToTheNorth,
    required this.onThirteenthBuilding,
    required this.onRandomize,
  });

  final GwtBuildingsLayout layout;
  final Animation<double> visibility;
  final GwtBuildingArtSet artSet;
  final bool includeThirteenthBuilding;
  final bool includeRailsToTheNorth;
  final ValueChanged<bool> onRailsToTheNorth;
  final ValueChanged<bool> onThirteenthBuilding;
  final VoidCallback onRandomize;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < Breakpoints.compact;
        final columns = compact ? 3 : 5;
        final padding = compact ? 12.0 : 20.0;
        final gap = compact ? 10.0 : 12.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(padding, padding, padding, 8),
              child: Text(
                l10n.t('gwt.randomizer.hint'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.35,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(padding, 0, padding, 4),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 20,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (includeRailsToTheNorth)
                              _ExpansionSwitch(
                                switchKey: const ValueKey(
                                  'gwt-rails-to-the-north',
                                ),
                                title: l10n.t('gwt.randomizer.railsToTheNorth'),
                                value: layout.includesRailsToTheNorth,
                                onChanged: onRailsToTheNorth,
                              ),
                            if (includeThirteenthBuilding)
                              _ExpansionSwitch(
                                switchKey: const ValueKey(
                                  'gwt-thirteenth-building',
                                ),
                                title: l10n.t(
                                  'gwt.randomizer.thirteenthBuilding',
                                ),
                                value: layout.includesThirteenthBuilding,
                                onChanged: onThirteenthBuilding,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _RandomizeButton(
                        key: const ValueKey('gwt-buildings-randomize'),
                        onPressed: onRandomize,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: FadeTransition(
                opacity: visibility,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: GridView.builder(
                    padding: EdgeInsets.fromLTRB(padding, 4, padding, padding),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: gap,
                      mainAxisSpacing: gap,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: layout.visibleNumbers.length,
                    itemBuilder: (context, index) {
                      final number = layout.visibleNumbers[index];
                      return _BuildingTile(
                        number: number,
                        side: layout.sideOf(number),
                        compact: compact,
                        artSet: artSet,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PublicBuildingsPanel extends StatelessWidget {
  const _PublicBuildingsPanel({
    required this.layout,
    required this.visibility,
    required this.artSet,
    required this.onRandomize,
  });

  final GwtPublicBuildingsLayout layout;
  final Animation<double> visibility;
  final GwtBuildingArtSet artSet;
  final VoidCallback onRandomize;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < Breakpoints.compact;
        final columns = compact ? 3 : 5;
        final padding = compact ? 12.0 : 20.0;
        final gap = compact ? 10.0 : 12.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(padding, padding, padding, 8),
              child: Text(
                l10n.t('gwt.randomizer.publicHint'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.35,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(padding, 0, padding, 4),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: _RandomizeButton(
                  key: const ValueKey('gwt-public-buildings-randomize'),
                  onPressed: onRandomize,
                ),
              ),
            ),
            Expanded(
              child: FadeTransition(
                opacity: visibility,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: GridView.builder(
                    padding: EdgeInsets.fromLTRB(padding, 4, padding, padding),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: gap,
                      mainAxisSpacing: gap,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: GwtPublicBuildingsLayout.locations.length,
                    itemBuilder: (context, index) {
                      final location =
                          GwtPublicBuildingsLayout.locations[index];
                      return _PublicLocationTile(
                        location: location,
                        tile: layout.tileOn(location),
                        compact: compact,
                        artSet: artSet,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RandomizeButton extends StatelessWidget {
  const _RandomizeButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: const Icon(Icons.casino_outlined, size: 18),
      label: Text(context.l10n.t('gwt.randomizer.randomize')),
    );
  }
}

class _ExpansionSwitch extends StatelessWidget {
  const _ExpansionSwitch({
    required this.switchKey,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final Key switchKey;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        Switch(
          key: switchKey,
          value: value,
          onChanged: onChanged,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ],
    );
  }
}

class _BuildingTile extends StatelessWidget {
  const _BuildingTile({
    required this.number,
    required this.side,
    required this.compact,
    required this.artSet,
  });

  final int number;
  final GwtBuildingSide side;
  final bool compact;
  final GwtBuildingArtSet artSet;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final art = GwtBuildingArt.private(number, side, artSet: artSet);
    return Semantics(
      label: l10n.t('gwt.randomizer.tileSemantics', {
        'n': '$number',
        'side': side.code,
      }),
      child: KeyedSubtree(
        key: ValueKey('gwt-building-$number'),
        child: art == null
            ? _LetterFallbackTile(
                title: _SideOrLocationTitle(
                  prefix: '$number',
                  letter: side.code,
                  compact: compact,
                ),
                letter: side.code,
                compact: compact,
              )
            : _ArtTile(
                asset: art,
                title: _SideOrLocationTitle(
                  prefix: '$number',
                  letter: side.code,
                  compact: compact,
                ),
                compact: compact,
              ),
      ),
    );
  }
}

class _PublicLocationTile extends StatelessWidget {
  const _PublicLocationTile({
    required this.location,
    required this.tile,
    required this.compact,
    required this.artSet,
  });

  final String location;
  final String tile;
  final bool compact;
  final GwtBuildingArtSet artSet;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      label: l10n.t('gwt.randomizer.publicTileSemantics', {
        'location': location,
        'tile': tile,
      }),
      child: KeyedSubtree(
        key: ValueKey('gwt-public-location-$location'),
        child: _ArtTile(
          asset: GwtBuildingArt.public(tile, artSet: artSet),
          title: _SideOrLocationTitle(
            prefix: location,
            letter: tile,
            compact: compact,
            showArrow: true,
          ),
          compact: compact,
          imageKey: ValueKey('gwt-public-tile-$location'),
        ),
      ),
    );
  }
}

class _ArtTile extends StatelessWidget {
  const _ArtTile({
    required this.asset,
    required this.title,
    required this.compact,
    this.imageKey,
  });

  final String asset;
  final Widget title;
  final bool compact;
  final Key? imageKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _TileCard(
      compact: compact,
      title: title,
      child: ColoredBox(
        color: scheme.surfaceContainerLow,
        child: Image.asset(
          asset,
          key: imageKey,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

class _LetterFallbackTile extends StatelessWidget {
  const _LetterFallbackTile({
    required this.title,
    required this.letter,
    required this.compact,
  });

  final Widget title;
  final String letter;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _TileCard(
      compact: compact,
      title: title,
      child: ColoredBox(
        color: scheme.secondaryContainer,
        child: Center(
          child: Text(
            letter,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: scheme.onSecondaryContainer,
              fontWeight: FontWeight.w800,
              height: 1,
              fontSize: compact ? 42 : 52,
            ),
          ),
        ),
      ),
    );
  }
}

class _TileCard extends StatelessWidget {
  const _TileCard({
    required this.title,
    required this.child,
    required this.compact,
  });

  final Widget title;
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 6 : 8,
          compact ? 4 : 6,
          compact ? 6 : 8,
          compact ? 6 : 8,
        ),
        child: Column(
          children: [
            title,
            SizedBox(height: compact ? 4 : 6),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideOrLocationTitle extends StatelessWidget {
  const _SideOrLocationTitle({
    this.prefix,
    required this.letter,
    required this.compact,
    this.showArrow = false,
  });

  final String? prefix;
  final String letter;
  final bool compact;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gap = SizedBox(width: compact ? 2 : 4);
    final highlighted = DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 9,
          vertical: compact ? 1 : 2,
        ),
        child: Text(
          letter,
          style: TextStyle(
            color: scheme.onPrimary,
            fontWeight: FontWeight.w900,
            fontSize: compact ? 14 : 16,
            height: 1.2,
          ),
        ),
      ),
    );
    final label = prefix == null
        ? null
        : Text(
            prefix!,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: compact ? 14 : 16,
              color: scheme.onSurface,
            ),
          );
    final arrow = Icon(
      Icons.arrow_forward_rounded,
      size: compact ? 13 : 15,
      color: scheme.onSurfaceVariant,
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: showArrow && label != null
            ? [highlighted, gap, arrow, gap, label]
            : [
                if (label != null) ...[label, gap],
                highlighted,
              ],
      ),
    );
  }
}
