import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/widgets/app_page.dart';
import 'century_game.dart';
import 'century_rules.dart';

const centuryInk = Color(0xFF3A2430);
const centuryMuted = Color(0xFF6B5560);
const _paper = Color(0xFFFBF3E8);
const _accent = CenturySpiceRoadGame.plum;
const _gold = Color(0xFFF0C674);

/// Card back colours, as printed.
const centuryPointBack = Color(0xFFE07B2A);
const centuryMerchantBack = Color(0xFF5B3A78);
const centuryCaravanBack = Color(0xFF7D7A78);

/// The page frame shared by the Century hub pages: cover, title and a
/// centred, scrolling column.
class CenturyPage extends StatelessWidget {
  const CenturyPage({
    super.key,
    required this.titleKey,
    required this.children,
  });

  final String titleKey;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final gap = SizedBox(height: compact ? 14 : 18);
    return AppPage(
      title: context.l10n.t(titleKey),
      coverImageAsset: CenturySpiceRoadGame.coverAsset,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(compact ? 12 : 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) gap,
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CenturyPlayerPicker extends StatelessWidget {
  const CenturyPlayerPicker({
    super.key,
    required this.players,
    required this.onChanged,
  });

  final int players;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      key: const ValueKey('century-players'),
      showSelectedIcon: false,
      segments: [
        for (final n in CenturyRules.playerCounts)
          ButtonSegment(
            value: n,
            label: Text(context.l10n.t('century.players', {'n': '$n'})),
          ),
      ],
      selected: {players},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

/// A cream panel under a plum band with gold lettering, like the rulebook's
/// section headers.
class CenturyPanel extends StatelessWidget {
  const CenturyPanel({
    super.key,
    required this.title,
    required this.children,
    this.body,
  });

  final String title;
  final String? body;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _accent.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4E1F3A), _accent, Color(0xFF4E1F3A)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 22,
              vertical: compact ? 10 : 12,
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: _gold,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(compact ? 14 : 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (body != null) ...[
                  Text(
                    body!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: centuryInk,
                      height: 1.4,
                    ),
                  ),
                  if (children.isNotEmpty) SizedBox(height: compact ? 12 : 16),
                ],
                ...children,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// An icon, a label with an optional hint, and a value on the right.
class CenturyRow extends StatelessWidget {
  const CenturyRow({
    super.key,
    required this.lead,
    required this.label,
    required this.value,
    this.hint,
    this.leadWidth,
    this.trailing,
    this.highlight = false,
  });

  final Widget lead;

  /// Shown between the label and [value], e.g. the cubes it counts.
  final Widget? trailing;
  final String label;
  final String? hint;
  final String value;
  final double? leadWidth;

  /// Shows [value] in a plum pill that pops when it changes.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final valueStyle = TextStyle(
      color: highlight ? Colors.white : centuryInk,
      fontWeight: FontWeight.w900,
      fontSize: compact ? 16 : 18,
    );
    final valueText = Text(value, style: valueStyle);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 6 : 7),
      child: Row(
        children: [
          SizedBox(
            width: leadWidth ?? (compact ? 40 : 48),
            child: Center(child: lead),
          ),
          SizedBox(width: compact ? 10 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: centuryInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (hint != null)
                  Text(
                    hint!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: centuryMuted,
                      height: 1.3,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          const SizedBox(width: 8),
          if (highlight)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: Tween(begin: 0.6, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                ),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Container(
                key: ValueKey(value),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: valueText,
              ),
            )
          else
            valueText,
        ],
      ),
    );
  }
}

class CenturyNote extends StatelessWidget {
  const CenturyNote({super.key, required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? Icons.info_outline_rounded, size: 20, color: _accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: centuryMuted,
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

/// A small isometric spice cube.
class SpiceCube extends StatelessWidget {
  const SpiceCube({super.key, required this.spice, required this.size});

  final CenturySpice spice;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _CubePainter(spice.color),
    );
  }
}

class _CubePainter extends CustomPainter {
  const _CubePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final top = Offset(w / 2, 0);
    final left = Offset(0, h * 0.25);
    final right = Offset(w, h * 0.25);
    final centre = Offset(w / 2, h * 0.5);
    final bottom = Offset(w / 2, h);
    final leftBottom = Offset(0, h * 0.75);
    final rightBottom = Offset(w, h * 0.75);

