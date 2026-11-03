import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/board_game.dart';
import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/widgets/app_page.dart';
import 'gwt_setup_hints_screen.dart';
import '../../shared/widgets/loading_image.dart';

/// Argentina's city maps: each city is played on its side A or B.
class GwtCityMaps {
  const GwtCityMaps._();

  static const sides = ['a', 'b'];

  static const _icons = 'assets/games/great_western_trail_argentina/icons';
  static const coverAsset = '$_icons/city-center.png';

  static const _files = {
    'leHavre': 'map-le-havre',
    'rotterdam': 'map-rotterdam',
    'liverpool': 'map-liverpool',
  };

  static String mapAsset(String city, String side) =>
      '$_icons/${_files[city]}-$side.jpg';

  /// A first game uses every a-side.
  static Map<String, String> firstGame() => {
    for (final city in GwtSetupHints.cities) city: sides.first,
  };

  static Map<String, String> random(math.Random random) => {
    for (final city in GwtSetupHints.cities)
      city: sides[random.nextInt(sides.length)],
  };
}

class GwtCityMapsRandomizerScreen extends StatefulWidget {
  const GwtCityMapsRandomizerScreen({
    super.key,
    required this.game,
    this.random,
  });

  final BoardGame game;

  /// Injected by tests for repeatable draws.
  final math.Random? random;

  @override
  State<GwtCityMapsRandomizerScreen> createState() =>
      _GwtCityMapsRandomizerScreenState();
}

