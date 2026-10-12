import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/widgets/app_page.dart';
import 'cob_game.dart';

class CobQuickReferenceScreen extends StatefulWidget {
  const CobQuickReferenceScreen({super.key});

  static const frontAsset =
      'assets/games/castles_of_burgundy/quick_reference_front.png';
  static const backAsset =
      'assets/games/castles_of_burgundy/quick_reference_back.png';

  @override
  State<CobQuickReferenceScreen> createState() =>
      _CobQuickReferenceScreenState();
}

class _CobQuickReferenceScreenState extends State<CobQuickReferenceScreen>
    with TickerProviderStateMixin {
  late final AnimationController _turn;
  late final AnimationController _lens;

  final _stackKey = GlobalKey();
  final _cardKey = GlobalKey();

  final _pointers = <int>{};
  int? _activePointer;
  Offset? _pointerStart;
  var _draggingLens = false;
  var _multiTouch = false;

  Offset? _focal;
  Offset _focalOnStack = Offset.zero;
  Size _cardSize = Size.zero;
  Size _stackSize = Size.zero;
  String _lensAsset = CobQuickReferenceScreen.frontAsset;
  var _panToken = 0;

  @override
  void initState() {
    super.initState();
    _turn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _lens = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
  }

  @override
  void dispose() {
    _turn.dispose();
    _lens.dispose();
    super.dispose();
  }

  void _flip() {
    if (_turn.isAnimating || _focal != null) {
      return;
    }
    if (_turn.value >= 0.5) {
      _turn.reverse();
    } else {
      _turn.forward();
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointers.add(event.pointer);
    if (_pointers.length > 1 || _turn.isAnimating) {
      _multiTouch = _pointers.length > 1;
      _cancelLens();
      return;
    }
    _activePointer = event.pointer;
    _pointerStart = event.localPosition;
    _draggingLens = false;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer || _pointers.length != 1) {
      return;
    }
    final start = _pointerStart;
    if (start == null || _turn.isAnimating) {
      return;
    }
    if (!_draggingLens) {
      if ((event.localPosition - start).distance < 18) {
        return;
      }
      _draggingLens = true;
      _panToken++;
      _lens.forward();
    }
    _track(event.localPosition);
  }

  void _onPointerUp(PointerEvent event) {
    final tap =
        !_multiTouch &&
        !_draggingLens &&
        event.pointer == _activePointer &&
        _pointers.length == 1;
    _pointers.remove(event.pointer);
    if (event.pointer == _activePointer) {
      _activePointer = null;
      _pointerStart = null;
    }
    if (_draggingLens && _pointers.isEmpty) {
      _draggingLens = false;
      _hideLens();
    }
    if (_pointers.isEmpty) {
      _multiTouch = false;
    }
    if (tap && !_turn.isAnimating) {
      _flip();
    }
  }

  void _cancelLens() {
    _activePointer = null;
    _pointerStart = null;
    if (!_draggingLens && _focal == null) {
      return;
    }
    _draggingLens = false;
    _hideLens();
  }

  void _hideLens() {
    final token = _panToken;
    _lens.reverse().whenComplete(() {
      if (!mounted || token != _panToken) {
        return;
      }
      setState(() => _focal = null);
    });
  }

  void _track(Offset cardLocal) {
    final cardBox = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    final stackBox =
        _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (cardBox == null || stackBox == null || !cardBox.hasSize) {
      return;
    }
    final clamped = Offset(
      cardLocal.dx.clamp(0, cardBox.size.width),
      cardLocal.dy.clamp(0, cardBox.size.height),
    );
    setState(() {
      _focalOnStack = stackBox.globalToLocal(cardBox.localToGlobal(clamped));
      _cardSize = cardBox.size;
      _stackSize = stackBox.size;
      _focal = clamped;
      _lensAsset = _turn.value >= 0.5
          ? CobQuickReferenceScreen.backAsset
          : CobQuickReferenceScreen.frontAsset;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final padding = compact ? 12.0 : 20.0;
    final lensSize = compact ? 168.0 : 210.0;

    return AppPage(
      title: l10n.t('hub.quickReferencePersian'),
      coverImageAsset: CastlesOfBurgundySpecialEditionGame.coverAsset,
      body: Stack(
        key: _stackKey,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(padding, padding, padding, padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.t('cob.quickReference.hint'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                _HelpLine(
                  icon: Icons.pinch,
                  text: l10n.t('cob.quickReference.pinch'),
                ),
                const SizedBox(height: 2),
                _HelpLine(
                  icon: Icons.search,
                  text: l10n.t('cob.quickReference.drag'),
                ),
                SizedBox(height: compact ? 12 : 16),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final card = _fittedCard(constraints.biggest);
                      return InteractiveViewer(
                        minScale: 1,
                        maxScale: 4,
                        panEnabled: false,
                        clipBehavior: Clip.hardEdge,
                        child: Center(
                          child: SizedBox(
                            key: _cardKey,
                            width: card.width,
                            height: card.height,
                            child: Stack(
                            children: [
                              _FlippingSheet(
                                turns: _turn,
                                front: const _ReferenceFace(
                                  key: ValueKey('cob-reference-front'),
                                  asset: CobQuickReferenceScreen.frontAsset,
                                  labelKey: 'cob.quickReference.front',
                                ),
                                back: const _ReferenceFace(
                                  key: ValueKey('cob-reference-back'),
                                  asset: CobQuickReferenceScreen.backAsset,
                                  labelKey: 'cob.quickReference.back',
                                ),
                              ),
                              Positioned.fill(
                                child: Listener(
                                  behavior: HitTestBehavior.opaque,
                                  onPointerDown: _onPointerDown,
                                  onPointerMove: _onPointerMove,
                                  onPointerUp: _onPointerUp,
                                  onPointerCancel: _onPointerUp,
                                  child: const SizedBox.expand(),
                                ),
                              ),
                              if (_focal != null)
                                Positioned(
                                  left: _focal!.dx - 7,
                                  top: _focal!.dy - 7,
                                  child: const IgnorePointer(
                                    child: _FocalDot(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                    },
                  ),
                ),
                SizedBox(height: compact ? 12 : 16),
                Center(
                  child: FilledButton.tonalIcon(
                    key: const ValueKey('cob-reference-flip'),
                    onPressed: _flip,
                    icon: const Icon(Icons.flip),
                    label: Text(l10n.t('cob.quickReference.flip')),
                  ),
                ),
              ],
            ),
          ),
          if (_focal != null)
            _MagnifierLens(
              key: const ValueKey('cob-reference-magnifier'),
              appear: _lens,
              focal: _focal!,
              anchor: _focalOnStack,
              cardSize: _cardSize,
              stackSize: _stackSize,
              asset: _lensAsset,
              diameter: lensSize,
              label: l10n.t('cob.quickReference.magnifier'),
            ),
        ],
      ),
    );
  }

  Size _fittedCard(Size bounds) {
    const aspect = 3 / 4;
    var width = bounds.width;
    var height = width / aspect;
    if (height > bounds.height) {
      height = bounds.height;
      width = height * aspect;
    }
    return Size(width, height);
  }
}

class _FlippingSheet extends StatelessWidget {
  const _FlippingSheet({
    required this.turns,
    required this.front,
    required this.back,
  });

  final Animation<double> turns;
  final Widget front;
  final Widget back;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: turns,
      builder: (context, _) {
        final angle = turns.value * math.pi;
        final showBack = turns.value >= 0.5;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(angle),
          child: showBack
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(math.pi),
                  child: back,
                )
              : front,
        );
      },
    );
  }
}

class _ReferenceFace extends StatelessWidget {
  const _ReferenceFace({
    super.key,
    required this.asset,
    required this.labelKey,
  });

  final String asset;
  final String labelKey;

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.t(labelKey);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          semanticLabel: label,
        ),
      ),
    );
  }
}

