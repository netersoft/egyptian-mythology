# Egyptian Mythology - Agent Guide

Offline reference/quiz app about Egyptian mythology, a Flutter rewrite of a legacy
native Android app (`.legacy/`, package `com.neteru.ankh`). No backend, no auth —
see `README.md` for the full feature/architecture overview.

## Project Setup

```bash
# Install dependencies
flutter pub get

# Generate Slang translations
dart run slang

# Run codegen (Riverpod, JSON serializable, Hive)
dart run build_runner build

# Run app
flutter run
```

## Essential Commands

```bash
# Regenerate launcher icons (from assets/images/launcher/icon.png + related)
dart run icons_launcher:create

# Regenerate splash screen (from assets/images/launcher/splash_logo.png + splash_background.png)
dart run flutter_native_splash:create

# Remove native splash
dart run flutter_native_splash:remove
```

## Code Quality

```bash
# Lint + static analysis
flutter analyze
dart analyze

# Format
dart format .
```

## Architecture

- **Entry point**: `lib/main.dart`
- **Core layer** (`lib/core/`): providers, services, models, routes, helpers
- **View layer** (`lib/view/`): screens, components, themes
- **State management**: Riverpod with code generation (`riverpod_generator`)
- **Routing**: go_router (`go_router_builder`)
- **Local storage**: Hive CE (score history) + SharedPreferences (settings)
- **Content**: bundled JSON (quiz) and HTML (documentation) assets, no REST API

## Environment

- Copy `.env.example` to `.env` before running
- SDK: `>=3.8.0 <4.0.0`

## Testing

Tests live under `test/` (`helpers/`, `models/`, `providers/`, `screens/`, `services/`),
using `mocktail` with a GetIt test-locator override (`test/helpers/test_utils.dart`) to
mock infrastructure singletons. Widget tests navigating through `MainRoute` (infinite
ankh-shake animation) or a screen with a real repeating `Timer` must never call
`pumpAndSettle()` — use a bounded `pump()`/`pump(duration)` pair instead.

```bash
flutter test
```
