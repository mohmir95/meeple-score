import 'dart:convert';
import 'dart:io';

import 'package:board_game_score_sheet/games/alchemists/alchemists_logic_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

Iterable<String> _keys() sync* {
  Iterable<String> walk(LogicPoint p) sync* {
    yield p.key;
    for (final s in p.sub) {
      yield* walk(s);
    }
  }

  for (final section in AlchemistsLogic.sections) {
    yield '${section.key}.title';
    yield '${section.key}.summary';
    for (final point in section.points) {
      yield* walk(point);
    }
  }
}

void main() {
  test('every frame exists and every text is translated', () {
    final frames = AlchemistsLogic.allFrames.toList();
    expect(frames, hasLength(50));
    expect(frames.toSet(), hasLength(50));
    for (final frame in frames) {
      expect(
        File(AlchemistsLogic.asset(frame)).existsSync(),
        isTrue,
        reason: frame,
      );
    }
    for (final lang in ['en', 'fa']) {
      final strings =
          jsonDecode(File('assets/i18n/$lang.json').readAsStringSync())
              as Map<String, dynamic>;
      for (final key in _keys()) {
        expect(
          strings.containsKey('alchemists.logic.$key'),
          isTrue,
          reason: '$lang: $key',
        );
      }
    }
  });

  test('bold markers become bold spans', () {
    final span = boldMarkup('a **b** c', null);
    expect(span.children, hasLength(3));
    expect((span.children![1] as TextSpan).style?.fontWeight, FontWeight.w800);
  });

  for (final width in [1200.0, 360.0]) {
    testWidgets('sections open and pictures can be browsed '
        '(${width.toInt()}px)', (tester) async {
      tester.view.physicalSize = Size(width, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpWithL10n(tester, const AlchemistsLogicScreen());
      expect(find.text('The Basics'), findsOneWidget);
      expect(find.text('Protect Your Information'), findsOneWidget);
      // Closed at first: no frames shown.
      expect(find.byType(PageView), findsNothing);

      await tester.tap(find.text('The Basics'));
      await pumpFor(tester);
      final mixing = find.byKey(
        const ValueKey('alchemists-frames-basics.mixing'),
      );
      expect(mixing, findsOneWidget);

      // Swipe to the next picture.
      await tester.drag(
        find.descendant(of: mixing, matching: find.byType(PageView)),
        Offset(-width / 2, 0),
      );
      await pumpFor(tester);

      // Tap to enlarge, then close.
      // Let the swipe settle: a tap on a moving page only stops it.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      // The middle of the picture, away from the arrow buttons.
      await tester.tap(
        find.descendant(of: mixing, matching: find.byType(AspectRatio)),
      );
      await pumpFor(tester);
      expect(
        find.byKey(const ValueKey('alchemists-viewer-close')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('alchemists-viewer-close')));
      await pumpFor(tester);
      expect(
        find.byKey(const ValueKey('alchemists-viewer-close')),
        findsNothing,
      );

      // Close the section again.
      await tester.tap(find.text('The Basics'));
      await pumpFor(tester);
      expect(mixing, findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
