import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/widgets/app_page.dart';
import 'project_l_game.dart';

/// Rule changes from the revised (2.0) and 2.5 rulebooks that work with the
/// original box: 90 pieces, 4 player mats, 2–4 players.
class ProjectLRevisedRules {
  const ProjectLRevisedRules._();

  static const groups = [
    (
      key: 'turn',
      rules: [
        (key: 'recycle', source: '2.0', optional: false),
        (key: 'blindDraw', source: '2.0', optional: false),
        (key: 'runOut', source: '2.5', optional: false),
      ],
    ),
    (
      key: 'end',
      rules: [
        (key: 'blackLimit', source: '2.0', optional: false),
        (key: 'unfinished', source: '2.0', optional: false),
      ],
    ),
    (
      key: 'other',
      rules: [
        (key: 'faceDown', source: '2.0', optional: false),
        (key: 'finishing', source: '2.0', optional: false),
        (key: 'endlessWhite', source: '2.5', optional: true),
      ],
    ),
  ];
}

const _panel = Color(0xFF11161B);
const _ink = Color(0xFFE8EEF2);
const _muted = Color(0xFF9AA8B4);

class ProjectLRevisedRulesScreen extends StatelessWidget {
  const ProjectLRevisedRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final padding = compact ? 12.0 : 20.0;
    var number = 0;

    return AppPage(
      title: l10n.t('hub.revisedRules'),
      coverImageAsset: ProjectLGame.coverAsset,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.t('projectL.rules.intro'),
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
                for (final group in ProjectLRevisedRules.groups) ...[
                  SizedBox(height: compact ? 18 : 24),
                  Text(
                    l10n.t('projectL.rules.group.${group.key}'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final rule in group.rules) ...[
                    _RuleCard(
                      key: ValueKey('project-l-rule-${rule.key}'),
                      number: ++number,
                      title: l10n.t('projectL.rules.${rule.key}.title'),
                      body: l10n.t('projectL.rules.${rule.key}.body'),
                      source: l10n.t('projectL.rules.source', {
                        'v': rule.source,
                      }),
                      optional: rule.optional
                          ? l10n.t('projectL.rules.optional')
                          : null,
                      compact: compact,
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    super.key,
    required this.number,
    required this.title,
    required this.body,
    required this.source,
    required this.optional,
    required this.compact,
  });

  final int number;
  final String title;
  final String body;
  final String source;
  final String? optional;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const accent = ProjectLGame.cyan;
    final badge = compact ? 30.0 : 34.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 14 : 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: badge,
              height: badge,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(width: compact ? 12 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: _ink, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _Tag(text: source, color: _muted),
                      if (optional != null)
                        _Tag(text: optional!, color: accent),
                    ],
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

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
