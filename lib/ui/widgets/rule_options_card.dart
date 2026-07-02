import 'package:flutter/material.dart';
import 'package:ludo_club/models/ludo_models.dart';

class RuleOptionsCard extends StatelessWidget {
  const RuleOptionsCard({
    required this.state,
    required this.onRulesChanged,
    super.key,
  });

  final LudoGameState state;
  final ValueChanged<RuleOptions> onRulesChanged;

  @override
  Widget build(BuildContext context) {
    final rules = state.rules;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Regeln', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SegmentedButton<OpenRollRule>(
              segments: const [
                ButtonSegment(
                  value: OpenRollRule.oneRoll,
                  label: Text('1 Startwurf'),
                ),
                ButtonSegment(
                  value: OpenRollRule.threeRolls,
                  label: Text('3 Startwürfe'),
                ),
              ],
              selected: {rules.openRollRule},
              onSelectionChanged: (selection) {
                onRulesChanged(rules.copyWith(openRollRule: selection.first));
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Bei 6 aus dem Haus ziehen'),
              value: rules.mustLeaveBaseOnSix,
              onChanged: (value) =>
                  onRulesChanged(rules.copyWith(mustLeaveBaseOnSix: value)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Eigene Felder blockieren'),
              value: rules.blockOwnFields,
              onChanged: (value) =>
                  onRulesChanged(rules.copyWith(blockOwnFields: value)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Bonuswurf beim Ziel'),
              value: rules.extraTurnOnFinish,
              onChanged: (value) =>
                  onRulesChanged(rules.copyWith(extraTurnOnFinish: value)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Bonuswurf nach Schlag'),
              value: rules.extraTurnOnCapture,
              onChanged: (value) =>
                  onRulesChanged(rules.copyWith(extraTurnOnCapture: value)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dritte 6 beendet den Zug'),
              value: rules.threeSixesEndTurn,
              onChanged: (value) =>
                  onRulesChanged(rules.copyWith(threeSixesEndTurn: value)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Schlagzwang'),
              value: rules.mustCapture,
              onChanged: (value) =>
                  onRulesChanged(rules.copyWith(mustCapture: value)),
            ),
          ],
        ),
      ),
    );
  }
}
