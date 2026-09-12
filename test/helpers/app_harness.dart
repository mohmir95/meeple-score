import 'package:board_game_score_sheet/app/app.dart';
import 'package:board_game_score_sheet/domain/game_registry.dart';
import 'package:board_game_score_sheet/l10n/app_localizations.dart';
import 'package:board_game_score_sheet/l10n/l10n_scope.dart';
import 'package:board_game_score_sheet/l10n/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'memory_session_repository.dart';

bool _prefsMocked = false;
LocaleController? _cachedLocale;

Future<LocaleController> createTestLocale({String languageId = 'en'}) async {
  if (!_prefsMocked) {
    SharedPreferences.setMockInitialValues({
      LocaleController.storageKey: languageId,
    });
    _prefsMocked = true;
    _cachedLocale = await LocaleController.create();
  }
  await _cachedLocale!.setLanguage(AppLanguage.byId(languageId));
  return _cachedLocale!;
}

Future<void> pumpScoreSheetApp(
  WidgetTester tester, {
  MemorySessionRepository? repository,
  LocaleController? localeController,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pumpWidget(
    BoardGameScoreSheetApp(
      repository: repository ?? MemorySessionRepository(),
      registry: GameRegistry(),
      localeController: localeController ?? await createTestLocale(),
    ),
  );
  await pumpFor(tester);
}

Future<void> pumpWithL10n(
  WidgetTester tester,
  Widget home, {
  LocaleController? localeController,
}) async {
  await tester.pumpWidget(
    L10nScope(
      controller: localeController ?? await createTestLocale(),
      child: MaterialApp(home: home),
    ),
  );
  await pumpFor(tester);
}

/// Advances frames for a fixed time. Avoid [WidgetTester.pumpAndSettle]: a
/// leftover ticker or repeating animation waits until the 10-minute test timeout.
Future<void> pumpFor(
  WidgetTester tester, {
  Duration duration = const Duration(milliseconds: 400),
}) async {
  await tester.pump();
  await tester.pump(duration);
}

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int attempts = 20,
}) async {
  for (var i = 0; i < attempts; i++) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
  fail('Timed out waiting for $finder');
}

Future<void> openGwtSetup(WidgetTester tester) async {
  await pumpUntilFound(tester, find.text('Great Western Trail'));
  await tester.tap(find.text('Great Western Trail'));
  await pumpFor(tester);
  await pumpUntilFound(tester, find.text('Scoresheet'));
  await tester.tap(find.text('Scoresheet'));
  await pumpFor(tester);
  await pumpUntilFound(tester, find.text('Start game'));
}
