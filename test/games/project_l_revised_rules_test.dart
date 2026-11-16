import 'package:board_game_score_sheet/games/project_l/project_l_game.dart';
import 'package:board_game_score_sheet/games/project_l/project_l_revised_rules_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

void main() {
  test('Project L hub offers the revised rules', () {
    const game = ProjectLGame();
    expect(game.showQuickReference, isTrue);
    expect(game.quickReferenceTitleKey, 'hub.revisedRules');
    expect(game.hasScoresheet, isFalse);
    final rules = [
      for (final group in ProjectLRevisedRules.groups) ...group.rules,
    ];
    expect(rules, hasLength(8));
  });

  for (final width in [1200.0, 360.0]) {
    testWidgets('lists all eight revised rules (${width.toInt()}px)', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpWithL10n(tester, const ProjectLRevisedRulesScreen());
      expect(find.text('Recycle (new action)'), findsOneWidget);
      expect(find.text('Unfinished puzzles cost points'), findsOneWidget);
      expect(find.text('Endless White Deck'), findsOneWidget);
      expect(find.text('Optional'), findsOneWidget);
      expect(find.text('Rulebook 2.5'), findsNWidgets(2));
      expect(find.text('8'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
