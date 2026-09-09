import 'package:board_game_score_sheet/app/app.dart';
import 'package:board_game_score_sheet/domain/game_registry.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/memory_session_repository.dart';

void main() {
  testWidgets('home lists Great Western Trail and can start a game', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repository = MemorySessionRepository();
    await tester.pumpWidget(
      BoardGameScoreSheetApp(
        repository: repository,
        registry: GameRegistry(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Board Game Score Sheet'), findsOneWidget);
    expect(find.text('Great Western Trail'), findsOneWidget);
    expect(find.text('Simple Tally'), findsNothing);

    await tester.tap(find.text('Great Western Trail'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Great Western Trail'), findsOneWidget);
    expect(find.byTooltip('Red'), findsWidgets);
    expect(find.byTooltip('Blue'), findsWidgets);
    expect(find.byTooltip('Yellow'), findsWidgets);
    expect(find.byTooltip('White'), findsWidgets);
    await tester.tap(find.text('Start game'));
    await tester.pumpAndSettle();

    expect(find.text('Score pad'), findsOneWidget);
    expect(await repository.load(GreatWesternTrailGame.idValue), isNotNull);
  });

  testWidgets('home shows a resume chip for a saved game', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repository = MemorySessionRepository();
    await tester.pumpWidget(
      BoardGameScoreSheetApp(
        repository: repository,
        registry: GameRegistry(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Great Western Trail'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start game'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Resume'), findsOneWidget);
  });

  testWidgets('refresh restores an in-progress GWT game', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repository = MemorySessionRepository();
    await tester.pumpWidget(
      BoardGameScoreSheetApp(
        repository: repository,
        registry: GameRegistry(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Great Western Trail'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start game'));
    await tester.pumpAndSettle();
    expect(find.text('Score pad'), findsOneWidget);

    await tester.pumpWidget(
      BoardGameScoreSheetApp(
        repository: repository,
        registry: GameRegistry(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Score pad'), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Great Western Trail'), findsOneWidget);
  });

  testWidgets('home layout works on a narrow phone viewport', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(
      BoardGameScoreSheetApp(
        repository: MemorySessionRepository(),
        registry: GameRegistry(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Great Western Trail'), findsOneWidget);
    await tester.tap(find.text('Great Western Trail'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start game'));
    await tester.pumpAndSettle();

    expect(find.text('Score pad'), findsOneWidget);
    expect(find.text('Coins'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
