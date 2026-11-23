import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import 'century_rules.dart';
import 'century_widgets.dart';

/// The rulebook's Game Setup steps, with the numbers for the player count.
class CenturySetupHintsScreen extends StatefulWidget {
  const CenturySetupHintsScreen({super.key});

  @override
  State<CenturySetupHintsScreen> createState() =>
      _CenturySetupHintsScreenState();
}

class _CenturySetupHintsScreenState extends State<CenturySetupHintsScreen> {
  /// Point values on the rulebook's setup picture, for flavour.
  static const _samplePoints = [11, 15, 12, 9, 14];

  var _players = 4;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final cardWidth = compact ? 40.0 : 56.0;
    final spacing = compact ? 6.0 : 10.0;
    final coins = CenturyRules.coinsPerPile(_players);
    final toBox = CenturyRules.startingCardsToBox(_players);

    return CenturyPage(
      titleKey: 'hub.setupHints',
      children: [
        CenturyPlayerPicker(
          players: _players,
          onChanged: (n) => setState(() => _players = n),
        ),
        CenturyPanel(
          key: const ValueKey('century-setup-points'),
          title: l10n.t('century.setup.pointsTitle'),
          body: l10n.t('century.setup.pointsBody', {
            'cards': '${CenturyRules.faceUpPointCards}',
            'n': '$coins',
          }),
          children: [
            _Table(
              spacing: spacing,
              children: [
                for (var i = 0; i < CenturyRules.faceUpPointCards; i++)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: cardWidth,
                        child: i < 2
                            ? _CoinPile(
                                key: ValueKey(
                                  'century-setup-${i == 0 ? 'gold' : 'silver'}',
                                ),
                                gold: i == 0,
                                count: coins,
                                size: cardWidth * 0.6,
                              )
                            : null,
                      ),
                      SizedBox(height: spacing),
                      CenturyCard(
                        color: centuryPointBack,
                        width: cardWidth,
                        faceUp: true,
                        label: '${_samplePoints[i]}',
                      ),
                    ],
                  ),
                CenturyCard(
                  color: centuryPointBack,
                  width: cardWidth,
                  deck: true,
                ),
              ],
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('century-setup-merchants'),
          title: l10n.t('century.setup.merchantsTitle'),
          body: l10n.t('century.setup.merchantsBody', {
            'cards': '${CenturyRules.faceUpMerchantCards}',
          }),
          children: [
            _Table(
              spacing: spacing,
              children: [
                for (var i = 0; i < CenturyRules.faceUpMerchantCards; i++)
                  CenturyCard(
                    color: centuryMerchantBack,
                    width: cardWidth,
                    faceUp: true,
                  ),
                CenturyCard(
                  color: centuryMerchantBack,
                  width: cardWidth,
                  deck: true,
                ),
              ],
            ),
            SizedBox(height: compact ? 12 : 16),
            CenturyRow(
              key: const ValueKey('century-setup-starting-cards'),
              lead: CenturyCard(
                color: centuryMerchantBack,
                width: compact ? 24 : 28,
                faceUp: true,
              ),
              label: l10n.t('century.setup.startingCards'),
              hint: l10n.t('century.setup.startingCardsHint'),
              value: '${CenturyRules.startingCardsPerPlayer * _players}',
              highlight: true,
            ),
            if (toBox > 0)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: CenturyBadge(
                  key: const ValueKey('century-setup-to-box'),
                  text: l10n.t('century.setup.toBox', {'n': '$toBox'}),
                  error: true,
                ),
              ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('century-setup-spices'),
          title: l10n.t('century.setup.spicesTitle'),
          body: l10n.t('century.setup.spicesBody'),
          children: [_SpiceOrder(compact: compact)],
        ),
      ],
    );
  }
}

/// Cards laid out as on the table: face-up row with the deck on the right,
/// in every language.
class _Table extends StatelessWidget {
  const _Table({required this.children, required this.spacing});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                SizedBox(
                  width: i == children.length - 1 ? spacing * 2 : spacing,
                ),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _CoinPile extends StatelessWidget {
  const _CoinPile({
    super.key,
    required this.gold,
    required this.count,
    required this.size,
  });

  final bool gold;
  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CenturyCoin(gold: gold, size: size),
          Text(
            '× $count',
            style: TextStyle(
              color: centuryInk,
              fontWeight: FontWeight.w900,
              fontSize: size * 0.45,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// The four bowls in upgrade order, yellow to brown.
class _SpiceOrder extends StatelessWidget {
  const _SpiceOrder({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cube = compact ? 30.0 : 40.0;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final spice in CenturySpice.values) ...[
            if (spice.index > 0)
              Padding(
                padding: EdgeInsets.only(top: cube * 0.3),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: compact ? 16 : 20,
                  color: centuryMuted,
                ),
              ),
            Expanded(
              child: Column(
                key: ValueKey('century-setup-spice-${spice.name}'),
                children: [
                  SpiceCube(spice: spice, size: cube),
                  const SizedBox(height: 6),
                  Text(
                    l10n.t('century.spice.${spice.name}'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: centuryInk,
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 12 : 14,
                    ),
                  ),
                  Text(
                    l10n.t('century.colour.${spice.name}'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: centuryMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: compact ? 11 : 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
