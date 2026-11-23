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
            if (toBox > 0) ...[
              SizedBox(height: compact ? 12 : 16),
              Center(
                child: CenturyBadge(
                  key: const ValueKey('century-setup-to-box'),
                  text: l10n.t('century.setup.toBox', {'n': '$toBox'}),
                  error: true,
                ),
              ),
            ],
          ],
        ),
        CenturyPanel(
          key: const ValueKey('century-setup-spices'),
          title: l10n.t('century.setup.spicesTitle'),
          body: l10n.t('century.setup.spicesBody'),
          children: [
            CenturySpiceOrder(nameKey: (s) => 'century.spice.${s.name}'),
          ],
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
