"""Draws the Heliopolitan family tree shown on the Heliopolis cosmogony page.

One PNG per locale (assets/docs/res/pictures/cosmogonies/arbre-<locale>.png),
transparent, in the docs' gold tones so it reads on their black background.
Re-run after changing a name:  python3 tool/family_tree.py
"""
from PIL import Image, ImageDraw, ImageFont

NAMES = {
    'fr': ['Noun', 'Atoum', 'Chou', 'Tefnout', 'Geb', 'Nout', 'Osiris', 'Isis', 'Horus\nl’Ancien', 'Seth', 'Nephtys', 'Horus'],
    'en': ['Nun', 'Atum', 'Shu', 'Tefnut', 'Geb', 'Nut', 'Osiris', 'Isis', 'Horus\nthe Elder', 'Seth', 'Nephthys', 'Horus'],
    'de': ['Nun', 'Atum', 'Schu', 'Tefnut', 'Geb', 'Nut', 'Osiris', 'Isis', 'Horus\nder Ältere', 'Seth', 'Nephthys', 'Horus'],
    'es': ['Nun', 'Atum', 'Shu', 'Tefnut', 'Geb', 'Nut', 'Osiris', 'Isis', 'Horus\nel Viejo', 'Seth', 'Neftis', 'Horus'],
    'pt': ['Nun', 'Atum', 'Shu', 'Tefnut', 'Geb', 'Nut', 'Osíris', 'Ísis', 'Hórus,\no Velho', 'Seth', 'Néftis', 'Hórus'],
}

W, H = 1100, 1060
TEXT = (255, 223, 0, 255)
LINE = (218, 165, 32, 255)
FONT = ImageFont.truetype('assets/fonts/montserrat/montserrat_medium.ttf', 42)
STROKE = 4

# Vertical centre of each generation; horizontal positions are computed from
# the rendered label widths so long names never touch or leave the canvas.
ROWS = {'nun': 60, 'atum': 220, 'shu': 380, 'tefnut': 380, 'geb': 560, 'nut': 560,
        'osiris': 790, 'isis': 790, 'elder': 790, 'seth': 790, 'nephthys': 790, 'horus': 990}
SPOUSE_GAP = 90  # room for the double marriage line
SIBLING_GAP = 50
KEYS = ['nun', 'atum', 'shu', 'tefnut', 'geb', 'nut', 'osiris', 'isis', 'elder', 'seth', 'nephthys', 'horus']


def draw(locale):
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    names = dict(zip(KEYS, NAMES[locale]))
    width = lambda k: d.multiline_textbbox((0, 0), names[k], font=FONT, spacing=4)[2]

    # Last row: [Osiris = Isis]  Horus the Elder  [Seth = Nephthys], centred.
    last = ['osiris', 'isis', 'elder', 'seth', 'nephthys']
    gaps = [SPOUSE_GAP, SIBLING_GAP, SIBLING_GAP, SPOUSE_GAP]
    total = sum(width(k) for k in last) + sum(gaps)
    assert total <= W - 20, f'{locale}: last row is {total}px wide'
    x = (W - total) / 2
    pos = {}
    for i, k in enumerate(last):
        pos[k] = (x + width(k) / 2, ROWS[k])
        x += width(k) + (gaps[i] if i < len(gaps) else 0)
    for a, b in (('shu', 'tefnut'), ('geb', 'nut')):
        half = (width(a) + SPOUSE_GAP + width(b)) / 2
        pos[a] = (W / 2 - half + width(a) / 2, ROWS[a])
        pos[b] = (W / 2 + half - width(b) / 2, ROWS[b])
    pos['nun'] = (W / 2, ROWS['nun'])
    pos['atum'] = (W / 2, ROWS['atum'])
    right_of_osiris = pos['osiris'][0] + width('osiris') / 2
    pos['horus'] = ((right_of_osiris + pos['isis'][0] - width('isis') / 2) / 2, ROWS['horus'])

    boxes = {}
    for key, name in names.items():
        x, y = pos[key]
        box = d.multiline_textbbox((x, y), name, font=FONT, anchor='mm', align='center', spacing=4)
        boxes[key] = box
        d.multiline_text((x, y), name, font=FONT, fill=TEXT, anchor='mm', align='center', spacing=4)

    top = lambda k: (pos[k][0], boxes[k][1] - 14)
    bottom = lambda k: (pos[k][0], boxes[k][3] + 14)

    def couple(a, b):
        # Double line between spouses; returns the point children hang from.
        y = pos[a][1]
        x0, x1 = boxes[a][2] + 12, boxes[b][0] - 12
        d.line([(x0, y - 5), (x1, y - 5)], fill=LINE, width=STROKE)
        d.line([(x0, y + 5), (x1, y + 5)], fill=LINE, width=STROKE)
        return ((x0 + x1) // 2, y + 5)

    def children(parent, kids, bar_y):
        px, py = parent
        d.line([(px, py), (px, bar_y)], fill=LINE, width=STROKE)
        xs = [pos[k][0] for k in kids]
        d.line([(min(xs + [px]), bar_y), (max(xs + [px]), bar_y)], fill=LINE, width=STROKE)
        for k in kids:
            d.line([(pos[k][0], bar_y), top(k)], fill=LINE, width=STROKE)

    # Atum emerges from the Nun: dashed line.
    (x, y0), (_, y1) = bottom('nun'), top('atum')
    for y in range(y0, y1, 18):
        d.line([(x, y), (x, min(y + 9, y1))], fill=LINE, width=STROKE)

    children(bottom('atum'), ['shu', 'tefnut'], 300)
    children(couple('shu', 'tefnut'), ['geb', 'nut'], 480)
    children(couple('geb', 'nut'), ['osiris', 'isis', 'elder', 'seth', 'nephthys'], 680)
    couple('seth', 'nephthys')
    oi = couple('osiris', 'isis')
    d.line([oi, top('horus')], fill=LINE, width=STROKE)

    img.save(f'assets/docs/res/pictures/cosmogonies/arbre-{locale}.png', optimize=True)


if __name__ == '__main__':
    for locale in NAMES:
        draw(locale)
