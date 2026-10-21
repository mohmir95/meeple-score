import 'package:board_game_score_sheet/shared/widgets/score_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';

Future<List<int>> _pumpStepper(WidgetTester tester, int value) async {
  final changes = <int>[];
  await pumpWithL10n(
    tester,
    Scaffold(
      body: Center(
        child: ScoreStepper(value: value, onChanged: changes.add),
      ),
    ),
  );
  await tester.tap(find.text('$value'));
  await pumpFor(tester);
  return changes;
}

TextField _field(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField));

void main() {
  testWidgets('score entry starts empty when the value is zero', (
    tester,
  ) async {
    final changes = await _pumpStepper(tester, 0);

    expect(_field(tester).controller!.text, isEmpty);

    await tester.enterText(find.byType(TextField), '12');
    await tester.tap(find.text('Save'));
    await pumpFor(tester);
    expect(changes, [12]);
  });

  testWidgets('score entry pre-selects an existing value', (tester) async {
    final changes = await _pumpStepper(tester, 15);

    final controller = _field(tester).controller!;
    expect(controller.text, '15');
    expect(
      controller.selection,
      const TextSelection(baseOffset: 0, extentOffset: 2),
    );

    // Typing over the selection replaces the value instead of appending.
    tester.testTextInput.enterText('8');
    await tester.tap(find.text('Save'));
    await pumpFor(tester);
    expect(changes, [8]);
  });

  testWidgets('clearing the score entry saves zero', (tester) async {
    final changes = await _pumpStepper(tester, 15);

    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('Save'));
    await pumpFor(tester);
    expect(changes, [0]);
  });
}
