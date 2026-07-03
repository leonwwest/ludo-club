import 'package:flutter/material.dart';
import 'package:ludo_club/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final rules = state.rules;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.rules, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SegmentedButton<OpenRollRule>(
              segments: [
                ButtonSegment(
                  value: OpenRollRule.oneRoll,
                  label: Text(l10n.oneRoll),
                ),
                ButtonSegment(
                  value: OpenRollRule.threeRolls,
                  label: Text(l10n.threeRolls),
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
              title: Text(l10n.mustLeaveBaseOnSix),
              value: rules.mustLeaveBaseOnSix,
              onChanged: (value) =>
                  onRulesChanged(rules.copyWith(mustLeaveBaseOnSix: value)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.blockOwnFields),
              value: rules.blockOwnFields,
              onChanged: (value) =>
                  onRulesChanged(rules.copyWith(blockOwnFields: value)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.extraTurnOnFinish),
              value: rules.extraTurnOnFinish,
              onChanged: (value) =>
                  onRulesChanged(rules.copyWith(extraTurnOnFinish: value)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.extraTurnOnCapture),
              value: rules.extraTurnOnCapture,
              onChanged: (value) =>
                  onRulesChanged(rules.copyWith(extraTurnOnCapture: value)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.threeSixesEndTurn),
              value: rules.threeSixesEndTurn,
              onChanged: (value) =>
                  onRulesChanged(rules.copyWith(threeSixesEndTurn: value)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.mustCapture),
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
