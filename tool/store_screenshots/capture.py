"""Captures the raw screens for the Play Store screenshots, in one language.

Drives the app with adb on the shared `test-phone` emulator (1080x2400),
with SystemUI demo mode on (see README.md next to this file). Positions are
those of that screen size; every step waits for its screen to show up and
fails loudly when it doesn't.

    python3 tool/store_screenshots/capture.py <out_dir> <lang>

Writes <out_dir>/<lang>/<screen>.png for the screens listed in config.json.
The score history (for the progress chart) must already hold a few games:
see README.md.
"""

import subprocess
import sys
import time
from io import BytesIO
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from quiz_bot import QuizBot  # noqa: E402

PACKAGE = 'com.neteru.ankh.dev'
LANGS = ['fr', 'en', 'de', 'es', 'pt']  # order of the language picker
SHOT = Path('/tmp/store_screenshots_shot.png')

# Main menu buttons, top to bottom.
MENU = {'documentation': 1048, 'quiz': 1226, 'stats': 1404, 'settings': 1584}
# Documentation menu buttons.
DOCS = {'gods': 1092, 'reference': 1626}


def adb(*args):
    subprocess.run(['adb', 'shell', *map(str, args)], check=True, capture_output=True)


def tap(x, y, wait=1.0):
    adb('input', 'tap', x, y)
    time.sleep(wait)


def back(wait=1.5):
    adb('input', 'keyevent', 'KEYCODE_BACK')
    time.sleep(wait)


def screen():
    png = subprocess.run(['adb', 'exec-out', 'screencap', '-p'], check=True, capture_output=True).stdout
    SHOT.write_bytes(png)
    return Image.open(BytesIO(png)).convert('RGB')


def shot_path():
    screen()
    return str(SHOT)


def is_yellow(p):
    return p[0] > 220 and p[1] > 170 and p[2] < 60


def wait_until(check, what, timeout=30):
    deadline = time.time() + timeout
    while time.time() < deadline:
        img = screen()
        # Android's "Viewing full screen" hint (light sheet, blue "Got it").
        if all(c > 220 for c in img.getpixel((540, 120))) and img.getpixel((925, 631))[2] > 120:
            tap(925, 631, 2)
            continue
        if check(img):
            return img
        time.sleep(1)
    raise RuntimeError(f'{what} did not show up within {timeout}s')


def menu_shown(img):
    """The main or documentation menu: a column of yellow buttons."""
    return all(is_yellow(img.getpixel((700, y))) for y in (1048, 1226, 1404))  # right of the labels


def restart():
    adb('am', 'force-stop', PACKAGE)
    adb('monkey', '-p', PACKAGE, '-c', 'android.intent.category.LAUNCHER', '1')
    wait_until(menu_shown, 'the main menu', 40)
    time.sleep(1)


def set_language(lang):
    restart()
    tap(540, MENU['settings'], 2)
    tap(540, 1962, 1.5)                      # language row
    tap(320, 1674 + 147 * LANGS.index(lang), 3)
    restart()                                # whatever the picker did, start clean


def map_top(img):
    """Top of the map of sites: first row with the map's blue."""
    for y in range(250, 2200, 2):
        if sum(1 for x in range(40, 1040, 6) if img.getpixel((x, y)) == (64, 164, 223)) >= 3:
            return y
    return None


def scroll_to(detect, target):
    for _ in range(8):
        y = detect(screen())
        if y is None:
            adb('input', 'swipe', 540, 1600, 540, 1100, 800)
            time.sleep(1)
            continue
        delta = y - target
        if abs(delta) <= 8:
            return
        step = max(-1000, min(1000, delta))
        step += 21 if step > 0 else -21     # touch slop
        adb('input', 'swipe', 540, 1500, 540, 1500 - step, 1500)
        time.sleep(1.2)
    raise RuntimeError(f'could not scroll to {target}')


def capture(out, lang):
    out = Path(out) / lang
    out.mkdir(parents=True, exist_ok=True)
    set_language(lang)

    # 1. Main menu.
    screen().save(out / 'menu.png')

    # 2. A god's page: Anubis, 5th entry of the Gods drawer in every language.
    tap(540, MENU['documentation'], 2)
    wait_until(menu_shown, 'the documentation menu')
    tap(540, DOCS['gods'], 2.5)
    tap(72, 206, 1.5)
    tap(120, 1236, 3)
    wait_until(lambda img: sum(img.getpixel((60, 600))) < 40, 'the Anubis page')  # black reader background
    screen().save(out / 'god.png')

    # 3. The map of sites: 2nd entry of the Reference drawer.
    back()
    wait_until(menu_shown, 'the documentation menu')
    tap(540, DOCS['reference'], 2.5)
    tap(72, 206, 1.5)
    tap(180, 794, 3)
    scroll_to(map_top, 600)
    screen().save(out / 'map.png')

    # 4. Score progression (the history is shared by every language).
    restart()
    tap(540, MENU['stats'], 2.5)
    tap(332, 2204, 2.5)                      # Progress
    wait_until(lambda img: all(c > 240 for c in img.getpixel((540, 1700))), 'the progression chart')
    screen().save(out / 'progress.png')

    # 5. The quiz, a right answer turning green; 6. the review of mistakes.
    restart()
    tap(540, MENU['quiz'], 2)
    tap(540, 2204, 3)                        # Let's play
    bot = QuizBot(lang, shot_path)
    # Keep the first frame where the tapped answer shows the right-answer
    # green. The OCR sometimes misreads a question: then try the next one.
    green = lambda p: p[1] > 200 and p[0] < 80 and p[2] < 80
    for attempt in range(5):
        for _ in range(10):
            if (xy := bot.answer(correct=True)) is not None:
                break
            time.sleep(1)
        else:
            raise RuntimeError('no quiz question showed up')
        try:
            wait_until(lambda img: green(img.getpixel((xy[0] - 140, xy[1]))), 'the green right answer', 3).save(out / 'quiz.png')
            break
        except RuntimeError:
            time.sleep(2.5)                  # wrong pick: wait for the next question
    else:
        raise RuntimeError('no right answer in 5 questions')
    time.sleep(2)
    bot.play(rights=5)                       # then wrong answers until game over
    wait_until(lambda img: bot.game_over(), 'the game-over screen')
    for y in (1314, 1418):                   # the button sits lower under a "record" banner
        tap(540, y, 2.5)
        if sum(screen().getpixel((1000, 150))) < 30:   # black app bar of the review
            break
    else:
        raise RuntimeError('the review of mistakes did not open')
    screen().save(out / 'review.png')


if __name__ == '__main__':
    capture(sys.argv[1], sys.argv[2])
