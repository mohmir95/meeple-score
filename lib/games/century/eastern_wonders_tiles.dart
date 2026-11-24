import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import 'century_eastern_wonders_rules.dart';
import 'century_widgets.dart';

const _market = Color(0xFF7FA66B);
const _port = Color(0xFF3E8FA0);
const _vpTile = Color(0xFFD9822B);
const _vpBack = Color(0xFF5E8C86);
const _closed = Color(0xFFB23A2E);
const _bonus = Color(0xFFB23A2E);

enum _Hex { market, port, sea }

/// A small honeycomb of market tiles with a port at each corner. Eastern
/// Wonders' map is 5 columns of 4, 5, 6, 5 and 4 tiles, the outer columns
/// starting and ending with a port. With [sea], the From Sand to Sea map:
/// the same shape with 4 of the market tiles swapped for sea tiles.
class EwMiniMap extends StatelessWidget {
  const EwMiniMap({super.key, required this.hex, this.sea = false});

  final double hex;
  final bool sea;

  static const _m = _Hex.market, _p = _Hex.port, _s = _Hex.sea;

  /// Columns of the Eastern Wonders map, left to right, top to bottom.
  static const _columns = [
    [_p, _m, _m, _p],
    [_m, _m, _m, _m, _m],
    [_m, _m, _m, _m, _m, _m],
    [_m, _m, _m, _m, _m],
    [_p, _m, _m, _p],
  ];

  /// Columns of the From Sand to Sea map for a first game.
  static const _seaColumns = [
    [_p, _m, _m, _p],
    [_m, _s, _m, _s, _m],
    [_m, _m, _m, _m, _m, _s],
    [_m, _s, _m, _m, _m],
    [_p, _m, _m, _p],
  ];

  static const _seaColor = Color(0xFF7CC4D6);

  Widget _tile(_Hex kind, {bool flatTop = false}) {
    Widget icon(Color color, IconData data) => Stack(
      alignment: Alignment.center,
      children: [
        HexTile(color: color, size: hex, flatTop: flatTop),
        Icon(data, color: Colors.white, size: hex * 0.45),
      ],
    );
    return switch (kind) {
      _Hex.market => HexTile(color: _market, size: hex, flatTop: flatTop),
      _Hex.sea => icon(_seaColor, Icons.waves_rounded),
      _Hex.port => icon(_port, Icons.anchor_rounded),
    };
  }

  /// Flat-topped tiles in straight columns, each column centred.
  Widget _columnMap() {
    final columns = sea ? _seaColumns : _columns;
    final h = HexTile.heightFor(hex, flatTop: true);
    final gap = hex * 0.06;
    final stepX = hex * 0.75 + gap;
    final stepY = h + gap;
    final tallest = columns.fold(0, (n, c) => c.length > n ? c.length : n);
    return SizedBox(
      key: const ValueKey('ew-mini-map-columns'),
      width: (columns.length - 1) * stepX + hex,
      height: tallest * stepY - gap,
      child: Stack(
        children: [
          for (var c = 0; c < columns.length; c++)
            for (var i = 0; i < columns[c].length; i++)
              Positioned(
                left: c * stepX,
                top: ((tallest - columns[c].length) / 2 + i) * stepY,
                child: _tile(columns[c][i], flatTop: true),
              ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _columnMap();
  }
}

/// Example custom map shapes, like the rulebook's "Create Your Own Maps".
class EwMapShapes extends StatelessWidget {
  const EwMapShapes({super.key, required this.hex});

  final double hex;

  /// The rulebook's three examples, each using all 24 tiles. Columns as
  /// (top offset in tiles, number of tiles), left to right. Neighbouring
  /// columns sit half a tile apart, so they interlock.
  static const _shapes = [
    // A diagonal band rising to the right.
    [(2.0, 3), (1.5, 4), (1.0, 4), (0.5, 4), (0.0, 4), (0.5, 3), (1.0, 2)],
    // A bumpy top over a V-shaped bottom.
    [(0.0, 3), (0.5, 3), (0.0, 4), (0.5, 4), (0.0, 4), (0.5, 3), (0.0, 3)],
    // Rising to a peak on the right, with a notch beneath it.
    [(1.0, 4), (1.5, 4), (1.0, 4), (0.5, 4), (0.0, 4), (0.5, 4)],
  ];

  static const _teal = Color(0xFF6CB8B8);

  @override
  Widget build(BuildContext context) {
    final h = HexTile.heightFor(hex, flatTop: true);
    final gap = hex * 0.06;
    final stepX = hex * 0.75 + gap;
    final stepY = h + gap;
    Widget shape(List<(double, int)> columns) {
      final bottom = columns.fold(
        0.0,
        (b, c) => c.$1 + c.$2 > b ? c.$1 + c.$2 : b,
      );
      return SizedBox(
        width: (columns.length - 1) * stepX + hex,
        height: bottom * stepY - gap,
        child: Stack(
          children: [
            for (var c = 0; c < columns.length; c++)
              for (var i = 0; i < columns[c].$2; i++)
                Positioned(
                  left: c * stepX,
                  top: (columns[c].$1 + i) * stepY,
                  child: HexTile(color: _teal, size: hex, flatTop: true),
                ),
          ],
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Wrap(
        key: const ValueKey('ew-map-shapes'),
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: hex,
        runSpacing: hex * 0.6,
        children: [for (final s in _shapes) shape(s)],
      ),
    );
  }
}

/// A VP tile on each port, then the Closed Port tile hidden among the next
/// tiles of the pile.
class EwVpTiles extends StatelessWidget {
  const EwVpTiles({super.key, required this.hex});

  final double hex;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: centuryMuted,
      fontWeight: FontWeight.w700,
    );
    Widget group(String label, List<Widget> tiles) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) SizedBox(width: hex * 0.08),
              tiles[i],
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(label, textAlign: TextAlign.center, style: labelStyle),
      ],
    );
    return Directionality(
      textDirection: TextDirection.ltr,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            group(l10n.t('centuryEw.setup.onPorts'), [
              for (var i = 0; i < EasternWondersRules.ports; i++)
                HexTile(color: _vpTile, size: hex, label: 'VP'),
            ]),
            SizedBox(width: hex * 0.6),
            group(
              l10n.t('centuryEw.setup.pileTop', {
                'n': '${EasternWondersRules.closedPortAmong + 1}',
              }),
              [
                for (var i = 0; i <= EasternWondersRules.closedPortAmong; i++)
                  i == 2
                      ? HexTile(
                          key: const ValueKey('ew-setup-closed-port'),
                          color: _closed,
                          size: hex,
                          label: '✕',
                        )
                      : HexTile(color: _vpBack, size: hex),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EwBonusTile extends StatelessWidget {
  const EwBonusTile({
    super.key,
    required this.vp,
    required this.size,
    required this.top,
  });

  final int vp;
  final double size;

  /// The tile on top of the stack, taken first.
  final bool top;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _bonus,
            borderRadius: BorderRadius.circular(size * 0.16),
            border: Border.all(
              color: top ? const Color(0xFFF0C674) : Colors.white,
              width: top ? 3 : 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 3,
                offset: Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '$vp',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: size * 0.48,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          top ? context.l10n.t('centuryEw.setup.onTop') : ' ',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: centuryMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
