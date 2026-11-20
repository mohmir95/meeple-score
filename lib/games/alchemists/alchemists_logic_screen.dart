import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/loading_image.dart';
import 'alchemists_game.dart';

const _frames = 'assets/games/alchemists/logic';

/// One point of the tutorial: a line of text (a translation key under
/// `alchemists.logic.`), optional video frames, and optional sub-points.
class LogicPoint {
  const LogicPoint(this.key, {this.frames = const [], this.sub = const []});

  final String key;

  /// Frame file names in [_frames], shown as a swipeable strip.
  final List<String> frames;
  final List<LogicPoint> sub;
}

class LogicSection {
  const LogicSection(this.key, this.points);

  final String key;
  final List<LogicPoint> points;
}

/// Techniques for the deduction puzzle, from Meeple University's video.
class AlchemistsLogic {
  const AlchemistsLogic._();

  static const sections = [
    LogicSection('basics', [
      LogicPoint('basics.ingredients', frames: ['1-1']),
      LogicPoint('basics.aspects'),
      LogicPoint('basics.mixing', frames: ['1-3-1', '1-3-2', '1-3-3', '1-3-4']),
      LogicPoint('basics.neutral', frames: ['1-4-1']),
    ]),
    LogicSection('reading', [
      LogicPoint('reading.token'),
      LogicPoint('reading.coloured', frames: ['2-2']),
      LogicPoint('reading.neutral'),
    ]),
    LogicSection('linked', [
      LogicPoint('linked.why'),
      LogicPoint('linked.letters', frames: ['3-2']),
      LogicPoint('linked.follow'),
      LogicPoint('linked.allPairs'),
    ]),
    LogicSection('selling', [
      LogicPoint('selling.exact', frames: ['4-1-1', '4-1-2', '4-1-3', '4-1-4']),
      LogicPoint(
        'selling.partial',
        frames: ['4-2'],
        sub: [
          LogicPoint('selling.partialToken', frames: ['4-2-1']),
          LogicPoint('selling.partialCross', frames: ['4-2-2-1', '4-2-2-2']),
        ],
      ),
    ]),
    LogicSection('thinking', [
      LogicPoint('thinking.sameColour', frames: ['5-1-1', '5-1-3']),
      LogicPoint(
        'thinking.sizes',
        frames: ['5-2-1', '5-2-2', '5-2-3', '5-2-4', '5-2-5'],
      ),
      LogicPoint(
        'thinking.twoOptions',
        frames: ['5-3-1', '5-3-2', '5-3-3', '5-3-4', '5-3-5', '5-3-6'],
      ),
      LogicPoint('thinking.foundRow', frames: ['5-4-1', '5-4-2']),
      LogicPoint(
        'thinking.twoOfEach',
        frames: ['5-5-1', '5-5-2', '5-5-3', '5-5-4', '5-5-5', '5-5-6'],
      ),
    ]),
    LogicSection('theories', [
      LogicPoint('theories.hedged', frames: ['6-1-1', '6-1-2']),
      LogicPoint('theories.confirmed', frames: ['6-2']),
      LogicPoint('theories.debunk', frames: ['6-3-1', '6-3-2', '6-3-3']),
    ]),
    LogicSection('planning', [
      LogicPoint('planning.predict', frames: ['7-1']),
      LogicPoint('planning.pick', frames: ['7-2-1', '7-2-2']),
    ]),
    LogicSection('strategy', [
      LogicPoint('strategy.public', frames: ['8-1']),
      LogicPoint('strategy.worst', frames: ['8-2']),
      LogicPoint('strategy.bigHand'),
      LogicPoint('strategy.sevenExperiments'),
      LogicPoint('strategy.trust', frames: ['8-5-1', '8-5-2']),
    ]),
  ];

  /// Every frame used, for asset checks.
  static Iterable<String> get allFrames sync* {
    Iterable<String> walk(LogicPoint p) sync* {
      yield* p.frames;
      for (final s in p.sub) {
        yield* walk(s);
      }
    }

    for (final section in sections) {
      for (final point in section.points) {
        yield* walk(point);
      }
    }
  }

  static String asset(String frame) => '$_frames/$frame.jpg';
}

const _ink = Color(0xFF2A2433);
const _muted = Color(0xFF5E566B);
const _paper = Color(0xFFF7F3FA);

class AlchemistsLogicScreen extends StatelessWidget {
  const AlchemistsLogicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final padding = compact ? 12.0 : 20.0;

