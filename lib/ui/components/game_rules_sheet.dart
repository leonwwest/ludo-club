import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ludo_club/models/game_rules.dart';
import 'package:ludo_club/services/rule_preset_service.dart';
import 'package:ludo_club/widgets/rule_summary_chips.dart';

Future<void> showGameRulesSheet({
  required BuildContext context,
  required GameRules initialRules,
  required ValueChanged<GameRules> onRulesChanged,
  required BuildContext messengerContext,
  RulePresetService? presetService,
}) {
  final navigator = Navigator.of(context);
  final nameController = TextEditingController();
  bool savingPreset = false;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      GameRules current = initialRules;

      void updateRules(GameRules next) {
        current = next;
        onRulesChanged(next);
      }

      return Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Material(
            color: Colors.white,
            child: StatefulBuilder(
              builder: (ctx, setModalState) {
                void setAndUpdate(GameRules next) {
                  setModalState(() {
                    updateRules(next);
                  });
                }

                Future<void> savePreset() async {
                  final service = presetService;
                  if (service == null) {
                    return;
                  }
                  final messenger =
                      ScaffoldMessenger.maybeOf(messengerContext);
                  if (messenger == null) {
                    return;
                  }
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    messenger.showSnackBar(
                      const SnackBar(
                          content: Text('Enter a preset name before saving.')),
                    );
                    return;
                  }
                  setModalState(() {
                    savingPreset = true;
                  });
                  final saved = await service.saveNamedPreset(name, current);
                  if (!ctx.mounted) {
                    return;
                  }
                  setModalState(() {
                    savingPreset = false;
                    nameController.clear();
                  });
                  messenger.showSnackBar(
                    SnackBar(
                        content: Text(
                            'Preset "${saved.name}" saved. Available in Quick Play.')),
                  );
                }

                return SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Active Rules',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => navigator.pop(),
                              tooltip: 'Close',
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Toggle house rules mid-game. Changes apply immediately for all players.',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF6B7280),
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        RuleSummaryChips(rules: current),
                        const SizedBox(height: 16),
                        _RuleToggle(
                          title: 'Require a six to leave home',
                          subtitle:
                              'When off, tokens can enter play with any roll.',
                          value: current.mustRollSixToStart,
                          onChanged: (value) => setAndUpdate(
                            current.copyWith(mustRollSixToStart: value),
                          ),
                        ),
                        _RuleToggle(
                          title: 'Safe tiles prevent captures',
                          subtitle:
                              'Disable to allow capturing on coloured start tiles.',
                          value: current.safeFieldsEnabled,
                          onChanged: (value) => setAndUpdate(
                            current.copyWith(safeFieldsEnabled: value),
                          ),
                        ),
                        _RuleToggle(
                          title: 'Extra turn after rolling a six',
                          subtitle:
                              'Limit defined by the max consecutive sixes setting.',
                          value: current.extraTurnOnSix,
                          onChanged: (value) => setAndUpdate(
                            current.copyWith(extraTurnOnSix: value),
                          ),
                        ),
                        _RuleToggle(
                          title: 'Extra turn after capturing',
                          subtitle:
                              'Award another roll when an opponent token is captured.',
                          value: current.extraTurnOnCapture,
                          onChanged: (value) => setAndUpdate(
                            current.copyWith(extraTurnOnCapture: value),
                          ),
                        ),
                        _RuleToggle(
                          title: 'Captures return tokens home',
                          subtitle:
                              'When off, captured tokens remain stacked on the tile.',
                          value: current.captureReturnsToHome,
                          onChanged: (value) => setAndUpdate(
                            current.copyWith(captureReturnsToHome: value),
                          ),
                        ),
                        _RuleToggle(
                          title: 'Allow stacking on main path',
                          subtitle: 'Multiple occupancy disables blockades.',
                          value: current.multipleOccupancyAllowed,
                          onChanged: (value) => setAndUpdate(
                            current.copyWith(multipleOccupancyAllowed: value),
                          ),
                        ),
                        _RuleToggle(
                          title: 'Require exact roll to finish',
                          subtitle: 'Turn off to clamp overshoots to the goal.',
                          value: current.exactRollToFinish,
                          onChanged: (value) => setAndUpdate(
                            current.copyWith(exactRollToFinish: value),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _PiecesToWinSelector(
                          rules: current,
                          onChanged: setAndUpdate,
                        ),
                        const SizedBox(height: 12),
                        _MaxSixesSlider(
                          rules: current,
                          onChanged: setAndUpdate,
                        ),
                        const SizedBox(height: 12),
                        if (presetService == null)
                          Text(
                            'Loading preset storage...',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF9CA3AF),
                              fontSize: 12,
                            ),
                          )
                        else ...[
                          const Divider(),
                          Text(
                            'Save as preset',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              hintText: 'Preset name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              icon: const Icon(Icons.save),
                              onPressed: savingPreset ? null : savePreset,
                              label: Text(
                                  savingPreset ? 'Saving...' : 'Save preset'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    },
  ).whenComplete(nameController.dispose);
}

class _RuleToggle extends StatelessWidget {
  const _RuleToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF111827),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          color: const Color(0xFF6B7280),
          fontSize: 12,
        ),
      ),
    );
  }
}

class _PiecesToWinSelector extends StatelessWidget {
  const _PiecesToWinSelector({
    required this.rules,
    required this.onChanged,
  });

  final GameRules rules;
  final ValueChanged<GameRules> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Pieces required to win',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
        ),
        DropdownButton<int>(
          value: rules.piecesToWin,
          items: const [1, 2, 3, 4]
              .map((value) => DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value tokens'),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              onChanged(rules.copyWith(piecesToWin: value));
            }
          },
        ),
      ],
    );
  }
}

class _MaxSixesSlider extends StatelessWidget {
  const _MaxSixesSlider({
    required this.rules,
    required this.onChanged,
  });

  final GameRules rules;
  final ValueChanged<GameRules> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Max consecutive sixes: ${rules.maxConsecutiveSixes}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        Slider(
          value: rules.maxConsecutiveSixes.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          label: '${rules.maxConsecutiveSixes}',
          onChanged: (value) {
            final rounded = value.round().clamp(1, 5);
            onChanged(rules.copyWith(maxConsecutiveSixes: rounded));
          },
        ),
      ],
    );
  }
}
