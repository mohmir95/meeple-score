import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';

class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = L10nScope.controllerOf(context);
    final next = controller.language.next;
    return Semantics(
      button: true,
      label: context.l10n.t('language.switchTo', {'name': next.nativeName}),
      child: TextButton(
        onPressed: controller.cycleLanguage,
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
          minimumSize: const Size(48, 40),
        ),
        child: Text(
          next.nativeName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
