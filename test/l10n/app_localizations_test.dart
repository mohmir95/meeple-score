import 'dart:convert';

import 'package:board_game_score_sheet/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('interpolates named placeholders', () {
    final l10n = AppLocalizations(AppLanguage.byId('en'), {
      'play.wins': '{name} wins!',
      'home.playersCount': '{min}–{max} players',
    });

    expect(l10n.t('play.wins', {'name': 'Ada'}), 'Ada wins!');
    expect(
      l10n.t('home.playersCount', {'min': '2', 'max': '4'}),
      '2–4 players',
    );
    expect(l10n.t('missing.key'), 'missing.key');
  });

  test('English and Persian resource files share the same keys', () async {
    final english = jsonDecode(await rootBundle.loadString('assets/i18n/en.json'))
        as Map<String, dynamic>;
    final persian = jsonDecode(await rootBundle.loadString('assets/i18n/fa.json'))
        as Map<String, dynamic>;

    expect(english.keys.toSet(), persian.keys.toSet());
    expect(english.values.every((value) => value is String), isTrue);
    expect(persian.values.every((value) => value is String), isTrue);
  });

  test('loads Persian strings from JSON', () async {
    final l10n = await AppLocalizations.load('fa');
    expect(l10n.t('setup.startGame'), 'شروع بازی');
    expect(l10n.t('game.gwt.name'), 'Great Western Trail');
    expect(l10n.isRtl, isTrue);
  });
}
