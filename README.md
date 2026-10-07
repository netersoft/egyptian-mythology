# Egyptian Mythology

[![Flutter CI](https://github.com/netersoft/egyptian-mythology/actions/workflows/flutter.yml/badge.svg)](https://github.com/netersoft/egyptian-mythology/actions/workflows/flutter.yml)

## Description

A fully offline reference and quiz app about Egyptian mythology: a documentation viewer (Gods, Cosmogonies, Myths, plus a Reference section with a glossary, a map of sites and a timeline) with full-text search, a 20-second-per-question quiz with a 3-life system, themes and a review of missed questions, score history with a progress chart, and settings for language/music/sound — available in French, English, German, Spanish and Portuguese.

This is a Flutter rewrite of a legacy native Android app (`com.neteru.ankh`). It has no backend.

## Tech stack

- Mobile: Flutter, Dart SDK `>=3.8.0 <4.0.0`
- State management: Riverpod (`riverpod_generator`, code-gen)
- Routing: go_router (`go_router_builder`)
- Local storage: Hive CE (score history) + SharedPreferences (settings, best score)
- Content: bundled JSON (quiz questions) and HTML assets (`flutter_widget_from_html_core`, documentation)
- i18n: [Slang](https://pub.dev/packages/slang)
- Audio: `audioplayers` (looping background music + click SFX)

## Prerequisites

- Flutter SDK matching `>=3.8.0 <4.0.0` (CI runs on the `stable` channel, no pinned patch version)
- A `.env` file (see [Environment variables](#environment-variables))

## Installation

```bash
cp .env.example .env
flutter pub get
dart run slang
dart run build_runner build
flutter run
```

## Environment variables

The `.env` file is bundled as an asset and loaded at runtime — treat every value in it as **public** (there is no backend to talk to, only theme colors).

| Variable | Description | Value |
|----------|-------------|-------|
| `APP_PRIMARY_COLOR` | Primary theme color, hex — golden yellow | `#FFD700` |
| `APP_SECONDARY_COLOR` | Secondary theme color, hex — goldenrod | `#DAA520` |
| `APP_ACCENT_COLOR` | Accent theme color, hex — black | `#000000` |

These mirror the legacy app's `colors.xml` palette (`goldenYellow`/`goldenRod`/`black`).

## Running tests

```bash
flutter test
# with coverage, as run in CI:
flutter test --coverage
```

## Environments

Not applicable — this is a fully offline app with no backend and no staging/production deployment targets. See [Release Builds](#release-builds) for how builds are produced.

## Architecture

The app is split into two main layers:

- `lib/core/`: state, services, routing, models, helpers, storage, and cross-cutting logic.
- `lib/view/`: screens, reusable widgets, and themes.

Runtime composition starts from:

- `lib/main.dart`: entry point only.
- `lib/core/bootstrap/app_bootstrap.dart`: Flutter, env, Hive, DI, and locale bootstrap.
- `lib/app.dart`: root app widget, theme, and router view.
- `lib/core/lifecycle/app_lifecycle_layer.dart`: app lifecycle side effects.

Internationalisation uses [Slang](https://pub.dev/packages/slang) with type-safe generated translations (`context.t`). Source files are in `assets/i18n/*.i18n.json` (base locale: fr). Locale is initialised from the device locale at bootstrap via `LocaleSettings.useDeviceLocale()`.

## Project Structure

```txt
lib/
├── main.dart                          # Entry point
├── app.dart                           # MaterialApp.router + TranslationProvider
├── core/
│   ├── bootstrap/                     # App initialisation (env, Hive, DI, locale)
│   ├── services/                      # DI, Hive, i18n, audio, quiz, scores, documentation
│   ├── routes/                        # go_router_builder route defs + GoRouter factory
│   ├── providers/                     # Riverpod providers (account/settings, navigation, quiz)
│   ├── models/                        # JSON-serializable + plain models (quiz, docs, scores)
│   ├── enums/                         # Typed constants
│   ├── helpers/                       # Router redirection, logging
│   └── tools/                         # Constants, color/string helpers
├── view/
│   ├── themes/                        # AppTheme, AppColors (from .env)
│   ├── screens/                       # Documentation, quiz, stats, account (settings), other (about), main
│   └── components/                    # Reusable widgets (backgrounds, buttons, containers, text, etc.)
├── assets/
│   ├── i18n/                          # Translation source files (*.i18n.json)
│   ├── docs/                          # Documentation HTML (gods/cosmogonies/myths/reference + credits), per locale
│   ├── glossary/                      # Glossary entries JSON, per locale
│   ├── quiz/                          # Quiz questions JSON per locale + question_refs.json (question → doc page)
│   ├── audio/                         # Background music + click SFX
│   └── images/                        # Launcher icons, splash, Egyptian artwork
└── test/                              # Unit + widget tests
```

Generated files (`*.g.dart`, `*.config.dart`) are excluded from git — they are rebuilt via `dart run build_runner build`.

## State And Dependency Management

All providers use `@riverpod` code generation. Riverpod is the app-facing state management layer.

`GetIt` is used for infrastructure singletons such as shared preferences, Hive, and navigation. New state should prefer Riverpod providers, while low-level platform services can remain injectable through `GetIt`.

## Routing

Routes are centralized in `lib/core/routes/app_route.dart` (type-safe `go_router_builder` definitions) and `lib/core/routes/router.dart` (GoRouter factory). There is no auth/access guard — every route is reachable directly, matching the legacy app.

`QuizPlayRoute`/`GameOverRoute` are deliberately direct children of `MainRoute` (siblings of `InstructionsRoute`, not nested under it) so `context.go()` from `GameOverScreen` rebuilds a minimal `[Main, Play]`/`[Main, GameOver]` stack — matching the legacy app's `FLAG_ACTIVITY_CLEAR_TASK` behavior. The normal Instructions → Play flow still uses `context.push()`.

## Features

Ported from the legacy Android app, then extended:

- **Documentation** (`view/screens/documentation/`) — browse Gods, Cosmogonies, Myths and Reference (glossary, map, timeline) as native-rendered HTML (`flutter_widget_from_html_core`). God names link to their page, glossary terms show their definition in a sheet, each section resumes where the reader left off, and a full-text search covers every page.
- **Quiz** (`view/screens/quiz/`) — 20s-per-question, 3-life state machine (`QuizController`), optionally restricted to one theme (gods, cosmogonies, myths); score persisted to Hive on game over, then a review of the missed questions with explanations and a link to the matching documentation page.
- **Stats** (`view/screens/stats/`) — score history, best score, `fl_chart` progress graph, clear history.
- **Settings** (`view/screens/account/settings_screen.dart`) — language, music/sound toggles.
- **About** (`view/screens/other/about_screen.dart`) — sources and credits page, privacy policy, contact (`mailto:`), rate (Play Store listing via `url_launcher`), share (`share_plus`).

## Fonts

The app-wide font is Kemet: [Macondo](https://fonts.google.com/specimen/Macondo) (John Vargas Beltrán) with the capital M of [Marcellus](https://fonts.google.com/specimen/Marcellus) (Astigmatic), whose inscriptional M is closer to the legacy app's Papyrus than Macondo's swashed one. `tool/build_font.py` builds it from the two sources in `tool/fonts/` (needs `pip install fonttools`). The splash title uses [Caladea](https://fonts.google.com/specimen/Caladea) Bold (Huerta Tipográfica).

All three are under the SIL Open Font License: `assets/fonts/<font>/OFL.txt` must ship with them, and the OFL's Reserved Font Names are why the modified Macondo has its own name. They replace Papyrus and Cambria, commercial fonts the app had no license to embed; `AppTextScaler`'s 1.2 factor keeps Kemet at Papyrus's apparent size.

## Privacy policy

The privacy policy ships in the app (`assets/docs/<locale>/privacy_policy.html`, one per app language, opened from the About page). The store listings link to the public copy at https://netersoft.github.io/egyptian-mythology/privacy/ (English: `/en/`), served by GitHub Pages from the public `netersoft/netersoft.github.io` repository. After editing the policy, regenerate the pages and push that repository:

```bash
python3 tool/build_privacy_pages.py ~/Dev/Projects/Web/netersoft.github.io
```

## Quality

```bash
dart format .
flutter analyze
flutter test
```

Code generation:

```bash
dart run slang
dart run build_runner build
```

Generated files (`*.g.dart`) must **not** be edited manually. They are regenerated via the commands above.

## Build Flavors (dev / staging / prod)

Flavors separate **app identity** only (so dev/staging/prod can be installed side by side on the same device/simulator) — there's a single `.env` (`cp .env.example .env` locally, `echo "$ENV_FILE" > .env` in CI), no separate `.env.dev`/`.env.staging`/`.env.prod` file to keep in sync.

- **Android** — ready to use, verified with a real build:

  ```bash
  flutter run --flavor dev
  flutter build apk --flavor staging --release
  flutter build apk --flavor prod --release
  ```

  Each flavor gets its own `applicationId` suffix (`.dev`, `.staging`, none for `prod`) and app name (`android/app/build.gradle`), so all three can be installed at once. `AndroidManifest.xml`'s label already points at the per-flavor resource.

- **iOS** — needs one manual step per flavor before `--flavor` works, since duplicating build configurations/schemes safely requires Xcode itself (not something to hand-edit in `project.pbxproj`):

  1. Open `ios/Runner.xcworkspace` in Xcode.
  2. For each flavor (`dev`, `staging`, `prod`): **Product → Scheme → Manage Schemes** → duplicate an existing scheme, name it exactly the flavor name (case-sensitive — `flutter build ios --flavor dev` looks for a scheme literally named `dev`).
  3. For each new scheme, duplicate the Debug/Release/Profile build configurations (**Project → Info → Configurations**) and give the duplicates a distinct `PRODUCT_BUNDLE_IDENTIFIER` (e.g. append `.dev`) so they can coexist on a device the same way the Android flavors do; point each new scheme at its matching configurations.
  4. Commit the resulting `project.pbxproj` and `.xcscheme` changes.

  Until that's done, `flutter build ios`/`flutter run` without `--flavor` continues to work unchanged.

## Release Builds

Pushing a `v*` tag (or running the workflow manually) triggers two build jobs in CI, after the quality job passes:

- **Android**: `flutter build apk --release --flavor prod`, uploaded as a workflow artifact. Signed with the debug key until the project has its own `key.properties` + keystore (see `android/app/build.gradle`) — good for smoke-testing and manual QA, not for a Play Store release.
- **iOS**: `flutter build ios --release --no-codesign` — verifies the iOS side still compiles. It does not produce an installable `.ipa`; that requires real Apple Developer signing (Fastlane match, an App Store Connect API key, etc.), not set up yet. Not flavor-aware yet, per the manual iOS step above.

### Android release signing

To build a properly signed Android release (e.g. for a Play Store upload):

1. Drop the release keystore somewhere under `android/` (e.g. `android/app/upload-keystore.jks`).
2. `cp android/key.properties.example android/key.properties` and fill in `storePassword`, `keyPassword`, `keyAlias`, and `storeFile`.
3. `flutter build appbundle --release --flavor prod` (or `apk`). `key.properties` is gitignored and read automatically by `android/app/build.gradle`, which then signs with this keystore instead of the debug key.

This app was previously published as `com.neteru.ankh`; reusing the original upload key (or an app-signing-managed equivalent from the Play Console) is required for updates to land on the existing store listing rather than a new one.

Add real signing (an Apple Developer account) and store-publishing steps once this app is ready to ship on iOS.

## License

Egyptian Mythology is free software by Netersoft.

- **Code**: the source code (`lib/`, `test/`, `tool/` and the platform folders) is licensed under the [GNU General Public License v3.0](LICENSE).
- **Content**: the texts, translations and pictures made by Netersoft for the app are licensed under [Creative Commons Attribution-ShareAlike 4.0](https://creativecommons.org/licenses/by-sa/4.0/).
- **Third-party files** keep their own licenses: the Kemet and Caladea fonts (SIL Open Font License 1.1, see [Fonts](#fonts)), and the pictures, music and sounds whose authors and licenses are listed in the in-app Sources and credits page (`assets/docs/<locale>/credits.html`).
- **Names and icons**: the Netersoft name, the Egyptian Mythology name, and the app icons and logos (`assets/images/launcher/` and `assets/images/egyptian/ankh_launcher.png`) are not covered by these licenses. A modified version must use another name and icon.

Copyright © 2018-2026 Netersoft.
