import 'package:flutter/material.dart';
import 'package:ludo_club/l10n/app_localizations.dart';
import 'package:ludo_club/models/ludo_models.dart';

class RuleOptionsCard extends StatelessWidget {
  const RuleOptionsCard({
    required this.state,
    required this.onRulesChanged,
    this.enabled = true,
    super.key,
  });

  final LudoGameState state;
  final ValueChanged<RuleOptions> onRulesChanged;
  final bool enabled;

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
            if (!enabled) ...[
              const SizedBox(height: 10),
              Semantics(
                liveRegion: true,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lock_outline, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.rulesLockedTitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.rulesLockedBody,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
              onSelectionChanged: enabled
                  ? (selection) {
                      onRulesChanged(
                        rules.copyWith(openRollRule: selection.first),
                      );
                    }
                  : null,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.mustLeaveBaseOnSix),
              value: rules.mustLeaveBaseOnSix,
              onChanged: enabled
                  ? (value) => onRulesChanged(
                        rules.copyWith(mustLeaveBaseOnSix: value),
                      )
                  : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.blockOwnFields),
              value: rules.blockOwnFields,
              onChanged: enabled
                  ? (value) =>
                      onRulesChanged(rules.copyWith(blockOwnFields: value))
                  : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.extraTurnOnFinish),
              value: rules.extraTurnOnFinish,
              onChanged: enabled
                  ? (value) =>
                      onRulesChanged(rules.copyWith(extraTurnOnFinish: value))
                  : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.extraTurnOnCapture),
              value: rules.extraTurnOnCapture,
              onChanged: enabled
                  ? (value) =>
                      onRulesChanged(rules.copyWith(extraTurnOnCapture: value))
                  : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.extraTurnOnSixNoMove),
              value: rules.extraTurnOnSixNoMove,
              onChanged: enabled
                  ? (value) => onRulesChanged(
                        rules.copyWith(extraTurnOnSixNoMove: value),
                      )
                  : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.threeSixesEndTurn),
              value: rules.threeSixesEndTurn,
              onChanged: enabled
                  ? (value) =>
                      onRulesChanged(rules.copyWith(threeSixesEndTurn: value))
                  : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.mustCapture),
              value: rules.mustCapture,
              onChanged: enabled
                  ? (value) =>
                      onRulesChanged(rules.copyWith(mustCapture: value))
                  : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.doublePieceBlockades),
              value: rules.doublePieceBlockades,
              onChanged: enabled
                  ? (value) => onRulesChanged(
                        rules.copyWith(doublePieceBlockades: value),
                      )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
