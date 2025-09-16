import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/models/game_rules.dart';
import 'package:ludo_club/services/rule_preset_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('save and retrieve custom rule preset', () async {
    final service = await RulePresetService.create();
    final rules = GameRules.standard.copyWith(extraTurnOnSix: false);

    final saved = await service.saveNamedPreset('House Rules', rules);
    expect(saved.name, 'House Rules');

    final presets = await service.getPresets();
    expect(presets, hasLength(1));
    expect(presets.first.name, 'House Rules');
    expect(presets.first.rules.extraTurnOnSix, isFalse);
  });

  test('save overwrites presets with same name', () async {
    final service = await RulePresetService.create();
    await service.saveNamedPreset('My Preset', GameRules.standard);
    final updatedRules = GameRules.standard.copyWith(piecesToWin: 2);
    final updated = await service.saveNamedPreset('My Preset', updatedRules);

    final presets = await service.getPresets();
    expect(presets, hasLength(1));
    expect(presets.first.id, updated.id);
    expect(presets.first.rules.piecesToWin, 2);
  });

  test('delete preset removes it from storage', () async {
    final service = await RulePresetService.create();
    final preset =
        await service.saveNamedPreset('Temp Preset', GameRules.standard);
    await service.deletePreset(preset.id);

    final presets = await service.getPresets();
    expect(presets, isEmpty);
  });
}
