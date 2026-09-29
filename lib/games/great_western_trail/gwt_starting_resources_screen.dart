import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../domain/board_game.dart';
import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/widgets/app_page.dart';

/// Exchange token artwork. Photos taken on the board keep their source bounds
/// and are clipped to the token's D shape; pre-cut PNGs are drawn as-is.
class GwtTokenArt {
  const GwtTokenArt.photo({
    required this.asset,
    required this.imageSize,
    required this.bounds,
    required double curveStart,
  }) : _curveStart = curveStart;

  const GwtTokenArt.cutout({required this.asset, required Size size})
    : imageSize = size,
      bounds = Rect.zero,
      _curveStart = null;

  final String asset;
  final Size imageSize;
  final Rect bounds;
  final double? _curveStart;

  bool get needsClip => _curveStart != null;

  Rect get _visible => needsClip ? bounds : Offset.zero & imageSize;

  double get aspectRatio => _visible.width / _visible.height;
}

/// What each edition hands out at setup.
class GwtStartingSetup {
  const GwtStartingSetup({
    required this.coin5Asset,
    required this.coin1Asset,
    required this.token,
    this.cardBackAsset,
    this.cardBackAspect = 1,
    this.firstPlayerCards,
    this.tokenNeedsRailsToTheNorth = false,
    this.firstPlayerMoney = 6,
    this.moneyKey = 'gwt.startingResources.dollars',
    this.coinKey = 'gwt.startingResources.coin',
    this.exhaustionCardAsset,
    this.exhaustionCardAspect = 1,
  });

  /// Argentina shuffles 1 Exhaustion card into every starting deck.
  final String? exhaustionCardAsset;
  final double exhaustionCardAspect;

  final String coin5Asset;
  final String coin1Asset;
  final GwtTokenArt token;

  /// Player 1's money; each later seat gets 1 more.
  final int firstPlayerMoney;

  /// Translation keys for the money amount and coin label, taking `{n}`.
  final String moneyKey;
  final String coinKey;

  /// Set when players draw starting cards; the count grows by 1 per seat.
  final String? cardBackAsset;
  final double cardBackAspect;
  final int? firstPlayerCards;

  /// First Edition only hands out the token with Rails to the North.
  final bool tokenNeedsRailsToTheNorth;

  static const firstEdition = GwtStartingSetup(
    coin5Asset: 'assets/games/great_western_trail/icons/coin-5.jpg',
    coin1Asset: 'assets/games/great_western_trail/icons/coin-1.jpg',
    token: GwtTokenArt.photo(
      asset: 'assets/games/great_western_trail/icons/exchange-token.jpg',
      imageSize: Size(697, 592),
      bounds: Rect.fromLTRB(44, 60, 646, 538),
      curveStart: 425,
    ),
    cardBackAsset: 'assets/games/great_western_trail/icons/card-back.png',
    cardBackAspect: 441 / 663,
    firstPlayerCards: 4,
    tokenNeedsRailsToTheNorth: true,
  );

  static const secondEdition = GwtStartingSetup(
    coin5Asset: 'assets/games/great_western_trail_2e/icons/coin-5.png',
    coin1Asset: 'assets/games/great_western_trail_2e/icons/coin-1.png',
    token: GwtTokenArt.cutout(
      asset: 'assets/games/great_western_trail_2e/icons/exchange-token.png',
      size: Size(480, 389),
    ),
    cardBackAsset: 'assets/games/great_western_trail_2e/icons/card-back.png',
    cardBackAspect: 319 / 480,
    firstPlayerCards: 4,
  );

  static const argentina = GwtStartingSetup(
    coin5Asset: 'assets/games/great_western_trail_argentina/icons/coin-5.png',
    coin1Asset: 'assets/games/great_western_trail_argentina/icons/coin-1.png',
    token: GwtTokenArt.cutout(
      asset:
          'assets/games/great_western_trail_argentina/icons/exchange-token.png',
      size: Size(252, 221),
    ),
    cardBackAsset:
        'assets/games/great_western_trail_argentina/icons/card-back.png',
    cardBackAspect: 378 / 600,
    firstPlayerCards: 4,
    firstPlayerMoney: 7,
    moneyKey: 'gwt.startingResources.pesos',
    coinKey: 'gwt.startingResources.pesoCoin',
    exhaustionCardAsset:
        'assets/games/great_western_trail_argentina/icons/exhaustion-card.png',
    exhaustionCardAspect: 307 / 480,
  );

