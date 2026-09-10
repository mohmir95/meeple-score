import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';

class GwtSetup extends StatelessWidget {
  const GwtSetup({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.t('game.gwt.setupTitle'), style: textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          l10n.t('game.gwt.setupBody'),
          style: textTheme.bodyMedium,
        ),
      ],
    );
  }
}
