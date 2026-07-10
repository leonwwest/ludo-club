import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ludo_club/constants/app_colors.dart';
import 'package:ludo_club/l10n/app_localizations.dart';
import 'package:ludo_club/services/app_settings.dart';

class SettingsCard extends StatelessWidget {
  const SettingsCard({
    required this.settings,
    required this.onReplayTutorial,
    super.key,
  });

  final AppSettingsController settings;
  final VoidCallback onReplayTutorial;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.settingsTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.volume_up_outlined),
              title: Text(l10n.sound),
              subtitle: Text(l10n.soundSubtitle),
              value: settings.soundEnabled,
              onChanged: (value) => unawaited(settings.setSoundEnabled(value)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.vibration_outlined),
              title: Text(l10n.haptics),
              subtitle: Text(l10n.hapticsSubtitle),
              value: settings.hapticsEnabled,
              onChanged: (value) =>
                  unawaited(settings.setHapticsEnabled(value)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.motion_photos_off_outlined),
              title: Text(l10n.reduceMotion),
              subtitle: Text(l10n.reduceMotionSubtitle),
              value: settings.reducedMotion,
              onChanged: (value) => unawaited(settings.setReducedMotion(value)),
            ),
            const Divider(height: 28),
            Text(
              l10n.language,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.slate600,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            SegmentedButton<AppLocaleMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: AppLocaleMode.system,
                  icon: const Icon(Icons.settings_suggest_outlined),
                  label: Text(l10n.systemLanguage),
                ),
                ButtonSegment(
                  value: AppLocaleMode.german,
                  label: Text(l10n.germanLanguage),
                ),
                ButtonSegment(
                  value: AppLocaleMode.english,
                  label: Text(l10n.englishLanguage),
                ),
              ],
              selected: {settings.localeMode},
              onSelectionChanged: (selection) =>
                  unawaited(settings.setLocaleMode(selection.first)),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onReplayTutorial,
              icon: const Icon(Icons.school_outlined),
              label: Text(l10n.tutorialReplay),
            ),
          ],
        ),
      ),
    );
  }
}
