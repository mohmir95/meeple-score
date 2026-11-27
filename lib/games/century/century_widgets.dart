import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/widgets/app_page.dart';
import 'century_east_to_west_all_game.dart';
import 'century_east_to_west_ew_game.dart';
import 'century_east_to_west_game.dart';
import 'century_eastern_wonders_game.dart';
import 'century_game.dart';
import 'century_new_world_game.dart';
import 'century_rules.dart';
import 'century_sand_to_sea_game.dart';

const centuryInk = Color(0xFF3A2430);
const centuryMuted = Color(0xFF6B5560);
const _gold = Color(0xFFF0C674);

/// Card back colours, as printed.
const centuryPointBack = Color(0xFFE07B2A);
const centuryMerchantBack = Color(0xFF5B3A78);
const centuryCaravanBack = Color(0xFF7D7A78);

/// Colours and cover of one Century game's hub pages.
class CenturyStyleData {
  const CenturyStyleData({
    required this.coverAsset,
    required this.accent,
    required this.dark,
    required this.paper,
  });

  final String coverAsset;

  /// Header bands, pills and icons.
  final Color accent;

  /// The ends of the header band gradient.
  final Color dark;

  /// Panel background.
  final Color paper;

  /// Plum bands on cream, like the Spice Road rulebook.
  static const spiceRoad = CenturyStyleData(
    coverAsset: CenturySpiceRoadGame.coverAsset,
    accent: CenturySpiceRoadGame.plum,
    dark: Color(0xFF4E1F3A),
    paper: Color(0xFFFBF3E8),
  );

  /// Deep green bands on parchment, like the From East to West rulebook.
  static const eastToWest = CenturyStyleData(
    coverAsset: CenturyEastToWestGame.coverAsset,
    accent: CenturyEastToWestGame.green,
    dark: Color(0xFF12301F),
    paper: Color(0xFFF7F1E2),
  );

  /// Red bands on parchment, like the From East to West (Eastern Wonders + A New World)
  /// rulebook.
  static const eastToWestEw = CenturyStyleData(
    coverAsset: CenturyEastToWestEwGame.coverAsset,
    accent: CenturyEastToWestEwGame.maroon,
    dark: Color(0xFF451412),
    paper: Color(0xFFF7F1E2),
  );

  /// Deep blue bands on parchment, for the three-game combination.
  static const eastToWestAll = CenturyStyleData(
    coverAsset: CenturyEastToWestAllGame.coverAsset,
    accent: CenturyEastToWestAllGame.navy,
    dark: Color(0xFF172739),
    paper: Color(0xFFF7F1E2),
  );

  /// Purple bands on pale sea green, like the From Sand to Sea rulebook.
  static const sandToSea = CenturyStyleData(
    coverAsset: CenturySandToSeaGame.coverAsset,
    accent: CenturySandToSeaGame.purple,
    dark: Color(0xFF3E1838),
    paper: Color(0xFFEEF3EE),
  );

  /// Forest-green bands on parchment, like the A New World rulebook.
  static const newWorld = CenturyStyleData(
    coverAsset: CenturyNewWorldGame.coverAsset,
    accent: CenturyNewWorldGame.forest,
    dark: Color(0xFF1C3A24),
    paper: Color(0xFFF7F1E2),
  );

  /// Brick-red bands on pale sea green, like the Eastern Wonders rulebook.
  static const easternWonders = CenturyStyleData(
    coverAsset: CenturyEasternWondersGame.coverAsset,
    accent: CenturyEasternWondersGame.brick,
    dark: Color(0xFF5A1C12),
    paper: Color(0xFFEFF5F1),
  );
}

/// Gives the Century widgets below it their game's colours.
class CenturyStyle extends InheritedWidget {
  const CenturyStyle({super.key, required this.data, required super.child});

  final CenturyStyleData data;

  static CenturyStyleData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CenturyStyle>()?.data ??
      CenturyStyleData.spiceRoad;

  @override
  bool updateShouldNotify(CenturyStyle old) => old.data != data;
}