  /// Hand size players discard down to at the start of their first turn.
  static const handLimit = 4;

  bool get hasCards => cardBackAsset != null && firstPlayerCards != null;

  int dollarsFor(int seat) => firstPlayerMoney + seat - 1;

  int? cardsFor(int seat) => hasCards ? firstPlayerCards! + seat - 1 : null;
}

class GwtStartingResourcesScreen extends StatefulWidget {
  const GwtStartingResourcesScreen({
    super.key,
    required this.game,
    required this.setup,
  });

  final BoardGame game;
  final GwtStartingSetup setup;

  @override
  State<GwtStartingResourcesScreen> createState() =>
      _GwtStartingResourcesScreenState();
}

class _GwtStartingResourcesScreenState
    extends State<GwtStartingResourcesScreen> {
  var _railsToTheNorth = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final setup = widget.setup;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final padding = compact ? 12.0 : 20.0;
    final accent = widget.game.accentColor;
    final gap = compact ? 16.0 : 20.0;
    final maxSeat = widget.game.maxPlayers;
    final showToken = !setup.tokenNeedsRailsToTheNorth || _railsToTheNorth;

    return AppPage(
      title: l10n.t('hub.startingResources'),
      coverImageAsset: widget.game.coverImageAsset,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SetupPanel(
                  key: const ValueKey('gwt-starting-resources-panel'),
                  accent: accent,
                  compact: compact,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PanelTitle(text: l10n.t('hub.startingResources')),
                      SizedBox(height: compact ? 18 : 24),
                      for (var seat = 1; seat <= maxSeat; seat++) ...[
                        if (seat > 1) SizedBox(height: compact ? 12 : 16),
                        _PlayerResourceRow(
                          setup: setup,
                          label: l10n.t('players.numbered', {'n': '$seat'}),
                          seat: seat,
                          maxSeat: maxSeat,
                          exchangeToken: showToken,
                          compact: compact,
                        ),
                      ],
                      if (setup.tokenNeedsRailsToTheNorth) ...[
                        SizedBox(height: compact ? 18 : 24),
                        _RailsToTheNorthOption(
                          token: setup.token,
                          value: _railsToTheNorth,
                          compact: compact,
                          onChanged: (value) =>
                              setState(() => _railsToTheNorth = value),
                        ),
                      ],
                    ],
                  ),
                ),
                if (setup.hasCards) ...[
                  SizedBox(height: gap),
                  _SetupPanel(
                    key: const ValueKey('gwt-starting-cards-panel'),
                    accent: accent,
                    compact: compact,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PanelTitle(text: l10n.t('gwt.startingCards.title')),
                        SizedBox(height: compact ? 10 : 12),
                        Text(
                          l10n.t('gwt.startingResources.cardsNote'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: const Color(0xFF2A2620),
                                height: 1.35,
                              ),
                        ),
                        if (setup.exhaustionCardAsset case final asset?) ...[
                          SizedBox(height: compact ? 12 : 16),
                          _ExhaustionCardCallout(
                            asset: asset,
                            aspect: setup.exhaustionCardAspect,
                            compact: compact,
                          ),
                        ],
                        SizedBox(height: compact ? 16 : 20),
                        _CardFans(setup: setup, maxSeat: maxSeat),
                        if (_discardSeats(setup, maxSeat) case final seats
                            when seats.isNotEmpty) ...[
                          SizedBox(height: compact ? 16 : 20),
                          _DiscardCallout(
                            text: l10n.t('gwt.startingResources.discardNote', {
                              'list': _joinSeats(
                                seats,
                                l10n.t('gwt.startingResources.listSeparator'),
                                l10n.t('gwt.startingResources.and'),
                              ),
                              'limit': '${GwtStartingSetup.handLimit}',
                            }),
                          ),
                        ],
                      ],
                    ),
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

