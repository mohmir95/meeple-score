import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/board_game.dart';
import '../../domain/game_series.dart';
import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import 'game_card.dart';

/// One banner for a whole series: its edition covers as slanted strips with
/// soft white seams, in the same white frame as every other banner.
class GameSeriesCard extends StatelessWidget {
  const GameSeriesCard({
    super.key,
    required this.series,
    required this.games,
    required this.onOpen,
    this.onResume,
  });

  final GameSeries series;
  final List<BoardGame> games;
  final VoidCallback onOpen;

  /// Set when one of the editions has a game in progress.
  final VoidCallback? onResume;

  @override
  Widget build(BuildContext context) {
    final compact = Breakpoints.isCompact(context);
    final l10n = context.l10n;
    final titleStyle = compact
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.titleLarge;
    final inset = compact ? 10.0 : 16.0;
    final title = l10n.t(series.titleKey);

    // The shadow sits outside the clip, so it never fills the corners.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BannerStyle.radius),
        boxShadow: [
          BoxShadow(
            color: BannerStyle.gold.withValues(alpha: 0.35),
            blurRadius: compact ? 18 : 28,
            offset: Offset(0, compact ? 8 : 12),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(BannerStyle.radius),
          // A layer of its own keeps the covers inside the rounded corners.
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onOpen,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Semantics(
                                label: title,
                                image: true,
                                excludeSemantics: true,
                                child: GameSeriesArt(games: games),
                              ),
                              Positioned(
                                left: inset,
                                right: inset,
                                bottom: inset,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // One line, shrinking on narrow cards.
                                    Expanded(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment:
                                            AlignmentDirectional.centerStart,
                                        child: Text(
                                          title,
                                          maxLines: 1,
                                          softWrap: false,
                                          style: titleStyle?.copyWith(
                                            color: BannerStyle.paleGold,
                                            fontWeight: FontWeight.w800,
                                            height: 1.15,
                                            shadows: BannerStyle.titleShadows,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _EditionsBadge(
                                      count: games.length,
                                      compact: compact,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const BannerFrame(),
                    PositionedDirectional(
                      top: compact ? 8 : 12,
                      end: compact ? 8 : 12,
                      child: GameStatusPill(
                        key: ValueKey('home-saved-series-${series.id}'),
                        inProgress: onResume != null,
                        finished: false,
                        onTap: onResume,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// The series art on its own: the edition covers as slanted strips with
/// soft white seams, darkening toward the bottom for the title.
class GameSeriesArt extends StatelessWidget {
  const GameSeriesArt({super.key, required this.games});

  final List<BoardGame> games;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final skew = size.width * 0.16;
        // Editions read left to right in every language, like boxes on a
        // shelf.
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: const Color(0xFF1A0F08),
                child: Stack(
                  children: [
                    for (var i = 0; i < games.length; i++)
                      _Strip(
                        game: games[i],
                        index: i,
                        count: games.length,
                        size: size,
                        skew: skew,
                      ),
                  ],
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x33000000),
                      Color(0x00000000),
                      Color(0xDD1A0F08),
                    ],
                    stops: [0, 0.45, 1],
                  ),
                ),
              ),
              IgnorePointer(
                child: CustomPaint(
                  painter: _SeamsPainter(count: games.length, skew: skew),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Where seam [index] (1 to count - 1) crosses the top and bottom edges.
({double top, double bottom}) _seam(
  int index,
  int count,
  Size size,
  double skew,
) {
  final x = size.width * index / count;
  return (top: x + skew / 2, bottom: x - skew / 2);
}

/// One edition's cover, cut to a slanted strip.
class _Strip extends StatelessWidget {
  const _Strip({
    required this.game,
    required this.index,
    required this.count,
    required this.size,
    required this.skew,
  });

  final BoardGame game;
  final int index;
  final int count;
  final Size size;
  final double skew;

  @override
  Widget build(BuildContext context) {
    final stripWidth = size.width / count;
    final boxWidth = stripWidth + skew;
    final center = stripWidth * (index + 0.5);
    return Positioned.fill(
      child: ClipPath(
        clipper: _StripClipper(index: index, count: count, skew: skew),
        child: Stack(
          children: [
            Positioned(
              left: center - boxWidth / 2,
              width: boxWidth,
              top: 0,
              bottom: 0,
              child: GameCover(game: game),
            ),
          ],
        ),
      ),
    );
  }
}

class _StripClipper extends CustomClipper<Path> {
  const _StripClipper({
    required this.index,
    required this.count,
    required this.skew,
  });

  final int index;
  final int count;
  final double skew;

  @override
  Path getClip(Size size) {
    final left = index == 0
        ? (top: -skew, bottom: -skew)
        : _seam(index, count, size, skew);
    final right = index == count - 1
        ? (top: size.width + skew, bottom: size.width + skew)
        : _seam(index + 1, count, size, skew);
    return Path()
      ..moveTo(left.top, 0)
      ..lineTo(right.top, 0)
      ..lineTo(right.bottom, size.height)
      ..lineTo(left.bottom, size.height)
      ..close();
  }

  @override
  bool shouldReclip(_StripClipper oldClipper) =>
      oldClipper.index != index ||
      oldClipper.count != count ||
      oldClipper.skew != skew;
}

/// Soft white seams between the cover strips.
class _SeamsPainter extends CustomPainter {
  const _SeamsPainter({required this.count, required this.skew});

  final int count;
  final double skew;

  @override
  void paint(Canvas canvas, Size size) {
    final halo = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final line = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, size.height),
        const [Color(0xF2FFFFFF), Color(0xD9F2F2F2), Color(0x99C8C8C8)],
        const [0, 0.5, 1],
      )
      ..strokeWidth = 1.6;
    for (var i = 1; i < count; i++) {
      final seam = _seam(i, count, size, skew);
      final a = Offset(seam.top, 0);
      final b = Offset(seam.bottom, size.height);
      canvas
        ..drawLine(a, b, halo)
        ..drawLine(a, b, line);
    }
  }

  @override
  bool shouldRepaint(_SeamsPainter oldDelegate) =>
      oldDelegate.count != count || oldDelegate.skew != skew;
}

/// Gold badge with the number of editions.
class _EditionsBadge extends StatelessWidget {
  const _EditionsBadge({required this.count, required this.compact});

  final int count;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF3A2208);
    return Semantics(
      label: context.l10n.t('home.editions', {'n': '$count'}),
      excludeSemantics: true,
      child: DecoratedBox(
        key: const ValueKey('home-series-badge'),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF1C4), Color(0xFFE8B84A), Color(0xFFB07A22)],
          ),
          border: Border.all(color: const Color(0xFFFFF6D8), width: 1),
          boxShadow: const [
            BoxShadow(color: Color(0x88E8B84A), blurRadius: 10),
            BoxShadow(
              color: Colors.black38,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 3 : 4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.layers_rounded, size: compact ? 14 : 16, color: ink),
              const SizedBox(width: 3),
              Text(
                '$count',
                style: TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w900,
                  fontSize: compact ? 13 : 15,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