    return AppPage(
      title: l10n.t('hub.logicPuzzle'),
      coverImageAsset: AlchemistsGame.coverAsset,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.t('alchemists.logic.intro'),
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.t('alchemists.logic.credit'),
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                ),
                SizedBox(height: compact ? 12 : 16),
                for (var i = 0; i < AlchemistsLogic.sections.length; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: compact ? 10 : 12),
                    child: _SectionCard(
                      number: i + 1,
                      section: AlchemistsLogic.sections[i],
                      compact: compact,
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

/// A collapsible section, closed until tapped, so the page stays short.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.number,
    required this.section,
    required this.compact,
  });

  final int number;
  final LogicSection section;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const accent = AlchemistsGame.purple;
    return Card(
      key: ValueKey('alchemists-logic-${section.key}'),
      margin: EdgeInsets.zero,
      color: _paper,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accent.withValues(alpha: 0.3)),
      ),
      child: ExpansionTile(
        key: ValueKey('alchemists-logic-tile-${section.key}'),
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: accent,
        collapsedIconColor: accent,
        tilePadding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
        childrenPadding: EdgeInsets.fromLTRB(
          compact ? 14 : 20,
          0,
          compact ? 14 : 20,
          compact ? 14 : 18,
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        leading: CircleAvatar(
          radius: 15,
          backgroundColor: accent,
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        title: Text(
          l10n.t('alchemists.logic.${section.key}.title'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          l10n.t('alchemists.logic.${section.key}.summary'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _muted),
        ),
        children: [
          for (final point in section.points)
            _Point(point: point, compact: compact),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.point, required this.compact, this.depth = 0});

  final LogicPoint point;
  final bool compact;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: _ink, height: 1.45);
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: depth * (compact ? 14.0 : 20.0),
        top: compact ? 8 : 10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Icon(
                  depth == 0 ? Icons.circle : Icons.circle_outlined,
                  size: 7,
                  color: AlchemistsGame.purple,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  boldMarkup(l10n.t('alchemists.logic.${point.key}'), style),
                ),
              ),
            ],
          ),
          if (point.frames.isNotEmpty) ...[
            SizedBox(height: compact ? 8 : 10),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 17),
              child: _FrameStrip(
                key: ValueKey('alchemists-frames-${point.key}'),
                frames: point.frames,
              ),
            ),
          ],
          for (final sub in point.sub)
            _Point(point: sub, compact: compact, depth: depth + 1),
        ],
      ),
    );
  }
}

/// Turns `**bold**` markers into bold spans.
TextSpan boldMarkup(String text, TextStyle? style) {
  final parts = text.split('**');
  return TextSpan(
    style: style,
    children: [
      for (var i = 0; i < parts.length; i++)
        if (parts[i].isNotEmpty)
          TextSpan(
            text: parts[i],
            style: i.isOdd
                ? const TextStyle(fontWeight: FontWeight.w800)
                : null,
          ),
    ],
  );
}

/// Video frames for one point: swipe between them, tap to enlarge.
class _FrameStrip extends StatefulWidget {
  const _FrameStrip({super.key, required this.frames});

  final List<String> frames;

  @override
  State<_FrameStrip> createState() => _FrameStripState();
}

class _FrameStripState extends State<_FrameStrip> {
  final _controller = PageController();
  var _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int page) => _controller.animateToPage(
    page,
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeOut,
  );

  @override
  Widget build(BuildContext context) {
    final frames = widget.frames;
    final many = frames.length > 1;
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: frames.length,
                  onPageChanged: (page) => setState(() => _page = page),
                  itemBuilder: (context, i) => GestureDetector(
                    // Opaque, so the picture is tappable even while it loads.
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _openViewer(context, frames, i),
                    child: loadingImage(
                      AlchemistsLogic.asset(frames[i]),
                      fit: BoxFit.cover,
                      semanticLabel: context.l10n.t(
                        'alchemists.logic.frameLabel',
                        {'n': '${i + 1}', 'total': '${frames.length}'},
                      ),
                    ),
                  ),
                ),
                if (many && _page > 0)
                  _ArrowButton(
                    alignment: AlignmentDirectional.centerStart,
                    icon: Icons.chevron_left_rounded,
                    onTap: () => _go(_page - 1),
                  ),
                if (many && _page < frames.length - 1)
                  _ArrowButton(
                    alignment: AlignmentDirectional.centerEnd,
                    icon: Icons.chevron_right_rounded,
                    onTap: () => _go(_page + 1),
                  ),
                const PositionedDirectional(
                  end: 6,
                  bottom: 6,
                  child: IgnorePointer(
                    child: Icon(
                      Icons.zoom_out_map_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (many) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < frames.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _page
                        ? AlchemistsGame.purple
                        : AlchemistsGame.purple.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.alignment,
    required this.icon,
    required this.onTap,
  });

  final AlignmentGeometry alignment;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Material(
          color: Colors.black45,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-screen frames with pinch zoom.
void _openViewer(BuildContext context, List<String> frames, int start) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (context) => Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            controller: PageController(initialPage: start),
            itemCount: frames.length,
            itemBuilder: (context, i) => InteractiveViewer(
              maxScale: 4,
              child: Center(
                child: loadingImage(
                  AlchemistsLogic.asset(frames[i]),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          PositionedDirectional(
            top: 8,
            end: 8,
            child: SafeArea(
              child: IconButton(
                key: const ValueKey('alchemists-viewer-close'),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