/// The page frame shared by the Century hub pages: cover, title and a
/// centred, scrolling column.
class CenturyPage extends StatelessWidget {
  const CenturyPage({
    super.key,
    required this.titleKey,
    required this.children,
    this.style = CenturyStyleData.spiceRoad,
  });

  final String titleKey;
  final List<Widget> children;
  final CenturyStyleData style;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final gap = SizedBox(height: compact ? 14 : 18);
    return AppPage(
      title: context.l10n.t(titleKey),
      coverImageAsset: style.coverAsset,
      body: CenturyStyle(data: style, child: _body(compact, gap)),
    );
  }

  Widget _body(bool compact, Widget gap) {
    return SingleChildScrollView(
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
    );
  }
}

/// One line of a [CenturyCountTable]: what is counted, and how many for
/// each player count. A zero shows as a dash.
class CenturyCountRow {
  const CenturyCountRow({
    required this.label,
    required this.value,
    this.lead,
    this.hint,
  });

  final String label;

  /// A smaller line under [label].
  final String? hint;
  final Object Function(int players) value;
  final Widget? lead;
}

/// Setup numbers for every player count at once: a column per count.
class CenturyCountTable extends StatelessWidget {
  const CenturyCountTable({
    super.key,
    required this.rows,
    this.counts = CenturyRules.playerCounts,
  });

  final List<CenturyCountRow> rows;
  final List<int> counts;

  @override
  Widget build(BuildContext context) {
    final style = CenturyStyle.of(context);
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final textTheme = Theme.of(context).textTheme;
    final column = compact ? 44.0 : 60.0;
    final pad = EdgeInsets.symmetric(vertical: compact ? 7 : 8);

    Widget header(int n) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: style.accent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person, color: Colors.white, size: 13),
              const SizedBox(width: 1),
              Text(
                '$n',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Widget value(Object v) {
      final none = v == 0 || v == '';
      return Padding(
        padding: pad,
        child: Text(
          none ? '–' : '$v',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: none ? centuryMuted : centuryInk,
            fontWeight: FontWeight.w900,
            fontSize: compact ? 15 : 17,
          ),
        ),
      );
    }

