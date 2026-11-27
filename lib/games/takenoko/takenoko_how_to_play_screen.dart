import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../century/century_widgets.dart';
import 'takenoko_game.dart';
import 'takenoko_rules.dart';

/// The rulebook's Playing the Game section, following the 2nd edition.
class TakenokoHowToPlayScreen extends StatelessWidget {
  const TakenokoHowToPlayScreen({super.key});

  static const weather = [
    (key: 'sun', icon: Icons.wb_sunny_rounded),
    (key: 'rain', icon: Icons.water_drop_rounded),
    (key: 'wind', icon: Icons.air_rounded),
    (key: 'storm', icon: Icons.bolt_rounded),
    (key: 'clouds', icon: Icons.cloud_rounded),
    (key: 'choice', icon: Icons.help_outline_rounded),
  ];

  static const actions = [
    (key: 'plot', icon: Icons.hexagon_outlined),
    (key: 'irrigation', icon: Icons.water_rounded),
    (key: 'gardener', icon: Icons.agriculture_rounded),
    (key: 'panda', icon: Icons.pets_rounded),
    (key: 'objective', icon: Icons.style_outlined),
  ];

  static const improvements = [
    (key: 'enclosure', icon: Icons.fence_rounded),
    (key: 'fertilizer', icon: Icons.spa_rounded),
    (key: 'watershed', icon: Icons.water_drop_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String t(String key, [Map<String, String> args = const {}]) =>
        l10n.t('takenoko.play.$key', args);

    return CenturyPage(
      titleKey: 'hub.howToPlay',
      style: TakenokoGame.style,
      children: [
        CenturyPanel(
          key: const ValueKey('takenoko-play-turn'),
          title: t('turnTitle'),
          body: t('turnBody'),
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                CenturyActionChip(text: t('weatherStep')),
                // Points the reading way, so it flips in Persian.
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: TakenokoGame.bamboo,
                  size: 22,
                ),
                CenturyActionChip(text: t('actionsStep')),
              ],
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('takenoko-play-weather'),
          title: t('weatherTitle'),
          body: t('weatherBody'),
          children: [
            for (final face in weather)
              CenturyPoint(
                key: ValueKey('takenoko-play-weather-${face.key}'),
                icon: face.icon,
                title: t('weather.${face.key}.title'),
                text: t('weather.${face.key}'),
              ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('takenoko-play-actions'),
          title: t('actionsTitle'),
          body: t('actionsBody'),
          children: [
            for (final action in actions)
              CenturyPoint(
                key: ValueKey('takenoko-play-action-${action.key}'),
                icon: action.icon,
                title: t('action.${action.key}.title'),
                text: t('action.${action.key}', {
                  'n': '${TakenokoRules.handLimit}',
                }),
              ),
            const SizedBox(height: 8),
            CenturyNote(text: t('shared')),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('takenoko-play-growth'),
          title: t('growthTitle'),
          body: t('growthBody'),
          children: [
            CenturyPoint(
              icon: Icons.water_drop_outlined,
              text: t('growth.irrigated'),
            ),
            CenturyPoint(icon: Icons.eco_outlined, text: t('growth.first')),
            CenturyPoint(icon: Icons.height_rounded, text: t('growth.max')),
            const SizedBox(height: 8),
            CenturyNote(
              icon: Icons.warning_amber_rounded,
              text: t('growth.never'),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('takenoko-play-movement'),
          title: t('moveTitle'),
          body: t('moveBody'),
          children: [
            CenturyPoint(icon: Icons.water_rounded, text: t('move.pond')),
            CenturyPoint(icon: Icons.block_rounded, text: t('move.gap')),
            CenturyPoint(
              icon: Icons.directions_walk_rounded,
              text: t('move.atLeast'),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('takenoko-play-improvements'),
          title: t('improvementsTitle'),
          body: t('improvementsBody'),
          children: [
            for (final improvement in improvements)
              CenturyPoint(
                key: ValueKey('takenoko-play-improvement-${improvement.key}'),
                icon: improvement.icon,
                title: t('improvement.${improvement.key}.title'),
                text: t('improvement.${improvement.key}'),
              ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('takenoko-play-objectives'),
          title: t('objectivesTitle'),
          body: t('objectivesBody'),
          children: [
            CenturyNote(
              icon: Icons.emoji_events_outlined,
              text: t('objectivesEnd'),
            ),
          ],
        ),
      ],
    );
  }
}
