import 'package:board_game_score_sheet/features/home/game_card.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_game.dart';
import 'package:board_game_score_sheet/shared/widgets/language_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';
import 'helpers/memory_session_repository.dart';

void main() {
  testWidgets('home lists Great Western Trail and can start a game', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repository = MemorySessionRepository();
    await pumpScoreSheetApp(tester, repository: repository);
    await pumpUntilFound(
      tester,
      find.text('Great Western Trail First Edition'),
    );

    expect(find.text('Board Game Score Sheet'), findsOneWidget);
    expect(find.text('Great Western Trail First Edition'), findsOneWidget);
    expect(find.text('Great Western Trail Second Edition'), findsOneWidget);
    expect(find.text('First Edition'), findsOneWidget);
    expect(find.text('Second Edition'), findsOneWidget);
    expect(find.text('Simple Tally'), findsNothing);
    expect(find.text('فارسی'), findsOneWidget);

    await tester.tap(find.text('First Edition'));
    await pumpFor(tester);
    await pumpUntilFound(tester, find.text('Scoresheet'));
    expect(find.text('Scoresheet'), findsOneWidget);
    expect(find.text('Buildings Randomizer'), findsOneWidget);
    expect(find.text('Coming Soon'), findsWidgets);

    await tester.tap(find.text('Scoresheet'));
    await pumpFor(tester);
    await pumpUntilFound(tester, find.text('Start game'));

    expect(
      find.widgetWithText(AppBar, 'Great Western Trail First Edition'),
      findsWidgets,
    );
    expect(find.byTooltip('Red'), findsOneWidget);
    expect(find.byTooltip('Blue'), findsOneWidget);
    await tester.tap(find.text('Start game'));
    await pumpFor(tester);
    await pumpUntilFound(tester, find.text('Score pad'));

    expect(find.text('Score pad'), findsOneWidget);
    expect(await repository.load(GreatWesternTrailGame.idValue), isNotNull);
  });

  testWidgets('home shows a resume chip for a saved game', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repository = MemorySessionRepository();
    await pumpScoreSheetApp(tester, repository: repository);
    await openGwtSetup(tester);
    await tester.tap(find.text('Start game'));
    await pumpFor(tester);
    await pumpUntilFound(tester, find.text('Score pad'));
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pumpFor(tester);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pumpFor(tester);
    await pumpUntilFound(tester, find.text('Resume'));

    expect(find.text('Resume'), findsOneWidget);
  });

  testWidgets('refresh restores an in-progress GWT game', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repository = MemorySessionRepository();
    final localeController = await createTestLocale();
    await pumpScoreSheetApp(
      tester,
      repository: repository,
      localeController: localeController,
    );
    await pumpUntilFound(
      tester,
      find.text('Great Western Trail First Edition'),
    );
    await openGwtSetup(tester);
    await tester.tap(find.text('Start game'));
    await pumpFor(tester);
    await pumpUntilFound(tester, find.text('Score pad'));
    expect(find.text('Score pad'), findsOneWidget);

    await pumpScoreSheetApp(
      tester,
      repository: repository,
      localeController: localeController,
    );
    await pumpUntilFound(tester, find.text('Score pad'));

    expect(find.text('Score pad'), findsOneWidget);
    expect(
      find.widgetWithText(AppBar, 'Great Western Trail First Edition'),
      findsOneWidget,
    );
  });

  testWidgets('home layout works on a narrow phone viewport', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await pumpScoreSheetApp(tester);
    await pumpUntilFound(
      tester,
      find.text('Great Western Trail First Edition'),
    );

    expect(find.text('Great Western Trail First Edition'), findsWidgets);

    final first = tester.getRect(find.byType(GameCard).at(0));
    final second = tester.getRect(find.byType(GameCard).at(1));
    expect(first.top, closeTo(second.top, 1));
    expect(first.right, lessThanOrEqualTo(second.left + 1));
    expect(first.width, closeTo(first.height, 2));
    expect(second.width, closeTo(second.height, 2));
    expect(first.width, lessThan(220));

    await openGwtSetup(tester);
    expect(find.textContaining('You are ranchers'), findsOneWidget);
    await tester.tap(find.text('Start game'));
    await pumpFor(tester);
    await pumpUntilFound(tester, find.text('Score pad'));

    expect(find.text('Score pad'), findsOneWidget);
    expect(find.text('Coins'), findsOneWidget);
    expect(
      find.image(
        const AssetImage('assets/games/great_western_trail/icons/coins.png'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('language toggle switches English and Persian', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await pumpScoreSheetApp(tester);
    await pumpUntilFound(tester, find.text('Board Game Score Sheet'));

    expect(find.text('Board Game Score Sheet'), findsOneWidget);
    await tester.tap(find.byType(LanguageToggle));
    await pumpFor(tester);
    await pumpUntilFound(tester, find.text('برگه امتیاز بازی رومیزی'));
    expect(find.text('English'), findsWidgets);
  });
}
