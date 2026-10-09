# Play Store screenshots

`store/screenshots/<lang>/` holds the 6 phone screenshots of the store listing, one set per
app language: 1080×1920 (9:16) 24-bit PNGs, a gold title in the app's Kemet font over an
indigo gradient, and the whole app screen in a phone frame.

## Feature graphic

`store/feature_graphic/<lang>.png` is the 1024×500 banner at the top of the listing: the
app's icon, name and a tagline next to two of the screenshots, cut out of
`store/screenshots/<lang>/`. Rebuild it after the screenshots:

```bash
python3 tool/store_screenshots/feature.py
```

Its icon, screens, names and taglines are under `feature` in `config.json`.

## Regenerate them

1. Start the shared emulator (`test-phone`, 1080×2400) and install a fresh build:

   ```bash
   flutter build apk --profile --flavor dev
   adb install -r build/app/outputs/flutter-apk/app-dev-profile.apk
   adb shell pm clear com.neteru.ankh.dev
   ```

2. Clean status bar (10:00, full battery and Wi-Fi, no notifications):

   ```bash
   adb shell settings put global sysui_demo_allowed 1
   adb shell am broadcast -a com.android.systemui.demo -e command enter
   adb shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 1000
   adb shell am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged false
   adb shell am broadcast -a com.android.systemui.demo -e command network -e wifi show -e level 4 -e fully true
   adb shell am broadcast -a com.android.systemui.demo -e command network -e mobile hide
   adb shell am broadcast -a com.android.systemui.demo -e command notifications -e visible false
   ```

3. Fill the score history so the progression chart has a curve: play a handful of games
   with rising scores, by hand or with `quiz_bot.py` (`QuizBot(lang, shot).play(rights)`
   answers `rights` questions right, then wrong ones until the game is over).

4. Capture each language and build the images:

   ```bash
   for lang in en fr de es pt; do python3 tool/store_screenshots/capture.py /tmp/captures $lang; done
   python3 tool/store_screenshots/compose.py /tmp/captures
   ```

   Each capture plays one more game (for the quiz and the review of mistakes), which joins
   the history shown on the next languages' chart.

5. Look at every image before uploading them, then exit demo mode
   (`adb shell am broadcast -a com.android.systemui.demo -e command exit`).

## How it works

- `config.json`: screen order, titles in each language, colors, and `"fit": "full"` (show
  the whole phone: the quiz answers and the chart sit at the bottom of the screen).
- `capture.py` drives the app with `adb` taps at the positions of a 1080×2400 screen and
  waits for each screen from its pixels, failing loudly when one doesn't show up.
- `quiz_bot.py` reads the quiz with macOS Vision (`ocr.swift`, compiled once into the temp
  folder), finds the question in `assets/quiz/questions_<lang>.json` and taps the right
  answer. Vision's `.accurate` mode hangs on macOS 27, hence `.fast`; it misreads a question
  now and then, so the capture retries until an answer turns green.
- `compose.py` builds the final images.