class _HelpLine extends StatelessWidget {
  const _HelpLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(text, textAlign: TextAlign.center, style: style),
        ),
      ],
    );
  }
}

class _FocalDot extends StatelessWidget {
  const _FocalDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        color: const Color(0xFF7A2E3B).withValues(alpha: 0.85),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 4),
        ],
      ),
    );
  }
}

class _MagnifierLens extends StatelessWidget {
  const _MagnifierLens({
    super.key,
    required this.appear,
    required this.focal,
    required this.anchor,
    required this.cardSize,
    required this.stackSize,
    required this.asset,
    required this.diameter,
    required this.label,
  });

  static const _magnification = 2.7;

  final Animation<double> appear;
  final Offset focal;
  final Offset anchor;
  final Size cardSize;
  final Size stackSize;
  final String asset;
  final double diameter;
  final String label;

  @override
  Widget build(BuildContext context) {
    final focalOnPage = anchor;
    final gap = 28.0;
    final roomAbove = focalOnPage.dy - (diameter + gap);
    final preferredY = roomAbove >= 8
        ? focalOnPage.dy - (diameter / 2 + gap)
        : focalOnPage.dy + (diameter / 2 + gap);
    final maxX = math.max(diameter / 2 + 8, stackSize.width - diameter / 2 - 8);
    final maxY = math.max(diameter / 2 + 8, stackSize.height - diameter / 2 - 8);
    final center = Offset(
      focalOnPage.dx.clamp(diameter / 2 + 8, maxX),
      preferredY.clamp(diameter / 2 + 8, maxY),
    );

    return Positioned(
      left: center.dx - diameter / 2,
      top: center.dy - diameter / 2,
      width: diameter,
      height: diameter,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: appear,
          builder: (context, child) {
            final t = Curves.easeOutBack.transform(appear.value.clamp(0, 1));
            return Opacity(
              opacity: appear.value.clamp(0, 1),
              child: Transform.scale(scale: 0.86 + 0.14 * t, child: child),
            );
          },
          child: Semantics(
            label: label,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: ClipOval(
                child: ColoredBox(
                  color: const Color(0xFFF3E6C8),
                  child: Stack(
                    children: [
                      Positioned(
                        left: diameter / 2 - focal.dx * _magnification,
                        top: diameter / 2 - focal.dy * _magnification,
                        width: cardSize.width * _magnification,
                        height: cardSize.height * _magnification,
                        child: Image.asset(
                          asset,
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.high,
                          gaplessPlayback: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
