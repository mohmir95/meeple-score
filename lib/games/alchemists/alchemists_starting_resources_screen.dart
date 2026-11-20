import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/widgets/app_page.dart';
import 'alchemists_game.dart';

/// Starting resources from the "Player's Laboratory" rulebook page.
class AlchemistsSetup {
  const AlchemistsSetup._();

  static const playerCounts = [2, 3, 4];
  static const gold = 2;

  /// Action cubes: 6 for 2 players, 5 for 3, 4 for 4.
  static int actionCubes(int players) => 8 - players;

  /// Every player uses only this many cubes in the first round.
  static const firstRoundCubes = 3;

  static int ingredients({required bool master}) => master ? 2 : 3;

  static const favorsDrawn = 2;
  static const favorsKept = 1;

  /// Hedge seals: 2 in each aspect colour.
  static const hedgeSeals = [
    (key: 'red', color: Color(0xFFC0392B)),
    (key: 'green', color: Color(0xFF3E9B4F)),
    (key: 'blue', color: Color(0xFF2E86C1)),
  ];
  static const hedgeSealsPerColour = 2;

  /// Star seals: 3 silver worth 3, 2 gold worth 5.
  static const starSeals = [
    (key: 'silver', color: Color(0xFFBCC1C8), points: 3, count: 3),
    (key: 'gold', color: Color(0xFFE2B33C), points: 5, count: 2),
  ];
}

const _ink = Color(0xFF2A2433);
const _muted = Color(0xFF5E566B);
const _paper = Color(0xFFF7F3FA);
const _accent = AlchemistsGame.purple;

class AlchemistsStartingResourcesScreen extends StatefulWidget {
  const AlchemistsStartingResourcesScreen({super.key});

  @override
  State<AlchemistsStartingResourcesScreen> createState() =>
      _AlchemistsStartingResourcesScreenState();
}

class _AlchemistsStartingResourcesScreenState
    extends State<AlchemistsStartingResourcesScreen> {
  var _players = 4;
  var _master = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final padding = compact ? 12.0 : 20.0;
    final gap = SizedBox(height: compact ? 14 : 18);
    final cubes = AlchemistsSetup.actionCubes(_players);
    final icon = compact ? 26.0 : 30.0;

    return AppPage(
      title: l10n.t('hub.startingResources'),
      coverImageAsset: AlchemistsGame.coverAsset,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<int>(
                  key: const ValueKey('alchemists-setup-players'),
                  showSelectedIcon: false,
                  segments: [
                    for (final n in AlchemistsSetup.playerCounts)
                      ButtonSegment(
                        value: n,
                        label: Text(
                          l10n.t('alchemists.setup.players', {'n': '$n'}),
                        ),
                      ),
                  ],
                  selected: {_players},
                  onSelectionChanged: (s) => setState(() => _players = s.first),
                ),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  key: const ValueKey('alchemists-setup-variant'),
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: false,
                      label: Text(l10n.t('alchemists.setup.apprentice')),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text(l10n.t('alchemists.setup.master')),
                    ),
                  ],
                  selected: {_master},
                  onSelectionChanged: (s) => setState(() => _master = s.first),
                ),
                gap,
                _Panel(
                  key: const ValueKey('alchemists-setup-each'),
                  compact: compact,
                  title: l10n.t('alchemists.setup.eachTitle'),
                  children: [
                    _Row(
                      key: const ValueKey('alchemists-setup-gold'),
                      compact: compact,
                      lead: _Flat.circle(const Color(0xFFE2B33C), icon * 0.8),
                      label: l10n.t('alchemists.setup.gold'),
                      count: '${AlchemistsSetup.gold}',
                    ),
                    _Row(
                      key: const ValueKey('alchemists-setup-cubes'),
                      compact: compact,
                      lead: _Flat.square(const Color(0xFFC62828), icon * 0.7),
                      label: l10n.t('alchemists.setup.cubes'),
                      count: '$cubes',
                    ),
                    _Row(
                      key: const ValueKey('alchemists-setup-ingredients'),
                      compact: compact,
                      lead: _Flat.card(const Color(0xFF8B5E3C), icon),
                      label: l10n.t('alchemists.setup.ingredients'),
                      count: '${AlchemistsSetup.ingredients(master: _master)}',
                    ),
                    _Row(
                      key: const ValueKey('alchemists-setup-favors'),
                      compact: compact,
                      lead: _Flat.card(const Color(0xFFB07CC6), icon),
                      label: l10n.t('alchemists.setup.favors', {
                        'drawn': '${AlchemistsSetup.favorsDrawn}',
                        'kept': '${AlchemistsSetup.favorsKept}',
                      }),
                      count: '${AlchemistsSetup.favorsKept}',
                    ),
                    SizedBox(height: compact ? 10 : 12),
                    _Note(
                      key: const ValueKey('alchemists-setup-first-round'),
                      text: l10n.t('alchemists.setup.firstRound', {
                        'first': '${AlchemistsSetup.firstRoundCubes}',
                        'rest': '${cubes - AlchemistsSetup.firstRoundCubes}',
                      }),
                    ),
                  ],
                ),
                gap,
                _Panel(
                  key: const ValueKey('alchemists-setup-seals'),
                  compact: compact,
                  title: l10n.t('alchemists.setup.sealsTitle'),
                  children: [
                    _Row(
                      key: const ValueKey('alchemists-setup-hedge'),
                      compact: compact,
                      lead: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final seal in AlchemistsSetup.hedgeSeals)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 1,
                              ),
                              child: _Seal(
                                medal: seal.color,
                                width: icon * 0.75,
                              ),
                            ),
                        ],
                      ),
                      leadWidth: icon * 2.6,
                      label: l10n.t('alchemists.setup.hedgeSeals', {
                        'n': '${AlchemistsSetup.hedgeSealsPerColour}',
                      }),
                      count:
                          '${AlchemistsSetup.hedgeSeals.length * AlchemistsSetup.hedgeSealsPerColour}',
                    ),
                    for (final seal in AlchemistsSetup.starSeals)
                      _Row(
                        key: ValueKey('alchemists-setup-star-${seal.key}'),
                        compact: compact,
                        lead: _Seal(
                          medal: seal.color,
                          width: icon * 0.75,
                          star: true,
                        ),
                        leadWidth: icon * 2.6,
                        label: l10n.t('alchemists.setup.starSeal.${seal.key}', {
                          'points': '${seal.points}',
                        }),
                        count: '${seal.count}',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    super.key,
    required this.compact,
    required this.title,
    required this.children,
  });

  final bool compact;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 22,
          vertical: compact ? 14 : 18,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: _accent,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: compact ? 8 : 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// A tile swatch, a label and a count on the right.
