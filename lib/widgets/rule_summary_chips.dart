import 'package:flutter/material.dart';
import 'package:ludo_club/models/game_rules.dart';

class RuleSummaryChips extends StatelessWidget {
  const RuleSummaryChips(
      {super.key, required this.rules, this.compact = false});

  final GameRules rules;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: compact ? 11.0 : 12.5,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF1F2937),
    );
    final chips = _specsFor(rules).map((spec) {
      return Padding(
        padding: const EdgeInsets.only(right: 6, bottom: 6),
        child: Chip(
          label: Text(spec.label, style: textStyle),
          side: BorderSide(
            color:
                spec.active ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
          ),
          backgroundColor:
              spec.active ? const Color(0xFFE0ECFF) : const Color(0xFFF3F4F6),
          padding: compact
              ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
              : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
      );
    }).toList();

    return Wrap(children: chips);
  }

  List<_RuleChipSpec> _specsFor(GameRules rules) {
    return [
      _RuleChipSpec(
        label: rules.mustRollSixToStart ? 'Six to start' : 'Free start',
        active: rules.mustRollSixToStart,
      ),
      _RuleChipSpec(
        label: rules.safeFieldsEnabled ? 'Safe tiles' : 'Unsafe board',
        active: rules.safeFieldsEnabled,
      ),
      _RuleChipSpec(
        label: rules.extraTurnOnSix ? 'Extra turn on six' : 'Single roll only',
        active: rules.extraTurnOnSix,
      ),
      _RuleChipSpec(
        label: rules.extraTurnOnCapture
            ? 'Capture extra turn'
            : 'No capture bonus',
        active: rules.extraTurnOnCapture,
      ),
      _RuleChipSpec(
        label: rules.exactRollToFinish ? 'Exact finish' : 'Flexible finish',
        active: rules.exactRollToFinish,
      ),
      _RuleChipSpec(
        label: rules.multipleOccupancyAllowed
            ? 'Stacking allowed'
            : 'Single occupancy',
        active: rules.multipleOccupancyAllowed,
      ),
      _RuleChipSpec(
        label: rules.captureReturnsToHome ? 'Captures reset' : 'Captures stay',
        active: rules.captureReturnsToHome,
      ),
      _RuleChipSpec(
        label: 'Win ${rules.piecesToWin}',
        active: true,
      ),
      _RuleChipSpec(
        label: '${rules.maxConsecutiveSixes}x six limit',
        active: true,
      ),
    ];
  }
}

class _RuleChipSpec {
  _RuleChipSpec({required this.label, required this.active});
  final String label;
  final bool active;
}
