import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/widgets/app_page.dart';
import 'shelfie_game.dart';

/// Setup numbers from the rulebook that change with the player count.
class ShelfieSetup {
  const ShelfieSetup._();

  static const colors = 4;
  static const fullDicePerColor = 22;

  /// 1 Delivery Box per player, plus 1 more.
  static int deliveryBoxes(int players) => players + 1;

  /// Dice removed from each colour: none at 4, 5 at 3, 10 at 2 or solo.
  static int removedPerColor(int players) {
    if (players >= 4) {
      return 0;
    }
    return players == 3 ? 5 : 10;
  }

  static int dicePerColor(int players) =>
      fullDicePerColor - removedPerColor(players);

  static int diceInBag(int players) => dicePerColor(players) * colors;
}

class ShelfieSetupHintsScreen extends StatefulWidget {
  const ShelfieSetupHintsScreen({super.key});

  /// Only four boxes in the art are whole, so the fifth repeats the first.
  static const boxAssets = [
    'assets/games/shelfie_stacker/boxes/box1.png',
    'assets/games/shelfie_stacker/boxes/box2.png',
    'assets/games/shelfie_stacker/boxes/box3.png',
    'assets/games/shelfie_stacker/boxes/box4.png',
    'assets/games/shelfie_stacker/boxes/box1.png',
  ];

  @override
  State<ShelfieSetupHintsScreen> createState() =>
      _ShelfieSetupHintsScreenState();
}

class _ShelfieSetupHintsScreenState extends State<ShelfieSetupHintsScreen> {
  static const _ink = Color(0xFF26313D);
  static const _muted = Color(0xFF55606C);

  /// Dice colours, in the order of the printed pad.
  static const _dice = [
    (key: 'blue', color: Color(0xFF34A6E0), pips: 6),
    (key: 'green', color: Color(0xFF2FA552), pips: 3),
    (key: 'orange', color: Color(0xFFF08A24), pips: 4),
    (key: 'purple', color: Color(0xFFD653A8), pips: 2),
  ];

  var _players = const ShelfieStackerGame().maxPlayers;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final padding = compact ? 12.0 : 20.0;
    const game = ShelfieStackerGame();

    return AppPage(
      title: l10n.t('hub.setupHints'),
      coverImageAsset: ShelfieStackerGame.coverAsset,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<int>(
                  key: const ValueKey('shelfie-setup-players'),
                  showSelectedIcon: false,
                  segments: [
                    for (var n = game.minPlayers; n <= game.maxPlayers; n++)
                      ButtonSegment(
                        value: n,
                        label: Text(
                          n == 1
                              ? l10n.t('shelfie.setup.solo')
                              : l10n.t('shelfie.setup.players', {'n': '$n'}),
                        ),
                      ),
                  ],
                  selected: {_players},
                  onSelectionChanged: (selection) {
                    setState(() => _players = selection.first);
                  },
                ),
                SizedBox(height: compact ? 16 : 20),
                _boxesPanel(context, compact),
                SizedBox(height: compact ? 16 : 20),
                _dicePanel(context, compact),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _boxesPanel(BuildContext context, bool compact) {
    final l10n = context.l10n;
    final boxes = ShelfieSetup.deliveryBoxes(_players);
    final boxSize = compact ? 56.0 : 76.0;
    return _Panel(
      key: const ValueKey('shelfie-setup-boxes'),
      compact: compact,
      title: l10n.t('shelfie.setup.boxesTitle', {'n': '$boxes'}),
      body: l10n.t('shelfie.setup.boxesBody'),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: compact ? 8 : 14,
        runSpacing: 8,
        children: [
          for (var i = 0; i < boxes; i++)
            Image.asset(
              ShelfieSetupHintsScreen.boxAssets[i],
              width: boxSize,
              height: boxSize,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              semanticLabel: l10n.t('shelfie.setup.box'),
            ),
        ],
      ),
    );
  }

  Widget _dicePanel(BuildContext context, bool compact) {
    final l10n = context.l10n;
    final removed = ShelfieSetup.removedPerColor(_players);
    final perColor = ShelfieSetup.dicePerColor(_players);
    return _Panel(
      key: const ValueKey('shelfie-setup-dice'),
      compact: compact,
      title: l10n.t('shelfie.setup.diceTitle', {
        'n': '${ShelfieSetup.diceInBag(_players)}',
      }),
      body: removed == 0
          ? l10n.t('shelfie.setup.diceAll', {
              'n': '${ShelfieSetup.diceInBag(_players)}',
            })
          : l10n.t('shelfie.setup.diceRemove', {
              'n': '$removed',
              'total': '${removed * ShelfieSetup.colors}',
            }),
      child: Row(
        children: [
          for (final die in _dice)
            Expanded(
              child: Column(
                key: ValueKey('shelfie-setup-die-${die.key}'),
                children: [
                  _Die(
                    color: die.color,
                    pips: die.pips,
                    size: compact ? 52 : 68,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '× $perColor',
                    style: TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w900,
                      fontSize: compact ? 20 : 24,
                    ),
                  ),
                  Text(
                    l10n.t('shelfie.setup.color.${die.key}'),
                    style: const TextStyle(
                      color: _muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (removed > 0)
                    Text(
                      l10n.t('shelfie.setup.removed', {'n': '$removed'}),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    super.key,
    required this.compact,
    required this.title,
    required this.body,
    required this.child,
  });

  final bool compact;
  final String title;
  final String body;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2F6DB5);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Blue band like the header of the printed pad.
          Container(
            decoration: const BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 16 : 24,
              vertical: compact ? 10 : 12,
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(compact ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF26313D),
                    height: 1.35,
                  ),
                ),
                SizedBox(height: compact ? 14 : 18),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A Shelfie Stacker die: a coloured cube whose pips are white bars.
class _Die extends StatelessWidget {
  const _Die({required this.color, required this.pips, required this.size});

  final Color color;

  /// 2, 3, 4 or 6, drawn the way the game prints them.
  final int pips;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (rows, cols) = switch (pips) {
      2 => (2, 1),
      3 => (1, 3),
      4 => (2, 2),
      _ => (3, 2),
    };
    final gap = size * 0.07;
    final shade = Color.lerp(color, Colors.black, 0.18)!;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(color, Colors.white, 0.15)!, color],
        ),
        border: Border(bottom: BorderSide(color: shade, width: size * 0.07)),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var r = 0; r < rows; r++) ...[
            if (r > 0) SizedBox(height: gap),
            Expanded(
              child: Row(
                // Stretch so the childless pip boxes get the row's height.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var c = 0; c < cols; c++) ...[
                    if (c > 0) SizedBox(width: gap),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(size * 0.04),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
