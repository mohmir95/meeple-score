import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/widgets/language_toggle.dart';
import 'arena_painter.dart';
import 'bomb_painter.dart';
import 'cauldron_painter.dart';
import 'finger_picker.dart';
import 'magic_painter.dart';
import 'scenery_icon.dart';
import 'ufo_painter.dart';

/// The looks the page can wear. The rules are the same for every theme.
enum FirstPlayerTheme {
  // A magician octopus has eight arms, one per volunteer.
  magic(
    Color(0xFF1A0F2E),
    maxFingers: MagicPainter.arms,
    decideTime: Duration(milliseconds: 3000),
  ),
  // Long enough for every ingredient to drop in and the potion to brew.
  cauldron(
    Color(0xFF1B1530),
    decideTime: Duration(milliseconds: 5000),
  ),
  // Short suspense: the point is to pick a player, not to wait.
  bomb(
    Color(0xFF2B2D42),
    decideTime: Duration(milliseconds: 2600),
  ),
  // Long enough for several scanning stops before the lock.
  ufo(
    Color(0xFF0B1033),
    decideTime: Duration(milliseconds: 5000),
  ),
  // Kept to a few seconds so the bout doesn't drag, with a calm entrance.
  arena(
    Color(0xFF1E1E28),
    decideTime: Duration(milliseconds: 4200),
  );

  const FirstPlayerTheme(
    this.barColor, {
    this.maxFingers,
    this.decideTime = FingerPicker.defaultDecideTime,
  });

  /// App bar color, matching the top of the scene.
  final Color barColor;

  /// Most fingers this theme can show; null means every palette color.
  final int? maxFingers;

  /// How long its suspense lasts before the pick is revealed.
  final Duration decideTime;

  CustomPainter painter(FingerPicker picker, Duration now) => switch (this) {
    FirstPlayerTheme.magic => MagicPainter(picker: picker, now: now),
    FirstPlayerTheme.cauldron => CauldronPainter(picker: picker, now: now),
    FirstPlayerTheme.bomb => BombPainter(picker: picker, now: now),
    FirstPlayerTheme.ufo => UfoPainter(picker: picker, now: now),
    FirstPlayerTheme.arena => ArenaPainter(picker: picker, now: now),
  };
}

/// Picks the scenery at random, but never the one shown last time, so every
/// visit or new round looks fresh.
class FirstPlayerThemeRotation {
  const FirstPlayerThemeRotation._();

  static const storageKey = 'first_player_last_theme';

  /// A random theme other than the last one shown, remembered for next time.
  static Future<FirstPlayerTheme> next({math.Random? random}) async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      prefs = null;
    }
    final theme = pickAfter(
      prefs?.getString(storageKey),
      random ?? math.Random(),
    );
    try {
      await prefs?.setString(storageKey, theme.name);
    } catch (_) {
      // Not remembering only means the next pick may repeat.
    }
    return theme;
  }

  /// Remembers [theme] as the last one shown, so the next visit picks
  /// another.
  static Future<void> remember(FirstPlayerTheme theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, theme.name);
    } catch (_) {
      // Not remembering only means the next pick may repeat.
    }
  }

  /// A random theme, leaving out the one named [last].
  static FirstPlayerTheme pickAfter(String? last, math.Random random) {
    final fresh = [
      for (final theme in FirstPlayerTheme.values)
        if (theme.name != last) theme,
    ];
    final pool = fresh.isEmpty ? FirstPlayerTheme.values : fresh;
    return pool[random.nextInt(pool.length)];
  }
}

/// Everyone puts a finger on the screen and one of them is picked to go
/// first.
class FirstPlayerScreen extends StatefulWidget {
  const FirstPlayerScreen({super.key, this.random, this.theme});

  /// Injectable for tests.
  final math.Random? random;

  /// The first scenery to show. When null it's picked by
  /// [FirstPlayerThemeRotation], which also remembers it.
  final FirstPlayerTheme? theme;

  @override
  State<FirstPlayerScreen> createState() => _FirstPlayerScreenState();
}