    return Table(
      key: const ValueKey('century-count-table'),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: {
        0: const FlexColumnWidth(),
        for (var i = 0; i < counts.length; i++) i + 1: FixedColumnWidth(column),
      },
      border: TableBorder(
        horizontalInside: BorderSide(
          color: style.accent.withValues(alpha: 0.15),
        ),
      ),
      children: [
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                context.l10n.t('century.setup.playersHeader'),
                style: textTheme.labelMedium?.copyWith(
                  color: centuryMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (final n in counts) header(n),
          ],
        ),
        for (final row in rows)
          TableRow(
            children: [
              Padding(
                padding: pad,
                child: Row(
                  children: [
                    if (row.lead != null) ...[
                      row.lead!,
                      SizedBox(width: compact ? 8 : 10),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.label,
                            style: textTheme.titleSmall?.copyWith(
                              color: centuryInk,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (row.hint != null)
                            Text(
                              row.hint!,
                              style: textTheme.bodySmall?.copyWith(
                                color: centuryMuted,
                                height: 1.3,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              for (final n in counts) value(row.value(n)),
            ],
          ),
      ],
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
    this.optional = false,
  });

  final String title;
  final String? body;
  final List<Widget> children;

  /// An optional step rather than an action: an outlined header in the
  /// accent colour with an "Optional" tag, matching [CenturyActionChip].
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final style = CenturyStyle.of(context);
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      color: optional ? style.accent : _gold,
      fontWeight: FontWeight.w800,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: style.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: style.accent.withValues(alpha: optional ? 0.7 : 0.35),
          width: optional ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: style.accent.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: optional
                ? BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: style.accent.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : BoxDecoration(
                    gradient: LinearGradient(
                      colors: [style.dark, style.accent, style.dark],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(17),
                    ),
                  ),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 22,
              vertical: compact ? 10 : 12,
            ),
            child: optional
                ? Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      Text(title, style: titleStyle),
                      CenturyOptionalTag(color: style.accent),
                    ],
                  )
                : Text(title, textAlign: TextAlign.center, style: titleStyle),
          ),
          Padding(
            padding: EdgeInsets.all(compact ? 14 : 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (body != null) ...[
                  Text.rich(
                    centuryBoldSpans(body!),
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
    final style = CenturyStyle.of(context);
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
                  color: style.accent,
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

/// A bold lead-in line inside a panel, introducing the points below it.
class CenturySubheading extends StatelessWidget {
  const CenturySubheading({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: centuryInk,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// A note-styled box that starts collapsed; tapping the header shows
/// [children].
class CenturyCollapsible extends StatefulWidget {
  const CenturyCollapsible({
    super.key,
    required this.title,
    required this.children,
    this.icon,
  });

  final String title;
  final IconData? icon;
  final List<Widget> children;

  @override
  State<CenturyCollapsible> createState() => _CenturyCollapsibleState();
}

class _CenturyCollapsibleState extends State<CenturyCollapsible> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final style = CenturyStyle.of(context);
    final radius = BorderRadius.circular(12);
    return Container(
      decoration: BoxDecoration(
        color: style.accent.withValues(alpha: 0.07),
        borderRadius: radius,
        border: Border.all(color: style.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: radius,
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      widget.icon ?? Icons.info_outline_rounded,
                      size: 20,
                      color: style.accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: centuryMuted,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.expand_more_rounded,
                        size: 22,
                        color: style.accent,
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
            child: _open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Column(children: widget.children),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// [text] with each `**part**` in bold, optionally in [boldColor].
TextSpan centuryBoldSpans(String text, {Color? boldColor}) => TextSpan(
  children: [
    for (final (i, part) in text.split('**').indexed)
      TextSpan(
        text: part,
        style: i.isOdd
            ? TextStyle(fontWeight: FontWeight.w800, color: boldColor)
            : null,
      ),
  ],
);

class CenturyNote extends StatelessWidget {
  const CenturyNote({super.key, required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = CenturyStyle.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: style.accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: style.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon ?? Icons.info_outline_rounded,
            size: 20,
            color: style.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              centuryBoldSpans(text, boldColor: centuryInk),
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
  const CenturyBadge({
    super.key,
    required this.text,
    this.error = false,
    this.icon,
    this.iconColor = Colors.white,
  });

  final String text;
  final bool error;

  /// Drawn white on a dot of the badge colour, before the text.
  final IconData? icon;

  /// Colour of [icon]. Any colour but white sits on a white dot instead,
  /// e.g. a black star.
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final style = CenturyStyle.of(context);
    final color = error ? Theme.of(context).colorScheme.error : style.accent;
    final label = Text(
      text,
      style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
    );
    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(icon == null ? 10 : 4, 3, 10, 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: icon == null
          ? label
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: iconColor == Colors.white ? color : Colors.white,
                    shape: BoxShape.circle,
                    border: iconColor == Colors.white
                        ? null
                        : Border.all(color: color, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: iconColor, size: 13),
                ),
                const SizedBox(width: 5),
                Flexible(child: label),
              ],
            ),
    );
  }
}

/// A pointy-top hexagonal tile, such as a market, port or VP tile.
class HexTile extends StatelessWidget {
  const HexTile({
    super.key,
    required this.color,
    required this.size,
    this.label,
    this.labelColor = Colors.white,
    this.flatTop = false,
  });

  final Color color;

  /// Width of the tile; the height follows the hexagon.
  final double size;
  final String? label;
  final Color labelColor;

  /// Flat edges at top and bottom, so tiles stack in straight columns.
  final bool flatTop;

  /// Height of a tile of width [size].
  static double heightFor(double size, {bool flatTop = false}) =>
      size * (flatTop ? 0.866 : 1.1547);

  @override
  Widget build(BuildContext context) {
    final height = heightFor(size, flatTop: flatTop);
    return CustomPaint(
      size: Size(size, height),
      painter: _HexPainter(color, flatTop: flatTop),
      child: SizedBox(
        width: size,
        height: height,
        child: label == null
            ? null
            : Center(
                child: Text(
                  label!,
                  style: TextStyle(
                    color: labelColor,
                    fontWeight: FontWeight.w900,
                    fontSize: size * 0.34,
                    height: 1,
                  ),
                ),
              ),
      ),
    );
  }
}

class _HexPainter extends CustomPainter {
  const _HexPainter(this.color, {this.flatTop = false});

  final Color color;
  final bool flatTop;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = flatTop
        ? (Path()
            ..moveTo(w * 0.25, 0)
            ..lineTo(w * 0.75, 0)
            ..lineTo(w, h / 2)
            ..lineTo(w * 0.75, h)
            ..lineTo(w * 0.25, h)
            ..lineTo(0, h / 2)
            ..close())
        : (Path()
            ..moveTo(w / 2, 0)
            ..lineTo(w, h * 0.25)
            ..lineTo(w, h * 0.75)
            ..lineTo(w / 2, h)
            ..lineTo(0, h * 0.75)
            ..lineTo(0, h * 0.25)
            ..close());
    canvas.drawShadow(path, Colors.black, 2, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(color, Colors.white, 0.2)!, color],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeJoin = StrokeJoin.round
        ..color = Color.lerp(color, Colors.black, 0.4)!,
    );
  }

  @override
  bool shouldRepaint(_HexPainter old) =>
      old.color != color || old.flatTop != flatTop;
}

/// The four spice colours in upgrade order, each with its name from
/// [nameKey] and its colour word.
class CenturySpiceOrder extends StatelessWidget {
  const CenturySpiceOrder({super.key, required this.nameKey});

  final String Function(CenturySpice spice) nameKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final cube = compact ? 30.0 : 40.0;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final spice in CenturySpice.values) ...[
            if (spice.index > 0)
              Padding(
                padding: EdgeInsets.only(top: cube * 0.3),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: compact ? 16 : 20,
                  color: centuryMuted,
                ),
              ),
            Expanded(
              child: Column(
                key: ValueKey('century-spice-${spice.name}'),
                children: [
                  SpiceCube(spice: spice, size: cube),
                  const SizedBox(height: 6),
                  Text(
                    l10n.t(nameKey(spice)),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: centuryInk,
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 12 : 14,
                    ),
                  ),
                  Text(
                    l10n.t('century.colour.${spice.name}'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: centuryMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: compact ? 11 : 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// An icon, an optional bold lead-in and a line of rules text.
class CenturyPoint extends StatelessWidget {
  const CenturyPoint({
    super.key,
    required this.icon,
    required this.text,
    this.title,
  });

  final IconData icon;
  final String? title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: centuryInk, height: 1.4);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 5 : 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: CenturyStyle.of(context).accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  if (title != null)
                    TextSpan(
                      text: '$title ',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  centuryBoldSpans(text),
                ],
              ),
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

class CenturyActionChip extends StatelessWidget {
  const CenturyActionChip({
    super.key,
    required this.text,
    this.optional = false,
  });

  final String text;

  /// An optional step before the action: outlined instead of filled.
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final accent = CenturyStyle.of(context).accent;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: optional ? 5 : 6),
      decoration: BoxDecoration(
        color: optional ? Colors.transparent : accent,
        borderRadius: BorderRadius.circular(999),
        border: optional ? Border.all(color: accent, width: 1.5) : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: optional ? accent : Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}

/// A small "Optional" tag in the accent colour.
class CenturyOptionalTag extends StatelessWidget {
  const CenturyOptionalTag({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        context.l10n.t('century.optional'),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

/// An optional step, an arrow, then the actions to choose from with thin
/// dividers between them: "Move → Market | Port | Harvest".
class CenturyTurnFlow extends StatelessWidget {
  const CenturyTurnFlow({
    super.key,
    required this.optionalStep,
    required this.actions,
  });

  final String optionalStep;
  final List<String> actions;

  @override
  Widget build(BuildContext context) {
    final accent = CenturyStyle.of(context).accent;
    final divider = Container(
      width: 1.5,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: accent.withValues(alpha: 0.45),
    );
    return Wrap(
      key: const ValueKey('century-turn-flow'),
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        CenturyActionChip(text: optionalStep, optional: true),
        // Points the reading way, so it flips in Persian.
        Icon(Icons.arrow_forward_rounded, color: accent, size: 22),
        // The actions stay together on one line, shrinking on narrow phones.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) divider,
                CenturyActionChip(text: actions[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
