import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_localizations.dart';

class LocaleController extends ChangeNotifier {
  LocaleController._(this._prefs, this._localizations);

  static const storageKey = 'app_locale';

  final SharedPreferences? _prefs;
  AppLocalizations _localizations;

  AppLocalizations get strings => _localizations;
  AppLanguage get language => _localizations.language;

  static Future<LocaleController> create() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      prefs = null;
    }
    final saved = prefs?.getString(storageKey) ?? 'en';
    final localizations = await AppLocalizations.load(saved);
    return LocaleController._(prefs, localizations);
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (language.id == _localizations.language.id) {
      return;
    }
    _localizations = await AppLocalizations.load(language.id);
    notifyListeners();
    final prefs = _prefs;
    if (prefs != null) {
      unawaited(prefs.setString(storageKey, language.id));
    }
  }

  Future<void> cycleLanguage() => setLanguage(language.next);
}
