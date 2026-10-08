"""Answers the quiz on the emulator, right or wrong on purpose.

Reads the question and the four choices with macOS Vision (ocr.swift), finds
the question in assets/quiz/questions_<lang>.json and taps the right answer
(or a wrong one).
"""

import difflib
import itertools
import json
import subprocess
import tempfile
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
OCR_LANG = {'fr': 'fr-FR', 'en': 'en-US', 'de': 'de-DE', 'es': 'es-ES', 'pt': 'pt-BR'}


_OCR_BIN = Path(tempfile.gettempdir()) / 'store_screenshots_ocr'


def ocr(png, lang):
    # Compiled once: running the script with `swift` recompiles it each time.
    if not _OCR_BIN.exists() or _OCR_BIN.stat().st_mtime < (HERE / 'ocr.swift').stat().st_mtime:
        subprocess.run(['swiftc', '-O', str(HERE / 'ocr.swift'), '-o', str(_OCR_BIN)], check=True, timeout=300)
    # A hung OCR call must fail the run, not freeze it.
    out = subprocess.run([str(_OCR_BIN), str(png), OCR_LANG[lang]], check=True, capture_output=True, text=True, timeout=60).stdout
    lines = []
    for row in out.splitlines():
        box, text = row.split('\t', 1)
        x, y, w, h = map(int, box.split())
        lines.append((x, y, w, h, text))
    return lines


def similarity(a, b):
    return difflib.SequenceMatcher(None, a.lower(), b.lower()).ratio()


class QuizBot:
    def __init__(self, lang, shot):
        self.lang = lang
        self.shot = shot  # () -> path of a fresh full-screen capture
        self.questions = json.loads((ROOT / f'assets/quiz/questions_{lang}.json').read_text(encoding='utf-8'))

    def read(self):
        """(question, {choice text: (x, y)}) on screen, or None between questions."""
        lines = ocr(self.shot(), self.lang)
        question = ' '.join(t for x, y, w, h, t in lines if 1100 <= y <= 1450 and not t.strip().isdigit())
        # The 2x2 answer grid fills the band from y 1620 to 2080.
        cells = {}
        for x, y, w, h, t in lines:
            if 1620 <= y <= 2080:
                cx, cy = (284 if x + w / 2 < 540 else 796), (1736 if y + h / 2 < 1850 else 1964)
                cells.setdefault((cx, cy), []).append(t)
        if not question or len(cells) != 4:
            return None
        return question, {' '.join(v): k for k, v in cells.items()}

    def answer(self, correct=True):
        """Taps an answer; returns the tapped (x, y), or None when no question
        is on screen."""
        state = self.read()
        if state is None:
            return None
        question, cells = state
        entry = max(self.questions, key=lambda q: similarity(q['question'], question))
        # Short answers in the app's display font are often misread, so match
        # the four buttons to the four known choices at once (best overall
        # pairing), instead of looking for the answer alone.
        texts = list(cells)
        pairing = max(itertools.permutations(entry['choices']),
                      key=lambda choices: sum(similarity(t, c) for t, c in zip(texts, choices)))
        right = cells[texts[pairing.index(entry['answer'])]]
        target = right if correct else next(xy for xy in cells.values() if xy != right)
        subprocess.run(['adb', 'shell', 'input', 'tap', *map(str, target)], check=True)
        return target

    def game_over(self):
        """The game-over screen: its three yellow buttons (replay, home,
        stats) along the bottom, which no quiz screen has."""
        from PIL import Image
        im = Image.open(self.shot()).convert('RGB')
        return all((lambda p: p[0] > 220 and p[1] > 170 and p[2] < 60)(im.getpixel((x, 2140))) for x in (180, 470, 760))

    def play(self, rights, between=2.6, timeout=600):
        """Answers `rights` questions right, then wrong ones until the game is
        over. Raises when the game neither goes on nor ends, rather than
        reporting a game it didn't finish."""
        deadline = time.time() + timeout
        answered = 0
        while not self.game_over():
            if time.time() > deadline:
                raise RuntimeError(f'game not over after {timeout}s ({answered} answers)')
            if self.answer(correct=answered < rights) is not None:
                answered += 1
                time.sleep(between)
            else:
                time.sleep(1)
        return answered

    def wait_for(self, text, timeout=30):
        """Waits until `text` is read on screen; returns its centre."""
        deadline = time.time() + timeout
        while time.time() < deadline:
            for x, y, w, h, t in ocr(self.shot(), self.lang):
                if similarity(t, text) > 0.7:
                    return x + w // 2, y + h // 2
            time.sleep(1)
        raise RuntimeError(f'"{text}" did not show up within {timeout}s')