class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.compact,
    required this.lead,
    required this.label,
    required this.count,
    this.leadWidth,
  });

  final bool compact;
  final Widget lead;
  final String label;
  final String count;
  final double? leadWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 6 : 7),
      child: Row(
        children: [
          SizedBox(
            width: leadWidth ?? (compact ? 34 : 40),
            child: Center(child: lead),
          ),
          SizedBox(width: compact ? 10 : 14),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: _ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            count,
            style: TextStyle(
              color: _ink,
              fontWeight: FontWeight.w900,
              fontSize: compact ? 16 : 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 20, color: _accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _muted,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Flat, single-colour component icons with a darker outline.
class _Flat extends StatelessWidget {
  const _Flat._(this.color, this.size, this.radius);

  factory _Flat.circle(Color color, double d) =>
      _Flat._(color, Size(d, d), d / 2);

  factory _Flat.square(Color color, double d) =>
      _Flat._(color, Size(d, d), d * 0.18);

  factory _Flat.card(Color color, double h) =>
      _Flat._(color, Size(h * 0.68, h), h * 0.1);

  final Color color;
  final Size size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Color.lerp(color, Colors.black, 0.35)!),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

/// A seal: a red ribbon with a forked tail and a round medal on top, drawn
/// flat like the other icons. Hedge seals show a disc in their colour; star
/// seals show a silver or gold star.
class _Seal extends StatelessWidget {
  const _Seal({required this.medal, required this.width, this.star = false});

  final Color medal;
  final double width;
  final bool star;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, width * 1.55),
      painter: _SealPainter(medal, star: star),
    );
  }
}

class _SealPainter extends CustomPainter {
  const _SealPainter(this.medal, {required this.star});

  final Color medal;
  final bool star;

  /// A five-pointed star centred on [c], point up.
  static Path _star(Offset c, double outer) {
    final inner = outer * 0.45;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? outer : inner;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final p = c + Offset(math.cos(angle), math.sin(angle)) * r;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  static const _ribbon = Color(0xFFB3302B);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    Paint outline(Color c) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Color.lerp(c, Colors.black, 0.35)!;

    // Ribbon: hangs from behind the medal and ends in a V-shaped notch.
    final left = w * 0.17, right = w * 0.83;
    final ribbon = Path()
      ..moveTo(left, w * 0.45)
      ..lineTo(right, w * 0.45)
      ..lineTo(right, h)
      ..lineTo(w / 2, h - w * 0.28)
      ..lineTo(left, h)
      ..close();
    canvas
      ..drawShadow(ribbon, Colors.black, 1.5, false)
      ..drawPath(ribbon, Paint()..color = _ribbon)
      ..drawPath(ribbon, outline(_ribbon));

    // Medal on top.
    final centre = Offset(w / 2, w * 0.48);
    final radius = w * 0.46;
    final disc = Path()
      ..addOval(Rect.fromCircle(center: centre, radius: radius));
    canvas
      ..drawShadow(disc, Colors.black, 1.5, false)
      ..drawCircle(centre, radius, Paint()..color = _ribbon)
      ..drawCircle(centre, radius, outline(_ribbon));
    if (star) {
      final shape = _star(centre + Offset(0, radius * 0.06), radius * 0.82);
      canvas
        ..drawPath(shape, Paint()..color = medal)
        ..drawPath(shape, outline(medal));
    } else {
      canvas
        ..drawCircle(centre, radius * 0.68, Paint()..color = medal)
        ..drawCircle(centre, radius * 0.68, outline(medal));
    }
  }

  @override
  bool shouldRepaint(_SealPainter oldDelegate) =>
      oldDelegate.medal != medal || oldDelegate.star != star;
}
