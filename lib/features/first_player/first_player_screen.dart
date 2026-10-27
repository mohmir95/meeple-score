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
import 'finger_picker.dart';
import 'magic_painter.dart';
import 'meeples_painter.dart';
import 'treasure_painter.dart';

/// The looks the page can wear. The rules are the same for every theme.
enum FirstPlayerTheme {
  // A magician octopus has eight arms, one per volunteer.
  magic(
    Color(0xFF1A0F2E),
    maxFingers: MagicPainter.arms,
    decideTime: Duration(milliseconds: 3000),
  ),
  // A slower pull so the race can be followed.
  meeples(
    Color(0xFF7A4F2A),
    decideTime: Duration(milliseconds: 4000),
  ),
  // Short suspense: the point is to pick a player, not to wait.
  bomb(
    Color(0xFF2B2D42),
    decideTime: Duration(milliseconds: 2600),
  ),
  treasure(
    Color(0xFF3E2A18),
    decideTime: Duration(milliseconds: 3500),
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
    FirstPlayerTheme.meeples => MeeplesPainter(picker: picker, now: now),
    FirstPlayerTheme.bomb => BombPainter(picker: picker, now: now),
    FirstPlayerTheme.treasure => TreasurePainter(picker: picker, now: now),
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
      FingerPhase.picked => l10n.t('$name.picked'),
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
          : _buildSurface(context, theme),
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
