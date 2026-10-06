"""Builds Kemet, the app-wide font: Macondo with the capital M of Marcellus.

Macondo keeps the hand-lettered look of the legacy app's Papyrus, but its
swashed M reads poorly in "Main Menu", "Memphis" or "Maât"; Marcellus's
inscriptional M is close to Papyrus's. Both fonts are under the SIL Open
Font License with Reserved Font Names, so the result is renamed and stays
under the OFL (assets/fonts/kemet/OFL.txt).

Sources: tool/fonts/Macondo-Regular.ttf and tool/fonts/Marcellus-Regular.ttf
(Google Fonts). Needs fontTools:  pip install fonttools
Re-run after changing a source:  python3 tool/build_font.py
"""
from pathlib import Path

from fontTools.pens.transformPen import TransformPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parent.parent
SOURCES = ROOT / 'tool' / 'fonts'
OUT = ROOT / 'assets' / 'fonts' / 'kemet' / 'Kemet-Regular.ttf'

FAMILY = 'Kemet'
VERSION = '1.000'


def cap_height(font: TTFont) -> int:
    glyf = font['glyf']
    h = glyf[font.getBestCmap()[ord('H')]]
    h.recalcBounds(glyf)
    return h.yMax


def main() -> None:
    base = TTFont(SOURCES / 'Macondo-Regular.ttf')
    donor = TTFont(SOURCES / 'Marcellus-Regular.ttf')

    # Marcellus's M, scaled so its cap height matches Macondo's.
    scale = cap_height(base) / cap_height(donor)
    name = base.getBestCmap()[ord('M')]
    donor_name = donor.getBestCmap()[ord('M')]
    pen = TTGlyphPen(None)
    donor.getGlyphSet()[donor_name].draw(TransformPen(pen, (scale, 0, 0, scale, 0, 0)))
    glyph = pen.glyph()  # no hinting instructions: they were written for Marcellus
    base['glyf'][name] = glyph
    glyph.recalcBounds(base['glyf'])
    advance = round(donor['hmtx'][donor_name][0] * scale)
    base['hmtx'][name] = (advance, glyph.xMin)

    # The signature no longer matches the modified font.
    if 'DSIG' in base:
        del base['DSIG']

    copyright_ = (
        base['name'].getDebugName(0).strip().rstrip('.')
        + '. Copyright (c) 2012, Brian J. Bonislawsky DBA Astigmatic (AOETI), with Reserved Font Names "Marcellus".'
        + ' Kemet: Macondo with the M of Marcellus, by Netersoft (2026).'
    )
    names = {
        0: copyright_,
        1: FAMILY,
        2: 'Regular',
        3: f'{VERSION};NETERSOFT;{FAMILY}-Regular',
        4: f'{FAMILY} Regular',
        5: f'Version {VERSION}',
        6: f'{FAMILY}-Regular',
        16: FAMILY,
        17: 'Regular',
    }
    table = base['name']
    for record in list(table.names):
        if record.nameID in (7, 8, 9, 11, 12, 16, 17, 18, 21, 22):
            table.removeNames(nameID=record.nameID)
    for name_id, value in names.items():
        table.setName(value, name_id, 3, 1, 0x409)
        table.setName(value, name_id, 1, 0, 0)
    table.setName('This Font Software is licensed under the SIL Open Font License, Version 1.1.', 13, 3, 1, 0x409)
    table.setName('https://openfontlicense.org', 14, 3, 1, 0x409)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    base.save(OUT)
    print(OUT)


if __name__ == '__main__':
    main()