class _GwtCityMapsRandomizerScreenState
    extends State<GwtCityMapsRandomizerScreen> {
  static const _playerCounts = [2, 3, 4];

  /// Below this height the page scrolls, with the big map at [_shortMapSize].
  static const _minFitHeight = 560.0;
  static const _shortMapSize = 320.0;

  late final math.Random _random = widget.random ?? math.Random();
  late Map<String, String> _sides = GwtCityMaps.random(_random);
  late var _players = widget.game.maxPlayers;
  var _selected = GwtSetupHints.cities.first;
  var _firstGame = false;
  var _precached = false;

  void _draw() {
    setState(() => _sides = GwtCityMaps.random(_random));
  }

  void _setFirstGame(bool value) {
    setState(() {
      _firstGame = value;
      _sides = value ? GwtCityMaps.firstGame() : GwtCityMaps.random(_random);
    });
  }

  /// Loads every map up front, so each Randomize swaps them instantly.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) {
      return;
    }
    _precached = true;
    for (final city in GwtSetupHints.cities) {
      for (final side in GwtCityMaps.sides) {
        precacheImage(AssetImage(GwtCityMaps.mapAsset(city, side)), context);
      }
    }
    precacheImage(const AssetImage(GwtCityMaps.coverAsset), context);
  }

  String _label(BuildContext context, String city) {
    final l10n = context.l10n;
    return l10n.t('gwt.cityMaps.side', {
      'city': l10n.t('gwt.setup.city.$city'),
      'side': _sides[city]!.toUpperCase(),
    });
  }

  bool _covered(String city) => GwtSetupHints.cityCovered(city, _players);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final side = _sides[_selected]!;
    final covered = _covered(_selected);
    final bigMap = AspectRatio(
      aspectRatio: 1,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _CityMapArt(
          key: ValueKey('gwt-city-big-$_selected-$side-$covered'),
          coverKey: const ValueKey('gwt-city-cover-big'),
          city: _selected,
          side: side,
          covered: covered,
          semanticLabel: _label(context, _selected),
        ),
      ),
    );

    return AppPage(
      title: l10n.t('hub.cityMapsRandomizer'),
      coverImageAsset: widget.game.coverImageAsset,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: Breakpoints.contentMaxWidth,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final fits = constraints.maxHeight >= _minFitHeight;
              final content = Column(
                mainAxisSize: fits ? MainAxisSize.max : MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.t('gwt.cityMaps.hint'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.3,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // One row on every screen; phones label the segments with
                  // just the number, after a players icon.
                  Row(
                    children: [
                      if (compact) ...[
                        Icon(
                          Icons.group_outlined,
                          semanticLabel: l10n.t('players.title'),
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                      ],
                      // Shrinks rather than overflowing on the narrowest
                      // phones.
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: SegmentedButton<int>(
                            key: const ValueKey('gwt-city-maps-players'),
                            segments: [
                              for (final count in _playerCounts)
                                ButtonSegment(
                                  value: count,
                                  label: Text(
                                    compact
                                        ? '$count'
                                        : l10n.t('gwt.setup.players', {
                                            'n': '$count',
                                          }),
                                  ),
                                ),
                            ],
                            selected: {_players},
                            showSelectedIcon: false,
                            onSelectionChanged: (selection) =>
                                setState(() => _players = selection.single),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        key: const ValueKey('gwt-city-maps-randomize'),
                        onPressed: _firstGame ? null : _draw,
                        icon: const Icon(Icons.shuffle),
                        label: Text(l10n.t('gwt.randomizer.randomize')),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    key: const ValueKey('gwt-city-maps-first-game'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.t('gwt.cityMaps.firstGame')),
                    subtitle: Text(l10n.t('gwt.cityMaps.firstGameHint')),
                    value: _firstGame,
                    onChanged: _setFirstGame,
                  ),
                  Text(
                    l10n.t('gwt.setup.covers$_players'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _label(context, _selected),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (fits)
                    Expanded(child: Center(child: bigMap))
                  else
                    Center(
                      child: SizedBox.square(
                        dimension: _shortMapSize,
                        child: bigMap,
                      ),
                    ),
                  const SizedBox(height: 10),
                  // Le Havre stays on the left in every language, as on the
                  // table.
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final city in GwtSetupHints.cities)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: _CityThumbnail(
                              key: ValueKey('gwt-city-thumb-$city'),
                              city: city,
                              side: _sides[city]!,
                              covered: _covered(city),
                              selected: city == _selected,
                              label: _label(context, city),
                              size: compact ? 92 : 104,
                              onTap: () => setState(() => _selected = city),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
              final padding = EdgeInsets.all(compact ? 12 : 16);
              return fits
                  ? Padding(padding: padding, child: content)
                  : SingleChildScrollView(padding: padding, child: content);
            },
          ),
        ),
      ),
    );
  }
}

/// A small map that brings its city up as the big image.
class _CityThumbnail extends StatelessWidget {
  const _CityThumbnail({
    super.key,
    required this.city,
    required this.side,
    required this.covered,
    required this.selected,
    required this.label,
    required this.size,
    required this.onTap,
  });

  final String city;
  final String side;
  final bool covered;
  final bool selected;
  final String label;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: size,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: size,
                height: size,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? primary : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: _CityMapArt(
                  coverKey: ValueKey('gwt-city-cover-$city'),
                  city: city,
                  side: side,
                  covered: covered,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    color: selected ? primary : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A city map, with its cover tile over the city center when in play.
class _CityMapArt extends StatelessWidget {
  const _CityMapArt({
    super.key,
    required this.coverKey,
    required this.city,
    required this.side,
    required this.covered,
    this.semanticLabel,
  });

  final Key coverKey;
  final String city;
  final String side;
  final bool covered;
  final String? semanticLabel;

  /// Where the cover tile sits on a map, as fractions of the map's size.
  static const _centerX = 0.497;
  static const _centerY = 0.587;
  static const _coverRadius = 0.198;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        final radius = size * _coverRadius;
        return ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.02),
          child: Stack(
            children: [
              Positioned.fill(
                child: loadingImage(
                  GwtCityMaps.mapAsset(city, side),
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  semanticLabel: semanticLabel,
                  excludeFromSemantics: semanticLabel == null,
                ),
              ),
              if (covered)
                Positioned(
                  key: coverKey,
                  left: size * _centerX - radius,
                  top: size * _centerY - radius,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: loadingImage(
                        GwtCityMaps.coverAsset,
                        width: radius * 2,
                        height: radius * 2,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                        semanticLabel: context.l10n.t('gwt.cityMaps.cover'),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
