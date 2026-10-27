import 'dart:math' as math;

import 'package:board_game_score_sheet/features/first_player/finger_picker.dart';
import 'package:board_game_score_sheet/features/first_player/first_player_screen.dart';
import 'package:board_game_score_sheet/shared/widgets/language_toggle.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

Duration ms(int value) => Duration(milliseconds: value);

void main() {
  test('one finger never starts the countdown', () {
    final picker = FingerPicker(random: math.Random(1));
    picker.down(1, const Offset(10, 10), Duration.zero);
    picker.tick(ms(10000));
    expect(picker.phase, FingerPhase.waiting);
  });

  test('two fingers held still get caught after the countdown', () {
    final picker = FingerPicker(random: math.Random(1));
    picker.down(1, const Offset(10, 10), Duration.zero);
    picker.down(2, const Offset(90, 90), ms(100));
    expect(picker.phase, FingerPhase.arming);

    picker.tick(ms(1000));
    expect(picker.phase, FingerPhase.arming);
    expect(picker.armProgress(ms(1100)), closeTo(0.5, 0.01));

    expect(picker.tick(ms(2100)), isTrue);
    expect(picker.phase, FingerPhase.deciding);
    expect(picker.tick(ms(3600)), isTrue);
    expect(picker.phase, FingerPhase.picked);
    expect([1, 2], contains(picker.winner!.pointer));
  });

  test('the winner is drawn when the suspense starts and revealed after', () {
    final picker = FingerPicker(random: math.Random(4));
    picker.down(1, const Offset(10, 10), Duration.zero);
    picker.down(2, const Offset(90, 90), Duration.zero);
    expect(picker.chosen, isNull);

    picker.tick(ms(2000));
    expect(picker.phase, FingerPhase.deciding);
    final chosen = picker.chosen!.pointer;
    expect(picker.winner, isNull);

    picker.tick(ms(3500));
    expect(picker.winner!.pointer, chosen);
    expect(picker.chosen, isNull);
  });

  test('once the suspense starts, players are locked in', () {
    final picker = FingerPicker(random: math.Random(4));
    for (var i = 1; i <= 3; i++) {
      picker.down(i, Offset(i * 30.0, 0), Duration.zero);
    }
    picker.tick(ms(2000));
    final chosen = picker.chosen!.pointer;

    // Everyone lifts to watch: the round carries on with the same draw.
    for (var i = 1; i <= 3; i++) {
      picker.up(i, ms(2100));
    }
    expect(picker.phase, FingerPhase.deciding);
    expect(picker.touches, hasLength(3));
    expect(picker.chosen!.pointer, chosen);

    // A newcomer can't join mid-suspense.
    picker.down(9, Offset.zero, ms(2200));
    expect(picker.touches.keys, isNot(contains(9)));

    picker.tick(ms(3500));
    expect(picker.winner!.pointer, chosen);
    expect(picker.allLifted, isTrue);
  });

  test('every finger has the same chance of being chosen', () {
    final random = math.Random(11);
    final wins = <int, int>{};
    for (var round = 0; round < 3000; round++) {
      final picker = FingerPicker(random: random);
      for (var i = 0; i < 3; i++) {
        picker.down(i, Offset(i * 30.0, 0), Duration.zero);
      }
      picker.tick(ms(2000));
      picker.tick(ms(3500));
      wins.update(picker.winner!.pointer, (n) => n + 1, ifAbsent: () => 1);
    }
    for (final count in wins.values) {
      expect(count, closeTo(1000, 120));
    }
  });

  test('a finger landing or lifting restarts the countdown', () {
    final picker = FingerPicker(random: math.Random(1));
    picker.down(1, const Offset(10, 10), Duration.zero);
    picker.down(2, const Offset(90, 90), Duration.zero);
    picker.tick(ms(1900));
    picker.down(3, const Offset(50, 50), ms(1900));
    picker.tick(ms(2500));
    expect(picker.phase, FingerPhase.arming);

    // Lifting before the suspense starts still restarts the countdown.
    picker.up(3, ms(2600));
    expect(picker.phase, FingerPhase.arming);
    picker.tick(ms(4000));
    expect(picker.phase, FingerPhase.arming);
    picker.tick(ms(4600));
    expect(picker.phase, FingerPhase.deciding);
  });

  test('the catch stays until every finger lifts and a new round starts', () {
    final picker = FingerPicker(random: math.Random(2));
    picker.down(1, const Offset(10, 10), Duration.zero);
    picker.down(2, const Offset(90, 90), Duration.zero);
    picker.tick(ms(2000));
    picker.tick(ms(3500));
    final winner = picker.winner!.pointer;

    // A latecomer can't join a finished round.
    picker.down(3, const Offset(50, 50), ms(3600));
    expect(picker.touches.keys, isNot(contains(3)));

    picker.up(1, ms(4000));
    picker.up(2, ms(4000));
    expect(picker.phase, FingerPhase.picked);
    expect(picker.winner!.pointer, winner);

    picker.down(4, const Offset(30, 30), ms(5000));
    expect(picker.phase, FingerPhase.waiting);
    expect(picker.winner, isNull);
  });

  test('every finger gets its own color', () {
    final picker = FingerPicker();
    for (var i = 0; i < 4; i++) {
      picker.down(i, Offset(i * 10.0, 0), Duration.zero);
    }
    picker.up(1, Duration.zero);
    picker.down(9, Offset.zero, Duration.zero);
    final colors = [for (final t in picker.touches.values) t.colorIndex];
    expect(colors.toSet(), hasLength(colors.length));
    // The freed color is reused first.
    expect(picker.touches[9]!.colorIndex, 1);
  });

  /// Plays a two-finger round on [theme] and checks each message.
  Future<void> playRound(
    WidgetTester tester,
    FirstPlayerTheme theme, {
    required String title,
    required String needMore,
    required String choosing,
    required String picked,
  }) async {
    await pumpWithL10n(
      tester,
      FirstPlayerScreen(random: math.Random(3), theme: theme),
    );
    expect(find.text(title), findsOneWidget);
    expect(find.text('Everyone, put a finger on the screen'), findsOneWidget);

    final surface = tester.getRect(
      find.byKey(const ValueKey('first-player-surface')),
    );
    final a = await tester.startGesture(surface.center + const Offset(-80, 120));
    await tester.pump(ms(100));
    expect(find.text(needMore), findsOneWidget);
    final b = await tester.startGesture(surface.center + const Offset(80, 120));
    await tester.pump(ms(100));
    expect(find.text('Hold still…'), findsOneWidget);

    await tester.pump(ms(2100));
    expect(find.text(choosing), findsOneWidget);
    await tester.pump(theme.decideTime + ms(100));
    expect(find.text(picked), findsOneWidget);

    // The result stays after everyone lets go.
    await a.up();
    await b.up();
    await tester.pump(ms(2000));
    expect(find.text(picked), findsOneWidget);
  }

  testWidgets('the magician octopus reveals the first player', (tester) async {
    await playRound(
      tester,
      FirstPlayerTheme.magic,
      title: "The Octopus's Magic Show",
      needMore: 'Waiting for more volunteers…',
      choosing: 'Abracadabra…',
      picked: 'Ta-da! You go first!',
    );
  });

  testWidgets('the magnet pulls a meeple onto the pedestal', (tester) async {
    await playRound(
      tester,
      FirstPlayerTheme.meeples,
      title: 'Magnetic Meeples',
      needMore: 'Waiting for more meeples…',
      choosing: 'The magnet is pulling…',
      picked: 'On the pedestal! You go first.',
    );
  });

  testWidgets('one bomb is left and goes off over the first player', (
    tester,
  ) async {
    await playRound(
      tester,
      FirstPlayerTheme.bomb,
      title: 'Pass the Bomb',
      needMore: 'Waiting for more daredevils…',
      choosing: "Tick… tock… who's left?",
      picked: 'Boom! You go first!',
    );
  });

  testWidgets('a trail reaches the treasure first', (tester) async {
    await playRound(
      tester,
      FirstPlayerTheme.treasure,
      title: 'The Treasure Hunt',
      needMore: 'Waiting for more treasure hunters…',
      choosing: 'The race to the treasure is on…',
      picked: 'Treasure found! You go first!',
    );
  });

  testWidgets('the last fighter standing is the champion', (tester) async {
    await playRound(
      tester,
      FirstPlayerTheme.arena,
      title: 'Finger Arena',
      needMore: 'Waiting for a challenger…',
      choosing: 'Ding ding! Fight!',
      picked: 'Champion! You go first!',
    );
  });

  test('fingers past the limit are ignored, like an octopus with 8 arms', () {
    final picker = FingerPicker(maxFingers: 8);
    for (var i = 0; i < 10; i++) {
      picker.down(i, Offset(i * 10.0, 0), Duration.zero);
    }
    expect(picker.touches, hasLength(8));
    expect(picker.touches.keys, isNot(contains(8)));

    // Lifting one makes room again.
    picker.up(0, Duration.zero);
    picker.down(9, Offset.zero, Duration.zero);
    expect(picker.touches.keys, contains(9));

    // Without a limit every palette color can be used.
    expect(FingerPicker().maxFingers, fingerPalette.length);
  });

  testWidgets('debug mouse clicks pin fingers for desktop testing', (
    tester,
  ) async {
    await pumpWithL10n(
      tester,
      FirstPlayerScreen(random: math.Random(3), theme: FirstPlayerTheme.meeples),
    );
    expect(find.byKey(const ValueKey('first-player-pin-hint')), findsOneWidget);
    final surface = tester.getRect(
      find.byKey(const ValueKey('first-player-surface')),
    );
    final left = surface.center + const Offset(-100, 100);
    final right = surface.center + const Offset(100, 100);

    // Pins stay down after the click is released.
    await tester.tapAt(left, kind: PointerDeviceKind.mouse);
    await tester.pump(ms(100));
    expect(find.text('Waiting for more meeples…'), findsOneWidget);
    await tester.tapAt(right, kind: PointerDeviceKind.mouse);
    await tester.pump(ms(100));
    expect(find.text('Hold still…'), findsOneWidget);

    // Clicking a pin lifts it again.
    await tester.tapAt(right, kind: PointerDeviceKind.mouse);
    await tester.pump(ms(100));
    expect(find.text('Waiting for more meeples…'), findsOneWidget);

    await tester.tapAt(right, kind: PointerDeviceKind.mouse);
    await tester.pump(ms(2100));
    await tester.pump(FirstPlayerTheme.meeples.decideTime + ms(100));
    expect(find.text('On the pedestal! You go first.'), findsOneWidget);

    // Lift both pins. After a pick a quick click does nothing…
    await tester.tapAt(left, kind: PointerDeviceKind.mouse);
    await tester.tapAt(right, kind: PointerDeviceKind.mouse);
    await tester.pump(ms(100));
    await tester.tapAt(left, kind: PointerDeviceKind.mouse);
    await tester.pump(ms(100));
    expect(find.text('On the pedestal! You go first.'), findsOneWidget);
    expect(find.text('Magnetic Meeples'), findsOneWidget);

    // …but a touch and hold starts a fresh round on the same scenery.
    final hold = await tester.startGesture(
      left,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump(ms(300));
    expect(find.byKey(const ValueKey('first-player-hold')), findsOneWidget);
    await tester.pump(ms(400));
    await tester.pump(ms(100));
    await hold.up();
    await tester.pump(ms(100));
    expect(find.text('Magnetic Meeples'), findsOneWidget);
    expect(find.text('Everyone, put a finger on the screen'), findsOneWidget);
  });

  testWidgets('holding a finger mid-round never resets it', (tester) async {
    await pumpWithL10n(
      tester,
      FirstPlayerScreen(random: math.Random(3), theme: FirstPlayerTheme.magic),
    );
    final surface = tester.getRect(
      find.byKey(const ValueKey('first-player-surface')),
    );
    await tester.startGesture(surface.center);
    await tester.pump(ms(1500));
    expect(find.text('Waiting for more volunteers…'), findsOneWidget);
    expect(find.byKey(const ValueKey('first-player-hold')), findsNothing);
  });

  test('the next scenery is never the one shown last', () {
    final random = math.Random(5);
    for (final last in FirstPlayerTheme.values) {
      for (var i = 0; i < 20; i++) {
        expect(
          FirstPlayerThemeRotation.pickAfter(last.name, random),
          isNot(last),
        );
      }
    }
    // Nothing remembered yet: any theme will do.
    expect(
      FirstPlayerTheme.values,
      contains(FirstPlayerThemeRotation.pickAfter(null, random)),
    );
  });

  testWidgets('each visit shows a different scenery than the last', (
    tester,
  ) async {
    const titles = {
      "The Octopus's Magic Show": 'magic',
      'Magnetic Meeples': 'meeples',
      'Pass the Bomb': 'bomb',
      'The Treasure Hunt': 'treasure',
      'Finger Arena': 'arena',
    };
    String shown() => titles.entries
        .firstWhere(
          (entry) => find.text(entry.key).evaluate().isNotEmpty,
          orElse: () => const MapEntry('', 'none'),
        )
        .value;

    // Every visit differs from the one just before it.
    var previous = 'none';
    for (var visit = 0; visit < 6; visit++) {
      await pumpWithL10n(tester, FirstPlayerScreen(key: UniqueKey()));
      final current = shown();
      expect(current, isNot('none'));
      expect(current, isNot(previous));
      previous = current;
    }
  });

  testWidgets('the page has the language toggle', (tester) async {
    await pumpWithL10n(
      tester,
      const FirstPlayerScreen(theme: FirstPlayerTheme.magic),
    );
    expect(find.byType(LanguageToggle), findsOneWidget);
  });
}