class _FirstPlayerScreenState extends State<FirstPlayerScreen>
    with SingleTickerProviderStateMixin {
  /// Until the remembered theme loads, the page shows a plain backdrop.
  static const _loadingColor = Color(0xFF263238);

  /// How long to touch and hold after a pick to play again.
  static const _holdToRestart = Duration(milliseconds: 600);

  FirstPlayerTheme? _theme;
  late FingerPicker _picker;
  late final Ticker _ticker;
  Duration _now = Duration.zero;

  int? _holdPointer;
  Offset? _holdAt;
  Duration? _holdSince;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    final theme = widget.theme;
    if (theme != null) {
      _start(theme);
    } else {
      FirstPlayerThemeRotation.next().then((theme) {
        if (mounted) {
          setState(() => _start(theme));
        }
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  /// A fresh round on [theme].
  void _start(FirstPlayerTheme theme) {
    _theme = theme;
    _picker = FingerPicker(
      random: widget.random,
      maxFingers: theme.maxFingers,
      decideTime: theme.decideTime,
    );
    _pins.clear();
  }

  void _onTick(Duration elapsed) {
    _now = elapsed;
    if (_theme == null) {
      return;
    }
    final before = _picker.phase;
    if (_picker.tick(elapsed)) {
      if (_picker.phase == FingerPhase.picked) {
        HapticFeedback.mediumImpact();
      } else if (before == FingerPhase.arming) {
        HapticFeedback.selectionClick();
      }
    }
    final since = _holdSince;
    if (since != null && elapsed - since >= _holdToRestart) {
      _playAgain();
    }
    setState(() {});
  }

  /// After a pick, once every finger has lifted, a touch and hold starts a
  /// new round on the same scenery. Holding isn't a reset any other time,
  /// because holding a finger down is how the game is played.
  bool get _canPlayAgain =>
      _picker.phase == FingerPhase.picked && _picker.allLifted;

  void _playAgain() {
    _clearHold();
    HapticFeedback.mediumImpact();
    _start(_theme!);
  }

  /// The scenery can be changed only between rounds, so nobody's finger is
  /// lost to a switch.
  bool get _canSwitch => _picker.touches.isEmpty || _canPlayAgain;

  /// Moves [step] sceneries along, wrapping at either end.
  void _switchBy(int step) {
    final themes = FirstPlayerTheme.values;
    _switchTo(themes[(_theme!.index + step) % themes.length]);
  }

  void _switchTo(FirstPlayerTheme theme) {
    if (!_canSwitch || theme == _theme) {
      return;
    }
    HapticFeedback.selectionClick();
    _clearHold();
    setState(() => _start(theme));
    FirstPlayerThemeRotation.remember(theme);
  }

  void _clearHold() {
    _holdPointer = null;
    _holdAt = null;
    _holdSince = null;
  }

  void _down(PointerDownEvent event) {
    if (_theme == null) {
      return;
    }
    if (_canPlayAgain) {
      _holdPointer = event.pointer;
      _holdAt = event.localPosition;
      _holdSince = _now;
      return;
    }
    if (_pinsEnabled && event.kind == PointerDeviceKind.mouse) {
      _togglePin(event.localPosition);
      return;
    }
    _picker.down(event.pointer, event.localPosition, _now);
    HapticFeedback.selectionClick();
  }

  void _up(PointerEvent event) {
    if (event.pointer == _holdPointer) {
      // Let go too soon: nothing happens.
      _clearHold();
      return;
    }
    if (_theme == null || _isPinMouse(event)) {
      return;
    }
    _picker.up(event.pointer, _now);
  }

  /// Debug builds only: a mouse click pins a virtual finger and a click on
  /// a pin lifts it, so a whole round can be tested on a computer.
  static const _pinsEnabled = kDebugMode;
  static const _pinRadius = 40.0;
  final _pins = <int>{};

  /// Pins get negative ids so they never clash with real pointers.
  var _nextPin = -1;

  void _togglePin(Offset at) {
    for (final id in _pins) {
      final pin = _picker.touches[id];
      if (pin != null && (pin.position - at).distance <= _pinRadius) {
        _pins.remove(id);
        _picker.up(id, _now);
        return;
      }
    }
    final id = _nextPin--;
    _picker.down(id, at, _now);
    // A finished round ignores new fingers until everyone has lifted.
    if (_picker.touches.containsKey(id)) {
      _pins.add(id);
    }
  }

  /// Mouse moves and releases belong to pins, not to a real finger.
  bool _isPinMouse(PointerEvent event) =>
      _pinsEnabled && event.kind == PointerDeviceKind.mouse;

  String _message(BuildContext context, FirstPlayerTheme theme) {
    final l10n = context.l10n;
    final name = theme.name;
    return switch (_picker.phase) {
      FingerPhase.waiting when _picker.touches.length == 1 => l10n.t(
        '$name.needMore',
      ),
      FingerPhase.waiting => l10n.t('firstPlayer.prompt'),
      FingerPhase.arming => l10n.t('firstPlayer.hold'),
      FingerPhase.deciding => l10n.t('$name.choosing'),
      // Names the winner's color, so it's clear who it is.
      FingerPhase.picked => l10n.t('$name.picked', {
        'color': l10n.t(
          'firstPlayer.color.${_picker.winner?.colorIndex ?? 0}',
        ),
      }),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = _theme;
    final color = theme?.barColor ?? _loadingColor;
    return Scaffold(
      backgroundColor: color,
      appBar: AppBar(
        backgroundColor: color,
        title: Text(theme == null ? '' : l10n.t('${theme.name}.title')),
        actions: const [LanguageToggle()],
      ),
      body: theme == null
          ? const SizedBox.expand()
          : Column(
              children: [
                _ThemePager(
                  current: theme,
                  enabled: _canSwitch,
                  onStep: _switchBy,
                  onSelect: _switchTo,
                ),
                Expanded(
                  // Fades between sceneries when one is picked.
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: KeyedSubtree(
                      key: ValueKey(theme),
                      child: _buildSurface(context, theme),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSurface(BuildContext context, FirstPlayerTheme theme) {
    final l10n = context.l10n;
    final picked = _picker.phase == FingerPhase.picked;
    final holdAt = _holdAt;
    final holdSince = _holdSince;
    return Listener(
      key: const ValueKey('first-player-surface'),
      behavior: HitTestBehavior.opaque,
      onPointerDown: _down,
      onPointerMove: (event) =>
          _picker.move(event.pointer, event.localPosition),
      onPointerUp: _up,
      onPointerCancel: _up,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: theme.painter(_picker, _now)),
          if (_pinsEnabled)
            const Positioned(
              top: 8,
              left: 16,
              right: 16,
              child: IgnorePointer(
                child: Text(
                  'Debug: click to pin a finger, click a pin to lift it.',
                  key: ValueKey('first-player-pin-hint'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ),
            ),
          // Fills while a finger is held to play again.
          if (holdAt != null && holdSince != null)
            Positioned(
              left: holdAt.dx - 36,
              top: holdAt.dy - 36,
              width: 72,
              height: 72,
              child: IgnorePointer(
                child: CircularProgressIndicator(
                  key: const ValueKey('first-player-hold'),
                  value:
                      ((_now - holdSince).inMicroseconds /
                              _holdToRestart.inMicroseconds)
                          .clamp(0.0, 1.0),
                  strokeWidth: 5,
                  color: Colors.white,
                  backgroundColor: Colors.white24,
                ),
              ),
            ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: IgnorePointer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _message(context, theme),
                    key: const ValueKey('first-player-message'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      shadows: const [
                        Shadow(blurRadius: 12, color: Colors.black54),
                      ],
                    ),
                  ),
                  if (picked) ...[
                    const SizedBox(height: 6),
                    Text(
                      l10n.t('firstPlayer.again'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: Colors.white70),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A strip above the scene for choosing another scenery: arrows, an icon per
/// scenery, and a sideways swipe. It sits outside the touch surface, so using
/// it never counts as a finger.
class _ThemePager extends StatelessWidget {
  const _ThemePager({
    required this.current,
    required this.enabled,
    required this.onStep,
    required this.onSelect,
  });

  final FirstPlayerTheme current;

  /// False during a round, when the strip dims and ignores input.
  final bool enabled;
  final ValueChanged<int> onStep;
  final ValueChanged<FirstPlayerTheme> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.35,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: !enabled,
        child: GestureDetector(
          key: const ValueKey('first-player-pager'),
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity.abs() < 200) {
              return;
            }
            // A swipe toward the start brings the next scenery in.
            final towardStart = rtl ? velocity > 0 : velocity < 0;
            onStep(towardStart ? 1 : -1);
          },
          child: SizedBox(
            height: 52,
            child: Row(
              children: [
                IconButton(
                  key: const ValueKey('first-player-previous'),
                  onPressed: () => onStep(-1),
                  tooltip: l10n.t('firstPlayer.previous'),
                  color: Colors.white,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final theme in FirstPlayerTheme.values)
                        _SceneryTab(
                          key: ValueKey('first-player-scenery-${theme.name}'),
                          theme: theme,
                          label: l10n.t('${theme.name}.title'),
                          selected: theme == current,
                          onTap: () => onSelect(theme),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  key: const ValueKey('first-player-next'),
                  onPressed: () => onStep(1),
                  tooltip: l10n.t('firstPlayer.next'),
                  color: Colors.white,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One scenery's icon. The current one sits larger in a soft frame; the
/// others are smaller and faded.
class _SceneryTab extends StatelessWidget {
  const _SceneryTab({
    super.key,
    required this.theme,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final FirstPlayerTheme theme;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _duration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: InkResponse(
          onTap: onTap,
          radius: 24,
          child: AnimatedContainer(
            duration: _duration,
            curve: Curves.easeOut,
            width: 46,
            height: 42,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: selected ? 0.18 : 0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: selected ? 0.7 : 0),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: AnimatedOpacity(
              duration: _duration,
              opacity: selected ? 1 : 0.6,
              child: AnimatedScale(
                duration: _duration,
                curve: Curves.easeOut,
                scale: selected ? 1 : 0.82,
                child: SceneryIcon(theme, size: 32),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
