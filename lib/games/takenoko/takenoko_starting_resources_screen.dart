import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../century/century_widgets.dart';
import 'takenoko_game.dart';
import 'takenoko_rules.dart';

/// What each player starts with. The same for every player count and in
/// both editions.
class TakenokoStartingResourcesScreen extends StatelessWidget {
  const TakenokoStartingResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final card = compact ? 22.0 : 26.0;
    final wide = compact ? 64.0 : 76.0;

    String times(int n) => '× $n';

    Widget icon(IconData data) =>
        Icon(data, color: TakenokoGame.bamboo, size: compact ? 26 : 30);

    return CenturyPage(
      titleKey: 'hub.startingResources',
      style: TakenokoGame.style,
      children: [
        CenturyPanel(
          key: const ValueKey('takenoko-start-each'),
          title: l10n.t('takenoko.start.eachTitle'),
          body: l10n.t('takenoko.start.eachBody'),
          children: [
            CenturyRow(
              key: const ValueKey('takenoko-start-board'),
              lead: icon(Icons.dashboard_outlined),
              leadWidth: wide,
              label: l10n.t('takenoko.start.board'),
              value: times(1),
            ),
            CenturyRow(
              key: const ValueKey('takenoko-start-tokens'),
              lead: icon(Icons.radio_button_checked_rounded),
              leadWidth: wide,
              label: l10n.t('takenoko.start.tokens'),
              value: times(TakenokoRules.actionTokensPerPlayer),
            ),
            CenturyRow(
              key: const ValueKey('takenoko-start-hand'),
              lead: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (i, objective)
                        in TakenokoObjective.values.indexed) ...[
                      if (i > 0) const SizedBox(width: 3),
                      CenturyCard(color: objective.color, width: card * 0.8),
                    ],
                  ],
                ),
              ),
              leadWidth: wide,
              label: l10n.t('takenoko.start.hand'),
              hint: l10n.t('takenoko.start.handHint'),
              value: times(TakenokoObjective.values.length),
            ),
          ],
        ),
      ],
    );
  }
}