    Path face(List<Offset> points) => Path()..addPolygon(points, true);
    void fill(Path path, Color c) => canvas.drawPath(path, Paint()..color = c);

    fill(
      face([top, right, centre, left]),
      Color.lerp(color, Colors.white, 0.28)!,
    );
    fill(face([left, centre, bottom, leftBottom]), color);
    fill(
      face([centre, right, rightBottom, bottom]),
      Color.lerp(color, Colors.black, 0.22)!,
    );
    canvas.drawPath(
      face([top, right, rightBottom, bottom, leftBottom, left]),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeJoin = StrokeJoin.round
        ..color = Color.lerp(color, Colors.black, 0.45)!,
    );
  }

  @override
  bool shouldRepaint(_CubePainter old) => old.color != color;
}

/// A row of cubes: [counts] in upgrade order.
class SpiceCubes extends StatelessWidget {
  const SpiceCubes({super.key, required this.counts, required this.size});

  final Map<CenturySpice, int> counts;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: size * 0.15,
      runSpacing: size * 0.15,
      children: [
        for (final spice in CenturySpice.values)
          for (var i = 0; i < (counts[spice] ?? 0); i++)
            SpiceCube(spice: spice, size: size),
      ],
    );
  }
}

/// A gold or silver coin token with its point value.
class CenturyCoin extends StatelessWidget {
  const CenturyCoin({super.key, required this.gold, required this.size});

  final bool gold;
  final double size;

  @override
  Widget build(BuildContext context) {
    final base = gold ? const Color(0xFFE2B33C) : const Color(0xFFC3C7CD);
    final rim = Color.lerp(base, Colors.black, 0.3)!;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.35),
          colors: [Color.lerp(base, Colors.white, 0.4)!, base],
        ),
        border: Border.all(color: rim, width: size * 0.07),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '${gold ? CenturyRules.goldPoints : CenturyRules.silverPoints}',
        style: TextStyle(
          color: rim,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.5,
          height: 1,
        ),
      ),
    );
  }
}

/// A plain card: a coloured back, or a face with a coloured band and an
/// optional point value.
class CenturyCard extends StatelessWidget {
  const CenturyCard({
    super.key,
    required this.color,
    required this.width,
    this.faceUp = false,
    this.label,
    this.deck = false,
  });

  final Color color;
  final double width;
  final bool faceUp;
  final bool deck;

  /// Text in the band of a face-up card, or on a back.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final height = width * 1.45;
    final radius = BorderRadius.circular(width * 0.1);
    final dark = Color.lerp(color, Colors.black, 0.35)!;
    if (!faceUp) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(color, Colors.white, 0.18)!, color],
          ),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            if (deck) ...[
              BoxShadow(color: dark, offset: const Offset(2, 2)),
              BoxShadow(
                color: Color.lerp(color, Colors.black, 0.5)!,
                offset: const Offset(4, 4),
              ),
            ] else
              const BoxShadow(
                color: Color(0x33000000),
                blurRadius: 3,
                offset: Offset(0, 2),
              ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label ?? 'C',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontWeight: FontWeight.w900,
            fontSize: width * (label == null ? 0.5 : 0.3),
            height: 1,
          ),
        ),
      );
    }
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF4E6CF),
        borderRadius: radius,
        border: Border.all(color: color.withValues(alpha: 0.75), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              margin: EdgeInsets.all(width * 0.07),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(width * 0.06),
              ),
            ),
          ),
          SizedBox(
            height: height * 0.24,
            child: label == null
                ? null
                : Center(
                    child: Text(
                      label!,
                      style: TextStyle(
                        color: dark,
                        fontWeight: FontWeight.w900,
                        fontSize: width * 0.26,
                        height: 1,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// A small badge such as "−4 to the box".
class CenturyBadge extends StatelessWidget {
  const CenturyBadge({super.key, required this.text, this.error = false});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final color = error ? Theme.of(context).colorScheme.error : _accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
