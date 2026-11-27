import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../century/century_widgets.dart';
import 'takenoko_game.dart';

const _removedRed = Color(0xFFB3261E);

/// What the 2nd edition rulebook (2020) changed from the 1st edition one.
class TakenokoSecondEdition {
  const TakenokoSecondEdition._();

  /// [oldFirst] leads with the 1st edition rule, for rules the 2nd edition
  /// dropped; otherwise the 2nd edition rule comes first.
  static const groups = [
    (
      key: 'rules',
      oldFirst: false,
      changes: [
        'plotsReturn',
        'gardener',
        'irrigation',
        'clouds',
        'improvementMove',
      ],
    ),
    (
      key: 'removed',
      oldFirst: true,
      changes: ['improvementBamboo', 'variant', 'shortage'],
    ),
  ];
}

class TakenokoSecondEditionScreen extends StatelessWidget {
  const TakenokoSecondEditionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    var number = 0;

    return CenturyPage(
      titleKey: 'hub.updatedRules',
      style: TakenokoGame.style,
      children: [
        Text(
          l10n.t('takenoko.second.intro'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
        ),
        for (final group in TakenokoSecondEdition.groups)
          CenturyPanel(
            key: ValueKey('takenoko-second-${group.key}'),
            title: l10n.t('takenoko.second.group.${group.key}'),
            children: [
              for (final (i, change) in group.changes.indexed) ...[
                if (i > 0) const SizedBox(height: 12),
                _ChangeCard(
                  key: ValueKey('takenoko-second-$change'),
                  number: ++number,
                  title: l10n.t('takenoko.second.$change.title'),
                  before: l10n.t('takenoko.second.$change.before'),
                  after: l10n.t('takenoko.second.$change.after'),
                  oldFirst: group.oldFirst,
                ),
              ],
            ],
          ),
      ],
    );
  }
}

/// A numbered change: the leading rule shown open, the other edition's rule
/// beneath it (collapsed, except under a dropped rule).
class _ChangeCard extends StatelessWidget {
  const _ChangeCard({
    super.key,
    required this.number,
    required this.title,
    required this.before,
    required this.after,
    required this.oldFirst,
  });

  final int number;
  final String title;
  final String before;
  final String after;
  final bool oldFirst;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = CenturyStyle.of(context);
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final textTheme = Theme.of(context).textTheme;
    final badge = compact ? 28.0 : 32.0;

    final first = (label: l10n.t('takenoko.second.firstEdition'), text: before);
    final second = (
      label: l10n.t('takenoko.second.secondEdition'),
      text: after,
    );
    final lead = oldFirst ? first : second;
    final other = oldFirst ? second : first;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: badge,
          height: badge,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: style.accent,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SizedBox(width: compact ? 10 : 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.only(top: compact ? 3 : 5),
                child: Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    color: centuryInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _RuleBox(
                label: lead.label,
                text: lead.text,
                collapsible: false,
                // A rule the 2nd edition dropped is shown in red.
                color: oldFirst ? _removedRed : null,
              ),
              const SizedBox(height: 6),
              // Under a dropped rule, the 2nd edition note stays open.
              _RuleBox(
                label: other.label,
                text: other.text,
                collapsible: !oldFirst,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One edition's rule. An open one is in the accent colour; a [collapsible]
/// one is muted and shows only its label until tapped.
class _RuleBox extends StatefulWidget {
  const _RuleBox({
    required this.label,
    required this.text,
    required this.collapsible,
    this.color,
  });

  final String label;
  final String text;
  final bool collapsible;

  /// Replaces the accent colour of a leading box.
  final Color? color;

  @override
  State<_RuleBox> createState() => _RuleBoxState();
}

class _RuleBoxState extends State<_RuleBox> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final style = CenturyStyle.of(context);
    final textTheme = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(10);
    final lead = !widget.collapsible;
    final color = lead ? (widget.color ?? style.accent) : centuryMuted;
    final open = lead || _open;

    final label = Text(
      widget.label,
      style: textTheme.labelMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w900,
      ),
    );
    final body = Padding(
      padding: EdgeInsets.fromLTRB(12, lead ? 3 : 0, 12, 9),
      child: Text(
        widget.text,
        style: textTheme.bodyMedium?.copyWith(
          color: lead ? centuryInk : centuryMuted,
          height: 1.4,
        ),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: lead ? 0.1 : 0.06),
        borderRadius: radius,
        border: Border.all(color: color.withValues(alpha: lead ? 0.45 : 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (lead)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 0),
              child: label,
            )
          else
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: radius,
                onTap: () => setState(() => _open = !_open),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: Row(
                    children: [
                      Expanded(child: label),
                      AnimatedRotation(
                        turns: _open ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.expand_more_rounded,
                          size: 20,
                          color: centuryMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: open ? body : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
