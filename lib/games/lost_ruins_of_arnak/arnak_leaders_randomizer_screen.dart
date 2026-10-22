import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/player_colors.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/player_color_roster.dart';
import 'arnak_game.dart';
import 'arnak_leaders.dart';
import 'arnak_leaders_setup.dart';

/// Deals each player a few unique leaders to pick from.
class ArnakLeadersRandomizerScreen extends StatefulWidget {
  const ArnakLeadersRandomizerScreen({super.key, this.random});

  /// Injectable for tests.
  final math.Random? random;

  @override
  State<ArnakLeadersRandomizerScreen> createState() =>
      _ArnakLeadersRandomizerScreenState();
}

class _ArnakLeadersRandomizerScreenState
    extends State<ArnakLeadersRandomizerScreen> {
  static const _game = LostRuinsOfArnakGame();

  late final math.Random _random = widget.random ?? math.Random();

  /// Each player's color, in seat order; its length is the player count.
  late List<int> _colors = [
    for (final option in _game.playerColors.take(2)) option.value,
  ];
  late List<List<ArnakLeader>> _hands = ArnakLeaderDraft.deal(
    _colors.length,
    _random,
  );

  PlayerColorOption _colorAt(int index) {
    return _game.playerColors.firstWhere(
      (option) => option.value == _colors[index],
    );
  }

  /// Bumped on every deal so the portraits replay their drop-in animation.
  int _dealId = 0;

  void _deal() {
    setState(() {
      _hands = ArnakLeaderDraft.deal(_colors.length, _random);
      _dealId++;
    });
  }

  void _addPlayer(int colorValue) {
    if (_colors.length >= _game.maxPlayers || _colors.contains(colorValue)) {
      return;
    }
    _colors = [..._colors, colorValue];
    _deal();
  }

  void _removePlayer() {
    if (_colors.length <= _game.minPlayers) {
      return;
    }
    _colors = _colors.sublist(0, _colors.length - 1);
    _deal();
  }

  /// Recolors a seat; if another seat had that color, they swap.
  void _setColor(int index, int colorValue) {
    final taken = _colors.indexOf(colorValue);
    if (taken == index) {
      return;
    }
    setState(() {
      final next = [..._colors];
      if (taken != -1) {
        next[taken] = next[index];
      }
      next[index] = colorValue;
      _colors = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;

    return AppPage(
      title: l10n.t('hub.leadersRandomizer'),
      coverImageAsset: LostRuinsOfArnakGame.coverAsset,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(compact ? 12 : 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.t('arnak.draft.hint', {
                    'n': '${ArnakLeaderDraft.choicesFor(_colors.length)}',
                  }),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.t('players.title'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: PlayerColorRoster(
                        colors: [
                          for (var i = 0; i < _colors.length; i++) _colorAt(i),
                        ],
                        options: _game.playerColors,
                        accent: _game.accentColor,
                        keyPrefix: 'arnak-draft',
                        minPlayers: _game.minPlayers,
                        onAdd: _addPlayer,
                        onRemove: _removePlayer,
                        onColor: _setColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      key: const ValueKey('arnak-draft-randomize'),
                      onPressed: _deal,
                      icon: const Icon(Icons.shuffle),
                      label: Text(l10n.t('arnak.draft.randomize')),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                for (var p = 0; p < _hands.length; p++) ...[
                  if (p > 0) const SizedBox(height: 12),
                  _PlayerHand(
                    key: ValueKey('arnak-draft-hand-$p'),
                    label: l10n.t('players.numbered', {'n': '${p + 1}'}),
                    colorValue: _colors[p],
                    leaders: _hands[p],
                    compact: compact,
                    dealId: _dealId,
                    // Seat-order index of this hand's first card.
                    firstCard: p * ArnakLeaderDraft.choicesFor(_hands.length),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerHand extends StatelessWidget {
  const _PlayerHand({
    super.key,
    required this.label,
    required this.colorValue,
    required this.leaders,
    required this.compact,
    required this.dealId,
    required this.firstCard,
  });

  final String label;
  final int colorValue;
  final List<ArnakLeader> leaders;
  final bool compact;

  /// Changes on every deal, replaying the drop-in animation.
  final int dealId;

  /// Position of this hand's first card in the overall deal order.
  final int firstCard;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final portrait = compact ? 64.0 : 80.0;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: playerColor(colorValue),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: compact ? 12 : 20,
              runSpacing: 12,
              children: [
                for (var i = 0; i < leaders.length; i++)
                  _DealIn(
                    key: ValueKey('$dealId-${leaders[i].id}'),
                    order: firstCard + i,
                    child: SizedBox(
                      width: portrait + 16,
                      child: Column(
                        children: [
                          ArnakLeaderPortrait(
                            leader: leaders[i],
                            size: portrait,
                            colorValue: colorValue,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.t(leaders[i].l10nKey),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Drops a dealt card into place: it fades in while sliding down and
/// settling from a smaller size, one after another in deal [order].
class _DealIn extends StatelessWidget {
  const _DealIn({super.key, required this.order, required this.child});

  final int order;
  final Widget child;

  static const _stagger = Duration(milliseconds: 90);
  static const _drop = Duration(milliseconds: 420);

  @override
  Widget build(BuildContext context) {
    final delay = _stagger * order;
    final total = delay + _drop;
    final start = delay.inMicroseconds / total.inMicroseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: Curves.easeOutBack),
      child: child,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * -28),
            child: Transform.scale(scale: 0.6 + 0.4 * t, child: child),
          ),
        );
      },
    );
  }
}
