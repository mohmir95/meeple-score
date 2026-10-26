import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/player_colors.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/player_color_roster.dart';
import 'shelfie_characters.dart';
import 'shelfie_game.dart';

/// Deals each player 8 of their 16 Character Cards.
class ShelfieCharacterRandomizerScreen extends StatefulWidget {
  const ShelfieCharacterRandomizerScreen({super.key, this.random});

  /// Injectable for tests.
  final math.Random? random;

  @override
  State<ShelfieCharacterRandomizerScreen> createState() =>
      _ShelfieCharacterRandomizerScreenState();
}

class _ShelfieCharacterRandomizerScreenState
    extends State<ShelfieCharacterRandomizerScreen> {
  static const _game = ShelfieStackerGame();

  late final math.Random _random = widget.random ?? math.Random();

  /// Each player's color, in seat order; its length is the player count.
  late List<int> _colors = [
    for (final option in _game.playerColors.take(2)) option.value,
  ];
  /// On by default: the rulebook recommends cards 1–8 to start with.
  var _firstGame = true;
  late List<List<ShelfieCharacter>> _hands = _dealHands();

  /// Bumped on every deal so the cards replay their drop-in animation.
  int _dealId = 0;

  List<List<ShelfieCharacter>> _dealHands() {
    return ShelfieCharacterDeal.deal(
      _colors.length,
      _random,
      firstGame: _firstGame,
    );
  }

  PlayerColorOption _colorAt(int index) {
    return _game.playerColors.firstWhere(
      (option) => option.value == _colors[index],
    );
  }

  void _deal() {
    setState(() {
      _hands = _dealHands();
      _dealId++;
    });
  }

  void _addPlayer(int colorValue) {
    if (_colors.length >= _game.maxPlayers || _colors.contains(colorValue)) {
      return;
    }
    _setPlayers([..._colors, colorValue]);
  }

  void _removePlayer() {
    if (_colors.length <= _game.minPlayers) {
      return;
    }
    _setPlayers(_colors.sublist(0, _colors.length - 1));
  }

  /// The shared first-game hand is the same for any player count, so it
  /// keeps its cards; otherwise everyone gets a fresh deal.
  void _setPlayers(List<int> colors) {
    _colors = colors;
    if (_firstGame) {
      setState(() {});
    } else {
      _deal();
    }
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
      title: l10n.t('hub.characterRandomizer'),
      coverImageAsset: ShelfieStackerGame.coverAsset,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(compact ? 12 : 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.t('shelfie.chars.hint'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.t('players.title'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                PlayerColorRoster(
                  colors: [
                    for (var i = 0; i < _colors.length; i++) _colorAt(i),
                  ],
                  options: _game.playerColors,
                  accent: _game.accentColor,
                  keyPrefix: 'shelfie-chars',
                  minPlayers: _game.minPlayers,
                  showNumbers: false,
                  onAdd: _addPlayer,
                  onRemove: _removePlayer,
                  onColor: _setColor,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          key: const ValueKey('shelfie-chars-first-game'),
                          value: _firstGame,
                          onChanged: (on) {
                            _firstGame = on;
                            _deal();
                          },
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            l10n.t('shelfie.chars.firstGame'),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    FilledButton.icon(
                      key: const ValueKey('shelfie-chars-randomize'),
                      onPressed: _firstGame ? null : _deal,
                      icon: const Icon(Icons.shuffle),
                      label: Text(l10n.t('shelfie.chars.randomize')),
                    ),
                  ],
                ),
                if (_firstGame) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.t('shelfie.chars.firstGameHint'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 20),
                // Everyone holds the same 1–8 in a first game: one shared hand.
                if (_firstGame)
                  _PlayerHand(
                    key: const ValueKey('shelfie-chars-hand-all'),
                    label: l10n.t('shelfie.chars.allPlayers'),
                    dots: _colors,
                    colorValue: _game.accentColor.toARGB32(),
                    cards: _hands.first,
                    compact: compact,
                    dealId: _dealId,
                    firstCard: 0,
                  )
                else
                  for (var p = 0; p < _hands.length; p++) ...[
                    if (p > 0) const SizedBox(height: 12),
                    _PlayerHand(
                      key: ValueKey('shelfie-chars-hand-$p'),
                      label: l10n.t('shelfie.chars.playerHand', {
                        'color': l10n.colorLabel(_colorAt(p).name),
                      }),
                      dots: [_colors[p]],
                      colorValue: _colors[p],
                      cards: _hands[p],
                      compact: compact,
                      dealId: _dealId,
                      // Hands deal in together, each a beat after the last.
                      firstCard: p * 2,
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
    required this.dots,
    required this.colorValue,
    required this.cards,
    required this.compact,
    required this.dealId,
    required this.firstCard,
  });

  final String label;

  /// Player colors shown before [label]: one for a player's own hand, all of
  /// them for the shared first-game hand.
  final List<int> dots;

  /// Tints the card shadows.
  final int colorValue;
  final List<ShelfieCharacter> cards;
  final bool compact;

  /// Changes on every deal, replaying the drop-in animation.
  final int dealId;

  /// Position of this hand's first card in the overall deal order.
  final int firstCard;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (final dot in dots) ...[
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: playerColor(dot),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                const SizedBox(width: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Two rows of four, so a hand of 8 reads at a glance.
            LayoutBuilder(
              builder: (context, constraints) {
                final gap = compact ? 8.0 : 12.0;
                final width = (constraints.maxWidth - gap * 3) / 4;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (var i = 0; i < cards.length; i++)
                      _DealIn(
                        key: ValueKey('$dealId-$label-${cards[i].number}'),
                        order: firstCard + i,
                        child: SizedBox(
                          width: width,
                          child: _CharacterTile(
                            character: cards[i],
                            colorValue: colorValue,
                            compact: compact,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CharacterTile extends StatelessWidget {
  const _CharacterTile({
    required this.character,
    required this.colorValue,
    required this.compact,
  });

  final ShelfieCharacter character;
  final int colorValue;
  final bool compact;

  /// Same gold as the game banners on the home page.
  static const _gold = Color(0xFFF8E5B0);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = l10n.t(character.nameKey);
    final radius = BorderRadius.circular(compact ? 12 : 16);
    final inset = compact ? 6.0 : 10.0;
    // Styled like the home page banners: art, a dark fade, name on top.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: playerColor(colorValue).withValues(alpha: 0.3),
            blurRadius: compact ? 8 : 14,
            offset: Offset(0, compact ? 4 : 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: AspectRatio(
          aspectRatio: 1,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey('shelfie-char-${character.number}'),
              onTap: () => showShelfieCharacterDialog(context, character),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    character.asset,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    semanticLabel: name,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x22000000),
                          Color(0x00000000),
                          Color(0xD91A0F08),
                        ],
                        stops: [0, 0.45, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: inset,
                    right: inset,
                    bottom: inset - 2,
                    child: Text(
                      '${character.number}. $name',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _gold,
                        fontWeight: FontWeight.w800,
                        fontSize: compact ? 11 : 15,
                        height: 1.15,
                        shadows: const [
                          Shadow(blurRadius: 12, color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Card art, name and the rulebook's clarification for [character].
Future<void> showShelfieCharacterDialog(
  BuildContext context,
  ShelfieCharacter character,
) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final l10n = dialogContext.l10n;
      return AlertDialog(
        title: Text('${character.number}. ${l10n.t(character.nameKey)}'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      character.asset,
                      width: 220,
                      height: 220,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.t(character.rulesKey),
                  style: Theme.of(
                    dialogContext,
                  ).textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.t('common.close')),
          ),
        ],
      );
    },
  );
}

/// Drops a dealt card into place: it fades in while sliding down and
/// settling from a smaller size, one after another in deal [order].
class _DealIn extends StatelessWidget {
  const _DealIn({super.key, required this.order, required this.child});

  final int order;
  final Widget child;

  static const _stagger = Duration(milliseconds: 70);
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
