import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/widgets/app_page.dart';
import 'cob_game.dart';

typedef CobExpansion = ({
  String key,
  Map<String, int> coloured,
  Map<String, int> black,
});

/// Component counts from pages 2 and 3 of the Special Edition rulebook.
class CobTileCounts {
  const CobTileCounts._();

  /// Hex tile types with their base-game coloured and black market counts.
  /// Inns exist only in the 6th Expansion.
  static const hexTypes = [
    (key: 'buildings', color: Color(0xFFE2C48C), base: 40, baseBlack: 16),
    (key: 'livestock', color: Color(0xFF79AE3D), base: 20, baseBlack: 8),
    (key: 'mines', color: Color(0xFF8C9196), base: 10, baseBlack: 2),
    (key: 'ships', color: Color(0xFF4FA8DC), base: 20, baseBlack: 6),
    (key: 'monasteries', color: Color(0xFFF1C232), base: 20, baseBlack: 6),
    (key: 'castles', color: Color(0xFFA6263E), base: 14, baseBlack: 2),
    (key: 'inns', color: Color(0xFFF2ECE0), base: 0, baseBlack: 0),
  ];

  /// Black market tiles in the base game.
  static int get baseBlack => hexTypes.fold(0, (sum, t) => sum + t.baseBlack);

  /// Hex tiles each expansion adds, coloured and black market, by type.
  static const List<CobExpansion> expansions = [
    // Black market: a geese (livestock) and a crane (building) tile.
    (
      key: 'second',
      coloured: {'monasteries': 2},
      black: {'livestock': 1, 'buildings': 1},
    ),
    // Black market: 2 building tiles.
    (
      key: 'whiteCastles',
      coloured: {'buildings': 6, 'monasteries': 1},
      black: {'buildings': 2},
    ),
    (key: 'inns', coloured: {'inns': 5}, black: {}),
  ];

  static Set<String> get allExpansions => {for (final e in expansions) e.key};

  static Iterable<CobExpansion> _on(Set<String> enabled) =>
      expansions.where((e) => enabled.contains(e.key));

  static int tilesIn(CobExpansion e) =>
      e.coloured.values.fold(0, (sum, n) => sum + n) +
      e.black.values.fold(0, (sum, n) => sum + n);

  static int coloured(String type, Set<String> enabled) =>
      hexTypes.firstWhere((t) => t.key == type).base +
      _on(enabled).fold(0, (sum, e) => sum + (e.coloured[type] ?? 0));

  static int colouredTotal(Set<String> enabled) =>
      hexTypes.fold(0, (sum, t) => sum + coloured(t.key, enabled));

  static int blackOf(String type, Set<String> enabled) =>
      hexTypes.firstWhere((t) => t.key == type).baseBlack +
      _on(enabled).fold(0, (sum, e) => sum + (e.black[type] ?? 0));

  static int black(Set<String> enabled) =>
      hexTypes.fold(0, (sum, t) => sum + blackOf(t.key, enabled));

  static int total(Set<String> enabled) =>
      colouredTotal(enabled) + black(enabled);

  /// Expansions that add other components, not hex tiles. Off by default.
  static const otherExpansions = ['vineyards', 'shields', 'tradeRoutes'];

  /// Every switch, in the order shown.
  static List<String> get toggles => [
    for (final e in expansions) e.key,
    ...otherExpansions,
  ];

  /// Vineyards Expansion.
  static const vineyardDoubleHexes = 51;
  static const vineBonusTiles = 24;

  static const shieldTiles = 18;
  static const tradeRouteTiles = 12;
  static const silverCoins = 24;
  static const workers = 26;

  /// Square trade goods tiles, 7 in each of 6 colours.
  static const tradeGoods = 42;
}

const _parchment = Color(0xFFF7F1E3);
const _ink = Color(0xFF2A2620);
const _muted = Color(0xFF6E6656);
const _wine = Color(0xFF6B2030);
const _blackTile = Color(0xFF2B2A28);

class CobTileCountsScreen extends StatefulWidget {
  const CobTileCountsScreen({super.key});

