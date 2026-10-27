import 'dart:math' as math;
import 'dart:ui';

enum FingerPhase {
  /// Fewer than two fingers, or they just changed.
  waiting,

  /// Two or more fingers holding still; the countdown is running.
  arming,

  /// The theme builds suspense before the pick.
  deciding,

  /// One finger is picked. Lasts until every finger lifts and a new one lands.
  picked,
}

/// One finger on the screen.
class FingerTouch {
  FingerTouch({
    required this.pointer,
    required this.position,
    required this.colorIndex,
    required this.since,
  });

  final int pointer;
  Offset position;

  /// Index into [fingerPalette]; stays with the finger until it lifts.
  final int colorIndex;

  /// When the finger landed, so themes can animate their greeting.
  final Duration since;
}

/// Who-goes-first rules shared by every theme, kept apart from drawing.
///
/// Times are the elapsed time of the screen's ticker, so tests can drive
/// them directly.
class FingerPicker {
  FingerPicker({
    math.Random? random,
    int? maxFingers,
    this.decideTime = defaultDecideTime,
  }) : _random = random ?? math.Random(),
       maxFingers = math.min(maxFingers ?? colorCount, colorCount);

  static const minFingers = 2;
  static final colorCount = fingerPalette.length;

  /// Fingers beyond this are ignored, e.g. an octopus has only eight arms.
  final int maxFingers;

  /// How long the fingers must hold still before the pick starts.
  static const armDelay = Duration(milliseconds: 2000);

  static const defaultDecideTime = Duration(milliseconds: 1500);

  /// How long the suspense lasts before the pick. Themes that tell a longer
  /// story, like the meeples' race, ask for more.
  final Duration decideTime;

  final math.Random _random;

  /// Fingers in the order they landed.
  final touches = <int, FingerTouch>{};

  var phase = FingerPhase.waiting;
  Duration _changedAt = Duration.zero;
  Duration _decidingAt = Duration.zero;

  /// The picked finger. Kept after it lifts so the result stays on screen.
  FingerTouch? winner;
  Duration? pickedAt;

  /// The finger that will be picked, drawn fairly when the suspense starts
  /// and revealed as [winner] when it ends, so a theme can build its
  /// animation toward it. `null` outside [FingerPhase.deciding].
  FingerTouch? chosen;

  Duration get decidingAt => _decidingAt;

  /// Players who lifted their finger after the round locked in. They stay
  /// in [touches] so their piece keeps playing out on screen.
  final lifted = <int>{};

  /// Whether the players are locked in: from the start of the suspense
  /// until the next round, lifting a finger doesn't change who is playing.
  bool get locked =>
      phase == FingerPhase.deciding || phase == FingerPhase.picked;

  /// Every player has let go of the screen.
  bool get allLifted => touches.keys.every(lifted.contains);

  void down(int pointer, Offset position, Duration now) {
    if (phase == FingerPhase.deciding) {
      // Locked in: nobody joins mid-suspense.
      return;
    }
    if (phase == FingerPhase.picked) {
      if (!allLifted) {
        // The round is over; latecomers don't join it.
        return;
      }
      touches.clear();
      lifted.clear();
      winner = null;
      pickedAt = null;
    }
    if (touches.length >= maxFingers) {
      return;
    }
    final used = {for (final touch in touches.values) touch.colorIndex};
    var color = 0;
    while (used.contains(color) && color < colorCount - 1) {
      color++;
    }
    touches[pointer] = FingerTouch(
      pointer: pointer,
      position: position,
      colorIndex: color,
      since: now,
    );
    _restart(now);
  }

  void move(int pointer, Offset position) {
    if (!lifted.contains(pointer)) {
      touches[pointer]?.position = position;
    }
  }

  void up(int pointer, Duration now) {
    if (!touches.containsKey(pointer)) {
      return;
    }
    if (locked) {
      // The round carries on so everyone can watch it with fingers off.
      lifted.add(pointer);
      return;
    }
    touches.remove(pointer);
    _restart(now);
  }

  void _restart(Duration now) {
    _changedAt = now;
    // Any change of fingers voids the secret draw; the next one is fresh.
    chosen = null;
    phase = touches.length >= minFingers
        ? FingerPhase.arming
        : FingerPhase.waiting;
  }

  /// Countdown progress while arming, from 0 to 1.
  double armProgress(Duration now) {
    if (phase != FingerPhase.arming) {
      return phase == FingerPhase.waiting ? 0 : 1;
    }
    final held = (now - _changedAt).inMicroseconds / armDelay.inMicroseconds;
    return held.clamp(0.0, 1.0);
  }

  /// Advances the round. Returns true when the phase changed.
  bool tick(Duration now) {
    switch (phase) {
      case FingerPhase.arming when now - _changedAt >= armDelay:
        phase = FingerPhase.deciding;
        _decidingAt = now;
        // Every finger has the same chance; the draw is just made early.
        final fingers = touches.values.toList();
        chosen = fingers[_random.nextInt(fingers.length)];
        return true;
      case FingerPhase.deciding when now - _decidingAt >= decideTime:
        winner = chosen;
        chosen = null;
        pickedAt = now;
        phase = FingerPhase.picked;
        return true;
      default:
        return false;
    }
  }
}

/// One color per finger, in landing order. Every theme uses the same colors.
const fingerPalette = [
  Color(0xFFE53935),
  Color(0xFF1E88E5),
  Color(0xFFFDD835),
  Color(0xFF43A047),
  Color(0xFF8E24AA),
  Color(0xFFFB8C00),
  Color(0xFFEC407A),
  Color(0xFF00ACC1),
  Color(0xFFC0CA33),
  Color(0xFFECEFF1),
];