List<int> _discardSeats(GwtStartingSetup setup, int maxSeat) => [
  for (var seat = 1; seat <= maxSeat; seat++)
    if ((setup.cardsFor(seat) ?? 0) > GwtStartingSetup.handLimit) seat,
];

String _joinSeats(List<int> seats, String separator, String and) {
  if (seats.length == 1) {
    return '${seats.single}';
  }
  final head = seats.sublist(0, seats.length - 1).join(separator);
  return '$head $and ${seats.last}';
}

class _ExhaustionCardCallout extends StatelessWidget {
  const _ExhaustionCardCallout({
    required this.asset,
    required this.aspect,
    required this.compact,
  });

  final String asset;
  final double aspect;
  final bool compact;

  static const _ink = Color(0xFF4A3F1E);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cardHeight = compact ? 64.0 : 80.0;
    return Container(
      key: const ValueKey('gwt-exhaustion-card-callout'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE9DC8C).withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ink.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Image.asset(
              asset,
              height: cardHeight,
              width: cardHeight * aspect,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              semanticLabel: l10n.t('gwt.startingCards.exhaustionCard'),
            ),
          ),
          SizedBox(width: compact ? 12 : 16),
          Expanded(
            child: Text(
              l10n.t('gwt.startingCards.exhaustionNote'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _ink,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscardCallout extends StatelessWidget {
  const _DiscardCallout({required this.text});

  final String text;

  static const _ink = Color(0xFF6B2030);

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('gwt-discard-callout'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _ink.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ink.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.back_hand_outlined, size: 20, color: _ink),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _ink,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RailsToTheNorthOption extends StatelessWidget {
  const _RailsToTheNorthOption({
    required this.token,
    required this.value,
    required this.compact,
    required this.onChanged,
  });

  final GwtTokenArt token;
  final bool value;
  final bool compact;
  final ValueChanged<bool> onChanged;

  static const _ink = Color(0xFF6B2030);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      key: const ValueKey('gwt-rails-to-the-north-option'),
      color: _ink.withValues(alpha: value ? 0.1 : 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: _ink.withValues(alpha: value ? 0.45 : 0.25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(12, 10, 6, 10),
          child: Row(
            children: [
              _ExchangeToken(
                art: token,
                height: compact ? 36 : 44,
                elevation: 2,
              ),
              SizedBox(width: compact ? 10 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.t('gwt.randomizer.railsToTheNorth'),
                      style: textTheme.titleSmall?.copyWith(
                        color: _ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.t('gwt.startingResources.exchangeTokenNote'),
                      style: textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF2A2620),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                key: const ValueKey('gwt-starting-rails-to-the-north'),
                value: value,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetupPanel extends StatelessWidget {
  const _SetupPanel({
    super.key,
    required this.accent,
    required this.compact,
    required this.child,
  });

  final Color accent;
  final bool compact;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1E3),
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
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 20 : 28,
          vertical: compact ? 22 : 28,
        ),
        child: child,
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: const Color(0xFF6B2030),
        fontWeight: FontWeight.w800,
        fontStyle: FontStyle.italic,
        height: 1.15,
      ),
    );
  }
}

class _PlayerResourceRow extends StatelessWidget {
  const _PlayerResourceRow({
    required this.setup,
    required this.label,
    required this.seat,
    required this.maxSeat,
    required this.exchangeToken,
    required this.compact,
  });

  final GwtStartingSetup setup;
  final String label;
  final int seat;
  final int maxSeat;
  final bool exchangeToken;
  final bool compact;

  static int _coinCount(int dollars) => dollars ~/ 5 + dollars % 5;

  @override
  Widget build(BuildContext context) {
    final dollars = setup.dollarsFor(seat);
    final fives = dollars ~/ 5;
    final ones = dollars % 5;

    return Row(
      children: [
        SizedBox(
          width: compact ? 80 : 120,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF1C1A17),
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final l10n = context.l10n;
              final spacing = compact ? 3.0 : 4.0;
              final groupGap = compact ? 3.0 : 6.0;
              // Size for the widest row with every item showing, so all rows
              // match and toggling the expansion never resizes the coins.
              var widestCoins = 0;
              for (var s = 1; s <= maxSeat; s++) {
                widestCoins = math.max(
                  widestCoins,
                  _coinCount(setup.dollarsFor(s)),
                );
              }
              final fixed = widestCoins * spacing + groupGap + 1;
              final units = widestCoins + setup.token.aspectRatio;
              final fitted = (constraints.maxWidth - fixed) / units;
              final iconSize = fitted.clamp(14.0, compact ? 30.0 : 36.0);

              return Wrap(
                spacing: spacing,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (var i = 0; i < fives; i++)
                    _Coin(
                      asset: setup.coin5Asset,
                      size: iconSize,
                      label: l10n.t(setup.coinKey, {'n': '5'}),
                    ),
                  for (var i = 0; i < ones; i++)
                    _Coin(
                      asset: setup.coin1Asset,
                      size: iconSize,
                      label: l10n.t(setup.coinKey, {'n': '1'}),
                    ),
                  if (exchangeToken)
                    Padding(
                      padding: EdgeInsetsDirectional.only(start: groupGap),
                      child: _ExchangeToken(
                        art: setup.token,
                        height: iconSize,
                        semanticLabel: l10n.t(
                          'gwt.startingResources.exchangeToken',
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        SizedBox(width: compact ? 8 : 12),
        _DollarAmount(
          dollars: dollars,
          setup: setup,
          maxSeat: maxSeat,
          compact: compact,
        ),
      ],
    );
  }
}

class _DollarAmount extends StatelessWidget {
  const _DollarAmount({
    required this.dollars,
    required this.setup,
    required this.maxSeat,
    required this.compact,
  });

  final int dollars;
  final GwtStartingSetup setup;
  final int maxSeat;
  final bool compact;

  // The setup panel stays cream in dark mode, so use the fixed brand shades
  // rather than the scheme's primary, which turns pale on dark themes.
  static final _fill = AppTheme.brand.withValues(alpha: 0.12);
  static final _border = AppTheme.brand.withValues(alpha: 0.55);
  static const _ink = AppTheme.brandDeep;

  static const _borderWidth = 1.2;

  static double _padding(bool compact) => compact ? 8 : 14;

  static TextStyle? _style(BuildContext context, bool compact) {
    final textTheme = Theme.of(context).textTheme;
    return (compact ? textTheme.titleSmall : textTheme.titleMedium)?.copyWith(
      color: _ink,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.3,
      height: 1.2,
    );
  }

  /// Width that fits the widest amount, so every row's pill (and therefore
  /// every row's coins) comes out the same size.
  static double widthFor(
    BuildContext context,
    GwtStartingSetup setup,
    int maxSeat,
    bool compact,
  ) {
    final l10n = context.l10n;
    final style = _style(context, compact);
    final scaler = MediaQuery.textScalerOf(context);
    var widest = 0.0;
    for (var seat = 1; seat <= maxSeat; seat++) {
      final painter = TextPainter(
        text: TextSpan(
          text: l10n.t(setup.moneyKey, {'n': '${setup.dollarsFor(seat)}'}),
          style: style,
        ),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      widest = math.max(widest, painter.width);
      painter.dispose();
    }
    final width = widest + 2 * (_padding(compact) + _borderWidth) + 1;
    return width.clamp(compact ? 52.0 : 64.0, compact ? 84.0 : 120.0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widthFor(context, setup, maxSeat, compact),
      padding: EdgeInsets.symmetric(
        horizontal: _padding(compact),
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: _fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _border, width: _borderWidth),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          context.l10n.t(setup.moneyKey, {'n': '$dollars'}),
          textAlign: TextAlign.center,
          maxLines: 1,
          style: _style(context, compact),
        ),
      ),
    );
  }
}

/// One tile per player showing a fan of the cards they draw.
class _CardFans extends StatelessWidget {
  const _CardFans({required this.setup, required this.maxSeat});

  final GwtStartingSetup setup;
  final int maxSeat;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final tileWidth =
            (constraints.maxWidth - gap * (maxSeat - 1)) / maxSeat;
        final cardHeight = (tileWidth * 0.8).clamp(44.0, 92.0);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var seat = 1; seat <= maxSeat; seat++) ...[
              if (seat > 1) const SizedBox(width: gap),
              Expanded(
                child: Column(
                  children: [
                    _CardFan(
                      asset: setup.cardBackAsset!,
                      aspect: setup.cardBackAspect,
                      count: setup.cardsFor(seat)!,
                      cardHeight: cardHeight,
                      width: tileWidth,
                      label: l10n.t('gwt.startingResources.cards', {
                        'n': '${setup.cardsFor(seat)}',
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.t('players.numbered', {'n': '$seat'}),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF1C1A17),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      l10n.t('gwt.startingResources.cards', {
                        'n': '${setup.cardsFor(seat)}',
                      }),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xFF6B2030),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Face-down cards fanned from a common pivot below the hand.
class _CardFan extends StatelessWidget {
  const _CardFan({
    required this.asset,
    required this.aspect,
    required this.count,
    required this.cardHeight,
    required this.width,
    required this.label,
  });

  final String asset;
  final double aspect;
  final int count;
  final double cardHeight;
  final double width;
  final String label;

  static const _stepAngle = 0.13;

  @override
  Widget build(BuildContext context) {
    final cardWidth = cardHeight * aspect;
    final spread = _stepAngle * (count - 1);
    final height = cardHeight * 1.15;

    return Semantics(
      label: label,
      image: true,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            for (var i = 0; i < count; i++)
              Positioned(
                bottom: 0,
                child: Transform.rotate(
                  angle: count == 1 ? 0 : -spread / 2 + _stepAngle * i,
                  origin: Offset(0, cardHeight * 0.45),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(cardWidth * 0.06),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      asset,
                      width: cardWidth,
                      height: cardHeight,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.medium,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExchangeToken extends StatelessWidget {
  const _ExchangeToken({
    required this.art,
    required this.height,
    this.elevation = 0,
    this.semanticLabel,
  });

  final GwtTokenArt art;
  final double height;
  final double elevation;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final width = height * art.aspectRatio;
    return Semantics(
      label: semanticLabel,
      image: semanticLabel != null,
      child: art.needsClip ? _clippedPhoto(width) : _cutout(width),
    );
  }

  Widget _image({required double width, required double height}) {
    return Image.asset(
      art.asset,
      width: width,
      height: height,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    );
  }

  Widget _clippedPhoto(double width) {
    final bounds = art.bounds;
    final scale = height / bounds.height;
    return PhysicalShape(
      clipper: _ExchangeTokenClipper(
        curveStart: (art._curveStart! - bounds.left) * scale,
      ),
      clipBehavior: Clip.antiAlias,
      color: const Color(0xFF1F3A45),
      elevation: elevation,
      shadowColor: Colors.black54,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -bounds.left * scale,
              top: -bounds.top * scale,
              child: _image(
                width: art.imageSize.width * scale,
                height: art.imageSize.height * scale,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cutout(double width) {
    final image = _image(width: width, height: height);
    if (elevation == 0) {
      return image;
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Transform.translate(
          offset: Offset(0, elevation),
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
              sigmaX: elevation * 1.5,
              sigmaY: elevation * 1.5,
            ),
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.black45,
                BlendMode.srcIn,
              ),
              child: image,
            ),
          ),
        ),
        image,
      ],
    );
  }
}

class _ExchangeTokenClipper extends CustomClipper<Path> {
  const _ExchangeTokenClipper({required this.curveStart});

  final double curveStart;

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final corner = Radius.circular(h * 0.06);
    return Path()
      ..moveTo(corner.x, 0)
      ..lineTo(curveStart, 0)
      ..arcToPoint(
        Offset(curveStart, h),
        radius: Radius.elliptical(w - curveStart, h / 2),
      )
      ..lineTo(corner.x, h)
      ..arcToPoint(Offset(0, h - corner.y), radius: corner)
      ..lineTo(0, corner.y)
      ..arcToPoint(Offset(corner.x, 0), radius: corner)
      ..close();
  }

  @override
  bool shouldReclip(_ExchangeTokenClipper oldClipper) =>
      oldClipper.curveStart != curveStart;
}

class _Coin extends StatelessWidget {
  const _Coin({required this.asset, required this.size, required this.label});

  final String asset;
  final double size;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.medium,
        semanticLabel: label,
      ),
    );
  }
}
