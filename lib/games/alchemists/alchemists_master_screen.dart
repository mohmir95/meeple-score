import 'package:flutter/material.dart';

import 'alchemists_logic_screen.dart';

/// Everything the rulebook says about the Master variant, as a guide in
/// collapsible sections. Texts live under `alchemists.master.` in the
/// translations.
class AlchemistsMaster {
  const AlchemistsMaster._();

  static const sections = [
    LogicSection('choosing', [
      LogicPoint('choosing.first'),
      LogicPoint('choosing.differences'),
    ]),
    LogicSection('setup', [
      LogicPoint('setup.ingredients'),
      LogicPoint('setup.conferences'),
      LogicPoint('setup.conflict'),
      LogicPoint('setup.app'),
    ]),
    LogicSection('debunking', [
      LogicPoint('debunking.proof'),
      LogicPoint(
        'debunking.how',
        sub: [
          LogicPoint('debunking.how1'),
          LogicPoint('debunking.how2'),
          LogicPoint('debunking.how3'),
        ],
      ),
      LogicPoint('debunking.success'),
      LogicPoint('debunking.failure'),
      LogicPoint('debunking.wrongVariant'),
    ]),
    LogicSection('oneTwo', [
      LogicPoint('oneTwo.one'),
      LogicPoint('oneTwo.two'),
      LogicPoint('oneTwo.penalties'),
      LogicPoint('oneTwo.reward'),
    ]),
    LogicSection('conflict', [
      LogicPoint('conflict.what'),
      LogicPoint('conflict.reward'),
      LogicPoint('conflict.mark'),
      LogicPoint('conflict.seals'),
      LogicPoint('conflict.reuse'),
      LogicPoint('conflict.clear'),
      LogicPoint('conflict.scoring'),
    ]),
    LogicSection('invalid', [
      LogicPoint('invalid.rule'),
      LogicPoint('invalid.back'),
      LogicPoint('invalid.example'),
      LogicPoint('invalid.repeat'),
    ]),
    LogicSection('round', [
      LogicPoint('round.award'),
      LogicPoint('round.conference'),
      LogicPoint('round.final'),
    ]),
    LogicSection('grid', [
      LogicPoint('grid.positive'),
      LogicPoint('grid.negative'),
    ]),
    LogicSection('mixing', [
      LogicPoint('mixing.free'),
      LogicPoint('mixing.equalizer'),
    ]),
  ];
}

class AlchemistsMasterScreen extends StatelessWidget {
  const AlchemistsMasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AlchemistsGuideScreen(
      titleKey: 'hub.masterVariant',
      prefix: 'alchemists.master',
      sections: AlchemistsMaster.sections,
    );
  }
}
