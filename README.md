# Ludo Club

A rebuilt Flutter Ludo app with a lean codebase, Material 3 UI, pure Dart game
rules, and a custom-painted board. The app no longer depends on image, SVG,
audio, database, AI, or statistics layers.

## What is included

- Local 2-4 player Ludo match
- Exact finish, safe fields, captures, extra turn on six or capture
- Optional rule variants for opening rolls, mandatory base exits, own-field blocks, capture bonuses, finish bonuses, third-six penalties, and mandatory captures
- Editable local player names, legal-move target explanations, undo, and a compact move log
- Automatic local save/resume via shared preferences with an explicit clear-save action
- Responsive 15x15 Ludo board rendered with Flutter canvas and widgets
- Mobile-first play surface with sticky action dock, bottom-sheet setup/rules/log, larger touch targets, target taps, auto single-move turns, and haptic feedback
- Generated brand mark, native/web app icons, avatars, dice art, and background texture
- Single controller based on `ChangeNotifier`
- Focused tests for rules, controller behavior, and app rendering

## Project layout

```text
lib/
├── logic/          # Pure Ludo rules
├── models/         # Immutable game state and domain models
├── providers/      # Thin UI controller
├── theme/          # UI palette helpers
├── ui/             # Main game screen
├── widgets/        # Board, dice, player progress widgets
└── main.dart       # App entry

assets/
├── avatars/        # Generated fictional player portraits
├── backgrounds/    # Generated in-app background art
├── branding/       # Generated brand mark used by the UI and web icons
├── dice/           # Generated roll-dice HUD artwork
└── pins/           # Generated player pin artwork

test/
├── logic/
├── providers/
└── widget/
```

## Development

```sh
flutter pub get
dart format .
flutter analyze
flutter test
flutter run -d chrome
```

## Device checks

```sh
flutter build ios --debug --no-codesign
flutter build apk --debug
```

iPhone builds are portrait-first. Android builds require a local Android SDK
and `ANDROID_HOME`; release distribution also needs a real release signing
configuration instead of debug signing.

## Notes

The native Flutter platform folders are intentionally kept. They are scaffold
and integration files, not disposable build artifacts. Generated build output
is cleaned with `flutter clean`.
