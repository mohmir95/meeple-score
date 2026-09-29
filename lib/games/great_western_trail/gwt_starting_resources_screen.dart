import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../domain/board_game.dart';
import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/widgets/app_page.dart';

class GwtStartingResourcesScreen extends StatefulWidget {
  const GwtStartingResourcesScreen({super.key, required this.game});

  final BoardGame game;

  static const coin5Asset = 'assets/games/great_western_trail/icons/coin-5.jpg';
  static const coin1Asset = 'assets/games/great_western_trail/icons/coin-1.jpg';
  static const exchangeTokenAsset =
      'assets/games/great_western_trail/icons/exchange-token.jpg';

  /// Player 1 starts with 6 dollars; each later seat gets 1 more.
  static int dollarsFor(int seat) => 5 + seat;

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
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final padding = compact ? 12.0 : 20.0;
    final accent = widget.game.accentColor;
    final gap = compact ? 16.0 : 20.0;

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
                      _PanelTitle(
                        text: l10n.isRtl
                            ? l10n.t('hub.startingResources')
                            : l10n.t('hub.startingResources').toUpperCase(),
                        letterSpacing: l10n.isRtl ? 0 : 1.1,
                      ),
                      SizedBox(height: compact ? 18 : 24),
                      for (var seat = 1;
                          seat <= widget.game.maxPlayers;
                          seat++) ...[
                        if (seat > 1) SizedBox(height: compact ? 12 : 16),
                        _PlayerResourceRow(
                          label: l10n.t('players.numbered', {'n': '$seat'}),
                          dollars: GwtStartingResourcesScreen.dollarsFor(seat),
                          maxDollars: GwtStartingResourcesScreen.dollarsFor(
                            widget.game.maxPlayers,
                          ),
                          exchangeToken: _railsToTheNorth,
                          compact: compact,
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: gap),
                _SetupPanel(
                  key: const ValueKey('gwt-rails-to-the-north-panel'),
                  accent: accent,
                  compact: compact,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PanelTitle(
                        text: l10n.t('gwt.randomizer.railsToTheNorth'),
                        color: const Color(0xFF6B2030),
                      ),
                      SizedBox(height: compact ? 10 : 12),
                      Text(
                        l10n.t('gwt.startingResources.exchangeTokenNote'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF2A2620),
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: compact ? 16 : 20),
                      Center(
                        child: _ExchangeToken(
                          height: compact ? 80 : 130,
                          elevation: 3,
                        ),
                      ),
                      SizedBox(height: compact ? 12 : 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              l10n.t('gwt.startingResources.playingExpansion'),
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: const Color(0xFF2A2620),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            key: const ValueKey(
                              'gwt-starting-rails-to-the-north',
                            ),
                            value: _railsToTheNorth,
                            onChanged: (value) =>
                                setState(() => _railsToTheNorth = value),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
  const _PanelTitle({
    required this.text,
    this.color = const Color(0xFF1C1A17),
    this.letterSpacing = 0,
  });

  final String text;
  final Color color;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: color,
        fontWeight: FontWeight.w800,
        fontStyle: FontStyle.italic,
        letterSpacing: letterSpacing,
        height: 1.15,
      ),
    );
  }
}

class _PlayerResourceRow extends StatelessWidget {
  const _PlayerResourceRow({
    required this.label,
    required this.dollars,
    required this.maxDollars,
    required this.exchangeToken,
    required this.compact,
  });

  final String label;
  final int dollars;
  final int maxDollars;
  final bool exchangeToken;
  final bool compact;

  static const _tokenAspect = _ExchangeToken.aspectRatio;

  static int _coinCount(int dollars) => dollars ~/ 5 + dollars % 5;

  @override
  Widget build(BuildContext context) {
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
              final tokenGap = compact ? 3.0 : 6.0;
              // Size for the widest row with the token, so every row matches
              // and toggling the expansion never resizes the coins.
              final widestCoins = _coinCount(maxDollars);
              final fixed = widestCoins * spacing + tokenGap + 1;
              final fitted =
                  (constraints.maxWidth - fixed) /
                  (widestCoins + _tokenAspect);
              final iconSize = fitted.clamp(20.0, compact ? 30.0 : 36.0);

              return Wrap(
                spacing: spacing,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (var i = 0; i < fives; i++)
                    _Coin(
                      asset: GwtStartingResourcesScreen.coin5Asset,
                      size: iconSize,
                      label: l10n.t('gwt.startingResources.coin', {'n': '5'}),
                    ),
                  for (var i = 0; i < ones; i++)
                    _Coin(
                      asset: GwtStartingResourcesScreen.coin1Asset,
                      size: iconSize,
                      label: l10n.t('gwt.startingResources.coin', {'n': '1'}),
                    ),
                  if (exchangeToken)
                    Padding(
                      padding: EdgeInsetsDirectional.only(start: tokenGap),
                      child: _ExchangeToken(
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
        _DollarAmount(dollars: dollars, compact: compact),
      ],
    );
  }
}

class _DollarAmount extends StatelessWidget {
  const _DollarAmount({required this.dollars, required this.compact});

  final int dollars;
  final bool compact;

  // The setup panel stays cream in dark mode, so use the fixed brand shades
  // rather than the scheme's primary, which turns pale on dark themes.
  static final _fill = AppTheme.brand.withValues(alpha: 0.12);
  static final _border = AppTheme.brand.withValues(alpha: 0.55);
  static const _ink = AppTheme.brandDeep;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: compact ? 52 : 64),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: _fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _border, width: 1.2),
      ),
      child: Text(
        context.l10n.t('gwt.startingResources.dollars', {'n': '$dollars'}),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: _ink,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
          height: 1.2,
        ),
      ),
    );
  }
}

/// The exchange token photo, trimmed of the surrounding board and clipped to
/// the physical token's D shape.
class _ExchangeToken extends StatelessWidget {
  const _ExchangeToken({
    required this.height,
    this.elevation = 0,
    this.semanticLabel,
  });

  final double height;
  final double elevation;
  final String? semanticLabel;

  // Token bounds inside the 697×592 source photo.
  static const _imageWidth = 697.0;
  static const _imageHeight = 592.0;
  static const _left = 44.0;
  static const _top = 60.0;
  static const _right = 646.0;
  static const _bottom = 538.0;
  static const _curveStart = 425.0;

  static const aspectRatio = (_right - _left) / (_bottom - _top);

  @override
  Widget build(BuildContext context) {
    final scale = height / (_bottom - _top);
    final width = height * aspectRatio;
    final clipper = _ExchangeTokenClipper(
      curveStart: (_curveStart - _left) * scale,
    );
    return Semantics(
      label: semanticLabel,
      image: semanticLabel != null,
      child: PhysicalShape(
        clipper: clipper,
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
                left: -_left * scale,
                top: -_top * scale,
                width: _imageWidth * scale,
                height: _imageHeight * scale,
                child: Image.asset(
                  GwtStartingResourcesScreen.exchangeTokenAsset,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.medium,
                  excludeFromSemantics: true,
                ),
              ),
            ],
          ),
        ),
      ),
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
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        semanticLabel: label,
      ),
    );
  }
}
