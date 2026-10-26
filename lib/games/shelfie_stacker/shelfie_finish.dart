import 'package:flutter/material.dart';

import '../../domain/models/player.dart';
import '../../l10n/l10n_scope.dart';
import '../../shared/player_colors.dart';
import 'shelfie_scoring.dart';
import 'shelfie_state.dart';

/// Asks which tied player holds the lowest-valued Character Card.
///
/// Returns the chosen player id, [ShelfieState.sharedVictory] when the cards
/// tie too, or `null` if the dialog was cancelled.
Future<String?> showShelfieLowestCardDialog(
  BuildContext context,
  ShelfieState state,
) {
  final tied = ShelfieScoring.tiedByTotal(state);
  if (tied.length < 2) {
    return Future.value(ShelfieState.sharedVictory);
  }

  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final l10n = dialogContext.l10n;
      final names = tied.map((player) => player.name).join(', ');
      var selected = state.lowestCardPlayerId;
      return StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text(l10n.t('shelfie.tieTitle')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.t('shelfie.tieMessage', {'names': names})),
                  const SizedBox(height: 12),
                  RadioGroup<String>(
                    groupValue: selected,
                    onChanged: (value) {
                      setModalState(() => selected = value);
                    },
                    child: Column(
                      children: [
                        for (final player in tied)
                          RadioListTile<String>(
                            value: player.id,
                            title: _PlayerOption(player: player),
                          ),
                        RadioListTile<String>(
                          value: ShelfieState.sharedVictory,
                          title: Text(l10n.t('shelfie.tieShared')),
                          subtitle: Text(l10n.t('shelfie.tieSharedHint')),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.t('common.cancel')),
              ),
              FilledButton(
                onPressed: selected == null
                    ? null
                    : () => Navigator.of(dialogContext).pop(selected),
                child: Text(l10n.t('common.confirm')),
              ),
            ],
          );
        },
      );
    },
  );
}

class _PlayerOption extends StatelessWidget {
  const _PlayerOption({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: playerColor(player.colorValue),
            shape: BoxShape.circle,
            border: Border.all(
              color: playerColorOutline(player.colorValue),
              width: isLightPlayerColor(player.colorValue) ? 1.5 : 0,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(child: Text(player.name)),
      ],
    );
  }
}