  @override
  State<CobTileCountsScreen> createState() => _CobTileCountsScreenState();
}

class _CobTileCountsScreenState extends State<CobTileCountsScreen> {
  /// Every expansion starts switched on.
  final _enabled = {...CobTileCounts.allExpansions};

  /// Whether the black market row is expanded to show its tiles by type.
  var _blackOpen = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final padding = compact ? 12.0 : 20.0;
    final gap = SizedBox(height: compact ? 16 : 20);

    return AppPage(
      title: l10n.t('hub.tileCounts'),
      coverImageAsset: CastlesOfBurgundySpecialEditionGame.coverAsset,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _expansionsPanel(context, compact),
                gap,
                _hexPanel(context, compact),
                gap,
                if (_enabled.contains('vineyards')) ...[
                  _vineyardsPanel(context, compact),
                  gap,
                ],
                _extrasPanel(context, compact),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _numberStyle(bool compact, {bool bold = false}) => TextStyle(
    color: _ink,
    fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
    fontSize: compact ? 16 : 18,
  );

  /// One table row: a tile swatch, a label, an optional breakdown such as
  /// "40 + 6", and a count on the right.
  Widget _row(
    BuildContext context,
    bool compact, {
    required Key key,
    required Widget lead,
    required String label,
    required String count,
    String? breakdown,
    bool bold = false,
    Widget? labelSuffix,
    double indent = 0,
  }) {
    final hex = compact ? 26.0 : 32.0;
    return Padding(
      key: key,
      padding: EdgeInsets.only(
        left: indent,
        top: compact ? 5 : 6,
        bottom: compact ? 5 : 6,
      ),
      child: Row(
        children: [
          SizedBox(
            width: hex * 1.2,
            child: Center(child: lead),
          ),
          SizedBox(width: compact ? 10 : 14),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: _ink,
                      fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                ),
                ?labelSuffix,
              ],
            ),
          ),
          if (breakdown != null)
            Text(
              breakdown,
              style: TextStyle(
                color: _muted,
                fontWeight: FontWeight.w700,
                fontSize: compact ? 12 : 13,
              ),
            ),
          SizedBox(
            width: compact ? 56 : 64,
            child: Text(
              count,
              textAlign: TextAlign.end,
              maxLines: 1,
              softWrap: false,
              style: _numberStyle(compact, bold: bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _expansionsPanel(BuildContext context, bool compact) {
    final l10n = context.l10n;
    return _Panel(
      key: const ValueKey('cob-tile-counts-expansions'),
      compact: compact,
      title: l10n.t('cob.tiles.expansionsTitle'),
      children: [
        // A Material of its own, so the rows' tap ripples show.
        Material(
          color: Colors.white.withValues(alpha: 0.55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: _wine.withValues(alpha: 0.2)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final key in CobTileCounts.toggles)
                _ExpansionToggle(
                  key: ValueKey('cob-tile-expansion-$key'),
                  label: l10n.t('cob.tiles.expansion.$key'),
                  value: _enabled.contains(key),
                  compact: compact,
                  onChanged: (on) => setState(() {
                    if (on) {
                      _enabled.add(key);
                    } else {
                      _enabled.remove(key);
                    }
                  }),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Coloured tiles by type, then the black market tiles as one count.
  Widget _hexPanel(BuildContext context, bool compact) {
    final l10n = context.l10n;
    final hex = compact ? 26.0 : 32.0;
    final black = CobTileCounts.black(_enabled);
    final blackAdded = black - CobTileCounts.baseBlack;
    const divider = Divider(height: 12, color: Color(0x332A2620));
    return _Panel(
      key: const ValueKey('cob-tile-counts-hexes'),
      compact: compact,
      title: l10n.t('cob.tiles.hexTitle', {
        'n': '${CobTileCounts.total(_enabled)}',
      }),
      children: [
        _row(
          context,
          compact,
          key: const ValueKey('cob-tile-sum-coloured'),
          lead: const SizedBox.shrink(),
          label: l10n.t('cob.tiles.coloured'),
          count: '${CobTileCounts.colouredTotal(_enabled)}',
          bold: true,
        ),
        for (final type in CobTileCounts.hexTypes)
          if (CobTileCounts.coloured(type.key, _enabled) > 0)
            _row(
              context,
              compact,
              key: ValueKey('cob-tile-coloured-${type.key}'),
              lead: _Hex(color: type.color, size: hex),
              label: l10n.t('cob.tiles.type.${type.key}'),
              breakdown:
                  type.base > 0 &&
                      CobTileCounts.coloured(type.key, _enabled) > type.base
                  ? '${type.base} + '
                        '${CobTileCounts.coloured(type.key, _enabled) - type.base}'
                  : null,
              count: '${CobTileCounts.coloured(type.key, _enabled)}',
            ),
        divider,
        // Tap to show the black market tiles by type. A Material of its own,
        // so the ripple shows over the panel.
        Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: const ValueKey('cob-tile-black-toggle'),
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _blackOpen = !_blackOpen),
            child: _row(
              context,
              compact,
              key: const ValueKey('cob-tile-sum-black'),
              lead: _Hex(color: _blackTile, size: hex),
              label: l10n.t('cob.tiles.blackMarket'),
              labelSuffix: AnimatedRotation(
                turns: _blackOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.expand_more_rounded, color: _muted),
              ),
              breakdown: blackAdded > 0
                  ? '${CobTileCounts.baseBlack} + $blackAdded'
                  : null,
              count: '$black',
              bold: true,
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: !_blackOpen
              ? const SizedBox(width: double.infinity)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final type in CobTileCounts.hexTypes)
                      if (CobTileCounts.blackOf(type.key, _enabled) > 0)
                        _row(
                          context,
                          compact,
                          key: ValueKey('cob-tile-black-${type.key}'),
                          indent: compact ? 12 : 16,
                          lead: _Hex(
                            color: _blackTile,
                            size: hex * 0.85,
                            rim: type.color,
                          ),
                          label: l10n.t('cob.tiles.type.${type.key}'),
                          breakdown:
                              CobTileCounts.blackOf(type.key, _enabled) >
                                  type.baseBlack
                              ? '${type.baseBlack} + '
                                    '${CobTileCounts.blackOf(type.key, _enabled) - type.baseBlack}'
                              : null,
                          count: '${CobTileCounts.blackOf(type.key, _enabled)}',
                        ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _vineyardsPanel(BuildContext context, bool compact) {
    final l10n = context.l10n;
    // Two hexes side by side must fit the row's swatch slot.
    final hex = compact ? 17.0 : 21.0;
    const vine = Color(0xFF6E8B2F);
    return _Panel(
      key: const ValueKey('cob-tile-counts-vineyards'),
      compact: compact,
      title: l10n.t('cob.tiles.vineyardsTitle'),
      children: [
        _row(
          context,
          compact,
          key: const ValueKey('cob-tile-vineyards-double'),
          lead: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Hex(color: vine, size: hex),
              _Hex(color: vine, size: hex),
            ],
          ),
          label: l10n.t('cob.tiles.doubleHexes'),
          count: '${CobTileCounts.vineyardDoubleHexes}',
        ),
        _row(
          context,
          compact,
          key: const ValueKey('cob-tile-vineyards-bonus'),
          lead: _VineBonusIcon(size: hex * 1.65),
          label: l10n.t('cob.tiles.vineBonus'),
          count: '${CobTileCounts.vineBonusTiles}',
        ),
      ],
    );
  }

  Widget _extrasPanel(BuildContext context, bool compact) {
    final l10n = context.l10n;
    final icon = compact ? 28.0 : 34.0;

    return _Panel(
      key: const ValueKey('cob-tile-counts-supplies'),
      compact: compact,
      title: l10n.t('cob.tiles.extrasTitle'),
      children: [
        if (_enabled.contains('shields'))
          _row(
            context,
            compact,
            key: const ValueKey('cob-tile-extra-shields'),
            lead: _ShieldIcon(size: icon),
            label: l10n.t('cob.tiles.shields'),
            count: '${CobTileCounts.shieldTiles}',
          ),
        if (_enabled.contains('tradeRoutes'))
          _row(
            context,
            compact,
            key: const ValueKey('cob-tile-extra-tradeRoutes'),
            lead: _TradeRouteIcon(size: icon),
            label: l10n.t('cob.tiles.tradeRoutes'),
            count: '${CobTileCounts.tradeRouteTiles}',
          ),
        _row(
          context,
          compact,
          key: const ValueKey('cob-tile-extra-silver'),
          lead: _CoinIcon(size: icon),
          label: l10n.t('cob.tiles.silver'),
          count: '${CobTileCounts.silverCoins}',
        ),
        _row(
          context,
          compact,
          key: const ValueKey('cob-tile-extra-workers'),
          lead: _WorkerIcon(size: icon),
          label: l10n.t('cob.tiles.workers'),
          count: '${CobTileCounts.workers}',
        ),
        _row(
          context,
          compact,
          key: const ValueKey('cob-tile-extra-goods'),
          lead: _GoodsIcon(size: icon),
          label: l10n.t('cob.tiles.tradeGoods'),
          count: '${CobTileCounts.tradeGoods}',
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    super.key,
    required this.compact,
    required this.title,
    required this.children,
  });

  final bool compact;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final accent = const CastlesOfBurgundySpecialEditionGame().accentColor;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _parchment,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 16 : 28,
          vertical: compact ? 18 : 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: _wine,
                fontWeight: FontWeight.w800,
                fontStyle: FontStyle.italic,
                height: 1.15,
              ),
            ),
            SizedBox(height: compact ? 12 : 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// A pointy-top hexagon tile.
class _Hex extends StatelessWidget {
  const _Hex({required this.color, required this.size, this.rim});

  final Color color;
  final double size;

  /// Outline colour; black market tiles show their type this way.
  final Color? rim;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * math.sqrt(3) / 2, size),
      painter: _HexPainter(color, rim),
    );
  }
}

class _HexPainter extends CustomPainter {
  const _HexPainter(this.color, this.rim);

  final Color color;
  final Color? rim;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final c = size.center(Offset.zero);
    final r = size.height / 2;
    for (var i = 0; i < 6; i++) {
      final angle = math.pi / 3 * i - math.pi / 2;
      final p = c + Offset(math.cos(angle), math.sin(angle)) * r;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas
      ..drawShadow(path, Colors.black, 1.5, false)
      ..drawPath(path, Paint()..color = color)
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rim == null ? 1 : size.height * 0.12
          ..color = rim ?? Color.lerp(color, Colors.black, 0.35)!,
      );
  }

  @override
  bool shouldRepaint(_HexPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.rim != rim;
}

/// A slim row with the expansion's name and a small switch.
class _ExpansionToggle extends StatelessWidget {
  const _ExpansionToggle({
    super.key,
    required this.label,
    required this.value,
    required this.compact,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final bool compact;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: compact ? 2 : 4,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Transform.scale(
              scale: 0.75,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: _wine,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A flat, single-colour shape with a darker outline, in the same style as
/// [_Hex].
class _Flat extends StatelessWidget {
  const _Flat({required this.color, required this.size, required this.shape});

  final Color color;
  final Size size;
  final Path Function(Size size) shape;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: size, painter: _FlatPainter(color, shape));
  }
}

class _FlatPainter extends CustomPainter {
  const _FlatPainter(this.color, this.shape);

  final Color color;
  final Path Function(Size size) shape;

  @override
  void paint(Canvas canvas, Size size) {
    final path = shape(size);
    canvas
      ..drawShadow(path, Colors.black, 1.5, false)
      ..drawPath(path, Paint()..color = color)
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Color.lerp(color, Colors.black, 0.35)!,
      );
  }

  @override
  bool shouldRepaint(_FlatPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.shape != shape;
}

/// Outlines for the flat component icons.
class _Shapes {
  const _Shapes._();

  static Path circle(Size s) => Path()..addOval(Offset.zero & s);

  static Path roundedSquare(Size s) => Path()
    ..addRRect(
      RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(s.width * 0.18)),
    );

  /// A long, rounded strip, like a trade route tile.
  static Path strip(Size s) => Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        Offset.zero & s,
        Radius.circular(s.height * 0.25),
      ),
    );

  /// A heater shield with a flat top.
  static Path shield(Size s) {
    final w = s.width, h = s.height;
    return Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.45)
      ..quadraticBezierTo(w, h * 0.85, w / 2, h)
      ..quadraticBezierTo(0, h * 0.85, 0, h * 0.45)
      ..close();
  }

  /// The vine bonus tile: a tall pear shape, broad and rounded at the top
  /// and narrowing to a rounded bottom, mirrored about the vertical axis.
  static Path vineTile(Size s) {
    final w = s.width, h = s.height;
    return Path()
      ..moveTo(w * 0.5, 0)
      ..cubicTo(w * 0.82, 0, w, h * 0.16, w, h * 0.4)
      ..cubicTo(w, h * 0.62, w * 0.8, h * 0.78, w * 0.72, h * 0.9)
      ..cubicTo(w * 0.66, h * 0.98, w * 0.58, h, w * 0.5, h)
      ..cubicTo(w * 0.42, h, w * 0.34, h * 0.98, w * 0.28, h * 0.9)
      ..cubicTo(w * 0.2, h * 0.78, 0, h * 0.62, 0, h * 0.4)
      ..cubicTo(0, h * 0.16, w * 0.18, 0, w * 0.5, 0)
      ..close();
  }
}

/// A silver coin.
class _CoinIcon extends StatelessWidget {
  const _CoinIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final d = size * 0.8;
    return _Flat(
      color: const Color(0xFFBCC1C8),
      size: Size(d, d),
      shape: _Shapes.circle,
    );
  }
}

/// A worker token: a teal square tile.
class _WorkerIcon extends StatelessWidget {
  const _WorkerIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final d = size * 0.78;
    return _Flat(
      color: const Color(0xFF7FB3A8),
      size: Size(d, d),
      shape: _Shapes.roundedSquare,
    );
  }
}

/// Trade goods: a small stack of square tiles in three of their colours.
class _GoodsIcon extends StatelessWidget {
  const _GoodsIcon({required this.size});

  final double size;

  static const _colours = [
    Color(0xFF4A86C8),
    Color(0xFFE0B23C),
    Color(0xFFB7322F),
  ];

  @override
  Widget build(BuildContext context) {
    final tile = size * 0.58;
    final step = size * 0.15;
    return SizedBox(
      width: tile + step * 2,
      height: tile + step * 2,
      child: Stack(
        children: [
          for (var i = 0; i < _colours.length; i++)
            Positioned(
              left: step * i,
              top: step * (2 - i),
              child: _Flat(
                color: _colours[i],
                size: Size(tile, tile),
                shape: _Shapes.roundedSquare,
              ),
            ),
        ],
      ),
    );
  }
}

/// A shield tile from the Shield Expansion.
class _ShieldIcon extends StatelessWidget {
  const _ShieldIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return _Flat(
      color: const Color(0xFFC09A4A),
      size: Size(size * 0.7, size * 0.82),
      shape: _Shapes.shield,
    );
  }
}

/// A trade route tile: a long green strip.
class _TradeRouteIcon extends StatelessWidget {
  const _TradeRouteIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return _Flat(
      color: const Color(0xFF7FA544),
      size: Size(size, size * 0.42),
      shape: _Shapes.strip,
    );
  }
}

/// A vine bonus tile from the Vineyards Expansion.
class _VineBonusIcon extends StatelessWidget {
  const _VineBonusIcon({required this.size});

  /// The tile's height; it is 0.8 times as wide.
  final double size;

  @override
  Widget build(BuildContext context) {
    return _Flat(
      color: const Color(0xFF6B3F9E),
      size: Size(size * 0.8, size),
      shape: _Shapes.vineTile,
    );
  }
}
