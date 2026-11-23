import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import 'century_rules.dart';
import 'century_widgets.dart';

/// What each player starts with: two starting cards, a caravan, and spice
/// cubes that depend on the seat. Every seat is listed, up to 5 players.
class CenturyStartingResourcesScreen extends StatelessWidget {
  const CenturyStartingResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final card = compact ? 26.0 : 30.0;
    final cube = compact ? 20.0 : 24.0;

    return CenturyPage(
      titleKey: 'hub.startingResources',
      children: [
        CenturyPanel(
          key: const ValueKey('century-start-each'),
          title: l10n.t('century.start.eachTitle'),
          children: [
            CenturyRow(
              key: const ValueKey('century-start-create'),
              lead: CenturyCard(
                color: centuryMerchantBack,
                width: card,
                faceUp: true,
              ),
              label: l10n.t('century.start.create'),
              hint: l10n.t('century.start.createHint'),
              value: '1',
            ),
            CenturyRow(
              key: const ValueKey('century-start-upgrade'),
              lead: CenturyCard(
                color: centuryMerchantBack,
                width: card,
                faceUp: true,
              ),
              label: l10n.t('century.start.upgrade'),
              hint: l10n.t('century.start.upgradeHint'),
              value: '1',
            ),
            CenturyRow(
              key: const ValueKey('century-start-caravan'),
              lead: CenturyCard(color: centuryCaravanBack, width: card),
              label: l10n.t('century.start.caravan'),
              hint: l10n.t('century.start.caravanHint', {
                'n': '${CenturyRules.caravanLimit}',
              }),
              value: '1',
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('century-start-spices'),
          title: l10n.t('century.start.spicesTitle'),
          body: l10n.t('century.start.spicesBody'),
          children: [
            for (var seat = 1; seat <= CenturyRules.playerCounts.last; seat++)
              _seatRow(context, seat, cube),
            SizedBox(height: compact ? 10 : 12),
            CenturyNote(text: l10n.t('century.start.spicesNote')),
          ],
        ),
      ],
    );
  }

  Widget _seatRow(BuildContext context, int seat, double cube) {
    final l10n = context.l10n;
    final spices = CenturyRules.startingSpices(seat);
    final total = spices.values.fold(0, (sum, n) => sum + n);
    return CenturyRow(
      key: ValueKey('century-start-seat-$seat'),
      lead: _SeatBadge(seat: seat, first: seat == 1),
      label: l10n.t('century.start.seat.$seat'),
      hint: [
        for (final spice in CenturySpice.values)
          if ((spices[spice] ?? 0) > 0)
            l10n.t('century.start.cubes', {
              'n': '${spices[spice]}',
              'spice': l10n.t('century.colour.${spice.name}'),
            }),
      ].join(' + '),
      value: '$total',
      trailing: Directionality(
        textDirection: TextDirection.ltr,
        child: SpiceCubes(counts: spices, size: cube),
      ),
    );
  }
}

class _SeatBadge extends StatelessWidget {
  const _SeatBadge({required this.seat, required this.first});

  final int seat;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: first ? const Color(0xFFE2B33C) : centuryCaravanBack,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$seat',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 15,
        ),
      ),
    );
  }
}
