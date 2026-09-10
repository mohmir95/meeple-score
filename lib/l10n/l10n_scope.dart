import 'package:flutter/material.dart';

import 'app_localizations.dart';
import 'locale_controller.dart';

class L10nScope extends InheritedNotifier<LocaleController> {
  const L10nScope({
    super.key,
    required LocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static LocaleController controllerOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<L10nScope>();
    assert(scope != null, 'L10nScope not found');
    return scope!.notifier!;
  }

  static AppLocalizations of(BuildContext context) {
    return controllerOf(context).strings;
  }
}

extension L10nContext on BuildContext {
  AppLocalizations get l10n => L10nScope.of(this);
}
