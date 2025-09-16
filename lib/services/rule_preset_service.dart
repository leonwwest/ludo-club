import 'dart:convert';

import 'package:ludo_club/models/game_rules.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RulePreset {
  final String id;
  final String name;
  final GameRules rules;

  const RulePreset({required this.id, required this.name, required this.rules});

  RulePreset copyWith({String? id, String? name, GameRules? rules}) {
    return RulePreset(
      id: id ?? this.id,
      name: name ?? this.name,
      rules: rules ?? this.rules,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rules': rules.toJson(),
      };

  factory RulePreset.fromJson(Map<String, dynamic> json) {
    return RulePreset(
      id: json['id'] as String,
      name: json['name'] as String,
      rules: GameRules.fromJson(json['rules'] as Map<String, dynamic>),
    );
  }
}

class RulePresetService {
  RulePresetService(this._prefs);

  static const String _storageKey = 'rule_presets_v1';

  final SharedPreferences _prefs;

  static Future<RulePresetService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return RulePresetService(prefs);
  }

  Future<List<RulePreset>> getPresets() async {
    final encoded = _prefs.getString(_storageKey);
    if (encoded == null) {
      return const [];
    }
    final decoded = json.decode(encoded);
    if (decoded is! List) {
      return const [];
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(RulePreset.fromJson)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<RulePreset> saveNamedPreset(String name, GameRules rules) async {
    final presets = (await getPresets()).toList();
    final lower = name.trim().toLowerCase();
    int index = -1;
    for (int i = 0; i < presets.length; i++) {
      if (presets[i].name.trim().toLowerCase() == lower) {
        index = i;
        break;
      }
    }

    late RulePreset preset;
    if (index >= 0) {
      preset = presets[index].copyWith(name: name.trim(), rules: rules);
      presets[index] = preset;
    } else {
      preset = RulePreset(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name.trim(),
        rules: rules,
      );
      presets.add(preset);
    }

    await _write(presets);
    return preset;
  }

  Future<void> deletePreset(String id) async {
    final presets = (await getPresets()).toList();
    presets.removeWhere((preset) => preset.id == id);
    await _write(presets);
  }

  Future<void> _write(List<RulePreset> presets) async {
    final encoded = json.encode(presets.map((p) => p.toJson()).toList());
    await _prefs.setString(_storageKey, encoded);
  }
}
