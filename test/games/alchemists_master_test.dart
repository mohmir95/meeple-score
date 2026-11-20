import 'dart:convert';
import 'dart:io';

import 'package:board_game_score_sheet/games/alchemists/alchemists_logic_screen.dart';
import 'package:board_game_score_sheet/games/alchemists/alchemists_master_screen.dart';
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

  yield 'intro';
  for (final section in AlchemistsMaster.sections) {
    yield '${section.key}.title';
    yield '${section.key}.summary';
    for (final point in section.points) {
      yield* walk(point);
    }
  }
}

void main() {
  test('every Master Variant text is translated', () {
    expect(AlchemistsMaster.sections, hasLength(9));
    for (final lang in ['en', 'fa']) {
      final strings =
          jsonDecode(File('assets/i18n/$lang.json').readAsStringSync())
              as Map<String, dynamic>;
      expect(strings.containsKey('hub.masterVariant'), isTrue);
      for (final key in _keys()) {
        expect(
          strings.containsKey('alchemists.master.$key'),
          isTrue,
          reason: '$lang: $key',
        );
      }
    }
  });

  for (final width in [1200.0, 360.0]) {
    testWidgets('sections open and close (${width.toInt()}px)', (tester) async {
      tester.view.physicalSize = Size(width, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpWithL10n(tester, const AlchemistsMasterScreen());
      expect(find.text('Master Variant'), findsOneWidget);
      expect(find.text('Master Debunking'), findsOneWidget);
      expect(find.text('Mixing the Variants'), findsOneWidget);
      expect(find.text('How it works:'), findsNothing);

      await tester.tap(find.text('Master Debunking'));
      await pumpFor(tester);
      expect(find.text('How it works:'), findsOneWidget);

      await tester.tap(find.text('Master Debunking'));
      await pumpFor(tester);
      expect(find.text('How it works:'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
