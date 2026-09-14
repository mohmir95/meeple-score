import 'package:flutter/material.dart';

import '../../domain/models/player.dart';
import '../../l10n/l10n_scope.dart';
import '../../shared/player_colors.dart';
import 'arnak_scoring.dart';
import 'arnak_state.dart';

/// Asks which tied player reached the Lost Temple first.
///
/// Returns the chosen player id, [ArnakState.nobodyReachedLostTemple] for
/// "no one", or `null` if the dialog was cancelled.
Future<String?> showArnakLostTempleDialog(
  BuildContext context,
  ArnakState state,
) {
  final tied = ArnakScoring.tiedByTotal(state);
  if (tied.length < 2) {
    return Future.value(ArnakState.nobodyReachedLostTemple);
  }

  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final l10n = dialogContext.l10n;
      final names = tied.map((player) => player.name).join(', ');
      var selected = state.lostTempleFirstPlayerId;
      return StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text(l10n.t('arnak.lostTempleTitle')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.t('arnak.lostTempleMessage', {'names': names})),
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
                          value: ArnakState.nobodyReachedLostTemple,
                          title: Text(l10n.t('arnak.lostTempleNone')),
                          subtitle: Text(l10n.t('arnak.lostTempleNoneHint')),
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
