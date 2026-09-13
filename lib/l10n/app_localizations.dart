import 'dart:convert';

import 'package:flutter/services.dart';

class AppLanguage {
  const AppLanguage({
    required this.id,
    required this.asset,
    required this.nativeName,
    required this.rtl,
  });

  final String id;
  final String asset;
  final String nativeName;
  final bool rtl;

  static const all = [
    AppLanguage(
      id: 'en',
      asset: 'assets/i18n/en.json',
      nativeName: 'English',
      rtl: false,
    ),
    AppLanguage(
      id: 'fa',
      asset: 'assets/i18n/fa.json',
      nativeName: 'فارسی',
      rtl: true,
    ),
  ];

  static AppLanguage byId(String id) {
    return all.firstWhere(
      (language) => language.id == id,
      orElse: () => all.first,
    );
  }

  AppLanguage get next {
    final index = all.indexWhere((language) => language.id == id);
    return all[(index + 1) % all.length];
  }
}

class AppLocalizations {
  AppLocalizations(this.language, this._strings);

  final AppLanguage language;
  final Map<String, String> _strings;

  bool get isRtl => language.rtl;

  bool has(String key) => _strings.containsKey(key);

  String t(String key, [Map<String, String>? args]) {
    var value = _strings[key] ?? key;
    if (args != null) {
      for (final entry in args.entries) {
        value = value.replaceAll('{${entry.key}}', entry.value);
      }
    }
    return value;
  }

  String tOr(String preferred, String fallback, [Map<String, String>? args]) {
    return t(has(preferred) ? preferred : fallback, args);
  }

  String colorLabel(String optionName) => t('color.$optionName');

  String winnerAnnouncement(Iterable<String> names) {
    final winners = names.toList();
    if (winners.isEmpty) {
      return t('play.noWinner');
    }
    if (winners.length == 1) {
      return t('play.wins', {'name': winners.first});
    }
    return t('play.tied', {'names': winners.join(', ')});
  }

  static Future<AppLocalizations> load(String languageId) async {
    final language = AppLanguage.byId(languageId);
    final raw = await rootBundle.loadString(language.asset);
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return AppLocalizations(language, const {});
    }
    final strings = <String, String>{
      for (final entry in decoded.entries)
        if (entry.value is String) entry.key.toString(): entry.value as String,
    };
    return AppLocalizations(language, strings);
  }
}
