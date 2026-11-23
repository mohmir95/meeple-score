import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import 'century_eastern_wonders_rules.dart';
import 'century_widgets.dart';

const _market = Color(0xFF7FA66B);
const _port = Color(0xFF3E8FA0);
const _vpTile = Color(0xFFD9822B);
const _vpBack = Color(0xFF5E8C86);
const _closed = Color(0xFFB23A2E);
const _bonus = Color(0xFFB23A2E);

/// The Eastern Wonders rulebook's Game Setup steps for the shared table.
class EasternWondersSetupHintsScreen extends StatelessWidget {
  const EasternWondersSetupHintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final hex = compact ? 30.0 : 40.0;

    return CenturyPage(
      titleKey: 'hub.setupHints',
      style: CenturyStyleData.easternWonders,
      children: [
        CenturyPanel(
          key: const ValueKey('ew-setup-map'),
          title: l10n.t('centuryEw.setup.mapTitle'),
          body: l10n.t('centuryEw.setup.mapBody', {
            'ports': '${EasternWondersRules.ports}',
          }),
          children: [
            Center(child: _MiniMap(hex: hex)),
            SizedBox(height: compact ? 12 : 16),
            Center(
              child: CenturyBadge(
                key: const ValueKey('ew-setup-to-box'),
                text: l10n.t('centuryEw.setup.toBox', {
                  'n': '${EasternWondersRules.tradeSymbols}',
                }),
                error: true,
              ),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('ew-setup-vp'),
          title: l10n.t('centuryEw.setup.vpTitle'),
          body: l10n.t('centuryEw.setup.vpBody', {
            'ports': '${EasternWondersRules.ports}',
            'n': '${EasternWondersRules.closedPortAmong}',
            'top': '${EasternWondersRules.closedPortAmong + 1}',
          }),
          children: [_VpTiles(hex: hex * 0.85)],
        ),
        CenturyPanel(
          key: const ValueKey('ew-setup-bonus'),
          title: l10n.t('centuryEw.setup.bonusTitle'),
          body: l10n.t('centuryEw.setup.bonusBody'),
          children: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: compact ? 8 : 12,
                children: [
                  for (final vp in EasternWondersRules.bonusVp)
                    _BonusTile(
                      key: ValueKey('ew-setup-bonus-$vp'),
                      vp: vp,
                      size: hex,
                      top: vp == EasternWondersRules.bonusVp.first,
                    ),
                ],
              ),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('ew-setup-spices'),
          title: l10n.t('century.setup.spicesTitle'),
          body: l10n.t('centuryEw.setup.spicesBody'),
          children: [
            CenturySpiceOrder(
              nameKey: (s) =>
                  'centuryEw.spice.${EasternWondersRules.spiceNames[s]}',
            ),
          ],
        ),
      ],
    );
  }
}

/// A small honeycomb of market tiles with a port at each corner.
class _MiniMap extends StatelessWidget {
  const _MiniMap({required this.hex});

  final double hex;

  /// Rows of the map: true is a port, false a market tile. Rows of 4 sit
  /// half a tile in.
  static const _rows = [
    [true, false, false, false, true],
    [false, false, false, false],
    [false, false, false, false, false],
    [false, false, false, false],
    [true, false, false, false, true],
  ];

  @override
  Widget build(BuildContext context) {
    final h = hex * 1.1547;
    final gap = hex * 0.06;
    final step = hex + gap;
    return SizedBox(
      width: 5 * step,
      height: (_rows.length - 1) * h * 0.75 + h,
      child: Stack(
        children: [
          for (var r = 0; r < _rows.length; r++)
            for (var i = 0; i < _rows[r].length; i++)
              Positioned(
                left: (i + (_rows[r].length == 4 ? 0.5 : 0)) * step,
                top: r * h * 0.75,
                child: _rows[r][i]
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          HexTile(color: _port, size: hex),
                          Icon(
                            Icons.anchor_rounded,
                            color: Colors.white,
                            size: hex * 0.5,
                          ),
                        ],
                      )
                    : HexTile(color: _market, size: hex),
              ),
        ],
      ),
    );
  }
}

/// A VP tile on each port, then the Closed Port tile hidden among the next
/// tiles of the pile.
class _VpTiles extends StatelessWidget {
  const _VpTiles({required this.hex});

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

class _BonusTile extends StatelessWidget {
  const _BonusTile({
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
